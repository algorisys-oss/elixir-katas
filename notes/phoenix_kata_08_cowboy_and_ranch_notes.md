# Kata 08: Cowboy & Ranch

## Where Cowboy Fits

In Kata 06, we built a raw TCP server with `:gen_tcp`. In Kata 07, we parsed HTTP by hand. Now let's meet the tools that do this **professionally** — **Ranch** and **Cowboy**.

```
Your Phoenix App
      ↑
   Phoenix Framework
      ↑
     Plug
      ↑
   Cowboy    ← HTTP server (parses HTTP, manages connections)
      ↑
   Ranch     ← TCP connection pool (accepts sockets, spawns workers)
      ↑
   :gen_tcp   ← Raw TCP (what we built in Kata 06)
```

Ranch and Cowboy replace our hand-rolled TCP server and HTTP parser with battle-tested, production-grade implementations.

---

## Ranch: The TCP Connection Pool

**Ranch** is an Erlang library (by the Cowboy team) that manages TCP connections. It does what our `accept_loop` did in Kata 06, but much better.

### What Ranch Does

1. **Listens** on a TCP port (like our `:gen_tcp.listen`)
2. **Accepts** connections using a pool of acceptor processes
3. **Spawns** a worker process for each connection
4. **Supervises** everything — crashes are handled gracefully

### Ranch Architecture

```
┌─────────────────────────────────────────┐
│              Ranch Listener              │
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐│
│  │Acceptor 1│ │Acceptor 2│ │Acceptor N││  ← Pool of acceptors
│  └────┬─────┘ └────┬─────┘ └────┬─────┘│
│       │             │             │      │
│  ┌────▼─────┐ ┌────▼─────┐ ┌────▼─────┐│
│  │ Worker 1 │ │ Worker 2 │ │ Worker N ││  ← One per connection
│  └──────────┘ └──────────┘ └──────────┘│
└─────────────────────────────────────────┘
```

Compare this to our Kata 06 server:
- We had **one** acceptor (single `accept_loop`)
- Ranch has **many** acceptors (default: 100)
- We used `spawn/1` for workers — no supervision
- Ranch uses supervised processes — crashes are recovered

### Ranch vs Our TCP Server

| Feature | Our Kata 06 Server | Ranch |
|---------|--------------------|-------|
| Acceptors | 1 (single loop) | 100 (configurable pool) |
| Supervision | None | Full OTP supervision tree |
| Backpressure | None | Connection limits |
| Transport | TCP only | TCP + TLS |
| Error handling | Crash = gone | Restart policy |

---

## Cowboy: The HTTP Server

**Cowboy** is an HTTP server built on top of Ranch. While Ranch handles TCP connections, Cowboy handles the HTTP protocol on top of those connections.

### What Cowboy Does

1. Reads raw TCP data from Ranch workers
2. **Parses** HTTP requests (like our Kata 07 parser, but production-grade)
3. Routes requests to **handlers** (your code)
4. **Builds** and sends HTTP responses
5. Supports HTTP/1.1, HTTP/2, and WebSockets

### Cowboy Request Flow

```
TCP bytes arrive (from Ranch)
    │
    ▼
┌─────────────────────────┐
│ Cowboy HTTP/1.1 Parser   │  Parses request line, headers, body
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Cowboy creates Req map   │  %{method: "GET", path: "/products", ...}
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Dispatch to handler      │  Your module's init/2 callback
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Handler returns response │  {status, headers, body}
└──────────┬──────────────┘
           │
           ▼
Cowboy sends HTTP response bytes back via TCP
```

### Cowboy Request Object

Cowboy creates a **request map** (Erlang map) from the parsed HTTP:

```erlang
%{
  method => "GET",
  path => "/products",
  qs => "page=2",
  headers => %{"host" => "example.com", "accept" => "text/html"},
  version => "HTTP/1.1",
  peer => {{127, 0, 0, 1}, 54321}
}
```

This is the **ancestor** of Phoenix's `%Plug.Conn{}` — Plug wraps this Cowboy request map into its own struct.

---

## Cowboy Handlers

