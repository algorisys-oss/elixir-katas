# Kata 13: Endpoint & Config

## What is the Endpoint?

The **Endpoint** is Phoenix's HTTP entry point — the first module that processes every incoming request. It's a pipeline of plugs that transforms raw HTTP into something your router can handle.

```
HTTP Request → Endpoint (plug chain) → Router → Controller/LiveView
```

Think of the Endpoint as the **front door** of your application. Everything passes through it.

---

## Endpoint Anatomy

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # 1. WebSocket support for LiveView
  @session_options [
    store: :cookie,
    key: "_my_app_key",
    signing_salt: "abc123",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  # 2. Static file serving
  plug Plug.Static,
    at: "/",
    from: :my_app,
    gzip: false,
    only: MyAppWeb.static_paths()

  # 3. Code reloading (dev only)
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :my_app
  end

  # 4. Request processing
  plug Plug.RequestId,
    http_header: "x-request-id"

  plug Plug.Telemetry,
    event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # 5. Session
  plug Plug.Session, @session_options

  # 6. Router (last plug!)
  plug MyAppWeb.Router
end
```

---

## Plug-by-Plug Walkthrough

### `Plug.Static` — Serve Static Files

```elixir
plug Plug.Static,
  at: "/",
  from: :my_app,
  only: ~w(assets fonts images favicon.ico robots.txt)
```

**What it does**: Checks if the request is for a static file. If yes, serves it directly from `priv/static/` and **stops** — the request never reaches the router.

**Why it's first**: Static files are the most common requests. Serving them early avoids unnecessary processing.

### `Plug.RequestId` — Add Request Tracking

```elixir
plug Plug.RequestId, http_header: "x-request-id"
```

Adds a unique `X-Request-Id` header to every response. Useful for tracing requests through logs and microservices.

### `Plug.Telemetry` — Performance Metrics

```elixir
plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
```

Emits telemetry events that Phoenix LiveDashboard uses to show request timing. This is how you get metrics without adding manual timing code.

### `Plug.Parsers` — Parse Request Bodies

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library()
```

Parses the request body based on Content-Type:
- `application/x-www-form-urlencoded` → HTML form data
- `multipart/form-data` → File uploads
- `application/json` → JSON APIs

After this plug, `conn.body_params` contains the parsed data.

### `Plug.MethodOverride` — Support HTML Form Methods

```elixir
plug Plug.MethodOverride
```

HTML forms only support GET and POST. This plug reads a `_method` parameter and overrides the HTTP method:

```html
<form method="post">
  <input type="hidden" name="_method" value="delete">
  <!-- This becomes a DELETE request -->
</form>
```

### `Plug.Head` — Handle HEAD Requests

```elixir
plug Plug.Head
```

Converts HEAD requests to GET requests (but strips the response body). This is an HTTP optimization — browsers use HEAD to check if a resource has changed.

### `Plug.Session` — Session Management

```elixir
plug Plug.Session,
  store: :cookie,
  key: "_my_app_key",
  signing_salt: "abc123"
```

Loads session data from signed/encrypted cookies. After this plug, you can use `get_session/2` and `put_session/3`.

### `MyAppWeb.Router` — Routing (Last!)

```elixir
plug MyAppWeb.Router
```

The router is the **last plug** in the endpoint. By the time the request reaches it, we have:
- Static files already served
- Request ID assigned
- Body parsed
- Session loaded
- Method possibly overridden

---

## Configuration System

Phoenix uses a layered configuration system:

```
config/config.exs      ← Shared (all environments)
config/dev.exs         ← Development overrides
config/test.exs        ← Test overrides
config/prod.exs        ← Production compile-time
config/runtime.exs     ← Production runtime (env vars)
```

### config/config.exs — Base Configuration

```elixir
import Config

# Endpoint config
config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "abc123"]

# Database config
config :my_app, MyApp.Repo,
  database: "my_app_dev"

# Logger config
config :logger, :console,
  format: "$time $metadata[$level] $message\n"

# Import environment-specific config (MUST be at the end)
import_config "#{config_env()}.exs"
```

### config/dev.exs — Development

```elixir
import Config

config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  debug_errors: true,
  code_reloader: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [...]},
    tailwind: {Tailwind, :install_and_run, [...]}
  ]

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
```

### config/runtime.exs — Production Runtime

```elixir
import Config

if config_env() == :prod do
  config :my_app, MyApp.Repo,
    url: System.get_env("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :my_app, MyAppWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST"), port: 443, scheme: "https"],
    secret_key_base: System.get_env("SECRET_KEY_BASE")
end
```

**Key difference**: `config.exs`, `dev.exs`, and `prod.exs` run at **compile time**. `runtime.exs` runs at **startup** — so it can read environment variables.

---

## How the Endpoint Boots

When you run `mix phx.server`:

```
1. Application.start/2
   │
   ▼
2. Supervisor starts children:
   ├── MyApp.Repo (database pool)
   ├── Phoenix.PubSub (messaging)
   └── MyAppWeb.Endpoint
       │
       ▼
3. Endpoint.init/2 reads config
   │
   ▼
4. Starts Cowboy on configured port
   │
   ▼
5. Compiles plug pipeline
   │
   ▼
6. Ready! Listening on port 4000
```

---

## Accessing Config at Runtime

```elixir
# In code:
Application.get_env(:my_app, MyAppWeb.Endpoint)
# => [url: [host: "localhost"], ...]

# Endpoint-specific:
MyAppWeb.Endpoint.config(:url)
# => [host: "localhost"]

MyAppWeb.Endpoint.url()
# => "http://localhost:4000"
```

---

## Key Takeaways

1. The **Endpoint** is the HTTP entry point — every request passes through its plug chain
2. Plugs run in order: static files → request ID → parsing → session → router
3. Static files are served first to avoid unnecessary processing
4. The **Router** is always the last plug in the endpoint
5. Configuration is layered: `config.exs` → `{env}.exs` → `runtime.exs`
6. `runtime.exs` is for production secrets via environment variables
7. The Endpoint boots as part of the OTP supervision tree
