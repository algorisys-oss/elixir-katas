# Kata 17: Nested Routes & Scopes

## Scopes — Grouping Routes

Scopes let you group routes that share a **path prefix** and/or **module prefix**:

```elixir
# Path prefix: /admin
# Module prefix: MyAppWeb.Admin
scope "/admin", MyAppWeb.Admin do
  pipe_through [:browser, :require_admin]

  get "/", DashboardController, :index
  # → GET /admin → MyAppWeb.Admin.DashboardController.index/2

  resources "/users", UserController
  # → GET /admin/users → MyAppWeb.Admin.UserController.index/2
end
```

### How Scopes Compose

```elixir
scope "/", MyAppWeb do              # prefix: /
  pipe_through :browser
  get "/", PageController, :home     # GET /
  get "/about", PageController, :about # GET /about
end

scope "/api", MyAppWeb.API do        # prefix: /api
  pipe_through :api
  get "/users", UserController, :index # GET /api/users
end

scope "/admin", MyAppWeb.Admin do    # prefix: /admin
  pipe_through [:browser, :require_admin]
  get "/", DashboardController, :index # GET /admin
end
```

---

## Nested Scopes

Scopes can be nested — prefixes accumulate:

```elixir
scope "/api", MyAppWeb.API do
  pipe_through :api

  scope "/v1", V1 do
    resources "/users", UserController
    # → GET /api/v1/users → MyAppWeb.API.V1.UserController.index/2
  end

  scope "/v2", V2 do
    resources "/users", UserController
    # → GET /api/v2/users → MyAppWeb.API.V2.UserController.index/2
  end
end
```

Both path prefixes (`/api` + `/v1`) and module prefixes (`MyAppWeb.API` + `V1`) stack.

---

## Nested Resources

Resources can contain other resources:

```elixir
resources "/users", UserController do
  resources "/posts", PostController
end
```

This generates **parent routes** and **child routes**:

```
# Parent routes:
GET    /users           UserController :index
GET    /users/:id       UserController :show
...

# Child routes (nested):
GET    /users/:user_id/posts      PostController :index
GET    /users/:user_id/posts/:id  PostController :show
POST   /users/:user_id/posts      PostController :create
...
```

Notice: The parent ID becomes `:user_id` (not `:id`) to avoid collision with the child's `:id`.

### In the Controller

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  def index(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user!(user_id)
    posts = Blog.list_posts_for_user(user)
    render(conn, :index, user: user, posts: posts)
  end

  def show(conn, %{"user_id" => user_id, "id" => id}) do
    user = Accounts.get_user!(user_id)
    post = Blog.get_post!(id)
    render(conn, :show, user: user, post: post)
  end
end
```

---

## Shallow Nesting

Deep nesting makes URLs unwieldy. A common pattern is **shallow nesting** — only nest the routes that need the parent:

```elixir
# Nested: only where parent context is needed
scope "/users/:user_id", MyAppWeb do
  pipe_through :browser
  resources "/posts", PostController, only: [:index, :new, :create]
end

# Flat: individual posts don't need /users/:user_id prefix
scope "/", MyAppWeb do
  pipe_through :browser
  resources "/posts", PostController, only: [:show, :edit, :update, :delete]
end
```

URLs:
```
GET  /users/5/posts      → list user 5's posts
POST /users/5/posts      → create post for user 5
GET  /posts/42           → show post 42 (no user in URL)
```

---

## `as:` Option — Custom Path Helper Names

When the same controller appears in multiple scopes, path helpers conflict:

```elixir
scope "/", MyAppWeb do
  resources "/products", ProductController
end

scope "/admin", MyAppWeb.Admin do
  resources "/products", ProductController
  # Error! Both generate product_path/3
end
```

Fix with `:as`:

```elixir
scope "/admin", MyAppWeb.Admin, as: :admin do
  resources "/products", ProductController
  # Generates admin_product_path/3
end
```

---

## Real-World Example

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # Public pages
  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :home
    resources "/products", ProductController, only: [:index, :show]
    resources "/blog", BlogController, only: [:index, :show]
  end

  # Authenticated user area
  scope "/", MyAppWeb do
    pipe_through [:browser, :require_auth]

    resources "/orders", OrderController
    resources "/settings", SettingsController, singleton: true
  end

  # Admin area
  scope "/admin", MyAppWeb.Admin, as: :admin do
    pipe_through [:browser, :require_admin]

    get "/", DashboardController, :index
    resources "/users", UserController
    resources "/products", ProductController
  end

  # API
  scope "/api", MyAppWeb.API do
    pipe_through :api

    scope "/v1", V1 do
      resources "/products", ProductController, only: [:index, :show]
    end
  end
end
```

---

## Key Takeaways

1. **Scopes** group routes with shared path and module prefixes
2. Scopes **nest** — prefixes accumulate (`/api` + `/v1` = `/api/v1`)
3. **Nested resources** generate child routes with parent ID (`:user_id`)
4. Use **shallow nesting** to avoid deeply nested URLs
5. Use `:as` to customize **path helper names** when scopes create conflicts
6. Use `pipe_through` in scopes to apply different middleware to route groups
