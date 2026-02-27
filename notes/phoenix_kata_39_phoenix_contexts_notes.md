# Kata 39: Phoenix Contexts

## What Is a Context?

A **context** is an Elixir module that acts as a boundary between your web layer and your business logic. It:

1. Groups related schemas, queries, and business rules under one module
2. Exposes a clean public API to controllers, LiveViews, and other callers
3. Is the **only** place in its domain that calls `Repo`

```
Browser Request
  └── Router
        └── Controller / LiveView       (web layer)
              └── MyApp.Accounts        (context — public API)
                    └── Repo + Schema   (data layer — private)
```

The web layer **never** calls `Repo` or uses schema modules directly. It only calls context functions.

---

## Why Contexts?

Without contexts you get the "fat controller" problem:

```elixir
# BAD — controller knows too much
def create(conn, %{"user" => params}) do
  changeset = User.changeset(%User{}, params)   # schema leaking into web
  case Repo.insert(changeset) do                # Repo in web layer
    {:ok, user} ->
      Mailer.send_welcome_email(user)           # side effects mixed in
      redirect(conn, to: ~p"/users/#{user.id}")
    {:error, changeset} ->
      render(conn, :new, changeset: changeset)
  end
end
```

With a context the controller stays thin:

```elixir
# GOOD — controller delegates everything
def create(conn, %{"user" => params}) do
  case Accounts.register_user(params) do
    {:ok, user} ->
      redirect(conn, to: ~p"/users/#{user.id}")
    {:error, changeset} ->
      render(conn, :new, changeset: changeset)
  end
end
```

`Accounts.register_user/1` handles the changeset, Repo call, and welcome email internally. The controller does not need to know any of that.

---

## Project Structure

```
lib/
└── my_app/
    ├── accounts.ex              # Accounts context (public API)
    ├── accounts/
    │   ├── user.ex              # User schema (private)
    │   └── token.ex             # Token schema (private)
    ├── blog.ex                  # Blog context
    ├── blog/
    │   ├── post.ex
    │   └── comment.ex
    └── repo.ex

lib/my_app_web/
    ├── controllers/
    │   └── user_controller.ex   # calls MyApp.Accounts.*
    └── live/
        └── dashboard_live.ex    # calls MyApp.Accounts.*, MyApp.Blog.*
```

Schemas inside the context directory (`accounts/user.ex`) are considered **private implementation details**. Callers never reference them directly.

---

## The Context Module

```elixir
# lib/my_app/accounts.ex
defmodule MyApp.Accounts do
  import Ecto.Query, warn: false
  alias MyApp.Repo
  alias MyApp.Accounts.User

  # List all users
  def list_users, do: Repo.all(User)

  # Get one user (raises on missing)
  def get_user!(id), do: Repo.get!(User, id)

  # Get one user (returns nil on missing)
  def get_user(id), do: Repo.get(User, id)

  # Create a user
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  # Update a user
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  # Delete a user
  def delete_user(%User{} = user), do: Repo.delete(user)

  # Return a changeset for use in forms
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
```

---

## The Schema Module

```elixir
# lib/my_app/accounts/user.ex
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :hashed_password, :string
    field :password, :string, virtual: true   # not persisted

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
  end
end
```

Note the `@doc false` on changesets — they're marked private to signal that callers shouldn't use them directly.

---

## mix phx.gen.context

The generator scaffolds the entire context in one command:

```bash
$ mix phx.gen.context Blog Post posts \
    title:string body:text published:boolean

# Creates:
# lib/my_app/blog.ex
# lib/my_app/blog/post.ex
# priv/repo/migrations/20240101000000_create_posts.exs
# test/my_app/blog_test.exs
# test/support/fixtures/blog_fixtures.ex
```

Then run:

```bash
$ mix ecto.migrate
```

The generated context has all six standard functions:

```elixir
Blog.list_posts()
Blog.get_post!(id)
Blog.create_post(attrs)
Blog.update_post(post, attrs)
Blog.delete_post(post)
Blog.change_post(post, attrs)    # changeset for forms
```

### Full HTML scaffold

To also generate the controller and templates:

```bash
$ mix phx.gen.html Blog Post posts title:string body:text

# Adds to router.ex:
resources "/posts", PostController
```

### Field types

| Type | SQL |
|---|---|
| `string` | VARCHAR |
| `text` | TEXT |
| `integer` | INTEGER |
| `float` | FLOAT |
| `boolean` | BOOLEAN |
| `map` | JSONB (Postgres) |
| `references:users` | user_id foreign key |
| `uuid` | UUID |
| `date` | DATE |
| `utc_datetime` | TIMESTAMP WITH TIME ZONE |

---

## Context Design Principles

### Name contexts after domain areas, not layers

```elixir
# Good — describes what the business does
defmodule MyApp.Accounts    # user identity
defmodule MyApp.Catalog     # products, categories
defmodule MyApp.Orders      # order lifecycle
defmodule MyApp.Notifications  # outbound messages

# Bad — describes how, not what
defmodule MyApp.Models      # too vague
defmodule MyApp.Database    # names the technology
defmodule MyApp.Helpers     # catch-all
```

### Return idiomatic results

```elixir
# Mutations return {:ok, struct} or {:error, changeset}
{:ok, user} = Accounts.create_user(attrs)
{:error, changeset} = Accounts.create_user(bad_attrs)

# Reads return struct, list, or nil
user = Accounts.get_user(id)       # nil if missing
user = Accounts.get_user!(id)      # raises if missing
users = Accounts.list_users()      # always a list
```

### Don't leak Ecto details

```elixir
# BAD — callers have to know about Ecto.Query
def search_users(query_string) do
  from(u in User, where: ilike(u.name, ^"%#{query_string}%"))
  # Returns an Ecto.Query — caller must call Repo.all themselves
end

# GOOD — fully encapsulated
def search_users(query_string) do
  like = "%#{query_string}%"
  User
  |> where([u], ilike(u.name, ^like))
  |> Repo.all()
end
```

---

## Splitting Large Contexts

When a context grows large, split it by sub-domain:

```elixir
defmodule MyApp.Accounts do
  # Core: create_user, get_user, authenticate
end

defmodule MyApp.Accounts.Sessions do
  # Token lifecycle: create_session_token, verify, revoke
end

defmodule MyApp.Accounts.Notifications do
  # Emails: send_confirmation, send_password_reset
end
```

Or use delegation in the main context:

```elixir
defmodule MyApp.Accounts do
  alias MyApp.Accounts.{UserQueries, SessionTokens}

  def list_users, do: UserQueries.all()
  def create_session_token(user), do: SessionTokens.create(user)
end
```

---

## Key Takeaways

1. **Contexts are boundary modules** — the single entry point for a domain area
2. **Schemas are private** — live inside the context directory, never referenced by the web layer
3. **Public API functions** hide `Repo`, schemas, and query logic from callers
4. **Use `mix phx.gen.context`** to scaffold a context, schema, migration, and tests together
5. **Name contexts after business domains**, not technical layers
6. **Return `{:ok, struct}` or `{:error, changeset}`** from mutating functions
7. When a context grows too large, **split by sub-domain** rather than combining unrelated things
