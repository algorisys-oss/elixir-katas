# Kata 66: Sibling Communication

## Goal
Manage communication between two sibling components that do not know about each other.

## Core Concepts

### 1. The Mediator Pattern
The Parent LiveView acts as the source of truth.
- Sibling A sends event to Parent.
- Parent updates state.
- Parent passes new state down to Sibling B via assigns.

## Implementation Details

1.  **Sibling A**: `send(self(), {:data_from_a, ...})`.
2.  **Parent**: `handle_info`, stores data in `@sibling_data`.
3.  **Sibling B**: Renders `@sibling_data` (passed as prop).

## Tips
- Avoid trying to hack direct component-to-component communication. The "Props down, Events up" pattern is scalable; spaghetti wiring is not.

## Challenge
Implement **Two-Way Communication**. Allow Sibling B to send a "Received!" acknowledgment back to Sibling A (via the Parent, of course).

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># 1. Sibling B sends `{:ack, "Got it"}` to Parent.
# 2. Parent assigns `ack_message`.
# 3. Sibling A displays `@ack_message`.
</code></pre>
</details>
