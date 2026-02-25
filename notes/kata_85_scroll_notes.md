# Kata 85: Scroll to Bottom

## The Concept
**Chat UI Behavior**. When a new message arrives, the view should scroll to reveal it.

## The Elixir Way
*   **The Problem**: LiveView updates the DOM, but doesn't change scroll position.
*   **The Solution**: A Hook `ScrollToBottom`.

## Deep Dive

### 1. `updated()` Callback
The Hook's `updated()` lifecycle method fires *after* LiveView has applied DOM patches.
```javascript
updated() {
  this.el.scrollTop = this.el.scrollHeight;
}
```
This ensures we scroll *after* the new message is inserted.

### 2. Conditional Scrolling
User experience nuance: If the user has scrolled *up* to read history, DO NOT yank them back to the bottom when a new message comes.
Logic:
```javascript
updated() {
  const isAtBottom = this.el.scrollTop + this.el.clientHeight >= this.el.scrollHeight - 50;
  if (isAtBottom) {
    this.el.scrollTop = this.el.scrollHeight;
  }
}
```

## Common Pitfalls

1.  **Smooth Scrolling**: `behavior: "smooth"` is nice but can be buggy if multiple messages arrive fast. Snap scrolling is safer for high-traffic chats.
2.  **Image Loading**: If a message contains an image, its height is 0 initially. When it loads, the scroll height changes. The Hook runs too early!
    *   **Fix**: Use `ResizeObserver` or explicit image dimensions.
