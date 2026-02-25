# Kata 65: Child to Parent Communication

## Goal
Pass data from a Child Component up to the Parent LiveView.

## Core Concepts

### 1. `send(self(), {:msg, data})`
The Component runs in the same process as the Parent. So `self()` is the Parent's PID.
The Parent receives this in `handle_info`.

### 2. Notification
Useful for "Form Saved", "Item Deleted" events where the Parent needs to update a list.

## Implementation Details

1.  **Child**: `send(self(), {:updated_message, "Hi"})`.
2.  **Parent**: `def handle_info({:updated_message, msg}, socket) ...`.
    *(Note: In this Kata environment, the `KataHost` handles generic messages or we simulate the effect)*.

## Tips
- Keep the message format consistent (e.g., `{:action, payload}`).

## Challenge
Send a **Structured Map** instead of a string. e.g. `%{text: "Hi", timestamp: DateTime.utc_now()}`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">send(self(), {:msg, %{text: "Hi", time: DateTime.utc_now()}})
# (The receiving logic would need to handle this)
</code></pre>
</details>
