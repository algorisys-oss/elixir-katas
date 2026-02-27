# Kata 13: Filtering & Sorting

## The Composable Query Pattern

Phoenix APIs often need to filter and sort data based on URL query parameters:

```
GET /api/users?status=active&role=admin&sort=name&order=asc
```

The key insight is that Ecto queries are **composable** — you can pipe a query through multiple functions, each adding a clause. If a parameter is missing, the function returns the query unchanged.

---

## Building Composable Filters

### The Controller

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  def index(conn, params) do
    users =
      User
      |> apply_filters(params)
      |> apply_sorting(params)
      |> Repo.all()

    json(conn, %{data: users})
  end
end
```

### The Filter Functions

Each filter is a separate function with two clauses:
1. One that matches when the param exists (adds a WHERE)
2. One that matches anything else (returns query unchanged)

```elixir
defp apply_filters(query, params) do
  query
  |> filter_by_status(params)
  |> filter_by_role(params)
  |> filter_by_search(params)
end

# Pattern 1: Match when param exists and is valid
defp filter_by_status(query, %{"status" => status})
     when status in ~w(active inactive suspended) do
  where(query, [u], u.status == ^status)
end
# Pattern 2: No param or invalid value — return query unchanged
defp filter_by_status(query, _params), do: query

defp filter_by_role(query, %{"role" => role})
     when role in ~w(admin editor viewer) do
  where(query, [u], u.role == ^role)
end
defp filter_by_role(query, _params), do: query
```

### Why This Pattern Works

```elixir
# All params present:
User
|> filter_by_status(%{"status" => "active"})   # adds WHERE status = 'active'
|> filter_by_role(%{"role" => "admin"})         # adds AND role = 'admin'

# No params:
User
|> filter_by_status(%{})   # returns query unchanged
|> filter_by_role(%{})     # returns query unchanged
# Result: SELECT * FROM users (no filters)
```

---

## Sorting

### Basic Sorting

```elixir
@allowed_sort_fields ~w(name email role status inserted_at)

defp apply_sorting(query, %{"sort" => field, "order" => order})
     when field in @allowed_sort_fields and order in ~w(asc desc) do
  direction = String.to_existing_atom(order)
  field_atom = String.to_existing_atom(field)
  order_by(query, [u], [{^direction, field(u, ^field_atom)}])
end

defp apply_sorting(query, %{"sort" => field})
     when field in @allowed_sort_fields do
  field_atom = String.to_existing_atom(field)
  order_by(query, [u], asc: field(u, ^field_atom))
end

# Default sort when no sort param
defp apply_sorting(query, _params) do
  order_by(query, [u], asc: u.id)
end
```

### Multi-Column Sort

```elixir
# GET /api/users?sort=role,name&order=asc,desc

defp apply_sorting(query, %{"sort" => fields_str, "order" => orders_str}) do
  fields = String.split(fields_str, ",")
  orders = String.split(orders_str, ",")

  sort_spec =
    Enum.zip(fields, orders)
    |> Enum.filter(fn {f, _} -> f in @allowed_sort_fields end)
    |> Enum.map(fn {f, o} ->
      dir = if o == "desc", do: :desc, else: :asc
      {dir, String.to_existing_atom(f)}
    end)

  order_by(query, [u], ^sort_spec)
end
```

---

## Security: Whitelisting

### Why Whitelisting Matters

```elixir
# DANGEROUS: allows any field name from the client
defp filter_by(query, field, value) do
  field_atom = String.to_atom(field)  # Atom table pollution!
  where(query, [u], field(u, ^field_atom) == ^value)
end

# SAFE: only allowed fields pass the guard
defp filter_by_status(query, %{"status" => status})
     when status in ~w(active inactive suspended) do
  where(query, [u], u.status == ^status)
end
```

Key safety rules:
1. **Whitelist field names** with guards (`when field in ~w(...)`)
2. **Whitelist values** when possible (status, role enums)
3. **Use `String.to_existing_atom/1`** instead of `String.to_atom/1` to prevent atom table exhaustion
4. **Use `^` in Ecto queries** to parameterize values (prevents SQL injection)

---

## Search / Text Filtering

```elixir
defp filter_by_search(query, %{"q" => search}) when byte_size(search) > 0 do
  term = "%#{search}%"
  where(query, [u], ilike(u.name, ^term) or ilike(u.email, ^term))
end
defp filter_by_search(query, _params), do: query
```

### Full-Text Search with PostgreSQL

```elixir
defp filter_by_search(query, %{"q" => search}) when byte_size(search) > 0 do
  where(query, [u],
    fragment(
      "to_tsvector('english', ? || ' ' || ?) @@ plainto_tsquery('english', ?)",
      u.name, u.email, ^search
    )
  )
end
```

---

## Date Range Filtering

```elixir
defp filter_by_date_range(query, %{"from" => from_str, "to" => to_str}) do
  with {:ok, from} <- Date.from_iso8601(from_str),
       {:ok, to} <- Date.from_iso8601(to_str) do
    where(query, [u], fragment("?::date", u.inserted_at) >= ^from
                  and fragment("?::date", u.inserted_at) <= ^to)
  else
    _ -> query  # Invalid dates — ignore the filter
  end
end
defp filter_by_date_range(query, _params), do: query
```

---

## Extracting to a Reusable Module

```elixir
defmodule MyApp.QueryHelpers do
  import Ecto.Query

  @doc "Apply a map of filters to a query"
  def apply_filters(query, params, allowed_filters) do
    Enum.reduce(allowed_filters, query, fn {param_key, field, values}, query ->
      case Map.get(params, param_key) do
        value when value in values ->
          where(query, [r], field(r, ^field) == ^value)
        _ ->
          query
      end
    end)
  end

  @doc "Apply sorting from params"
  def apply_sorting(query, params, allowed_fields, default_field \\ :id) do
    field = Map.get(params, "sort", Atom.to_string(default_field))
    order = Map.get(params, "order", "asc")

    if field in allowed_fields and order in ~w(asc desc) do
      dir = String.to_existing_atom(order)
      field_atom = String.to_existing_atom(field)
      order_by(query, [r], [{^dir, field(r, ^field_atom)}])
    else
      order_by(query, [r], asc: field(r, ^default_field))
    end
  end
end
```

Usage:

```elixir
def index(conn, params) do
  users =
    User
    |> QueryHelpers.apply_filters(params, [
      {"status", :status, ~w(active inactive suspended)},
      {"role", :role, ~w(admin editor viewer)}
    ])
    |> QueryHelpers.apply_sorting(params, ~w(name email role status))
    |> Repo.all()

  json(conn, %{data: users})
end
```

---

## Best Practices

1. **One function per filter** — keeps each filter focused and testable
2. **Always whitelist** field names and enum values with guards
3. **Default to no-op** — if a param is missing, return the query unchanged
4. **Provide a default sort** — always have a consistent default ordering
5. **Use `String.to_existing_atom/1`** — never `String.to_atom/1` with user input
6. **Validate early** — reject invalid params before they reach the query

## Common Pitfalls

- **Atom exhaustion**: Using `String.to_atom/1` with user input can exhaust the atom table (atoms are never garbage collected).
- **No default sort**: Without a consistent default `ORDER BY`, results may come back in unpredictable order, causing pagination issues.
- **SQL injection via fragments**: Always use `^` bindings in Ecto queries. Never interpolate user input into `fragment()` strings.
- **Missing indexes**: Filtering and sorting on unindexed columns gets slow on large tables. Add database indexes for commonly filtered/sorted fields.
