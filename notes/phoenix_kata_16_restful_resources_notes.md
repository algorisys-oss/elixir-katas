# Kata 16: RESTful Resources

## What is REST?

REST (Representational State Transfer) maps HTTP methods to CRUD operations on resources:

| HTTP Method | Path              | Action   | Purpose           |
|-------------|-------------------|----------|-------------------|
| GET         | /products         | index    | List all products |
| GET         | /products/new     | new      | Show create form  |
| POST        | /products         | create   | Save new product  |
| GET         | /products/:id     | show     | Show one product  |
| GET         | /products/:id/edit| edit     | Show edit form    |
| PUT/PATCH   | /products/:id     | update   | Update product    |
| DELETE      | /products/:id     | delete   | Remove product    |

These 7 routes are so common that Phoenix generates them all with a single line.

---

## The `resources` Macro

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  resources "/products", ProductController
end
```

This single line generates **all 7 RESTful routes**. Run `mix phx.routes` to see them:

```
GET    /products           ProductController :index
GET    /products/new       ProductController :new
POST   /products           ProductController :create
GET    /products/:id       ProductController :show
GET    /products/:id/edit  ProductController :edit
PUT    /products/:id       ProductController :update
PATCH  /products/:id       ProductController :update
DELETE /products/:id       ProductController :delete
```

Notice: Both PUT and PATCH map to `:update`. PUT means "replace entire resource", PATCH means "partial update". Phoenix routes both to the same action.

---

## Customizing with `:only` and `:except`

### Only specific actions

```elixir
# API — no form pages needed
resources "/products", ProductController, only: [:index, :show, :create, :update, :delete]

# Read-only resource
resources "/reports", ReportController, only: [:index, :show]
```

### Exclude specific actions

```elixir
# No deletion allowed
resources "/products", ProductController, except: [:delete]
```

---

## Singular Resources

For resources where there's only one (like "my profile"):

```elixir
# No :id in the path, no :index action
resources "/profile", ProfileController, singleton: true
```

Generates:
```
GET    /profile/new    ProfileController :new
POST   /profile        ProfileController :create
GET    /profile        ProfileController :show
GET    /profile/edit   ProfileController :edit
PUT    /profile        ProfileController :update
PATCH  /profile        ProfileController :update
DELETE /profile        ProfileController :delete
```

No `:id` needed — there's only one profile (the current user's).

---

## The Controller

Each action from `resources` needs a corresponding function in the controller:

```elixir
defmodule MyAppWeb.ProductController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    products = Catalog.list_products()
    render(conn, :index, products: products)
  end

  def new(conn, _params) do
    changeset = Catalog.change_product(%Product{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"product" => product_params}) do
    case Catalog.create_product(product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product created!")
        |> redirect(to: ~p"/products/#{product}")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    product = Catalog.get_product!(id)
    render(conn, :show, product: product)
  end

  def edit(conn, %{"id" => id}) do
    product = Catalog.get_product!(id)
    changeset = Catalog.change_product(product)
    render(conn, :edit, product: product, changeset: changeset)
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Catalog.get_product!(id)

    case Catalog.update_product(product, product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product updated!")
        |> redirect(to: ~p"/products/#{product}")

      {:error, changeset} ->
        render(conn, :edit, product: product, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product)

    conn
    |> put_flash(:info, "Product deleted!")
    |> redirect(to: ~p"/products")
  end
end
```

---

## Path Helpers & Verified Routes

Every resource route gets path helper functions:

```elixir
# Old style (path helpers):
product_path(conn, :index)          # "/products"
product_path(conn, :show, 42)       # "/products/42"
product_path(conn, :edit, product)  # "/products/5/edit"

# New style (verified routes — preferred):
~p"/products"           # "/products"
~p"/products/#{product}" # "/products/42"
~p"/products/#{product}/edit" # "/products/42/edit"
```

Verified routes (`~p`) are checked at **compile time** — typos become compiler errors, not runtime 404s.

---

## Route Naming with `:as`

```elixir
# Custom path helper name:
resources "/admin/products", Admin.ProductController, as: :admin_product
# Generates: admin_product_path/3 instead of product_path/3

# Useful when you have the same resource in different scopes:
scope "/", MyAppWeb do
  resources "/products", ProductController
end

scope "/admin", MyAppWeb.Admin do
  resources "/products", ProductController, as: :admin_product
end
```

---

## Key Takeaways

1. `resources "/path", Controller` generates all **7 CRUD routes**
2. Use `:only` and `:except` to limit which routes are generated
3. Use `singleton: true` for resources without an ID
4. Each route maps to a **controller action** (function)
5. Use `~p"/path"` (verified routes) for compile-time checked URLs
6. Both PUT and PATCH map to the `:update` action
7. `mix phx.routes` shows all generated routes
