# Kata 76: The Clock (Timers)

## The Concept
**Periodic Updates**. The server pushes an update to the client every second.
This demonstrates the "Active Server" capability of LiveView—the page is not static.

## The Elixir Way
*   `:timer.send_interval(1000, self(), :tick)`
    *   This built-in Erlang function sends a message to the current process every N milliseconds.
    *   **Cleanup**: When the LiveView process dies (user leaves), the timer is automatically cancelled. No manual `clearInterval` needed.

## Deep Dive

### 1. `connected?(socket)` Check
We wrap the timer start in `if connected?(socket)`.
*   **Mount 1 (Static)**: Comparison fails. No timer starts.
*   **Mount 2 (Live)**: Comparison succeeds. Timer starts.
If we started it on the static mount, nothing bad would happen (the process dies immediately anyway), but it's good practice to only start live machinery when connected.

### 2. `handle_info/2`
The `:tick` message arrives here.
```elixir
def handle_info(:tick, socket) do
  {:noreply, assign(socket, time: DateTime.utc_now())}
end
```
This triggers a re-render. LiveView diffing ensures only the text "12:00:01" is sent, not the whole clock HTML.

## Common Pitfalls

1.  **Overloading the Client**: Sending updates every 10ms (100fps) will flood the WebSocket and freeze the browser. Keep intervals reasonable (> 50ms). For smooth animations, use CSS or client-side requestAnimationFrame (Hooks).
2.  **Timezones**: `DateTime.utc_now()` is UTC. For user-local time, you either need a library (Tzdata) or use a JavaScript hook to send the browser's timezone offset to the server.
