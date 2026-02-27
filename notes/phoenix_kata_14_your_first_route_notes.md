# Kata 14: Your First Route

## What is Routing?

Routing is the mapping of **URLs to code**. When a browser requests `GET /products`, the router decides which function handles it.

```
GET /products → ProductController.index/2
GET /about    → PageController.about/2
POST /login   → SessionController.create/2
```

---

## Phoenix Router Anatomy

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # 1. Define pipelines (plug groups)
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
  end

  # 2. Define routes within scopes
  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/products", ProductController, :index
  end

  scope "/api", MyAppWeb do
    pipe_through :api

    get "/users", UserController, :index
  end
end
```

---

## Route Syntax

```elixir
get "/path", ControllerModule, :action_name
```

| Part | Meaning |
|------|---------|
| `get` | HTTP method (get, post, put, patch, delete) |
| `"/path"` | URL path to match |
| `ControllerModule` | Which controller handles this |
| `:action_name` | Which function in the controller |

### Examples

```elixir
get    "/"         , PageController,    :home      # Homepage
get    "/about"    , PageController,    :about     # About page
get    "/products" , ProductController, :index     # List products
post   "/products" , ProductController, :create    # Create product
get    "/products/:id", ProductController, :show   # Show one product
put    "/products/:id", ProductController, :update # Update product
delete "/products/:id", ProductController, :delete # Delete product
```

---

## Scopes

Scopes group routes that share a **path prefix** and/or **module prefix**:

```elixir
# All routes prefixed with "/" and modules prefixed with MyAppWeb
scope "/", MyAppWeb do
  pipe_through :browser

  get "/", PageController, :home
  # Matches: GET /
  # Calls: MyAppWeb.PageController.home/2
end

# All routes prefixed with "/admin"
scope "/admin", MyAppWeb.Admin do
  pipe_through [:browser, :require_admin]

  get "/", DashboardController, :index
  # Matches: GET /admin
  # Calls: MyAppWeb.Admin.DashboardController.index/2

  get "/users", UserController, :index
  # Matches: GET /admin/users
  # Calls: MyAppWeb.Admin.UserController.index/2
end
```

---

## pipe_through — Applying Pipelines

`pipe_through` selects which pipeline(s) a group of routes uses:

```elixir
scope "/", MyAppWeb do
  pipe_through :browser           # HTML pipeline
  get "/", PageController, :home
end

scope "/api", MyAppWeb do
  pipe_through :api               # JSON pipeline
  get "/users", UserController, :index
end

scope "/admin", MyAppWeb do
  pipe_through [:browser, :admin] # Multiple pipelines!
  get "/", AdminController, :index
end
```

---

## Viewing Your Routes

```bash
$ mix phx.routes

GET  /          MyAppWeb.PageController    :home
GET  /about     MyAppWeb.PageController    :about
GET  /products  MyAppWeb.ProductController :index
POST /products  MyAppWeb.ProductController :create
```

This shows every defined route, its HTTP method, path, controller, and action.

---

## A Complete First Route Example

### 1. Add the route (router.ex)

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  get "/", PageController, :home
  get "/hello", HelloController, :index    # ← New route
end
```

### 2. Create the controller

```elixir
defmodule MyAppWeb.HelloController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
```

### 3. Create the view module

```elixir
defmodule MyAppWeb.HelloHTML do
  use MyAppWeb, :html

  embed_templates "hello_html/*"
end
```

### 4. Create the template

```heex
<!-- lib/my_app_web/controllers/hello_html/index.html.heex -->
<h1>Hello, Phoenix!</h1>
<p>This is my first route.</p>
```

### 5. Visit http://localhost:4000/hello

The request flows:
```
GET /hello
  → Endpoint (plugs)
  → Router (matches GET /hello)
  → :browser pipeline (session, CSRF, etc.)
  → HelloController.index/2
  → HelloHTML renders index.html.heex
  → HTML response sent
```

---

## LiveView Routes

For LiveView (no controller needed):

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  live "/dashboard", DashboardLive
  live "/products/:id", ProductLive.Show
end
```

LiveView routes use `live` instead of `get` and point directly to a LiveView module — no controller or template files needed.

---

## Key Takeaways

1. The **Router** maps URLs to controllers/LiveViews
2. Route syntax: `get "/path", Controller, :action`
3. **Scopes** group routes with shared path/module prefixes
4. **pipe_through** selects which pipeline a group of routes uses
5. Use `mix phx.routes` to see all defined routes
6. A route needs: router entry → controller → view/template (or just LiveView)
7. LiveView routes use `live "/path", LiveViewModule`
