# Kata 14: Pagination

## Why Paginate?

Returning all records from a database query is impractical for large datasets:
- **Memory**: Loading 100,000 rows into memory can crash your server
- **Network**: Sending megabytes of JSON slows down clients
- **UX**: Users rarely need all data at once

Pagination splits results into smaller, manageable pages.

---

## Offset-Based Pagination

The simpler, more traditional approach.

### Request

```
GET /api/products?page=2&per_page=10
```

### Controller

```elixir
defmodule MyAppWeb.Api.ProductController do
  use MyAppWeb, :controller

  @default_page 1
  @default_per_page 10
  @max_per_page 100

  def index(conn, params) do
    page = parse_positive_int(params["page"], @default_page)
    per_page = parse_positive_int(params["per_page"], @default_per_page)
    per_page = min(per_page, @max_per_page)  # Cap to prevent abuse

    offset = (page - 1) * per_page

    products =
      Product
      |> order_by(asc: :id)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    total = Repo.aggregate(Product, :count)
    total_pages = ceil(total / per_page)

    json(conn, %{
      data: products,
      meta: %{
        page: page,
        per_page: per_page,
        total: total,
        total_pages: total_pages
      }
    })
  end
end
```

### How It Works

```sql
-- Page 1: skip 0, take 10
SELECT * FROM products ORDER BY id LIMIT 10 OFFSET 0;

-- Page 2: skip 10, take 10
SELECT * FROM products ORDER BY id LIMIT 10 OFFSET 10;

-- Page 5: skip 40, take 10
SELECT * FROM products ORDER BY id LIMIT 10 OFFSET 40;
```

### Pros

- Simple to implement and understand
- Can jump to any page directly
- Total count enables page number navigation
- Well-supported by frontend pagination libraries

### Cons

- **Consistency issues**: If rows are inserted/deleted between requests, items can be skipped or duplicated
- **Performance degrades**: `OFFSET 10000` means the database must scan and discard 10,000 rows
- **COUNT is expensive**: `Repo.aggregate(:count)` requires a full table scan on large tables

---

## Cursor-Based Pagination

Uses an opaque cursor (typically an encoded ID or timestamp) to mark the position.

### Request

```
GET /api/products?limit=10
GET /api/products?after=eyIxMCI=&limit=10
```

### Controller

```elixir
defmodule MyAppWeb.Api.ProductController do
  use MyAppWeb, :controller

  @default_limit 10
  @max_limit 100

  def index(conn, params) do
    limit = parse_positive_int(params["limit"], @default_limit)
    limit = min(limit, @max_limit)

    # Build query
    query =
      Product
      |> order_by(asc: :id)
      |> limit(^(limit + 1))  # Fetch one extra to check has_next

    # Apply cursor if present
    query =
      case decode_cursor(params["after"]) do
        {:ok, id} -> where(query, [p], p.id > ^id)
        :error -> query
      end

    results = Repo.all(query)
    has_next = length(results) > limit
    products = Enum.take(results, limit)

    last_cursor =
      case List.last(products) do
        nil -> nil
        product -> encode_cursor(product.id)
      end

    json(conn, %{
      data: products,
      meta: %{
        limit: limit,
        has_next: has_next,
        next_cursor: if(has_next, do: last_cursor)
      }
    })
  end

  defp encode_cursor(id), do: Base.url_encode64(to_string(id))

  defp decode_cursor(nil), do: :error
  defp decode_cursor(cursor) do
    case Base.url_decode64(cursor) do
      {:ok, val} ->
        case Integer.parse(val) do
          {id, ""} -> {:ok, id}
          _ -> :error
        end
      :error -> :error
    end
  end
end
```

### The "Limit + 1" Trick

To determine if there's a next page, fetch one extra record:

```elixir
# Request limit=10
# Fetch 11 rows
query = Product |> limit(11)

results = Repo.all(query)

if length(results) > 10 do
  # There are more pages
  products = Enum.take(results, 10)  # Return only 10
  has_next = true
else
  products = results
  has_next = false
end
```

This avoids a separate COUNT query.

### How It Works

