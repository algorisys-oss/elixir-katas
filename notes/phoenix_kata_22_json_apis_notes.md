# Kata 22: JSON APIs

## Phoenix API Controller

API controllers return JSON instead of HTML — no templates, no layouts, no flash messages.

```elixir
defmodule MyAppWeb.API.ProductController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    products = Catalog.list_products()
    json(conn, %{data: products})
  end

  def show(conn, %{"id" => id}) do
    product = Catalog.get_product!(id)
    json(conn, %{data: product})
  end
end
```

---

## Setting Up API Routes

```elixir
# In router.ex:
pipeline :api do
  plug :accepts, ["json"]
end

scope "/api", MyAppWeb.API do
  pipe_through :api

  resources "/products", ProductController, except: [:new, :edit]
  resources "/users", UserController, except: [:new, :edit]
end
```

No `:new` or `:edit` routes — APIs don't need form pages.

---

## JSON Responses

### Basic Response

```elixir
def index(conn, _params) do
  products = Catalog.list_products()
  json(conn, %{data: products})
  # → {"data": [...]}
end
```

### With Status Code

```elixir
def create(conn, %{"product" => params}) do
  case Catalog.create_product(params) do
    {:ok, product} ->
      conn
      |> put_status(:created)  # 201
      |> json(%{data: product})

    {:error, changeset} ->
      conn
      |> put_status(:unprocessable_entity)  # 422
      |> json(%{errors: format_errors(changeset)})
  end
end
```

### No Content

```elixir
def delete(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)
  {:ok, _} = Catalog.delete_product(product)
  send_resp(conn, :no_content, "")  # 204
end
```

---

## Error Formatting

Convert Ecto changeset errors to JSON:

```elixir
defp format_errors(changeset) do
  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end)
end
# → %{"name" => ["can't be blank"], "price" => ["must be greater than 0"]}
```

---

## Common Status Codes for APIs

| Code | Atom | When to Use |
|------|------|-------------|
| 200 | `:ok` | Successful GET, PUT, PATCH |
| 201 | `:created` | Successful POST (resource created) |
| 204 | `:no_content` | Successful DELETE |
| 400 | `:bad_request` | Malformed request body |
| 401 | `:unauthorized` | Missing/invalid auth token |
| 403 | `:forbidden` | Valid token but insufficient permissions |
| 404 | `:not_found` | Resource doesn't exist |
| 422 | `:unprocessable_entity` | Validation errors |

---

## JSON Views (Phoenix.JSON)

For structured serialization, use a JSON view module:

```elixir
defmodule MyAppWeb.API.ProductJSON do
  def index(%{products: products}) do
    %{data: for(product <- products, do: data(product))}
  end

  def show(%{product: product}) do
    %{data: data(product)}
  end

  defp data(product) do
    %{
      id: product.id,
      name: product.name,
      price: product.price,
      inserted_at: product.inserted_at
    }
  end
end
```

Then in the controller:
```elixir
def index(conn, _params) do
  products = Catalog.list_products()
  render(conn, :index, products: products)
  # Calls ProductJSON.index(%{products: products})
end
```

---

## Content Negotiation

Serve both HTML and JSON from the same controller:

```elixir
def show(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)

  case get_format(conn) do
    "json" -> json(conn, %{data: product})
    "html" -> render(conn, :show, product: product)
  end
end
```

---

## API Authentication

```elixir
pipeline :api_auth do
  plug MyAppWeb.Plugs.VerifyBearerToken
end

scope "/api", MyAppWeb.API do
  pipe_through [:api, :api_auth]
  resources "/products", ProductController
end
```

```elixir
defmodule MyAppWeb.Plugs.VerifyBearerToken do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Accounts.verify_token(token) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Invalid or missing token"})
        |> halt()
    end
  end
end
```

---

## Key Takeaways

1. Use `json/2` to return JSON responses, `send_resp/3` for no-content
2. Set status with `put_status/2` — use atoms like `:created`, `:not_found`
3. API routes skip `:new` and `:edit` (no forms needed)
4. Use JSON view modules for consistent serialization
5. Format changeset errors with `Ecto.Changeset.traverse_errors/2`
6. API auth uses Bearer tokens, not sessions/cookies
7. The `:api` pipeline is minimal — no sessions, CSRF, or layouts
