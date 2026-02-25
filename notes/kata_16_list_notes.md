# Kata 16: The List

## The Concept
Rendering a dynamic list of items is the cornerstone of any application. This kata introduces **Collection Rendering**, **Immutability**, and how LiveView tracks changes in a loop.

## The Elixir Way
*   **No Mutating Arrays**: You cannot `items.push("new")`. You must create a *new* list: `[new_item | old_items]`.
*   **Comprehensions**: We use `for` comprehensions (not `.map` loops) to generate HTML.
    ```elixir
    # Efficiently builds a list of IO data
    for item <- @items, do: <li>{item}</li>
    ```

## Deep Dive

### 1. Prepending is Fast (O(1))
Elixir Lists are Linked Lists.
*   **Prepend**: `[new | list]` is constant time. It just points the new head to the old list.
*   **Append**: `list ++ [new]` is linear time O(n). It must traverse the whole list to find the end.
*   **Lesson**: Always prepend if order doesn't matter (or reverse at render time).

### 2. Rendering Large Lists (Streams)
For small lists (like this kata), `assign(socket, items: list)` is fine.
For large lists (1000+ rows) or infinite scroll, sending the whole list on every update is too heavy.
**Production Solution**: Use `stream(socket, :items, list)`. This tells LiveView to manage the DOM on the client side and only send distinct "inserts" or "deletes" over the wire, keeping the server state minimal. (See Kata 71).

## Common Pitfalls

1.  **Duplicate Keys**: When rendering lists, React requires a `key`. LiveView *infers* keys in simple lists but requires `phx-update="stream"` and DOM IDs for complex localized updates.
2.  **Memory Bloat**: Storing 100,000 items in `socket.assigns` will eat server RAM because every process holds a copy. Always paginate or use streams for large datasets.
