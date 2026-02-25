# Kata 74: Stream Reset (Filtering)

## Goal
Replace the entire contents of a stream — useful for filtering, searching, or sorting.

## Core Concepts

### 1. `reset: true`
When calling `stream(socket, :items, new_items, reset: true)`, LiveView removes *all* existing items from the DOM container and replaces them with `new_items`.

### 2. Soft Reset
If you want to keep *some* items, reset is not the right tool; you'd have to manage deletions manually. `reset: true` is a "wipe and replace".

## Implementation Details

1.  **State**: `@filter`.
2.  **Action**: On filter change, fetch *all* matching items and stream with `reset: true`.

## Tips
- This is efficient because LiveView still diffs the result; if the new list overlaps with the old list, it might just reorder them (depending on implementation specifics), but logically it represents a full replacement.

## Challenge
Implementation **Sorting**. Add buttons to sort by "Name (A-Z)" or "Name (Z-A)". Re-stream the list in the correct order using `reset: true`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("sort", %{"order" => order}, socket) do
  sorted = Enum.sort_by(..., & &1.name, order)
  {:noreply, stream(socket, :items, sorted, reset: true)}
end
</code></pre>
</details>
