# Kata 46: Search URL

## The Concept
**Shareable Search Results**.
Combining `phx-debounce` (client-side delay) with `push_patch` (server-side URL update) creates the "Google-like" experience where typing updates the URL and results live.

## The Elixir Way
1.  **Input**: `<input phx-keyup="search" phx-debounce="300">`.
2.  **Event**: "`search`" handler calls `push_patch(to: ~p"?q=#{query}")`.
3.  **Update**: `handle_params` performs the actual search logic.

## Deep Dive

### 1. Why Round Trip?
Why not just search in the event handler?
If we search in `handle_event`, the URL doesn't update. If the user copies the link, they get an empty page.
By only updating the URL in the event, and searching in `handle_params`, we guarantee that **State == URL**.

### 2. URI Encoding
When putting user input into a URL, special characters (`&`, `?`, space) break things.
*   **Verified Routes (`~p`)**: Automatically encodes interpolation. `~p"/?q=#{query}"` handles spaces correctly (`%20`).
*   **Manual**: If building strings manually, use `URI.encode_query/1`.

### 3. Cleaning the URL
If query is empty, we usually want to remove the param entirely, not show `?q=`.
```elixir
query_params = if query == "", do: %{}, else: %{q: query}
push_patch(to: ~p"/search?#{query_params}")
```

## Common Pitfalls

1.  **Race Conditions**: Fast typing might trigger multiple events. LiveView serializes them, but `handle_params` might run multiple times. Database queries should be optimized.
2.  **Focus Loss**: As with all inputs, if you replace the input DOM element during update, focus is lost. Keep the input distinct from the search results container.
