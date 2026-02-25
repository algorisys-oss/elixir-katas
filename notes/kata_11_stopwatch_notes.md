# Kata 11: The Stopwatch

## Goal
Build a working stopwatch that tracks time in minutes, seconds, and deciseconds. This introduces **server-driven intervals** and precise state updates.

## Core Concepts

### 1. The Tick Loop
LiveView runs on the server. To create a loop, we send a message to ourself periodically.
- `Process.send_after(pid, message, time_ms)`

```elixir
# In handle_info
Process.send_after(self(), :tick, 100)
```

### 2. Handling Info
`handle_info/2` is the callback for internal Erlang messages (like our tick), whereas `handle_event/3` is for user interactions (clicks).

### 3. Formatting
Raw data (e.g., total deciseconds) should be stored in the state, but formatted into a human-readable string (MM:SS.d) only at render time.

## Implementation Details

1.  **State**: `time` (integer, starts at 0), `running` (boolean).
2.  **Events**:
    - **Start**: Sets `running: true` and triggers the first tick.
    - **Stop**: Sets `running: false`.
    - **Reset**: Resets `time` to 0.
3.  **Loop**:
    - `handle_info(:tick, socket)`: If running, increments time and schedules the next tick.

## Tips
- Always check if `@running` is true in `handle_info` before scheduling the next tick to ensure you can stop the loop cleanly.

## Challenge
Add a **Lap** feature. Button records the current time into a list of laps without stopping the watch.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># State: laps: []

def handle_event("lap", _, socket) do
  {:noreply, update(socket, :laps, &([socket.assigns.time | &1]))}
end</code></pre>
</details>
