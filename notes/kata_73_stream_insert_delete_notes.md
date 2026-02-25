# Kata 73: Stream Insert & Delete

## Goal
Manipulate stream items dynamically: Inserting at specific positions (top/bottom) and removing items.

## Core Concepts

### 1. `at: index`
`stream_insert(socket, :name, item, at: 0)` prepends to the list.
`at: -1` (default) appends.

### 2. `stream_delete`
Removes the element from the DOM based on its ID.

## Implementation Details

1.  **Prepend**: Use `at: 0`.
2.  **Delete**: Pass the struct or `%{id: ...}` to `stream_delete`.

## Tips
- Animation libraries (like auto-animate) work great with streams to smooth out these customized insertions.

## Challenge
**Visual Highlight**. When inserting an item, give it a CSS class (e.g., `bg-yellow-100`) that fades out. (This implies inserting the item with a specific "new status" field that renders the class, or using JS transitions).

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Render:
<div class={if item.is_new, do: "animate-flash", else: ""}>...</div>
</code></pre>
</details>