```sql
-- First page
SELECT * FROM products ORDER BY id LIMIT 11;

-- After cursor (id > 10)
SELECT * FROM products WHERE id > 10 ORDER BY id LIMIT 11;

-- After cursor (id > 20)
SELECT * FROM products WHERE id > 20 ORDER BY id LIMIT 11;
```

### Pros

- **Consistent**: No skipped or duplicated items, even with concurrent inserts/deletes
- **Fast on large tables**: `WHERE id > X` uses an index (no scanning like OFFSET)
- **No COUNT needed**: The "limit + 1" trick detects next page cheaply

### Cons

- Cannot jump to an arbitrary page number
- No total count (or requires a separate expensive query)
- More complex implementation, especially with multi-column sorting
- Harder for users to share "page 5" links

---

## Cursor Strategies

### Simple ID Cursor

```elixir
# Works when sorting by ID (primary key)
defp encode_cursor(product), do: Base.url_encode64("#{product.id}")
```

### Composite Cursor

For sorting by non-unique fields, encode multiple values:

```elixir
# Sorting by inserted_at, then id (for tiebreaking)
defp encode_cursor(product) do
  data = "#{DateTime.to_iso8601(product.inserted_at)}|#{product.id}"
  Base.url_encode64(data)
end

defp decode_cursor(cursor) do
  with {:ok, decoded} <- Base.url_decode64(cursor),
       [ts_str, id_str] <- String.split(decoded, "|"),
       {:ok, ts, _} <- DateTime.from_iso8601(ts_str),
       {id, ""} <- Integer.parse(id_str) do
    {:ok, ts, id}
  else
    _ -> :error
  end
end

# In the query:
defp apply_cursor(query, {:ok, ts, id}) do
  where(query, [p],
    p.inserted_at > ^ts or
    (p.inserted_at == ^ts and p.id > ^id)
  )
end
```

---

## Response Format Conventions

### Offset-Based Response

```json
{
  "data": [...],
  "meta": {
    "page": 2,
    "per_page": 10,
    "total": 150,
    "total_pages": 15
  },
  "links": {
    "self": "/api/products?page=2&per_page=10",
    "first": "/api/products?page=1&per_page=10",
    "prev": "/api/products?page=1&per_page=10",
    "next": "/api/products?page=3&per_page=10",
    "last": "/api/products?page=15&per_page=10"
  }
}
```

### Cursor-Based Response

```json
{
  "data": [...],
  "meta": {
    "limit": 10,
    "has_next": true,
    "next_cursor": "eyIxMCI="
  },
  "links": {
    "self": "/api/products?limit=10",
    "next": "/api/products?after=eyIxMCI=&limit=10"
  }
}
```

---

## Using a Pagination Library

The [Scrivener](https://github.com/drewolson/scrivener_ecto) library simplifies offset-based pagination:

```elixir
# In your Repo
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app
  use Scrivener
end

# In the controller
def index(conn, params) do
  page =
    Product
    |> order_by(asc: :id)
    |> Repo.paginate(params)

  json(conn, %{
    data: page.entries,
    meta: %{
      page: page.page_number,
      per_page: page.page_size,
      total: page.total_entries,
      total_pages: page.total_pages
    }
  })
end
```

---

## Best Practices

1. **Always set a max per_page/limit** to prevent clients from requesting millions of rows
2. **Always include an ORDER BY** — without it, results are nondeterministic
3. **Use cursor-based for public APIs** — better performance and consistency
4. **Use offset-based for admin UIs** — page jumping is more useful for internal tools
5. **Include pagination links** in responses for discoverability
6. **Use opaque cursors** — Base64-encode IDs so clients treat them as black boxes

## Common Pitfalls

- **No max limit**: Without a cap, a client can request `?per_page=999999` and exhaust your server's memory.
- **Missing ORDER BY**: Databases don't guarantee row order without ORDER BY. Pagination without consistent ordering produces unpredictable results.
- **OFFSET performance**: `OFFSET 100000` is slow because the database scans and discards 100,000 rows. For large tables, prefer cursor-based pagination.
- **Non-unique cursor fields**: If you cursor on `inserted_at` (which can have duplicates), you can skip or repeat rows. Always include a unique tiebreaker (like `id`).
- **Exposing internal IDs**: Using raw IDs as cursors leaks internal details. Base64-encoding makes cursors opaque to clients.
