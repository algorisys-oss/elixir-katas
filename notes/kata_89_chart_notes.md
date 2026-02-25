# Kata 89: Charts (3rd Party Libs)

## The Concept
Integrating heavyweight JS libraries (Chart.js, Maps, D3) that manipulate the DOM themselves.

## The Elixir Way
**`phx-update="ignore"`**.
This is the most important attribute. It tells LiveView: "I will render this `div` once, but after that, I promise never to touch its children. You (the Hook) own this DOM subtree."

## Deep Dive

### 1. Passing Data
We don't render HTML. We pass JSON data attributes.
```html
<canvas phx-hook="Chart" data-points={Jason.encode!(@points)} ...>
```
The Hook reads `dataset.points`, decodes it, and updates the Chart instance.

### 2. `push_event` for Updates
For real-time charts, passing huge JSON strings in attributes is slow.
Better pattern:
```elixir
push_event(socket, "new_point", %{y: 10})
```
The Hook subscribes:
```javascript
this.handleEvent("new_point", pt => this.chart.data.datasets[0].push(pt))
```

## Common Pitfalls

1.  **Memory Leaks**: You **must** destroy the Chart instance in the `destroyed()` callback of the hook. If the element is removed from DOM, the JS object hangs around.
2.  **Resize**: Canvas often struggles with resizing. Ensure the container has relative positioning.
