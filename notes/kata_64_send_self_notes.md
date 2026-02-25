# Kata 64: Self-referential Messages

## Goal
Demonstrate how a component can send messages to its own process (the LiveView process) to schedule future work.

## Core Concepts

### 1. `self()`
The PID of the LiveView process.

### 2. `Process.send_after(pid, msg, time)`
Schedules a message.
**Important**: In a LiveComponent, `handle_info` is NOT called on the component. It is called on the **Parent LiveView**.
*However*, if the component is the *only* thing, you might be confused.
**Correction**: LiveComponents *cannot* handle `handle_info`. The Parent must handle it and call `send_update` to the child.

## Implementation Details

1.  **The Demo**: Actually uses `phx-click="self_click"`. This is just an event.
2.  **True Self-Messaging**: Requires Parent cooperation.

## Tips
- If you need `handle_info` in a component, you are likely better off using a separate LiveView or having the parent manage the timer.

## Challenge
Implement a **Timer**. (Note: This requires modifying the Parent or understanding that `handle_info` goes to parent. Since we are in an isolated kata environment where we define the component, adding `handle_info` to the component *module* won't work unless the parent delegates or we use `send_update`).
**Simpler Challenge**: Add a "Double Click" button that increments by 2.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("double_click", _, socket) do
  {:noreply, update(socket, :clicks, &(&1 + 2))}
end
</code></pre>
</details>
