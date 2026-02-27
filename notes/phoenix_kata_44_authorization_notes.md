# Kata 44: Authorization

## Authentication vs Authorization

These are two distinct concerns:

- **Authentication**: Who are you? (login, sessions, tokens)
- **Authorization**: What are you allowed to do? (permissions, roles)
- **Scoping**: What data can you see? (query-level filtering)

Authentication answers "is this user who they claim to be?". Authorization answers "is this authenticated user allowed to perform this action on this resource?".

---

## Simple Role System

The simplest approach: add a `role` field directly to the User schema.

```elixir
schema "users" do
  field :email, :string
  field :hashed_password, :string, redact: true
  field :role, Ecto.Enum,
        values: [:user, :moderator, :admin],
        default: :user
  timestamps()
end
```

Helper functions in the Accounts context:

```elixir
def admin?(%User{role: :admin}), do: true
def admin?(_user), do: false

def moderator?(%User{role: role}),
  do: role in [:moderator, :admin]
```

Router plug for admin-only routes:

```elixir
defp require_admin(conn, _opts) do
  if conn.assigns.current_user && Accounts.admin?(conn.assigns.current_user) do
    conn
  else
    conn
    |> put_flash(:error, "You are not authorized to access this page.")
    |> redirect(to: ~p"/")
    |> halt()
  end
end

# Usage in router:
scope "/admin", MyAppWeb.Admin, as: :admin do
  pipe_through [:browser, :require_authenticated_user, :require_admin]
  resources "/users", UserController
end
```

---

## Role-Based Access Control (RBAC)

For more fine-grained control, map roles to lists of permissions:

```elixir
defmodule MyApp.Authorization do
  @permissions %{
    user: [:read, :create_comment, :update_own, :delete_own],
    moderator: [:read, :create_comment, :update_own, :delete_own,
                :delete_any, :hide_post],
    admin: :all   # special atom — admins can do everything
  }

  # Admins bypass all checks:
  def can?(%{role: :admin}, _action, _resource), do: true

  # Ownership-based actions:
  def can?(%{id: uid} = user, action, %{user_id: uid})
      when action in [:update_own, :delete_own] do
    perms = Map.get(@permissions, user.role, [])
    action in perms
  end

  # General permission check:
  def can?(user, action, _resource) do
    perms = Map.get(@permissions, user.role, [])
    action in perms
  end

  # Raise on failure (for use with `with`):
  def authorize!(user, action, resource) do
    if can?(user, action, resource) do
      {:ok, resource}
    else
      {:error, :unauthorized}
    end
  end
end
```

Usage:

```elixir
if Authorization.can?(current_user, :delete_any, comment) do
  Blog.delete_comment(comment)
end
```

---

## Policy Pattern

Centralizing authorization in per-resource policy modules is a clean, testable pattern. Inspired by Ruby's Pundit and Elixir's Bodyguard library:

```elixir
defmodule MyApp.Blog.Policy do
  alias MyApp.Accounts.User
  alias MyApp.Blog.Post

  # Return :ok or {:error, :unauthorized}

  # Admins can do anything:
  def authorize(_action, %User{role: :admin}, _resource), do: :ok

  # Authors can edit/delete their own posts:
  def authorize(action, %User{id: uid}, %Post{user_id: uid})
      when action in [:update, :delete], do: :ok

  # Everyone can read published posts:
  def authorize(:read, _user, %Post{published: true}), do: :ok

  # Logged-in users can create posts:
  def authorize(:create, %User{}, _params), do: :ok

  # Deny everything else:
  def authorize(_action, _user, _resource), do: {:error, :unauthorized}
end
```

Using the policy in a controller:

```elixir
def update(conn, %{"id" => id, "post" => params}) do
  post = Blog.get_post!(id)
  user = conn.assigns.current_user

  case Blog.Policy.authorize(:update, user, post) do
    :ok ->
      case Blog.update_post(post, params) do
        {:ok, post} -> redirect(conn, to: ~p"/posts/#{post}")
        {:error, changeset} -> render(conn, :edit, changeset: changeset)
      end

    {:error, :unauthorized} ->
      conn
      |> put_flash(:error, "You are not authorized to edit this post.")
      |> redirect(to: ~p"/posts")
  end
end
```

---

## Controller Plug Pattern

Use controller-level plugs to separate resource loading from authorization:

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  # These plugs run before the action, only for specified actions:
  plug :load_post when action in [:show, :edit, :update, :delete]
  plug :authorize_post when action in [:edit, :update, :delete]

  def show(conn, _params) do
    render(conn, :show, post: conn.assigns.post)
  end

  def edit(conn, _params) do
    render(conn, :edit, post: conn.assigns.post)
  end

  defp load_post(conn, _opts) do
    post = Blog.get_post!(conn.params["id"])
    assign(conn, :post, post)
  end

  defp authorize_post(conn, _opts) do
    user = conn.assigns.current_user
    post = conn.assigns.post

    if post.user_id == user.id or Accounts.admin?(user) do
      conn
    else
      conn
      |> put_flash(:error, "Not authorized.")
      |> redirect(to: ~p"/posts")
      |> halt()
    end
  end
