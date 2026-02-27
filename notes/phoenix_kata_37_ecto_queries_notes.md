# Kata 37: Queries with Ecto.Query

## What is Ecto.Query?

`Ecto.Query` is a macro-based DSL for building SQL queries in Elixir. Key properties:

- **Composable**: queries are data structures, not strings — build them incrementally
- **SQL injection safe**: Elixir variables pinned with `^` become SQL parameters
- **Lazy**: nothing hits the database until passed to `Repo.all/one/one!` etc.
- **Type-checked**: the compiler catches binding errors

```elixir
import Ecto.Query

query = from u in User,
  where: u.role == "admin",
  order_by: [asc: u.username],
  limit: 10

Repo.all(query)
```

---

## Two Query Syntaxes

### Keyword Syntax

All clauses in one `from` expression:

```elixir
from u in User,
  where: u.verified == true and u.age >= 18,
  order_by: [asc: u.username],
  limit: 20,
  offset: 40,
  select: %{id: u.id, name: u.username}
```

### Pipe Syntax

Build incrementally, compose across functions:

```elixir
User
|> where([u], u.verified == true)
|> where([u], u.age >= ^min_age)
|> order_by([u], asc: u.username)
|> limit(20)
|> Repo.all()
```

The square brackets `[u]` in pipe syntax are the **binding list** — they name the variable for that particular clause.

---

## Variable Pinning (^)

Always use `^` to inject Elixir variables into queries. Without it, Ecto tries to interpret it as a field name.

```elixir
user_id = 42
email = "alice@example.com"

# CORRECT — pinned:
from u in User,
  where: u.id == ^user_id and u.email == ^email

# WRONG — treated as field access, not a variable:
from u in User,
  where: u.id == user_id  # this would fail to compile
```

---

## where

```elixir
# Comparison:
from u in User, where: u.age > 18
from u in User, where: u.age >= 18 and u.verified == true

# IN list:
from u in User, where: u.role in ["admin", "editor"]
from u in User, where: u.id in ^user_ids  # pinned list

# NULL checks:
from u in User, where: is_nil(u.deleted_at)
from u in User, where: not is_nil(u.email)

# String LIKE:
from u in User, where: like(u.username, "%alice%")
from u in User, where: ilike(u.email, "%@example.com")  # case-insensitive

# NOT:
from u in User, where: u.role != "banned"
from u in User, where: not (u.role in ["banned", "suspended"])
```

---

## select

```elixir
# Whole struct (default):
from u in User  # => [%User{...}]

# Single field — returns list of values:
from u in User, select: u.email
# => ["alice@example.com", "bob@example.com"]

# Tuple:
from u in User, select: {u.id, u.email}
# => [{1, "alice@example.com"}, ...]

# Map:
from u in User, select: %{id: u.id, email: u.email}
# => [%{id: 1, email: "alice@example.com"}, ...]

# merge: start with struct, add computed fields
from u in User, select_merge: %{post_count: count(u.id)}
```

---

## order_by

```elixir
from u in User, order_by: [asc: u.username]
from u in User, order_by: [desc: u.inserted_at]
from u in User, order_by: [desc: u.inserted_at, asc: u.id]

# Dynamic direction:
direction = :desc
from u in User, order_by: [{^direction, u.username}]
```

---

## limit / offset (Pagination)

```elixir
page = 2
per_page = 20

from u in User,
  order_by: [asc: u.id],
  limit: ^per_page,
  offset: ^((page - 1) * per_page)
```

---

## group_by / having

```elixir
# Count posts per author:
from p in Post,
  group_by: p.author_id,
  select: {p.author_id, count(p.id)}

# HAVING — filter on aggregates:
from p in Post,
  group_by: p.author_id,
  having: count(p.id) > 5,
  select: {p.author_id, count(p.id)}

# Multiple aggregates:
from o in Order,
  group_by: o.status,
  select: %{
    status: o.status,
    count:  count(o.id),
    total:  sum(o.total_cents),
    avg:    avg(o.total_cents)
  }
```

Aggregate functions: `count/1`, `sum/2`, `avg/2`, `min/2`, `max/2`.

---

## Joins

### Using assoc/2 (follows defined associations)

