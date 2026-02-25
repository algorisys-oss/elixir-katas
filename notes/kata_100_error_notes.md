# Kata 100: Error Recovery

## The Concept
**Let it Crash**. But don't break the whole app.
If a single LiveComponent crashes, it shouldn't take down the entire Page.

## The Elixir Way
*   **Process Isolation**: LiveViews are isolated. If User A crashes, User B is unaffected.
*   **Supervisors**: If a LiveView crashes, the client automatically attempts to reconnect (`phx-disconnected`).

## Deep Dive

### 1. Error Boundaries in Components
Standard LiveComponents run in the *same* process as the parent. If they crash, the parent crashes.
**Solution**: To isolate a component, it must be a separate LiveView (fetched via `live_render`) or manage its risky operations in a separate `Task`.

### 2. The "Something went wrong" UI
When a crash occurs, the standard behavior is the page hangs or reloads.
You can customize the specific 500/404 pages in `ErrorHTML`.

## Common Pitfalls

1.  **Infinite Loops**: If `mount` raises an error, the client will reload, `mount` will raise again... loop.
    *   **Fix**: Be defensive in `mount`. Handle potential nil values or DB connection errors gracefully.
