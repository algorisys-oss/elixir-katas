# Kata 84: Accessible Focus

## The Concept
**Focus Management**.
When building accessible apps (WCAG), managing keyboard focus is non-negotiable.
LiveView needs help from the client to move focus after DOM updates.

## The Elixir Way
We use `phx-hook` because modifying `document.activeElement` is purely a client-side side-effect.
*   **Hook**: `FocusElement`.
*   **Event**: `pushEvent("moved_focus", ...)` is usually not needed. We just need to receive commands.

## Deep Dive

### 1. `handleEvent` in Hooks
The server can push a specific event to a hook.
```javascript
// Client
this.handleEvent("focus_element", ({id}) => {
  const el = document.getElementById(id)
  if (el) el.focus()
})
```
```elixir
# Server
push_event(socket, "focus_element", %{id: "btn-1"})
```
This is robust.

### 2. `phx-key="Enter"`
For buttons, simple `phx-click` works with Space/Enter.
For custom widgets (like a custom dropdown), you must handle `phx-window-keydown` or specific key bindings yourself.

## Common Pitfalls

1.  **Focus Loss**: If you replace the element that has focus (update its ID or remove it), focus resets to `<body>`. This destroys accessibility.
    *   **Fix**: Always keep stable DOM IDs. Use `phx-preserve-focus` if needed (though rare).
2.  **Timing**: If you show a modal and try to focus an input inside it *immediately*, it might fail if the transition hasn't finished. Use `requestAnimationFrame` in the hook.
