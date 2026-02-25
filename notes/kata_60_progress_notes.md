# Kata 60: Progress Bar

## The Concept
Visualizing long-running tasks. This Kata simulates a task using a recursive loop on the server.

## The Elixir Way
*   **The Loop**: A GenServer pattern. "Do work -> Report Progress -> Schedule next chunk".
*   **Smoothness**: The server reports progress in discrete steps (10%, 20%). CSS transitions smooth the gap between 10% and 20%.

## Deep Dive

### 1. The Recursive Loop (`send_after`)
```elixir
def handle_info(:tick, socket) do
  new_val = socket.assigns.val + 10
  if new_val < 100, do: Process.send_after(self(), :tick, 500)
  {:noreply, assign(socket, val: new_val)}
end
```
This is how simpler internal jobs work. For real heavy jobs, you would use a separate Task or Oban worker, and use **PubSub** to broadcast progress back to the LiveView.

### 2. CSS Smoothing
Updating the DOM 60 times a second from the server is inefficient.
Instead, update every 500ms (10%, 20%...) and let CSS interpolate:
```css
width: 20%;
transition: width 0.5s linear;
```
The user sees a continuous 60fps animation, but the server only sent 2 messages.

## Common Pitfalls

1.  **Blocking**: Never `Process.sleep` in the `handle_info`. It blocks the LiveView from handling other user events (like "Cancel"). Always return quickly and schedule the next tick.
2.  **Memory Leaks**: If the user navigates away, the LiveView process dies and the timer is cancelled automatically. (One of the great benefits of the Actor model—no need to manually cleanup intervals like in JavaScript).
