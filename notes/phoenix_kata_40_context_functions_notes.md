# Kata 40: Context Functions

## The Standard CRUD Pattern

Phoenix contexts expose a consistent set of functions for each schema. The generator (`mix phx.gen.context`) creates all six:

| Function | Returns | Purpose |
|---|---|---|
| `list_posts()` | `[%Post{}, ...]` | All records |
| `get_post!(id)` | `%Post{}` or raises | One record, or error |
| `get_post(id)` | `%Post{}` or `nil` | One record, or nil |
| `create_post(attrs)` | `{:ok, post}` or `{:error, cs}` | Insert |
| `update_post(post, attrs)` | `{:ok, post}` or `{:error, cs}` | Update |
| `delete_post(post)` | `{:ok, post}` or `{:error, cs}` | Delete |
| `change_post(post, attrs)` | `%Ecto.Changeset{}` | For forms (no DB call) |

---

## Read Functions

### list_*

Returns all records. Always returns a list (empty list if none found, never nil).

```elixir
def list_posts do
  Repo.all(Post)
end

# With ordering:
def list_posts do
  from(p in Post, order_by: [desc: p.inserted_at])
  |> Repo.all()
end

# With filtering:
def list_published_posts do
  from(p in Post,
    where: p.published == true,
    order_by: [desc: p.published_at])
  |> Repo.all()
end

# With pagination:
def list_posts(page: page, per_page: per_page) do
  offset = (page - 1) * per_page
  Post
  |> order_by([p], desc: p.inserted_at)
  |> limit(^per_page)
  |> offset(^offset)
  |> Repo.all()
end
```

### get_*! vs get_*

The bang variant raises on missing; the non-bang returns nil.

```elixir
# Raises Ecto.NoResultsError — Phoenix converts this to a 404
def get_post!(id), do: Repo.get!(Post, id)

# Returns nil — caller decides what to do
def get_post(id), do: Repo.get(Post, id)

# Get by any field
def get_post_by_slug(slug), do: Repo.get_by(Post, slug: slug)

# With preloaded associations
def get_post_with_comments!(id) do
  Post
  |> Repo.get!(id)
  |> Repo.preload([:comments, :author])
end
```

**When to use which:**
- Use `get_post!(id)` in controller actions when the ID comes from a URL parameter and a missing record should show a 404.
- Use `get_post(id)` when nil is an expected result you want to handle gracefully.

### Preloading

```elixir
# Two queries (load then preload):
post = Repo.get!(Post, id)
post = Repo.preload(post, [:comments, :author])

# One query (join):
from(p in Post,
  where: p.id == ^id,
  preload: [:comments, :author])
|> Repo.one!()

# Nested preload:
Repo.all(Post)
|> Repo.preload([comments: :author, author: :profile])
```

---

## Write Functions

### create_*

Inserts a new record using a blank struct and the provided attributes.

```elixir
def create_post(attrs \\ %{}) do
  %Post{}
  |> Post.changeset(attrs)
  |> Repo.insert()
end

# Returns:
# {:ok, %Post{id: 1, title: "Hello", ...}}
# {:error, %Ecto.Changeset{valid?: false, errors: [...]}}
```

Controller usage:

```elixir
def create(conn, %{"post" => post_params}) do
  case Blog.create_post(post_params) do
    {:ok, post} ->
      conn
      |> put_flash(:info, "Post created successfully.")
      |> redirect(to: ~p"/posts/#{post.id}")

    {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, :new, changeset: changeset)
  end
end
```

### update_*

Takes the loaded struct and new attributes. Always load the struct first so Ecto tracks which fields changed.

```elixir
def update_post(%Post{} = post, attrs) do
  post
  |> Post.changeset(attrs)
  |> Repo.update()
end

# Controller:
def update(conn, %{"id" => id, "post" => post_params}) do
  post = Blog.get_post!(id)

  case Blog.update_post(post, post_params) do
    {:ok, post} ->
      conn
      |> put_flash(:info, "Post updated.")
      |> redirect(to: ~p"/posts/#{post.id}")

    {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, :edit, post: post, changeset: changeset)
  end
end
```

### delete_*

Deletes an already-loaded struct.

```elixir
def delete_post(%Post{} = post) do
  Repo.delete(post)
end

# Deletion can fail if foreign key constraints prevent it:
case Blog.delete_post(post) do
  {:ok, _post} ->
    conn |> put_flash(:info, "Post deleted.") |> redirect(to: ~p"/posts")

  {:error, _changeset} ->
    conn |> put_flash(:error, "Cannot delete: has associated records.")
    |> redirect(to: ~p"/posts/#{post.id}")
end
```

