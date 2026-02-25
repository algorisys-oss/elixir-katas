# Kata 19: The Filter

## The Concept
**Real-time Search**. As the user types, the list shrinks. This introduces the concept of **Derived State**: computing the view from the raw data + parameters.

## The Elixir Way
*   **Source of Truth**: `@items` (the full list from DB).
*   **Parameter**: `@query` (what the user typed).
*   **View**: `filter(items, query)`.
We **never** delete items from `@items` during a search. We only hide them. If we deleted them, backspacing the search query wouldn't restore them!

## Deep Dive

### 1. Computed Computations
Where do we run the filter logic?
1.  **In Render**: `<%= for item <- filter(@items, @query) do %>`. Simple, prevents state duplication. Best for small lists.
2.  **In Assigns**: `assign(socket, display_items: filter(...))`. Updates `display_items` whenever `query` changes. Better for complex logic to keep `render` clean.

### 2. Case Insensitivity
Users expect "alice" to match "Alice".
```elixir
String.contains?(String.downcase(name), String.downcase(query))
```
Always normalize both sides of the comparison.

### 3. Debouncing
Filtering 10,000 items on every keystroke freezes the UI.
`phx-debounce="300"`
This tells the client: "Wait until the user stops typing for 300ms before sending the event." The server does work 10x less often.

## Common Pitfalls

1.  **Destructive Filtering**: Modifying the original list `socket.assigns.items`. Once filtered, the original data is lost. Always keep the original list separate or fetch fresh from DB.
2.  **Empty Queries**: `String.contains?("anything", "")` is always true. Ensure your logic handles empty strings gracefully (usually by returning the full list).
