# Kata 24: Error Handling

## How Phoenix Handles Errors

Phoenix converts exceptions to HTTP error responses automatically:

| Exception | Status | Page |
|-----------|--------|------|
| `Ecto.NoResultsError` | 404 | Not Found |
| `Phoenix.Router.NoRouteError` | 404 | Not Found |
| Any unhandled exception | 500 | Internal Server Error |

```elixir
# This automatically returns 404 if product doesn't exist:
def show(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)  # Raises if not found
  render(conn, :show, product: product)
end
```

---

## Error Views

Phoenix uses error view modules to render error pages:

```elixir
# For HTML errors:
defmodule MyAppWeb.ErrorHTML do
  use MyAppWeb, :html

  # Custom 404 page
  def render("404.html", _assigns) do
    "Page Not Found"
  end

  # Custom 500 page
  def render("500.html", _assigns) do
    "Internal Server Error"
  end

  # Catch-all for other errors
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
```

```elixir
# For JSON errors:
defmodule MyAppWeb.ErrorJSON do
  def render("404.json", _assigns) do
    %{errors: %{detail: "Not Found"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error"}}
  end

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
```

### Configured in config.exs:

```elixir
config :my_app, MyAppWeb.Endpoint,
  render_errors: [
    formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
    layout: false
  ]
```

---

## Action Fallback

`action_fallback` centralizes error handling for controllers:

```elixir
defmodule MyAppWeb.ProductController do
  use MyAppWeb, :controller

  action_fallback MyAppWeb.FallbackController

  def show(conn, %{"id" => id}) do
    # Return {:error, ...} tuples instead of handling errors inline
    with {:ok, product} <- Catalog.fetch_product(id) do
      render(conn, :show, product: product)
    end
    # If fetch_product returns {:error, :not_found},
    # FallbackController handles it
  end

  def create(conn, %{"product" => params}) do
    with {:ok, product} <- Catalog.create_product(params) do
      conn
      |> put_status(:created)
      |> render(:show, product: product)
    end
    # If create_product returns {:error, changeset},
    # FallbackController handles it
  end
end
```

### The Fallback Controller

```elixir
defmodule MyAppWeb.FallbackController do
  use MyAppWeb, :controller

  # Ecto changeset errors → 422
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(MyAppWeb.ErrorJSON)
    |> render("422.json", changeset: changeset)
  end

  # Not found → 404
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(MyAppWeb.ErrorJSON)
    |> render("404.json")
  end

  # Unauthorized → 401
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(MyAppWeb.ErrorJSON)
    |> render("401.json")
  end
end
```

---

## Custom Error Pages

### Rich HTML 404 Page

```heex
<!-- lib/my_app_web/controllers/error_html/404.html.heex -->
<div class="flex items-center justify-center min-h-screen">
  <div class="text-center">
    <h1 class="text-6xl font-bold text-gray-300">404</h1>
    <p class="text-xl text-gray-500 mt-4">Page not found</p>
    <a href="/" class="mt-6 inline-block text-blue-600 hover:underline">
      Go home
    </a>
  </div>
</div>
```

### Debug Errors in Development

In `dev.exs`:
```elixir
config :my_app, MyAppWeb.Endpoint,
  debug_errors: true  # Shows detailed error pages in dev
```

Set to `false` in production — users see your custom error pages instead.

---

## Rescue in Controllers

For fine-grained error handling:

```elixir
def show(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)
  render(conn, :show, product: product)
rescue
  Ecto.NoResultsError ->
    conn
    |> put_status(:not_found)
    |> put_view(MyAppWeb.ErrorHTML)
    |> render("404.html")
end
```

But prefer `action_fallback` over `rescue` — it's cleaner and more consistent.

---

## Plug.Exception Protocol

Make your own exceptions map to HTTP status codes:

```elixir
defmodule MyApp.NotFoundError do
  defexception message: "resource not found", plug_status: 404
end

defmodule MyApp.ForbiddenError do
  defexception message: "access denied", plug_status: 403
end
```

Now raising these exceptions automatically returns the correct status:

```elixir
def show(conn, %{"id" => id}) do
  case Catalog.get_product(id) do
    nil -> raise MyApp.NotFoundError
    product -> render(conn, :show, product: product)
  end
end
```

---

## Key Takeaways

1. Phoenix automatically converts **exceptions to HTTP errors** (404, 500)
2. `get_product!` (bang!) raises on not-found → auto 404
3. **Error views** (`ErrorHTML`, `ErrorJSON`) customize error responses
4. **`action_fallback`** centralizes error handling — return `{:error, ...}` tuples
5. Use **`with`** for clean pipelines that delegate errors to fallback
6. Custom exceptions with `plug_status` map to specific HTTP codes
7. `debug_errors: true` in dev shows detailed errors; custom pages in prod