end
```

**Important**: always call `halt/1` after redirecting in a plug. Without `halt`, the pipeline continues and the controller action still runs.

---

## Scope-Based Authorization

Filtering data at the **query level** is the most secure approach. Instead of fetching all records and filtering in Elixir, scope the query so unauthorized data is never loaded:

```elixir
defmodule MyApp.Blog do
  import Ecto.Query

  # Admin sees all posts; regular user sees only their own:
  def list_posts(%{role: :admin}), do: Repo.all(Post)

  def list_posts(user) do
    Post
    |> where(user_id: ^user.id)
    |> Repo.all()
  end

  # Safe fetch: raises if user does not own the post
  def get_post_for_user!(user, id) do
    Post
    |> where(id: ^id, user_id: ^user.id)
    |> Repo.one!()
  end

  # Always scope updates through the user:
  def update_post(user, id, attrs) do
    post = get_post_for_user!(user, id)
    post |> Post.changeset(attrs) |> Repo.update()
  end
end
```

This prevents **Insecure Direct Object Reference (IDOR)** attacks where a user guesses another user's resource ID in the URL (e.g., changing `/posts/42/edit` to `/posts/43/edit`).

---

## Phoenix 1.8 Scopes

Phoenix 1.8 introduces a first-class Scope concept that is threaded through contexts:

```elixir
defmodule MyApp.Scope do
  defstruct [:user, :role]

  def for_user(%User{} = user) do
    %__MODULE__{user: user, role: user.role}
  end
end

# Context functions accept a scope:
defmodule MyApp.Blog do
  def list_posts(%Scope{role: :admin}), do: Repo.all(Post)

  def list_posts(%Scope{user: user}) do
    Post |> where(user_id: ^user.id) |> Repo.all()
  end
end

# Controller passes scope derived from conn:
def index(conn, _params) do
  scope = Scope.for_user(conn.assigns.current_user)
  posts = Blog.list_posts(scope)
  render(conn, :index, posts: posts)
end
```

---

## Authorization in LiveView

**Critical rule**: check authorization in both `mount/3` AND `handle_event/3`. Users can send arbitrary WebSocket events from DevTools — never assume the UI prevents unauthorized actions.

```elixir
defmodule MyAppWeb.PostLive.Edit do
  use MyAppWeb, :live_view

  # on_mount ensures the user is authenticated:
  on_mount {UserAuth, :ensure_authenticated}

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user
    post = Blog.get_post!(id)

    # Check authorization in mount:
    if post.user_id != user.id and not Accounts.admin?(user) do
      {:ok,
       socket
       |> put_flash(:error, "Not authorized.")
       |> redirect(to: ~p"/posts")}
    else
      {:ok, assign(socket, post: post, changeset: Blog.change_post(post))}
    end
  end

  # ALSO check authorization in every event handler:
  def handle_event("save", %{"post" => params}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.post

    # Re-verify authorization (never trust UI state alone):
    if post.user_id != user.id and not Accounts.admin?(user) do
      {:noreply, socket |> put_flash(:error, "Not authorized.")}
    else
      case Blog.update_post(post, params) do
        {:ok, _post} ->
          {:noreply, push_navigate(socket, to: ~p"/posts")}
        {:error, changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

end
```

---

## Authorization Libraries

| Library | Style | Notes |
|---------|-------|-------|
| **Bodyguard** | Policy modules | Recommended, simple, well-documented |
| **Canada** | Protocol-based | Uses `Canada.Can` protocol on structs |
| **Canary** | Declarative plugs | Plug-based, auto-loads and authorizes |
| **Heimdall** | Permission sets | Full role + permission system |

Rolling your own is also very reasonable in Elixir. Pattern matching makes policy functions clean, readable, and easy to test without external dependencies.

---

## Key Takeaways

1. **Authentication is not authorization**: one tells you who the user is, the other what they can do
2. **Scope queries** at the DB level to prevent IDOR — never trust user-supplied IDs without ownership checks
3. **Policy modules** centralize authorization logic — one module per resource, easy to test
4. In **LiveView**, check authorization in both `mount/3` AND every `handle_event/3`
5. Always call **`halt/1` after redirect** in plugs to stop the pipeline from continuing
6. **Admin bypass** should be explicit — encode it as the first clause in policy functions
7. Use **`get_post_for_user!(user, id)`** patterns instead of `get_post!(id)` to prevent IDOR
8. The **Scope** pattern decouples authorization from the web layer, making context functions testable