In pure Cowboy (without Phoenix), you write **handler modules**:

```elixir
defmodule MyHandler do
  def init(req, state) do
    # req is Cowboy's request map
    method = :cowboy_req.method(req)
    path = :cowboy_req.path(req)

    {status, body} =
      case {method, path} do
        {"GET", "/"} -> {200, "Welcome!"}
        {"GET", "/about"} -> {200, "About page"}
        _ -> {404, "Not found"}
      end

    req = :cowboy_req.reply(status, %{
      "content-type" => "text/html"
    }, body, req)

    {:ok, req, state}
  end
end
```

### Dispatch Rules

Cowboy uses **dispatch rules** to map URLs to handlers:

```elixir
dispatch = :cowboy_router.compile([
  {:_, [                              # Any host
    {"/", MyHandler, []},             # / → MyHandler
    {"/api/[...]", ApiHandler, []},   # /api/* → ApiHandler
    {:_, NotFoundHandler, []}         # Everything else → 404
  ]}
])
```

The `{:_, routes}` pattern means "for any hostname." Each route is `{path_pattern, handler_module, initial_state}`.

---

## Starting a Cowboy Server

```elixir
# In your application supervisor:
:cowboy.start_clear(:my_http_listener,
  [port: 4000],                    # Ranch options (TCP)
  %{env: %{dispatch: dispatch}}    # Cowboy options (HTTP)
)
```

This single call:
1. Tells **Ranch** to listen on port 4000
2. Tells **Cowboy** to parse HTTP and dispatch to handlers
3. Creates the full supervision tree

---

## How Phoenix Uses Cowboy

Phoenix doesn't call Cowboy directly — it goes through **Plug**. But here's what happens under the hood:

```
mix phx.server
    │
    ▼
Phoenix.Endpoint.start_link()
    │
    ▼
Plug.Cowboy.http(MyAppWeb.Endpoint, [], port: 4000)
    │
    ▼
:cowboy.start_clear(:my_app_http, [port: 4000], cowboy_opts)
    │
    ▼
Ranch starts listening → Cowboy handles HTTP → Plug transforms → Phoenix routes
```

### Phoenix's Cowboy Configuration

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  http: [port: 4000],           # Ranch: listen on port 4000
  debug_errors: true,           # Cowboy: show error details
  check_origin: false           # Cowboy: WebSocket origin check
```

These options are passed through Phoenix → Plug → Cowboy → Ranch.

---

## Cowboy's WebSocket Support

Cowboy also handles **WebSocket** connections (which Phoenix Channels and LiveView use):

```
1. Browser: GET /live/websocket (HTTP Upgrade request)
2. Cowboy: Detects Upgrade header → switches protocol
3. Cowboy: Sends 101 Switching Protocols
4. Connection: Now uses WebSocket framing (not HTTP)
5. Phoenix: LiveView communicates over this WebSocket
```

This is how LiveView gets its real-time updates — Cowboy manages the WebSocket connection, Phoenix sends/receives messages over it.

---

## Inspecting Cowboy in Your Phoenix App

You can see Cowboy and Ranch in action:

```elixir
# In IEx (iex -S mix phx.server):

# See Ranch listeners
:ranch.info()
# => [{:my_app_http, ...}]

# See connection count
:ranch.procs(:my_app_http, :connections)

# See Cowboy's process tree
Process.list()
|> Enum.filter(fn pid ->
  info = Process.info(pid, [:dictionary])
  # Look for cowboy-related processes
end)
```

---

## Key Takeaways

1. **Ranch** manages TCP connections — it's a pool of acceptors that spawn workers
2. **Cowboy** handles HTTP on top of Ranch — parsing requests, dispatching to handlers
3. Cowboy creates a **request map** that becomes `%Plug.Conn{}`
4. In pure Cowboy, you write **handler modules** with `init/2`
5. Phoenix uses Cowboy through Plug — you rarely interact with Cowboy directly
6. Cowboy also handles **WebSocket** upgrades for LiveView and Channels
7. The stack is: `:gen_tcp` → Ranch → Cowboy → Plug → Phoenix → Your Code
