# Kata 56: The Tooltip

## The Concept
Revealing auxiliary information when hovering over an element.
This demonstrates **Pure CSS Interactions** where server roundtrips are unnecessary (and undesirable).

## The Elixir Way
We use **CSS Group Hover** instead of `phx-mouseenter` because:
1.  **Latency**: A tooltip should appear instantly. 50ms latency feels broken.
2.  **Traffic**: Hovering triggers thousands of events. The server doesn't need to know you hovered a help icon.

## Deep Dive

### 1. The `group` and `group-hover` Pattern
Tailwind allows parent-child interaction style.
```html
<div class="relative group">
  <button>Hover Me</button>
  <div class="invisible group-hover:visible absolute ...">
    Tooltip Content
  </div>
</div>
```
The child (`tooltip`) reacts to the state of the parent (`group`).

### 2. Positioning Logic
Absolute positioning requires a `relative` container.
*   `bottom-full`: Pushes the tooltip above the element.
*   `mb-2`: Adds spacing.
*   `left-1/2 -translate-x-1/2`: Centers it horizontally.

### 3. Z-Index
Tooltips battle with other elements (like cards or headers) for visibility.
Adding `z-50` ensures it floats above everything else in that stacking context.

## Common Pitfalls

1.  **Clipping**: If the parent container has `overflow-hidden`, the tooltip will get cut off. You may need to move the tooltip code higher in the DOM (portals) if your layout is strict, but for simple apps, removing `overflow-hidden` is easier.
2.  **Mobile**: There is no "hover" on touch screens. Tooltips are often inaccessible on mobile. Consider showing them on `focus` (tabbing) as well for better accessibility.
