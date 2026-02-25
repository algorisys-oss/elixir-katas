# Kata 62: Component IDs & Targeting

## Goal
Understand event targeting with `phx-target`.

## Core Concepts

### 1. `phx-target={@myself}`
Sends the event to the component itself.

### 2. `phx-target="#some-id"`
Sends the event to a specific DOM element (or component with that ID).

## Implementation Details

1.  **Event**: `phx-click="remove_item" phx-target={@myself}`.
2.  **Correction**: If you forget `phx-target`, the event goes to the **Parent LiveView**, causing a crash if not handled there.

## Tips
- Always check `phx-target` when debugging "handle_event not found" errors in components.

## Challenge
Add an action that clears **All Items** at once.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("clear_all", _, socket) do
  {:noreply, assign(socket, items: [])}
end
</code></pre>
</details>
