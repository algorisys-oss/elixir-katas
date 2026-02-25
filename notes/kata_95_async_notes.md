# Kata 95: Async Data (Phoenix 1.8+)

## The Concept
**Non-blocking UIs**.
If a database query takes 2 seconds, we don't want to block the entire page load (TTFB).
We want to render the skeleton immediately, then stream in the data when ready.

## The Elixir Way
**`assign_async`**.
```elixir
socket
|> assign_async(:users, fn -> {:ok, %{users: fetch_users()}} end)
```
This spawns a Task. When the Task completes, it sends a message to the LiveView, which updates the `@users` assign.

## Deep Dive

### 1. `<.async_result>` Component
This handles the state machine (loading -> ok | failed).
```elixir
<.async_result :let={users} assign={@users}>
  <:loading><Spinner /></:loading>
  <:failed>Error!</:failed>
  <table>...</table>
</.async_result>
```

### 2. Fast vs Slow
You can change *multiple* async assigns.
*   `assign_async(:fast_stats, ...)` (Loads in 50ms).
*   `assign_async(:slow_reports, ...)` (Loads in 2s).
The UI updates incrementally.

## Common Pitfalls

1.  **Over-fetching**: Don't wrap *everything* in async. Standard `assign` is faster for cheap data. Only use async for IO-heavy operations.
2.  **Flash of Content**: Ensure your `<:loading>` state matches the height of the final content (Skeleton) to avoid layout shift.
