# Kata 48: Redirects

## The Concept
Moving the user to a different page. LiveView has specific functions for different types of movement.

## The Elixir Way
*   **push_patch**: Same LiveView, new URL. (Lightweight).
*   **push_navigate**: Different LiveView. (Medium weight).
*   **redirect**: Different Application/External URL. (Full Reload).

## Deep Dive

### 1. `replace: true`
By default, navigation adds a new entry to the browser History (Back button works).
Sometimes (e.g., after a form error correction), you want to **replace** the current entry so the Back button skips the bad state.
`push_patch(..., replace: true)`.

### 2. Flash Messages
Redirects often occur after an action ("Item created!").
We use **Flash** messages (ephemeral notifications) to pass this context to the next page.
```elixir
socket
|> put_flash(:info, "Welcome back!")
|> push_navigate(to: "/dashboard")
```
The new LiveView reads the flash from the connection info on mount.

## Common Pitfalls

1.  **Redirect Loops**: If `mount` redirects to `/login` and `/login` redirects to `/dashboard` which redirects to `/login`... ensure your router guards are correct.
2.  **Dead Views**: `redirect` (external) kills the WebSocket. `push_navigate` keeps the WebSocket usage efficient (if navigating to another LiveView in the same app).
