# Kata 139: Virtual Scrolling

## The Concept
**Big Data Rendering**.
Rendering 10,000 DOM nodes is slow.
**Virtual Scrolling** only renders the 20 items currently visible in the viewport, plus a small buffer.

## The Elixir Way
This is a complex interplay of Server (Data) and Client (Scroll Position).
*   **Server**: Holds the full list (or filtered list). Slices it `Enum.slice(items, start, len)`.
*   **Client**: Hook `VirtualScroll` reports `scrollTop`.

## Deep Dive

### 1. The Math
1.  **Total Height**: `TotalItems * ItemHeight`. We create a fake `div` of this height to make the scrollbar look correct.
2.  **Offset**: `scrollTop / ItemHeight`. This tells us which index to start rendering.
3.  **Position**: The rendered items are absolutely positioned (or translated) to appear at the correct Y coordinate.

### 2. Debouncing Scroll
Sending an event on every pixel scroll (60fps) is too much for the server.
We usually buffer (Overscan) and only ask for more data when nearing the edge of the buffer.

## Common Pitfalls

1.  **Variable Heights**: Virtual scrolling is easy if every row is 50px. If rows have variable height (text wrapping), the math gets extremely hard. Stick to fixed heights or use JS-based estimators.
2.  **White Space**: If the user scrolls fast, they might see blank space before the server replies with the new slice. (Skeleton placeholders help here).
