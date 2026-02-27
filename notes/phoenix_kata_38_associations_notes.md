# Kata 38: Associations

## What are Associations?

Associations define relationships between schemas. Ecto has four association macros:

| Macro | Relationship | FK Location |
|-------|-------------|-------------|
| `belongs_to :user, User` | Child owns the FK | This schema's table |
| `has_one :profile, Profile` | Parent, one child | Child's table |
| `has_many :posts, Post` | Parent, many children | Child's table |
| `many_to_many :tags, Tag, join_through: "post_tags"` | Both sides, join table | Separate join table |

**Key rule**: Associations in Ecto are **not loaded automatically**. They are `%Ecto.Association.NotLoaded{}` until you explicitly preload them.

---

## belongs_to

`belongs_to` is placed on the child schema — the one that holds the foreign key column.

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :body,  :text

    # Adds :author_id field AND :author association:
    belongs_to :author, MyApp.Accounts.User

    timestamps()
  end
end
```

`belongs_to :author, User` adds two things to the struct:
- `author_id` — an integer field (the FK column)
- `author` — the association (loaded with `%Ecto.Association.NotLoaded{}` by default)

### Custom FK name

```elixir
# Default: field name + "_id" (e.g. :author => :author_id)
belongs_to :author, User                         # uses :author_id
belongs_to :author, User, foreign_key: :user_id  # explicit
```

### belongs_to migration

The FK column is in the child table:

```elixir
create table(:posts) do
  add :title,     :string, null: false
  add :author_id, references(:users, on_delete: :delete_all)
  timestamps()
end

create index(:posts, [:author_id])
```

---

## has_one

`has_one` is the inverse of `belongs_to`. The FK lives on the child table, but we define the association on the parent.

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string

    # Profile table has user_id column:
    has_one :profile, MyApp.Accounts.Profile

    timestamps()
  end
end

defmodule MyApp.Accounts.Profile do
  use Ecto.Schema

  schema "profiles" do
    field :bio,    :text
    field :avatar, :string

    belongs_to :user, MyApp.Accounts.User
  end
end
```

---

## has_many

`has_many` declares that a parent record can have multiple children. The FK lives on the child table.

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :email,    :string
    field :username, :string

    # Default FK: :user_id
    has_many :comments, MyApp.Blog.Comment

    # Custom FK:
    has_many :posts, MyApp.Blog.Post,
      foreign_key: :author_id

    timestamps()
  end
end
```

### on_delete Options

Control what happens when the parent is deleted. Set in the **migration** (DB-level) for best reliability:

```elixir
# Migration:
add :user_id, references(:users,
  on_delete: :nothing)      # default — FK error if child exists
add :user_id, references(:users,
  on_delete: :delete_all)   # cascade delete all children
add :user_id, references(:users,
  on_delete: :nilify_all)   # set FK to NULL on children
add :user_id, references(:users,
  on_delete: :restrict)     # prevent parent delete if children exist
```

---

## has_many :through

A shortcut to traverse a chain of associations:

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    has_many :memberships, MyApp.Accounts.Membership
    has_many :groups, through: [:memberships, :group]
  end
end

defmodule MyApp.Accounts.Membership do
  use Ecto.Schema

  schema "memberships" do
    belongs_to :user,  MyApp.Accounts.User
    belongs_to :group, MyApp.Accounts.Group
  end
end

# Usage:
user = Repo.get!(User, 1) |> Repo.preload(:groups)
user.groups  # => [%Group{}, ...]
```

---

## many_to_many

Uses a join table. Ecto manages the join table rows automatically.

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string

    many_to_many :tags, MyApp.Blog.Tag,
      join_through: "post_tags",
      on_replace: :delete  # remove old join rows on update

    timestamps()
  end
end

defmodule MyApp.Blog.Tag do
  use Ecto.Schema

  schema "tags" do
    field :name, :string

    many_to_many :posts, MyApp.Blog.Post,
      join_through: "post_tags"
  end
end
```

### Join Table Migration

```elixir
create table(:post_tags, primary_key: false) do
  add :post_id, references(:posts, on_delete: :delete_all)
  add :tag_id,  references(:tags,  on_delete: :delete_all)
end

