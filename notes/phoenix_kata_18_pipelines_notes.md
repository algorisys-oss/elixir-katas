# Kata 18: Pipelines

## What is a Pipeline?

A pipeline is a **named group of plugs** that runs on every request in a scope. Think of it as a filter chain — each plug transforms the connection before it reaches your controller.

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
end
```

---

## Built-in Pipelines

Phoenix generates two pipelines out of the box:

### `:browser` Pipeline

For HTML requests from web browsers:

```elixir
pipeline :browser do
  plug :accepts, ["html"]           # Only accept HTML
  plug :fetch_session               # Load session from cookie
  plug :fetch_live_flash            # Flash messages for LiveView
  plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
  plug :protect_from_forgery        # CSRF protection
  plug :put_secure_browser_headers  # Security headers (X-Frame-Options, etc.)
end
```

| Plug | Purpose |
|------|---------|
| `:accepts` | Reject requests for unsupported formats |
| `:fetch_session` | Read session data from signed cookie |
| `:fetch_live_flash` | Enable flash messages in LiveView |
| `:put_root_layout` | Set the root HTML layout |
| `:protect_from_forgery` | CSRF token validation |
| `:put_secure_browser_headers` | Add security headers to response |

### `:api` Pipeline

For JSON API requests:

```elixir
pipeline :api do
  plug :accepts, ["json"]  # Only accept JSON
end
```

Much simpler — no sessions, no CSRF, no layouts. APIs are stateless.

---

## Using Pipelines with `pipe_through`

Apply a pipeline to a scope:

```elixir
scope "/", MyAppWeb do
  pipe_through :browser          # HTML pipeline
  get "/", PageController, :home
end

scope "/api", MyAppWeb.API do
  pipe_through :api              # JSON pipeline
  get "/users", UserController, :index
end
```

### Multiple Pipelines

You can chain multiple pipelines:

```elixir
scope "/admin", MyAppWeb.Admin do
  pipe_through [:browser, :require_admin]
  # Runs :browser plugs first, then :require_admin plugs
  get "/", DashboardController, :index
end
```

Plugs run in order: first all `:browser` plugs, then all `:require_admin` plugs.

---

## Custom Pipelines

### Authentication Pipeline

```elixir
pipeline :require_auth do
  plug MyAppWeb.Plugs.FetchCurrentUser
  plug MyAppWeb.Plugs.RequireAuth
end
```

### Rate Limiting Pipeline

```elixir
pipeline :rate_limited do
  plug MyAppWeb.Plugs.RateLimit, max_requests: 100, window_ms: 60_000
end
```

### API Authentication

```elixir
pipeline :api_auth do
  plug MyAppWeb.Plugs.VerifyAPIKey
  plug MyAppWeb.Plugs.FetchAPIUser
end
```

---

## Writing a Pipeline Plug

A plug is either a **function plug** (a function) or a **module plug** (a module with `init/1` and `call/2`):

### Function Plug

```elixir
# In your router or a plug module:
defp require_admin(conn, _opts) do
  if conn.assigns[:current_user]&.admin? do
    conn
  else
    conn
    |> put_flash(:error, "Not authorized")
    |> redirect(to: "/")
    |> halt()  # ← Stop the pipeline!
  end
end
```

### Module Plug

```elixir
defmodule MyAppWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "Please log in")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
```

### `halt()` — Stopping the Pipeline

When a plug calls `halt()`, **no further plugs or controllers run**. The current response is sent. This is how authentication plugs block unauthorized requests.

---

## Pipeline Execution Flow

```
Request arrives
    ↓
Endpoint plugs (always run)
    ↓
Router matches route
    ↓
pipe_through :browser
    ↓
  plug :accepts          ← Check format
  plug :fetch_session    ← Load session
  plug :fetch_live_flash ← Flash support
  plug :put_root_layout  ← Set layout
  plug :protect_from_forgery ← CSRF check
  plug :put_secure_browser_headers ← Security
    ↓
pipe_through :require_auth (if chained)
    ↓
  plug FetchCurrentUser  ← Load user from session
  plug RequireAuth       ← Check user exists (halt if not!)
    ↓
Controller action runs
    ↓
Response sent
```

---

## Key Takeaways

1. **Pipelines** are named groups of plugs applied to scopes via `pipe_through`
2. Phoenix generates `:browser` and `:api` pipelines by default
3. Create **custom pipelines** for auth, rate limiting, API keys, etc.
4. Multiple pipelines run in order: `pipe_through [:browser, :require_auth]`
5. Use `halt()` in a plug to **stop the pipeline** and return early
6. Plugs are either **function plugs** (a function) or **module plugs** (a module with `init/1` + `call/2`)
7. Endpoint plugs run on ALL requests; pipeline plugs run only on matched routes
