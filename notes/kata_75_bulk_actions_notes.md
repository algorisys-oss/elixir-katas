# Kata 75: Bulk Actions with Streams

## The Concept
Performing actions on multiple items (Select All, Delete Selected).
This is tricky with Streams because the server **does not know** which items are currently rendered.

## The Elixir Way
*   **Hybrid State**: Use `stream` for the *Data* (`items`) and `assigns` for the *Selection* (`selected_ids` MapSet).
*   **The Render Loop**:
    ```elixir
    for {id, item} <- @streams.items do
       class={if item.id in @selected_ids ...}
    ```
    LiveView is smart enough to patch *only* the class attribute of the rows when `@selected_ids` changes, without sending the item data again.

## Deep Dive

### 1. `MapSet` for Selection
Selection is a Set operation (O(1) lookup).
We store just the IDs: `MapSet<[1, 5, 9]>`.

### 2. "Select All" with Streams
How do we select all if the server doesn't have the list?
1.  **Option A (DB)**: Fetch all IDs from DB. `assign(selected_ids: all_db_ids)`.
2.  **Option B (Current View)**: If the stream is backed by a cached list or if you only want to select *visible* items, it gets harder. Usually, "Select All" implies "All in Database".

### 3. Deleting Selected
When deleting, we iterate over the selected IDs and call `stream_delete` for each.
```elixir
Enum.reduce(ids, socket, fn id, sock -> stream_delete(sock, ...) end)
```

## Common Pitfalls

1.  **Stale Checkboxes**: If you rely on `phx-click` to toggle selection but don't update the `checked` attribute based on server state, the UI will drift out of sync. Always Control your inputs (`checked={...}`).
2.  **Performance**: Updating `selected_ids` for 1,000 items triggers 1,000 DOM diffs (class updates). This is usually fine, but for 10k items, you might need client-side optimisations (JS commands).
