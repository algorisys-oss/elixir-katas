# Kata 72: Infinite Scroll

## The Concept
Loading data as the user scrolls. A common pattern that replaces Pagination.

## The Elixir Way
*   **IntersectionObserver**: A JavaScript API (via Hooks) that tells us when a target element (sentinel) enters the viewport.
*   **Streams**: We use streams to append new pages efficiently without re-rendering the top 1000 items.

## Deep Dive

### 1. Client Hooks (`phx-hook`)
Hooks connect Elixir Lifecycle to JavaScript logic.
```javascript
Hooks.InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) {
        this.pushEvent("load-more", {})
      }
    })
    this.observer.observe(this.el)
  }
}
```

### 2. The Sentinel
We place a `div` at the bottom of the list. When the user scrolls down and sees this div, the JS Hook fires.
The server responds by appending more items to the stream and moving the sentinel down.

### 3. Memory Management
Infinite scroll can still crash the browser if you load 10,000 items.
Advanced technique: **Virtual Scrolling** (Kata 139) removes items from the DOM that scrolled off-screen.

## Common Pitfalls

1.  **Duplicate Loading**: If the user scrolls fast or network is slow, the observer might fire multiple times.
    *   **Fix**: Track `loading` state on the server and ignore "load-more" events while already loading.
2.  **Layout Shift**: Ensure the Sentinel has a defined height/spinner so it doesn't flicker in and out of view instantly.
