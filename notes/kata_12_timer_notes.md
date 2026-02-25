# Kata 12: The Timer

## Goal
Create a countdown timer that starts from a fixed duration and stops automatically when it reaches zero.

## Core Concepts

### 1. Countdown Logic
Similar to the stopwatch, but we **decrement** state.
```elixir
update(socket, :seconds, &(&1 - 1))
```

### 2. Termination Condition
We must check if the target has been reached (seconds <= 0) to stop the recursive loop.

```elixir
if socket.assigns.seconds > 0 do
  # Schedule next tick
else
  # Stop running
end
```

## Implementation Details

1.  **State**: `seconds` (e.g., 60), `running` (boolean).
2.  **Display**: Show formatted time or use a purely visual component like DaisyUI's countdown.
3.  **Loop**:
    - In `handle_info(:tick)`, check if `running` AND `seconds > 0`.
    - If true, decrement and reschedule.
    - If false, stop.

## Tips
- DaisyUI's `countdown` component uses a CSS variable `--value` to animate numbers.
  `<span style={"--value:#{@seconds};"}></span>`

## Challenge
Add **Pause** functionality. The timer should stop but retain the current remaining time, allowing `Start` to resume from there.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Currently 'Stop' resets or kills the loop. 
# Just ensure 'Stop' sets running: false without clearing seconds.
# The 'Start' event logic already handles finding the existing seconds.
# (See existing solution for Kata 12 - it might already effectively pause if not reset explicitly).</code></pre>
</details>
