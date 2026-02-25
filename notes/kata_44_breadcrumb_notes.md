# Kata 44: URL Parameters (Deep Linking)

## The Concept
**Deep Linking** is the ability to restore the exact state of a UI (tabs selected, filters applied, modal open) purely from the URL. This makes your application sharable and bookmarkable.

## The Elixir Way
In Single Page Apps (SPAs), URL routing is often a client-side library concern.
In LiveView, the **URL is a first-class citizen**. The server parses the URL and invokes specific callbacks (`handle_params`) to give your LiveView a chance to set up state *before* rendering. This ensures the initial HTML payload (standard HTTP) and the WebSocket connection (LiveView) are perfectly synced.

## Deep Dive

### 1. `handle_params/3` Lifecycle
This is a special callback invoked:
1.  After `mount` (initial load).
2.  Whenever the URL changes during a live navigation (`patch`).

It is the perfect place to **decode** URL strings into application state.
```elixir
def handle_params(params, _uri, socket) do
  # URL: ?tab=settings&sort=desc
  {:noreply, assign(socket, active_tab: params["tab"], sort: params["sort"])}
end
```

### 2. LiveComponent Blind Spot
**Crucial Architectural Concept**:
*   `handle_params` is **ONLY called on the parent LiveView**.
*   **LiveComponents DO NOT receive `handle_params`**.

If a component needs to know about the URL (like a Breadcrumb component), the **Parent** must capture the params and pass them down as assigns.
```elixir
# Parent LiveView
<.live_component module={Breadcrumb} params={@params} />
```
The component then reacts via `update/2`, not `handle_params`. *Forgetting this is a major source of bugs.*

### 3. `push_patch` vs `push_navigate`
*   `push_patch`: Updates the URL but **maintains the current LiveView process**. It is fast and preserves ephemeral state (like scrolled position). It triggers `handle_params`.
*   `push_navigate`: Tears down the current LiveView and mounts a new one (even if it's the same module). It is a full reset. Use this only when changing contexts completely.

## Common Pitfalls

1.  **Component "Magic"**: expecting a nested component to magically know the URL "id". It won't. You must pass it down from the top.
2.  **String vs Integers**: URL params are *always strings*. You must explicitly cast them (`String.to_integer/1`) before using them in logic or DB queries. Ecto casting handles this automatically, but manual casting is manual.
3.  **Encoding**: Always use `~p"/path?q=#{val}"` (verified routes) or `URI.encode_query` when building links to handle special characters correctly.
