# Kata 59: Skeleton Loading

## The Concept
**Perceived Performance**. A blank screen feels broken. A spinner feels slow. A Skeleton (gray placeholders) feels like "it's working and almost ready".

## The Elixir Way
*   **Conditionals**: We simply swap the component based on `@loading`.
*   **AsyncResult**: In Phoenix 1.8+, using `<.async_result>` combined with `assign_async` handles this "loading state" swap automatically!

## Deep Dive

### 1. Layout Stability (CLS)
The goal of a Skeleton is to occupy the **exact same space** as the final content.
If your list items are 64px high, your skeleton bars should be 64px high.
This prevents the page from jumping around when data loads (Cumulative Layout Shift).

### 2. `animate-pulse`
Tailwind provides this utility class which changes opacity from 1.0 to 0.5 and back.
It mimics a "breathing" state, indicating activity.

### 3. Usage with `assign_async`
```elixir
<.async_result :let={data} assign={@my_data}>
  <:loading><.skeleton_list /></:loading>
  <:failed>Error!</:failed>
  <.real_list items={data} />
</.async_result>
```
The future of Phoenix loading states relies heavily on this pattern.

## Common Pitfalls

1.  **Over-engineering**: Building a pixel-perfect skeleton replica of a complex card is wasted effort. Abstract representations (a box for an image, lines for text) are sufficient.
2.  **Jank**: If data loads in 50ms, showing a skeleton for 50ms then flashing to content is jarring. Sometimes it's better to show nothing for < 200ms, then the skeleton. (Debounced loading states).