### change_*

Returns a changeset for populating a form. Does **not** hit the database.

```elixir
def change_post(%Post{} = post, attrs \\ %{}) do
  Post.changeset(post, attrs)
end

# new action — empty changeset for a blank form:
def new(conn, _params) do
  changeset = Blog.change_post(%Post{})
  render(conn, :new, changeset: changeset)
end

# edit action — changeset pre-filled with current values:
def edit(conn, %{"id" => id}) do
  post = Blog.get_post!(id)
  changeset = Blog.change_post(post)
  render(conn, :edit, post: post, changeset: changeset)
end
```

---

## Error Handling

### Return value conventions

```elixir
# Reads never return error tuples:
Blog.list_posts()     # => [] or [%Post{}, ...]
Blog.get_post!(id)    # => %Post{} or raises Ecto.NoResultsError
Blog.get_post(id)     # => %Post{} or nil

# Writes always return ok/error tuples:
Blog.create_post(attrs)    # => {:ok, %Post{}} or {:error, changeset}
Blog.update_post(p, attrs) # => {:ok, %Post{}} or {:error, changeset}
Blog.delete_post(p)        # => {:ok, %Post{}} or {:error, changeset}
```

### Inspecting changeset errors

```elixir
{:error, changeset} = Blog.create_post(%{title: nil})

changeset.valid?   # => false
changeset.errors   # => [title: {"can't be blank", [validation: :required]}]

# Traverse to get human-readable messages:
Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
  Enum.reduce(opts, msg, fn {key, value}, acc ->
    String.replace(acc, "%{#{key}}", to_string(value))
  end)
end)
# => %{title: ["can't be blank"]}
```

### Custom error tuples

Not all failures involve changesets. Use custom atoms for business rule failures:

```elixir
def authenticate_user(email, password) do
  case get_user_by_email(email) do
    nil ->
      Bcrypt.no_user_verify()   # prevent timing attacks
      {:error, :not_found}
    user ->
      if Bcrypt.verify_pass(password, user.hashed_password) do
        {:ok, user}
      else
        {:error, :invalid_password}
      end
  end
end

# Caller:
case Accounts.authenticate_user(email, password) do
  {:ok, user}                 -> log_in(conn, user)
  {:error, :not_found}        -> put_flash(conn, :error, "No account found.")
  {:error, :invalid_password} -> put_flash(conn, :error, "Wrong password.")
end
```

---

## Ecto.Multi for Atomic Operations

When a single context function needs multiple DB operations to succeed or fail together:

```elixir
def register_user_with_profile(user_attrs, profile_attrs) do
  Ecto.Multi.new()
  |> Ecto.Multi.insert(:user,
      User.registration_changeset(%User{}, user_attrs))
  |> Ecto.Multi.run(:profile, fn _repo, %{user: user} ->
      attrs = Map.put(profile_attrs, :user_id, user.id)
      Repo.insert(Profile.changeset(%Profile{}, attrs))
    end)
  |> Repo.transaction()
end

# Returns:
# {:ok, %{user: %User{}, profile: %Profile{}}}
# {:error, :user, %Ecto.Changeset{}, %{}}      (user insert failed)
# {:error, :profile, %Ecto.Changeset{}, %{user: user}}  (profile insert failed)
```

---

## LiveView Usage

Context functions work identically in LiveViews:

```elixir
defmodule MyAppWeb.PostLive.Index do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: Blog.list_published_posts())}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    post = Blog.get_post!(id)

    case Blog.delete_post(post) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post deleted.")
         |> assign(posts: Blog.list_published_posts())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete post.")}
    end
  end
end
```

---

## Key Takeaways

1. **list_*** always returns a list (empty, never nil)
2. **get_*!** raises on missing — use when you expect the record to exist (URL params)
3. **get_*** returns nil — use when nil is an expected, handleable result
4. **create_*/update_*/delete_*** return `{:ok, struct}` or `{:error, changeset}`
5. **change_*** returns a changeset for forms without touching the database
6. Pass the **loaded struct** to `update_*` and `delete_*`, not just an ID
7. Use **Ecto.Multi** when multiple operations must succeed or fail atomically
8. Custom business rule failures use **custom error atoms** like `{:error, :not_found}`
