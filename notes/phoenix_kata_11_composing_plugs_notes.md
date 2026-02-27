# Kata 11: Composing Plugs

## The Middleware Pattern

In web development, **middleware** is code that sits between the server and your application, transforming requests and responses. In Elixir, plugs ARE middleware.

The power of plugs comes from **composition** — chaining them together to build complex behavior from simple parts:

```
Request → [Plug A] → [Plug B] → [Plug C] → Handler → Response
```

Each plug does ONE thing, and together they form a pipeline.

---

## Plug.Builder: Composing Plugs

`Plug.Builder` lets you compose multiple plugs into a single module:

```elixir
defmodule MyApp.Pipeline do
  use Plug.Builder

  plug Plug.Logger
  plug Plug.RequestId
  plug :add_server_header
  plug MyApp.AuthPlug
  plug MyApp.Router

  def add_server_header(conn, _opts) do
    put_resp_header(conn, "server", "MyApp/1.0")
  end
end
```

`Plug.Builder` compiles all the plugs into a single `call/2` function at compile time. This means **zero runtime overhead** from composition — it's as fast as writing one big function.

---

## How Phoenix Uses Plug Composition

### The Endpoint (Top-Level Pipeline)

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  plug Plug.Static,
    at: "/", from: :my_app,
    only: ~w(assets fonts images favicon.ico robots.txt)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug MyAppWeb.Router
end
```

Every request passes through ALL these plugs before reaching the router.

### Router Pipelines

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug MyAppWeb.Plugs.ApiAuth
  end

  scope "/", MyAppWeb do
    pipe_through :browser    # Use the :browser pipeline
    get "/", PageController, :home
  end

  scope "/api", MyAppWeb do
    pipe_through :api        # Use the :api pipeline
    resources "/users", UserController
  end
end
```

`pipe_through` selects which pipeline a group of routes uses. Routes can even use **multiple pipelines**:

```elixir
scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_admin]  # Both pipelines!
  get "/dashboard", AdminController, :dashboard
end
```

---

## The Full Request Flow

Here's the complete plug chain for a browser request to `/products`:

```
TCP Connection (Ranch/Cowboy)
    │
    ▼
╔══ Endpoint Plugs ═══════════════════════════════╗
║ Plug.Static      → Check if static file         ║
║ Plug.RequestId   → Add X-Request-Id header       ║
║ Plug.Telemetry   → Start timing                  ║
║ Plug.Parsers     → Parse request body            ║
║ Plug.MethodOverride → Handle _method param       ║
║ Plug.Head        → Convert HEAD to GET           ║
║ Plug.Session     → Load session from cookie      ║
╚═════════════════════════════════════════════════╝
    │
    ▼
╔══ Router ════════════════════════════════════════╗
║ Match route: GET /products → ProductController    ║
╚═════════════════════════════════════════════════╝
    │
    ▼
╔══ Pipeline :browser ═════════════════════════════╗
║ :accepts         → Verify Accept header           ║
║ :fetch_session   → Load session data              ║
║ :fetch_live_flash → Load flash messages           ║
║ :put_root_layout → Set layout template            ║
║ :protect_from_forgery → Check CSRF token          ║
║ :put_secure_browser_headers → Add security hdrs   ║
╚═════════════════════════════════════════════════╝
    │
    ▼
╔══ Controller Plugs ══════════════════════════════╗
║ :require_auth    → Check authentication           ║
║ :load_product    → Load product from DB           ║
╚═════════════════════════════════════════════════╝
    │
    ▼
ProductController.index(conn, params)
    │
    ▼
Response sent back through the chain
```

---

## Halting: Short-Circuiting the Pipeline

Any plug can **halt** the pipeline — preventing all subsequent plugs from running:

```elixir
defmodule MyApp.RateLimiter do
  import Plug.Conn

  def init(opts), do: Keyword.get(opts, :max_requests, 100)

  def call(conn, max_requests) do
    ip = to_string(:inet_parse.ntoa(conn.remote_ip))
    count = MyApp.RateStore.increment(ip)

    if count > max_requests do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(429, ~s({"error": "Rate limit exceeded"}))
      |> halt()    # ← STOP HERE. No more plugs run.
    else
      conn  # Continue to next plug
    end
  end
end
```

When `halt()` is called:
1. The conn's `halted` field is set to `true`
2. `Plug.Builder` checks this field before calling the next plug
3. All remaining plugs are **skipped**
4. The response that was already set gets sent

### Common Halt Patterns

```elixir
# Authentication
if user, do: conn, else: conn |> send_resp(401, "Unauthorized") |> halt()

# Rate limiting
if under_limit, do: conn, else: conn |> send_resp(429, "Too Many Requests") |> halt()

# Maintenance mode
if maintenance?, do: conn |> send_resp(503, "Under Maintenance") |> halt(), else: conn

# Feature flags
if feature_enabled?, do: conn, else: conn |> send_resp(404, "Not Found") |> halt()
```

---

## Building Custom Pipelines

Here are practical plug compositions:

### API Pipeline with Auth

```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug MyApp.Plugs.ApiAuth      # Verify Bearer token
  plug MyApp.Plugs.RateLimiter  # Rate limit by IP
  plug MyApp.Plugs.RequestLogger, log_level: :info
end
```

### Admin Pipeline

```elixir
pipeline :admin do
  plug :require_auth
  plug :require_role, :admin
  plug :put_layout, html: {MyAppWeb.Layouts, :admin}
end
```

### Shared CORS Pipeline

```elixir
defmodule MyApp.Plugs.CORS do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
  end
end
```

---

## Design Principles

### 1. Single Responsibility
Each plug does ONE thing:
- `Plug.Logger` — logs
- `Plug.Parsers` — parses
- `Plug.Session` — sessions

### 2. Order Matters
Plugs that parse the body must come before plugs that read it:
```elixir
plug Plug.Parsers    # Parse body first
plug :check_body     # Now body_params is available
```

### 3. Fail Fast
Put auth/rate-limiting early so unauthorized requests get rejected quickly:
```elixir
plug MyApp.RateLimiter    # Reject early
plug MyApp.Auth           # Reject unauthorized
plug Plug.Parsers         # Only parse valid requests
```

### 4. Keep Plugs Pure
Plugs should be side-effect free when possible:
```elixir
# Good: transforms conn
def my_plug(conn, _), do: assign(conn, :key, "value")

# Avoid: side effects in the plug itself
def my_plug(conn, _) do
  send_email(conn.assigns.user)  # Don't do this in a plug!
  conn
end
```

---

## Key Takeaways

1. **Plug composition** chains simple plugs into complex pipelines
2. `Plug.Builder` compiles plug chains at compile time — zero runtime overhead
3. Phoenix uses three levels: **Endpoint plugs**, **Router pipelines**, **Controller plugs**
4. `halt()` short-circuits the pipeline — remaining plugs are skipped
5. **Order matters** — parsing before reading, auth before processing
6. `pipe_through` in the router selects which pipeline group routes use
7. The middleware pattern makes behavior modular, testable, and reusable
