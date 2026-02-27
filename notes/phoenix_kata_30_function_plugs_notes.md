# Kata 30: Function Plugs

## What Is a Function Plug?

A **function plug** is any function that accepts a `%Plug.Conn{}` struct and options, and returns a `%Plug.Conn{}`. This is the simplest form of middleware in the Plug ecosystem.

```elixir
# The function plug contract:
def my_plug(conn, opts) do
  # Transform conn in some way
  conn
end
```

Used in router pipelines with `plug :my_plug` or `plug :my_plug, some_option: true`.

---

## The Plug.Conn Contract

Every plug must:
1. Accept `conn` (a `%Plug.Conn{}`) as the first argument
2. Accept `opts` as the second argument (can be `_opts` if unused)
3. Return a `%Plug.Conn{}`

```elixir
# Minimal no-op plug:
def identity(conn, _opts), do: conn

# With options:
def set_locale(conn, opts) do
  locale = Keyword.get(opts, :default, "en")
  Plug.Conn.assign(conn, :locale, locale)
end

# Usage in pipeline:
plug :set_locale, default: "fr"
```

---

## Adding Assigns

Function plugs commonly enrich `conn.assigns` with data available throughout the request lifecycle:

```elixir
import Plug.Conn

# Single assign:
def put_locale(conn, _opts) do
  locale = get_session(conn, :locale) || "en"
  assign(conn, :locale, locale)
end

# Multiple assigns:
def put_app_context(conn, _opts) do
  conn
  |> assign(:app_name, "MyApp")
  |> assign(:app_version, Application.spec(:my_app, :vsn) |> to_string())
  |> assign(:env, Mix.env())
end
```

Assigns are accessible in templates as `@locale`, `@app_name`, etc., and in controllers as `conn.assigns.locale`.

---

## Logging and Instrumentation

Function plugs are perfect for cross-cutting concerns like logging and metrics:

```elixir
require Logger

def log_request(conn, _opts) do
  start = System.monotonic_time(:millisecond)

  Plug.Conn.register_before_send(conn, fn conn ->
    elapsed = System.monotonic_time(:millisecond) - start
    Logger.info("#{conn.method} #{conn.request_path} => #{conn.status} (#{elapsed}ms)")
    conn
  end)
end
```

`register_before_send/2` schedules a callback to run **after the controller** returns but **before** response bytes are written — ideal for logging status codes and response times.

---

## Using `conn.private` for Metadata

Use `conn.private` for framework/library metadata (not user data):

```elixir
def start_timer(conn, _opts) do
  Plug.Conn.put_private(conn, :request_start,
    System.monotonic_time(:microsecond))
end

# Later plug reads it:
def log_duration(conn, _opts) do
  t0 = conn.private[:request_start]
  t1 = System.monotonic_time(:microsecond)
  Logger.debug("Duration: #{Float.round((t1 - t0) / 1000, 2)}ms")
  conn
end
```

Convention: `conn.assigns` is for user/application data; `conn.private` is for library/framework internals.

---

## Function Plugs in Router Pipelines

Define function plugs in the same module (or import them) to use in pipelines:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Plug.Conn

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_locale          # custom function plug
    plug :add_request_id      # custom function plug
  end

  defp put_locale(conn, _opts) do
    assign(conn, :locale, get_session(conn, :locale) || "en")
  end

  defp add_request_id(conn, _opts) do
    id = :crypto.strong_rand_bytes(8) |> Base.encode16()
    conn
    |> assign(:request_id, id)
    |> put_resp_header("x-request-id", id)
  end
end
```

---

## Controller-Level Function Plugs

Controllers can define their own plugs that only apply to specific actions:

```elixir
defmodule MyAppWeb.ProductController do
  use MyAppWeb, :controller

  # Only for write actions:
  plug :load_product when action in [:show, :edit, :update, :delete]
  plug :verify_owner when action in [:edit, :update, :delete]

  def show(conn, _params) do
    # conn.assigns.product already set!
    render(conn, :show)
  end

  defp load_product(conn, _opts) do
    product = Catalog.get_product!(conn.params["id"])
    assign(conn, :product, product)
  end

  defp verify_owner(conn, _opts) do
    if conn.assigns.product.user_id == conn.assigns.current_user.id do
      conn
    else
      conn
      |> put_flash(:error, "Not authorized")
      |> redirect(to: ~p"/products")
      |> halt()
    end
  end
end
```

The `when action in [...]` guard limits which actions the plug runs for.

---

## Halting the Pipeline

Call `Plug.Conn.halt/1` to stop processing and prevent further plugs from running:

```elixir
def require_https(conn, _opts) do
  if conn.scheme == :https do
    conn
  else
    conn
    |> Plug.Conn.send_resp(301, "https://#{conn.host}#{conn.request_path}")
    |> halt()
  end
end
```

After `halt/1`, `conn.halted` is `true` and no subsequent plugs execute.

---

## Function Plug vs Module Plug

| Feature | Function Plug | Module Plug |
|---------|--------------|-------------|
| Definition | `def/defp` function | Module with `init/1` and `call/2` |
| Reuse | Within same module | Across any module |
| Initialization | None (opts passed directly) | `init/1` runs at compile time |
| Best for | Simple transforms, same-module use | Complex middleware, shared libraries |

---

## Key Takeaways

1. A function plug is any `def my_plug(conn, opts) :: conn` function
2. Use `plug :function_name` or `plug :function_name, opts` to invoke
3. `assign/3` adds data to `conn.assigns` for templates and controllers
4. `register_before_send/2` enables post-controller, pre-response hooks
5. `halt/1` stops the pipeline — essential for auth and redirects
6. Use `when action in [...]` in controllers to limit plug scope
7. `conn.private` is for framework metadata; `conn.assigns` is for app data