create unique_index(:post_tags, [:post_id, :tag_id])
```

### Assigning many_to_many with put_assoc

```elixir
# Fetch the tags to assign:
tags = Repo.all(from t in Tag, where: t.id in ^tag_ids)

# Preload first (required for put_assoc):
post = Repo.get!(Post, id) |> Repo.preload(:tags)

changeset =
  post
  |> Post.changeset(attrs)
  |> Ecto.Changeset.put_assoc(:tags, tags)

Repo.update(changeset)
# Ecto handles the post_tags join table automatically.
```

---

## Rich Join Table

When the join table needs extra fields, define a schema for it:

```elixir
defmodule MyApp.Accounts.UserRole do
  use Ecto.Schema

  schema "user_roles" do
    field :granted_at, :utc_datetime

    belongs_to :user, MyApp.Accounts.User
    belongs_to :role, MyApp.Accounts.Role
  end
end

defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    has_many :user_roles, UserRole
    has_many :roles, through: [:user_roles, :role]
  end
end
```

---

## Preloading

All association access requires preloading first:

```elixir
# After fetching — separate query:
user = Repo.get!(User, 1)
user = Repo.preload(user, :posts)

# Multiple associations at once:
user = Repo.preload(user, [:posts, :profile, :comments])

# Nested (posts AND their comments):
user = Repo.preload(user, posts: :comments)

# Deep nesting:
user = Repo.preload(user, posts: [comments: :author])

# In the initial query (more efficient — one round-trip):
import Ecto.Query

user = Repo.one(
  from u in User,
    where: u.id == ^id,
    preload: [posts: :comments]
)

# Conditional preload (only published posts):
published = from p in Post, where: p.status == "published"
user = Repo.preload(user, posts: published)
```

### Join-based Preload (avoids separate query)

```elixir
# Two queries (posts, then authors separately):
Repo.all(from p in Post, preload: :author)

# One query (JOIN):
Repo.all(
  from p in Post,
    join: u in assoc(p, :author),
    preload: [author: u]
)
```

---

## The N+1 Problem

N+1 occurs when you load a list and then access an unloaded association for each item:

```elixir
# BAD — N+1 queries:
posts = Repo.all(Post)
Enum.each(posts, fn post ->
  IO.puts post.author.name  # raises! author not loaded
end)

# If you magically loaded it each time, it'd be:
# 1 query for posts + 1 query per post = N+1

# GOOD — 2 queries total:
posts = Repo.all(from p in Post, preload: :author)

# BEST — 1 query (join):
posts = Repo.all(
  from p in Post,
    join: u in assoc(p, :author),
    preload: [author: u]
)
```

---

## cast_assoc / cast_embed

For handling nested association data in changesets:

```elixir
# cast_assoc: for has_many data coming from params
def post_changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body])
  |> cast_assoc(:comments, with: &Comment.changeset/2)
end

# Params format:
%{
  "title" => "Hello",
  "comments" => [
    %{"body" => "Great post!"},
    %{"id" => "5", "body" => "Updated comment"}  # update existing
  ]
}
```

```elixir
# cast_embed: for embedded schemas
def user_changeset(user, attrs) do
  user
  |> cast(attrs, [:name])
  |> cast_embed(:address,
       with: &Address.changeset/2,
       required: true)
end
```

---

## Checking if Loaded

```elixir
user = Repo.get!(User, 1)

Ecto.assoc_loaded?(user.posts)   # => false (not preloaded)
user.posts
# => %Ecto.Association.NotLoaded{__field__: :posts, ...}

user = Repo.preload(user, :posts)
Ecto.assoc_loaded?(user.posts)   # => true
user.posts  # => [%Post{}, ...]
```

---

## Key Takeaways

1. `belongs_to` adds the FK column — it belongs on the schema whose table has the FK
2. `has_one` and `has_many` are declared on the parent — the FK lives on the child table
3. `many_to_many` uses a join table — Ecto manages join rows with `put_assoc`
4. **Always preload** before accessing an association — never access `%Ecto.Association.NotLoaded{}`
5. Use **join-based preloads** (`join: u in assoc/2` + `preload: [author: u]`) to avoid N+1 in hot paths
6. `cast_assoc` validates nested association data recursively from params
7. Use `has_many :through` to traverse a chain of associations without extra queries
