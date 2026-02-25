# Kata 54: The Modal Dialog

## The Concept
A crucial UI pattern for interruptions. It covers the entire screen, focuses attention, and traps interaction.

## The Elixir Way
*   **JS Commands**: We prefer `Phoenix.LiveView.JS` for opening/closing modals. Pure CSS/JS toggle is faster than a server roundtrip.
*   **Server State (Optional)**: Only track `show_modal` on the server if the modal *content* needs to be loaded on demand (e.g., fetching details).

## Deep Dive

### 1. The Backdrop Trap
The backdrop covers the screen.
```html
<div phx-click={hide_modal()}>
  <div class="modal-content" phx-click-away={hide_modal()}>
    ...
  </div>
</div>
```
Closing on backdrop click is standard. `phx-key="Escape"` is also expected.

### 2. `phx-remove` Animations
When an element is removed from the DOM (modal closes), it usually vanishes instantly.
To animate the exit (fade out):
```elixir
<div phx-remove={JS.transition("fade-out", time: 200)}>
```
This instructs LiveView to *wait* 200ms (running the animation) before actually killing the DOM node.

### 3. Focus Management
Accessibility is hard here. When a modal opens, focus should move *into* the modal. When it closes, it should return to the button that opened it.
`LiveView.JS.focus()` and `focus_first()` helpers assist with this.

## Common Pitfalls

1.  **Z-Index Wars**: Ensure your modal z-index is higher than your navbar or toaster notifications.
2.  **Scroll Locking**: When a modal is open, the `<body>` should have `overflow: hidden` to prevent the background page from scrolling. You can toggle this class using `JS.add_class("overflow-hidden", to: "body")`.
