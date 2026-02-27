# Kata 02: API Resource Routes & Controllers

## The `resources` Macro for APIs

Phoenix's `resources` macro generates all 7 RESTful routes by default. For APIs, we exclude the two browser-only routes:

```elixir
# Full set (browser) — 7 routes:
resources "/posts", PostController

# API set — 5 routes (no form pages):
resources "/posts", PostController, except: [:new, :edit]
```

### Why Exclude `:new` and `:edit`?

The `:new` action renders an HTML form for creating a resource. The `:edit` action renders an HTML form for editing. API clients (mobile apps, React SPAs, other servers) build their own forms — they just need endpoints that accept and return JSON.

| Action | Browser | API | Purpose |
|--------|---------|-----|---------|
| index | Yes | Yes | List all resources |
| show | Yes | Yes | Get one resource |
| new | Yes | **No** | Render "create" form |
| create | Yes | Yes | Create resource from params |
| edit | Yes | **No** | Render "edit" form |
| update | Yes | Yes | Update resource from params |
| delete | Yes | Yes | Delete a resource |

---

## Generated Routes

Given this router:

```elixir
scope "/api", MyAppWeb.Api do
  pipe_through :api
  resources "/posts", PostController, except: [:new, :edit]
end
```

Phoenix generates:

```
GET    /api/posts          PostController :index
GET    /api/posts/:id      PostController :show
POST   /api/posts          PostController :create
PUT    /api/posts/:id      PostController :update
PATCH  /api/posts/:id      PostController :update
DELETE /api/posts/:id      PostController :delete
```

Note: Both `PUT` and `PATCH` route to the same `update` action. By convention, `PUT` replaces the entire resource and `PATCH` updates partial fields, but Phoenix routes both to `update/2`.

---

## API Controllers: `json/2` Instead of `render/2`

Browser controllers use `render/2` to render HTML templates. API controllers use `json/2` to send JSON responses:

```elixir
defmodule MyAppWeb.Api.PostController do
  use MyAppWeb, :controller

  alias MyApp.Blog

  # Browser controller would do:
  # render(conn, :index, posts: posts)

  # API controller does:
  def index(conn, _params) do
    posts = Blog.list_posts()
    json(conn, %{data: posts})
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    json(conn, %{data: post})
  end

  def create(conn, %{"post" => post_params}) do
    case Blog.create_post(post_params) do
      {:ok, post} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/posts/#{post}")
        |> json(%{data: post})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    Blog.delete_post(post)
    send_resp(conn, :no_content, "")
  end
end
```

### Key Differences: Browser vs API Controller

| Aspect | Browser Controller | API Controller |
|--------|-------------------|----------------|
| Response | `render(conn, :index, assigns)` | `json(conn, data)` |
| Templates | `.html.heex` files | None needed |
| Redirects | `redirect(conn, to: path)` | Return JSON + status |
| Errors | Flash messages + redirect | JSON error body |
| Status codes | Mostly implicit (200) | Explicit with `put_status` |

---

## Nested Resources for APIs

When resources have parent-child relationships, use nested routes:

```elixir
scope "/api", MyAppWeb.Api do
  pipe_through :api

  resources "/posts", PostController, except: [:new, :edit] do
    resources "/comments", CommentController, except: [:new, :edit]
  end
end
```

This generates nested paths:

```
GET    /api/posts/:post_id/comments          CommentController :index
GET    /api/posts/:post_id/comments/:id      CommentController :show
POST   /api/posts/:post_id/comments          CommentController :create
PUT    /api/posts/:post_id/comments/:id      CommentController :update
DELETE /api/posts/:post_id/comments/:id      CommentController :delete
```

The nested controller receives `post_id` in params:

```elixir
defmodule MyAppWeb.Api.CommentController do
  use MyAppWeb, :controller

  def index(conn, %{"post_id" => post_id}) do
    comments = Blog.list_comments_for_post(post_id)
    json(conn, %{data: comments})
  end

  def create(conn, %{"post_id" => post_id, "comment" => comment_params}) do
    case Blog.create_comment(post_id, comment_params) do
      {:ok, comment} ->
        conn
        |> put_status(:created)
        |> json(%{data: comment})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end
end
```

### When to Nest vs Flatten

- **Nest** when the child only makes sense in context of the parent (`/posts/42/comments`)
- **Flatten** when the child is independently addressable (`/comments/99`)
- **Avoid deep nesting** — more than 2 levels gets unwieldy (`/posts/42/comments/7/replies` — consider flattening `replies`)

---

## Only Generating Specific Actions

You can also use `only:` instead of `except:`:

```elixir
# Read-only API — no create, update, or delete
resources "/posts", PostController, only: [:index, :show]

# Write-only (rare, but possible)
resources "/logs", LogController, only: [:create]
```

---

## Viewing Your Routes

Use `mix phx.routes` to see all generated routes:

```bash
$ mix phx.routes

  GET    /api/posts          MyAppWeb.Api.PostController :index
  GET    /api/posts/:id      MyAppWeb.Api.PostController :show
  POST   /api/posts          MyAppWeb.Api.PostController :create
  PUT    /api/posts/:id      MyAppWeb.Api.PostController :update
  PATCH  /api/posts/:id      MyAppWeb.Api.PostController :update
  DELETE /api/posts/:id      MyAppWeb.Api.PostController :delete
```
