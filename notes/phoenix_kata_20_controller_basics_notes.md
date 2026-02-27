# Kata 20: Controller Basics

## What is a Controller?

A controller is a module that handles HTTP requests. Each function (called an **action**) receives the connection (`conn`) and parameters (`params`), then returns a response.

```elixir
defmodule MyAppWeb.ProductController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    products = Catalog.list_products()
    render(conn, :index, products: products)
  end
end
```

---

## The Connection (`conn`)

Every action receives `%Plug.Conn{}` — the connection struct. It contains everything about the request AND response:

```elixir
def show(conn, _params) do
  # Request info:
  conn.method        # "GET"
  conn.request_path  # "/products/42"
  conn.params        # %{"id" => "42"}
  conn.query_string  # "tab=reviews"

  # Assigns (shared state):
  conn.assigns        # %{current_user: %User{...}}

  # Response (you set these):
  conn.status         # 200
  conn.resp_headers   # [{"content-type", "text/html"}]
end
```

---

## Response Types

### render — HTML Response

```elixir
def index(conn, _params) do
  products = Catalog.list_products()
  render(conn, :index, products: products)
  # Looks up ProductHTML.index template
  # Returns 200 with rendered HTML
end
```

### json — JSON Response

```elixir
def index(conn, _params) do
  products = Catalog.list_products()
  json(conn, %{data: products, count: length(products)})
  # Returns 200 with JSON body
end
```

### text — Plain Text Response

```elixir
def health(conn, _params) do
  text(conn, "OK")
  # Returns 200 with plain text
end
```

### html — Raw HTML Response

```elixir
def inline(conn, _params) do
  html(conn, "<h1>Hello!</h1>")
  # Returns 200 with raw HTML string
end
```

### redirect — Redirect Response

```elixir
def create(conn, params) do
  # ... create resource ...
  redirect(conn, to: ~p"/products/#{product}")
  # Returns 302 redirect
end
```

### send_resp — Custom Status

```elixir
def no_content(conn, _params) do
  send_resp(conn, 204, "")
  # Returns 204 No Content
end

def accepted(conn, _params) do
  send_resp(conn, 202, "Processing...")
  # Returns 202 Accepted
end
```

---

## Setting Status Codes

```elixir
def create(conn, params) do
  conn
  |> put_status(:created)  # 201
  |> json(%{id: 42})
end

def not_authorized(conn, _params) do
  conn
  |> put_status(:forbidden)  # 403
  |> json(%{error: "Not authorized"})
end
```

Common status atoms: `:ok` (200), `:created` (201), `:no_content` (204), `:bad_request` (400), `:unauthorized` (401), `:forbidden` (403), `:not_found` (404), `:unprocessable_entity` (422).

---

## Setting Headers

```elixir
def download(conn, _params) do
  conn
  |> put_resp_header("content-disposition", "attachment; filename=\"data.csv\"")
  |> put_resp_content_type("text/csv")
  |> send_resp(200, csv_data)
end
```

---

## Assigns

Pass data to templates via assigns:

```elixir
def show(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)
  user = conn.assigns.current_user  # Set by auth plug

  conn
  |> assign(:product, product)
  |> assign(:page_title, product.name)
  |> render(:show)
  # In template: @product, @page_title
end

# Or inline:
render(conn, :show, product: product, page_title: product.name)
```

---

## Action Naming Conventions

| Action | HTTP Method | Path | Purpose |
|--------|------------|------|---------|
| `index` | GET | /products | List all |
| `new` | GET | /products/new | Show form |
| `create` | POST | /products | Save new |
| `show` | GET | /products/:id | Show one |
| `edit` | GET | /products/:id/edit | Show edit form |
| `update` | PUT/PATCH | /products/:id | Save changes |
| `delete` | DELETE | /products/:id | Remove |

These are conventions, not requirements — you can name actions anything.

---

## Key Takeaways

1. Controllers handle HTTP requests through **action functions**
2. Every action receives `conn` (connection) and `params`
3. Use `render/3` for HTML, `json/2` for JSON, `text/2` for plain text
4. Use `redirect/2` for redirects, `send_resp/3` for custom status
5. Set status with `put_status/2`, headers with `put_resp_header/3`
6. Pass data to templates via `assign/3` or the third arg to `render/3`
7. Follow REST conventions for action naming (index, show, create, etc.)
