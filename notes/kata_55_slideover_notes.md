# Kata 55: The Slideover (Drawer)

## The Concept
A panel sliding in from the edge (Right/Left). Commonly used for "context" details or mobile navigation menus.

## The Elixir Way
Very similar to the Modal, but the **Transition** logic is different.
*   **Enter**: `translate-x-full` (offscreen right) ➔ `translate-x-0` (onscreen).
*   **Leave**: The reverse.

## Deep Dive

### 1. CSS Transforms
Moving elements with `transform: translateX(...)` is GPU-accelerated and smooth.
Avoid animating `left` or `margin` properties, which trigger CPU layout repaints (slow).

### 2. LiveView JS Transitions
```elixir
JS.transition(
  {"ease-out duration-300", "translate-x-full", "translate-x-0"},
  to: "#drawer"
)
```
LiveView handles applying the classes for the start, active, and end states of the animation.

### 3. Mobile Considerations
On mobile, a slideover usually takes 100% width. On desktop, fixed width (e.g. `w-96`).
Tailwind: `w-full md:w-96`.

## Common Pitfalls

1.  **Click-Outside**: If you use a backdrop, ensure it doesn't block the slideover itself. The slideover should sit *on top* of the backdrop in the Z-stack.
2.  **State Sync**: If you close the drawer via JS (clicking X), but the server thinks it's open, the next patch might re-open it.
    *   **Fix**: Use `JS.push("close")` alongside the visual hide, so the server state stays in sync.
