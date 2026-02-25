# Kata 42: Path Params

## The Concept
**Resource Identification**. `/users/1` vs `/users?id=1`.
Path parameters identify a specific resource, whereas query parameters typically modify the view of a list.

## The Elixir Way
*   **Router Pattern Matching**: The definition `live "/items/:id", ItemLive` attempts to capture the segment.
*   **Strictness**: If the user visits `/items` (missing ID), this route will **not match**. You need a separate route or a catch-all if you want to handle both.

## Deep Dive

### 1. `handle_params` Pattern Matching
Typical pattern:
```elixir
def handle_params(%{"id" => id}, _uri, socket) do
  item = get_item!(id)
  {:noreply, assign(socket, item: item)}
end

def handle_params(_params, _uri, socket) do
  # Handle index page (no ID)
  {:noreply, socket}
end
```

### 2. Error Handling (404)
What if `get_item!(id)` fails?
*   In standard controllers, we raise `Ecto.NoResultsError` which translates to 404.
*   In LiveView `handle_params`, raising an exception also crashes the process and renders the 404 page. This is acceptable behavior.

### 3. Params in `mount/3`?
Technically, `mount` receives params too. However, `handle_params` is preferred for URL handling because it runs on *every* navigation event, whereas `mount` only runs once per connection.

## Common Pitfalls

1.  **Integer Casting**: `id` is a string "42". `get_item(42)` might work if your DB driver handles casting, but `ids == "42"` in Elixir comparisons will fail if you expect an integer.
2.  **Changing ID without Reloading**: If you go from `/items/1` to `/items/2` via `push_patch`, the LiveView is **not re-mounted**. Only `handle_params` runs. Your setup logic must be in `handle_params` to handle the data switch.
