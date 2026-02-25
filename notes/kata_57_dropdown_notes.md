# Kata 57: The Dropdown

## The Concept
A toggleable menu. Unlike tooltips (hover), dropdowns toggle on **Click** and persist until dismissed.

## The Elixir Way
*   **State**: Track `show_dropdown` (boolean) on the server.
*   **Dismissal**: `phx-click-away` handles the complexity of "clicking anywhere else".

## Deep Dive

### 1. `phx-click-away`
This event fires when a click occurs *outside* the bound element.
```html
<div class="relative" phx-click-away="close_dropdown">
   <button phx-click="toggle">Menu</button>
   <%= if @show_dropdown do %>
     <div class="absolute ...">Items</div>
   <% end %>
</div>
```
**Crucial**: The `phx-click-away` listener must be on the *container* that wraps both the button and the menu.

### 2. Keyboard Accessibility
Users should be able to:
1.  Tab to the button.
2.  Hit Enter to open.
3.  Tab through menu items.
4.  Hit Escape to close.
Use `phx-window-keydown="close_dropdown" phx-key="Escape"` when the menu is open to support step 4.

## Common Pitfalls

1.  **Z-Indexing**: Dropdowns inside "Cards" often get clipped or covered by the next card in grid layouts. `relative` context resets the stack. ensure your dropdown has a high `z-index`.
2.  **JS Transition**: Using `JS.toggle` is more efficient than a server round trip for pure UI toggles, but verifying state (e.g. "is user admin?") requires the server trip.
