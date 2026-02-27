# Kata 15: Route Parameters

## Path Parameters

Path parameters capture dynamic segments of a URL:

```elixir
get "/users/:id", UserController, :show
```

When someone visits `/users/42`, Phoenix extracts `42` and puts it in `conn.params`:

```elixir
def show(conn, %{"id" => id}) do
  # id is "42" (always a string!)
  user = Accounts.get_user!(id)
  render(conn, :show, user: user)
end
```

### Multiple Path Parameters

```elixir
get "/users/:user_id/posts/:id", PostController, :show
```

For `/users/5/posts/42`:
```elixir
conn.params = %{"user_id" => "5", "id" => "42"}
```

---

## Query Parameters

Query parameters come after `?` in the URL:

```
/products?page=2&sort=name&category=books
```

They're automatically parsed into `conn.params`:

```elixir
def index(conn, params) do
  # params = %{"page" => "2", "sort" => "name", "category" => "books"}
  page = String.to_integer(params["page"] || "1")
  sort = params["sort"] || "name"
  products = Products.list(page: page, sort: sort)
  render(conn, :index, products: products)
end
```

### Path params + Query params merge

For `GET /users/42?tab=posts`:

```elixir
get "/users/:id", UserController, :show

# In the controller:
def show(conn, %{"id" => id, "tab" => tab}) do
  # id = "42", tab = "posts"
end
```

Both path and query params are merged into one `params` map.

---

## Pattern Matching in Controllers

Elixir's pattern matching makes param handling elegant:

```elixir
# Match specific values
def show(conn, %{"format" => "json"} = params) do
  json(conn, %{data: "..."})
end

def show(conn, %{"format" => "html"} = params) do
  render(conn, :show)
end

# Default clause
def show(conn, params) do
  render(conn, :show)
end
```

### Requiring Parameters

```elixir
# This crashes (MatchError) if "id" is missing:
def show(conn, %{"id" => id}) do
  # ...
end

# Safer — provide defaults:
def index(conn, params) do
  page = Map.get(params, "page", "1") |> String.to_integer()
  per_page = Map.get(params, "per_page", "20") |> String.to_integer()
  # ...
end
```

---

## Catch-All Routes

### Glob Matching

```elixir
get "/files/*path", FileController, :show
```

For `/files/images/photos/sunset.jpg`:
```elixir
# path = ["images", "photos", "sunset.jpg"]
def show(conn, %{"path" => path_segments}) do
  full_path = Enum.join(path_segments, "/")
  # full_path = "images/photos/sunset.jpg"
end
```

### Catch-all for 404s

Routes are matched **top to bottom**. Put catch-all routes last:

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  get "/", PageController, :home
  get "/about", PageController, :about

  # This MUST be last — it matches everything!
  get "/*path", PageController, :not_found
end
```

---

## Verified Routes (~p sigil)

Phoenix provides compile-time verified route paths:

```elixir
# Instead of string paths (can have typos):
"/users/#{user.id}"

# Use verified routes (compile-time checked):
~p"/users/#{user.id}"
```

If the route doesn't exist in your router, you get a **compile-time error** — not a runtime 404.

```elixir
# In templates:
<.link navigate={~p"/users/#{@user}"}>View Profile</.link>

# In controllers:
redirect(conn, to: ~p"/products/#{product}")
```

---

## Nested Routes

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  # Top-level
  resources "/users", UserController do
    # Nested — generates /users/:user_id/posts routes
    resources "/posts", PostController
  end
end
```

Generated routes:
```
GET    /users/:user_id/posts      PostController :index
GET    /users/:user_id/posts/:id  PostController :show
POST   /users/:user_id/posts      PostController :create
# etc.
```

In the controller:
```elixir
def index(conn, %{"user_id" => user_id}) do
  user = Accounts.get_user!(user_id)
  posts = Blog.list_posts_for_user(user)
  render(conn, :index, posts: posts, user: user)
end
```

---

## Practical Patterns

### Optional Parameters with Defaults

```elixir
def index(conn, params) do
  opts = [
    page: to_integer(params["page"], 1),
    per_page: to_integer(params["per_page"], 20),
    sort: params["sort"] || "inserted_at",
    order: params["order"] || "desc"
  ]
  products = Products.list(opts)
  render(conn, :index, products: products, opts: opts)
end

defp to_integer(nil, default), do: default
defp to_integer(str, default) do
  case Integer.parse(str) do
    {n, ""} -> n
    _ -> default
  end
end
```

### Slug-Based Routes

```elixir
get "/blog/:slug", BlogController, :show

# /blog/my-first-post
def show(conn, %{"slug" => slug}) do
  post = Blog.get_post_by_slug!(slug)
  render(conn, :show, post: post)
end
```

---

## Key Takeaways

1. **Path params** (`:id`) capture dynamic URL segments — always strings
2. **Query params** (`?key=value`) are merged into the same `params` map
3. Use **pattern matching** in controller function heads for clean param handling
4. **Glob routes** (`*path`) capture multiple segments as a list
5. Put **catch-all routes last** — routes match top to bottom
6. Use `~p"/path/#{id}"` for **compile-time verified** routes
7. All params are **strings** — convert to integers/atoms as needed
