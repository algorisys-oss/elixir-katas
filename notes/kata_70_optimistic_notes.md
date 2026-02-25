# Kata 70: Optimistic UI

## Goal
Make the UI feel instant by updating the state *before* the server confirms the action.

## Core Concepts

### 1. Immediate Feedback
On event trigger, update the UI logic immediately (e.g., set `saved: true`).
Then schedule the actual work.

### 2. Rollback (Error Handling)
If the server work fails, you must revert the UI state and show an error.

## Implementation Details

1.  **Event**: `save_optimistic`.
    *   Set `saving: true` (or "Saved" status).
    *   Schedule process work.
2.  **Process**: Waits 1s (simulating network), then sends confirmation.

## Tips
- Use this for "Like" buttons or "Todo Checkboxes" where 99% of requests succeed.

## Challenge
Add an **"Undo"** feature. After saving, show an "Undo" button for 5 seconds. If clicked, revert the change (even if the server operation finished).

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># 1. On save, show Undo button.
# 2. Schedule clear_undo after 5s.
# 3. If clicked, revert state.
</code></pre>
</details>
