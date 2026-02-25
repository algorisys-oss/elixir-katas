# Kata 79: Typing Indicator

## Goal
Show "User is typing..." notifications in real-time.

## Core Concepts

### 1. Debounce Input
Input must have `phx-change` to detect typing.
Use `phx-debounce="500"` (client side) or handle throttling on server.

### 2. Broadcast Events
- `typing_start`: Broadcast when input becomes non-empty.
- `typing_end`: Broadcast when input is cleared or on blur.

## Implementation Details

1.  **State**: `typing_users` (MapSet).
2.  **Logic**: When receiving `typing_start`, add to set. `typing_end`: remove.

## Tips
- Use a server-side timer to auto-clear typing status if no updates are received after a few seconds (zombie typing prevention).

## Challenge
Change the **Timeout**. Currently 3000ms. Reduce it to **1000ms** to make the indicator disappear faster when users stop typing.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">@typing_timeout 1000
</code></pre>
</details>
