# Kata 09: Plug Basics

## What is Plug?

**Plug** is the specification for composable modules between web servers and your application. Think of it as the **adapter** between Cowboy (the HTTP server) and Phoenix (your framework).

```
Cowboy (raw HTTP) → Plug (transforms) → Phoenix (your app)
```

Plug defines two things:
1. A **data structure** (`%Plug.Conn{}`) representing the HTTP connection
2. A **behaviour** (interface) for modules that transform that connection

Every single request in Phoenix passes through a chain of plugs.

---

## The Plug.Conn Struct

`%Plug.Conn{}` is **the** central data structure. It represents everything about an HTTP request and response:

```elixir
%Plug.Conn{
  # Request fields (read these)
  host: "localhost",
  port: 4000,
  method: "GET",
  request_path: "/products",
  query_string: "page=2",
  req_headers: [{"accept", "text/html"}, {"host", "localhost"}],
  params: %{"page" => "2"},
  body_params: %{},
  cookies: %{},
  remote_ip: {127, 0, 0, 1},

  # Response fields (write these)
  status: nil,           # Set with put_status/2
  resp_headers: [...],   # Set with put_resp_header/3
  resp_body: nil,        # Set with send_resp/3

  # State tracking
  state: :unset,         # :unset → :set → :sent
  halted: false,         # If true, remaining plugs are skipped

  # Assigned data
  assigns: %{},          # Your custom data (put_assign/3)
  private: %{}           # Framework data (put_private/3)
}
```

### Key Principle: Immutable Transformation

`Plug.Conn` is a struct — and in Elixir, structs are **immutable**. Every function that "modifies" the conn actually returns a **new** conn:

```elixir
conn = put_status(conn, 200)           # Returns NEW conn with status: 200
conn = put_resp_header(conn, "x-custom", "value")  # Returns NEW conn
conn = assign(conn, :user, user)       # Returns NEW conn with assigns.user
```

This is why Phoenix controllers and plugs always use the pipe operator:

```elixir
conn
|> put_status(200)
|> put_resp_header("content-type", "text/html")
|> send_resp(200, "<h1>Hello</h1>")
```

---

## Two Types of Plugs

### 1. Function Plugs

A function plug is any function that takes a `conn` and options, and returns a `conn`:

```elixir
def my_plug(conn, _opts) do
  # Transform and return the conn
  assign(conn, :request_time, DateTime.utc_now())
end
```

**Signature**: `(Plug.Conn.t(), any()) :: Plug.Conn.t()`

### 2. Module Plugs

A module plug is a module that implements two callbacks:

```elixir
defmodule MyPlug do
  @behaviour Plug

  def init(opts) do
    # Called at compile time (or once at startup)
    # Transform options — result is passed to call/2
    opts
  end

  def call(conn, opts) do
    # Called for every request
    # Transform and return the conn
    assign(conn, :custom_data, opts[:key])
  end
end
```

- `init/1` runs **once** (at compile time) — use it for expensive setup
- `call/2` runs for **every request** — keep it fast

---

## Using Plugs in Phoenix

### In a Controller (Function Plugs)

```elixir
defmodule MyAppWeb.ProductController do
  use MyAppWeb, :controller

  plug :require_auth           # Function plug — calls require_auth/2
  plug :load_product when action in [:show, :edit]

  def show(conn, _params) do
    render(conn, :show)
  end

  defp require_auth(conn, _opts) do
    if conn.assigns[:current_user] do
      conn  # Authenticated — continue
    else
      conn
      |> put_status(401)
      |> put_view(ErrorHTML)
      |> render(:"401")
      |> halt()  # Stop further plugs and action
    end
  end

  defp load_product(conn, _opts) do
    product = Products.get!(conn.params["id"])
    assign(conn, :product, product)
  end
end
```

### In the Router (Module Plugs)

```elixir
# In router.ex
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
end
```

