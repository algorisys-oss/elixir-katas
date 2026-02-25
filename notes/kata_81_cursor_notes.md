# Kata 81: Live Cursors

## The Concept
Showing other users' mouse positions.
This is the ultimate stress test for latency and throughput.

## The Elixir Way
*   **Client**: Hook sends `mousemove` (throttled).
*   **Server**: Broadcasts pos to Topic.
*   **Subscribers**: Update `socket.assigns.cursors`.

## Deep Dive

### 1. Throttling is Critical
Mouse events fire every pixel. Sending 1000 events/sec will kill the server.
**Client Hook**:
```javascript
this.el.addEventListener("mousemove", throttle(e => {
  this.pushEvent("move", {x: e.pageX, y: e.pageY})
}, 50)) // 20 updates per second max
```

### 2. SVG Overlay
Rendering cursors using absolute `div`s or `svg` elements. `pointer-events-none` is essential so the cursors don't block clicks on the underlying content.

### 3. Latency Compensation
Even with 10ms latency, cursors look jerky.
**CSS Transition**:
```css
.cursor { transition: top 0.1s linear, left 0.1s linear; }
```
This interpolates the movement between updates, making it look 60fps smooth.

## Common Pitfalls

1.  **Broadcasting to Self**: You typically don't need to see your own "network cursor". Filter it out in `handle_info` or use `broadcast_from`.
2.  **Bandwidth**: Each packet is small, but `(NumUsers * NumUsers * UpdateRate)` grows quadratically. For > 50 users, consider filtering broadcasts (only to nearby users) or getting a bigger server!