```elixir
from p in Post,
  join: u in assoc(p, :author),
  where: u.verified == true,
  select: p
```

### Manual Join

```elixir
from p in Post,
  join: u in User, on: u.id == p.author_id,
  where: u.role == "admin",
  select: {p.title, u.username}
```

### Join Types

```elixir
join:          # INNER JOIN
left_join:     # LEFT OUTER JOIN
right_join:    # RIGHT OUTER JOIN
cross_join:    # CROSS JOIN
full_join:     # FULL OUTER JOIN
```

### Preloading with Join (avoid N+1)

```elixir
from p in Post,
  join: u in assoc(p, :author),
  preload: [author: u]
```

This loads posts and their authors in a **single query**, rather than one query per post.

---

## Subqueries

```elixir
latest_posts = from p in Post,
  where: p.status == "published",
  order_by: [desc: p.published_at],
  limit: 5

from p in subquery(latest_posts),
  join: u in User, on: u.id == p.author_id,
  select: %{title: p.title, author: u.username}
```

---

## Dynamic Queries

Build query conditions at runtime without string concatenation:

```elixir
import Ecto.Query

def list_users(filters) do
  conditions = build_conditions(filters)
  from(u in User, where: ^conditions) |> Repo.all()
end

defp build_conditions(filters) do
  Enum.reduce(filters, dynamic(true), fn
    {:role, role}, acc ->
      dynamic([u], ^acc and u.role == ^role)
    {:verified, verified}, acc ->
      dynamic([u], ^acc and u.verified == ^verified)
    {:min_age, age}, acc ->
      dynamic([u], ^acc and u.age >= ^age)
    _other, acc ->
      acc
  end)
end
```

---

## fragment/1 — Raw SQL

Use `fragment/1` when you need database-specific functions not in Ecto's DSL. Parameters are still safely parameterized.

```elixir
# Case-insensitive email match:
from u in User,
  where: fragment("lower(?)", u.email) == ^String.downcase(email)

# PostgreSQL-specific ordering:
from p in Post,
  order_by: fragment("? DESC NULLS LAST", p.published_at)

# JSONB access (Postgres):
from u in User,
  where: fragment("?->>'city' = ?", u.metadata, ^city)

# Array contains (Postgres):
from p in Post,
  where: fragment("? @> ARRAY[?]::text[]", p.tags, ^tag)
```

---

## Named Bindings

Named bindings let you reference joins in later pipe stages:

```elixir
query = from p in Post, as: :post

query = from [post: p] in query,
  join: u in User, as: :author,
    on: u.id == p.author_id

# Add clause using the named binding:
query = from [author: u] in query,
  where: u.verified == true

# Useful for composing queries across function boundaries:
def with_author(query) do
  from [post: p] in query,
    join: u in User, as: :author, on: u.id == p.author_id
end

def active_authors(query) do
  from [author: u] in query,
    where: u.verified == true
end

Post
|> with_author()
|> active_authors()
|> Repo.all()
```

---

## Composable Queries (Context Scopes)

```elixir
defmodule MyApp.Blog do
  import Ecto.Query

  def base_query do
    from p in Post, where: p.deleted_at is nil
  end

  def published(query) do
    from p in query, where: p.status == "published"
  end

  def by_author(query, author_id) do
    from p in query, where: p.author_id == ^author_id
  end

  def recent(query, days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -days * 86400)
    from p in query, where: p.published_at >= ^cutoff
  end

  # Usage:
  def list_published_by_author(author_id) do
    base_query()
    |> published()
    |> by_author(author_id)
    |> recent(30)
    |> Repo.all()
  end
end
```

---

## Key Takeaways

1. Queries are **data** — build them incrementally, compose with pipes
2. Always **pin** Elixir variables with `^` to prevent injection and tell Ecto it's a value
3. Use **keyword syntax** for simple queries, **pipe syntax** for composable/dynamic queries
4. `fragment/1` lets you use raw SQL safely when Ecto's DSL is not enough
5. `dynamic/2` is the right way to build conditional WHERE clauses at runtime
6. Use **named bindings** (`as:`) to reference joins across function boundaries
7. Join with `preload:` to load associations in one query instead of N+1 queries