Each `plug` call adds a transformation step. Requests flow through them in order.

---

## The Plug Pipeline

When a request comes in, it flows through plugs **in order**:

```
Request arrives
    │
    ▼
plug :fetch_session      →  Loads session from cookie
    │
    ▼
plug :protect_from_forgery  →  Checks CSRF token
    │
    ▼
plug :put_secure_headers →  Adds security headers
    │
    ▼
plug :require_auth       →  Checks authentication
    │                          (might halt here!)
    ▼
Controller.action/2      →  Your business logic
    │
    ▼
Response sent
```

### Halting the Pipeline

If a plug calls `halt(conn)`, **all remaining plugs are skipped**:

```elixir
def require_auth(conn, _opts) do
  if conn.assigns[:current_user] do
    conn  # Continue to next plug
  else
    conn
    |> send_resp(401, "Unauthorized")
    |> halt()  # STOP — no more plugs run, action is skipped
  end
end
```

---

## Plug.Conn Helper Functions

The most common functions you'll use:

| Function | Purpose | Example |
|----------|---------|---------|
| `assign/3` | Store data in assigns | `assign(conn, :user, user)` |
| `put_status/2` | Set response status | `put_status(conn, 200)` |
| `put_resp_header/3` | Add response header | `put_resp_header(conn, "x-key", "val")` |
| `send_resp/3` | Send a response | `send_resp(conn, 200, "OK")` |
| `halt/1` | Stop the pipeline | `halt(conn)` |
| `get_session/2` | Read session data | `get_session(conn, :user_id)` |
| `put_session/3` | Write session data | `put_session(conn, :user_id, 42)` |
| `fetch_cookies/1` | Load cookies | `fetch_cookies(conn)` |
| `put_resp_cookie/3` | Set a cookie | `put_resp_cookie(conn, "theme", "dark")` |

---

## Building a Complete Plug

Here's a real-world example — a request logger plug:

```elixir
defmodule MyAppWeb.Plugs.RequestLogger do
  @behaviour Plug
  import Plug.Conn
  require Logger

  def init(opts) do
    # Default log level
    Keyword.get(opts, :log_level, :info)
  end

  def call(conn, log_level) do
    start_time = System.monotonic_time()

    # Register a callback that runs AFTER the response is sent
    register_before_send(conn, fn conn ->
      duration = System.monotonic_time() - start_time
      duration_ms = System.convert_time_unit(duration, :native, :millisecond)

      Logger.log(log_level,
        "#{conn.method} #{conn.request_path} → #{conn.status} (#{duration_ms}ms)")

      conn
    end)
  end
end

# Usage in router:
# plug MyAppWeb.Plugs.RequestLogger, log_level: :debug
```

---

## How Phoenix Uses Plugs Internally

Phoenix itself is built from plugs:

```
Phoenix.Endpoint                    (module plug)
  └── Plug.Static                   (serves static files)
  └── Plug.RequestId                (adds request ID header)
  └── Plug.Telemetry                (emits timing events)
  └── Plug.Parsers                  (parses request body)
  └── Plug.Session                  (loads session)
  └── Phoenix.Router                (routes to controller)
       └── Pipeline plugs           (your pipeline)
       └── Controller plugs         (your controller plugs)
       └── Controller.action/2      (your code!)
```

Every step is a plug. Phoenix is just a collection of well-organized plugs.

---

## Key Takeaways

1. **Plug** is a specification — a function or module that transforms `%Plug.Conn{}`
2. `%Plug.Conn{}` represents the **entire** HTTP request/response lifecycle
3. **Function plugs**: `(conn, opts) -> conn` — simple, used in controllers
4. **Module plugs**: `init/1` + `call/2` — reusable, configurable, used across the app
5. Plugs run in **order** — each one transforms the conn for the next
6. `halt/1` **stops** the pipeline — no more plugs or actions run
7. Phoenix is **built from plugs** — the entire framework is plug compositions
