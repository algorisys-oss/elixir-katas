# Kata 41: URL Params (Query String)

## The Concept
**Deep Linking**. The ability to bookmark or share a specific state of the application (e.g., "Page 2, sorted by Date").
In LiveView, we synchronize the server state with the URL query string (`?filter=...`).

## The Elixir Way
*   **Reactive URL**: usage of `push_patch` updates the URL without reloading.
*   **Callback**: `handle_params/3` is the standard callback to parse URL changes.
*   **Lifecycle**: `handle_params` runs *after* `mount`, so you can use it to override default state.

## Deep Dive

### 1. `handle_params/3`
This function is invoked when:
1.  The user first loads the page (HTTP request).
2.  The user clicks a `<.link patch={...}>`.
3.  The user clicks browser Back/Forward (popstate).
It is the **Single Source of Truth** for URL-driven state.

### 2. Params Decoding
Params are always strings.
```elixir
%{"page" => "1", "sort" => "desc"}
```
You must cast them manually (`String.to_integer`) or use Ecto embedded schemas to cast/validate them safely.

### 3. Updates via `push_patch`
To change the URL, we don't allow `window.history.pushState` in client JS.
We tell the server:
```elixir
{:noreply, push_patch(socket, to: ~p"/items?sort=asc")}
```
The server sends a message to the client -> Client updates URL -> Client sends "params changed" message back to Server -> Server calls `handle_params`.

## Common Pitfalls

1.  **Multiple Sources of Truth**: If you update `socket.assigns.sort` in a click handler *AND* in `handle_params`, you have duplicated logic.
    *   **Fix**: Click handler should *only* `push_patch`. `handle_params` should allow the assign update.
2.  **Mount vs Params**: Setting defaults in `mount` and then overwriting in `handle_params` works, but be careful not to trigger double database queries.
3.  **LiveComponent Limitations**: As mentioned before, `handle_params` is **never called** on a LiveComponent. The parent LiveView must pass the params down.
