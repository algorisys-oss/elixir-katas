# Kata 63: Send Update

## Goal
Demonstrate how to update a component from the outside (Parent -> Child) or how a component updates itself via `send_update` (though often internal assignment is easier).

## Core Concepts

### 1. `send_update(ComponentModule, id: "...", key: value)`
The standard way for a Parent to push new data into a stateful child component. This triggers the child's `update/2` callback.

## Implementation Details

1.  **Code**: The demo handles internal updates.
2.  **Concept**: In a real app, a Parent might call `send_update` when some global state changes.

## Tips
- `send_update` is asynchronous.

## Challenge
Add a **Character Count** display that updates as you type in the input.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"><div class="text-xs">Chars: <%= String.length(@message) %></div>
</code></pre>
</details>
