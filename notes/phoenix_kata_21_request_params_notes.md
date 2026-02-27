# Kata 21: Request Params & Pattern Matching

## Where Params Come From

Controller params are merged from three sources:

1. **Path params**: `/users/:id` → `%{"id" => "42"}`
2. **Query params**: `?page=2&sort=name` → `%{"page" => "2", "sort" => "name"}`
3. **Body params**: Form data or JSON body → `%{"user" => %{"name" => "Alice"}}`

All three are merged into a single `params` map.

---

## Pattern Matching Params

Elixir's pattern matching makes param handling clean and expressive:

### Extracting Required Params

```elixir
# Requires "id" — crashes with MatchError if missing
def show(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)
  render(conn, :show, product: product)
end
```

### Multiple Required Params

```elixir
def update(conn, %{"id" => id, "product" => product_params}) do
  product = Catalog.get_product!(id)
  Catalog.update_product(product, product_params)
end
```

### Keeping the Full Map

```elixir
# Extract AND keep the full map:
def create(conn, %{"product" => product_params} = params) do
  page = params["redirect_to"] || "/products"
  # product_params has the nested form data
  # params has everything
end
```

---

## Pattern Matching on Values

Match on specific param values to dispatch different behaviors:

```elixir
# JSON format
def show(conn, %{"id" => id, "format" => "json"}) do
  product = Catalog.get_product!(id)
  json(conn, product)
end

# HTML format (default)
def show(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)
  render(conn, :show, product: product)
end
```

Elixir tries clauses **top to bottom** — more specific matches first!

---

## Optional Params with Defaults

```elixir
def index(conn, params) do
  page = Map.get(params, "page", "1") |> String.to_integer()
  per_page = Map.get(params, "per_page", "20") |> String.to_integer()
  sort = params["sort"] || "inserted_at"
  order = params["order"] || "desc"

  products = Catalog.list_products(
    page: page,
    per_page: per_page,
    sort: sort,
    order: order
  )

  render(conn, :index, products: products)
end
```

---

## Nested Params (Form Data)

HTML forms send nested params:

```html
<form action="/users" method="post">
  <input name="user[name]" value="Alice" />
  <input name="user[email]" value="alice@example.com" />
  <input name="user[address][city]" value="NYC" />
</form>
```

Becomes:
```elixir
%{
  "user" => %{
    "name" => "Alice",
    "email" => "alice@example.com",
    "address" => %{"city" => "NYC"}
  }
}
```

Pattern match the nested structure:
```elixir
def create(conn, %{"user" => user_params}) do
  case Accounts.create_user(user_params) do
    {:ok, user} -> redirect(conn, to: ~p"/users/#{user}")
    {:error, changeset} -> render(conn, :new, changeset: changeset)
  end
end
```

---

## Guard Clauses

Combine pattern matching with guards for validation:

```elixir
def show(conn, %{"id" => id}) when is_binary(id) do
  case Integer.parse(id) do
    {num, ""} when num > 0 ->
      product = Catalog.get_product!(num)
      render(conn, :show, product: product)
    _ ->
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid ID"})
  end
end
```

---

## Strong Parameters Pattern

Unlike Rails, Phoenix doesn't have built-in strong parameters. Use pattern matching and explicit maps:

```elixir
def create(conn, %{"user" => user_params}) do
  # Only allow specific keys:
  allowed = Map.take(user_params, ["name", "email", "role"])
  # Or use Ecto changesets to cast only permitted fields
  case Accounts.create_user(allowed) do
    {:ok, user} -> redirect(conn, to: ~p"/users/#{user}")
    {:error, changeset} -> render(conn, :new, changeset: changeset)
  end
end
```

In practice, Ecto changesets handle this — `cast/3` only accepts fields you specify.

---

## Key Takeaways

1. Params come from **path**, **query string**, and **body** — merged into one map
2. Use **pattern matching** in function heads to extract required params
3. Match on **specific values** to dispatch different behaviors
4. Use `Map.get/3` or `||` for **optional params with defaults**
5. Form data arrives as **nested maps** matching the input `name` structure
6. All params are **strings** — convert types explicitly
7. Ecto changesets handle **permitted parameters** (like Rails strong params)
