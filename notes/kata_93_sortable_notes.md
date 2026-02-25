# Kata 93: Sortable List

## Goal
Reorder list items via Drag & Drop.

## Core Concepts

### 1. `SortableJS` (or similar lib) in a Hook
The Hook initializes the library on the container.
`onEnd`: Pushes the new index to the server.

### 2. Server Sync
The server must receive `move_item` event and reorder the list in the assigns to match the client. If not synced, the next patch might jump items back.

## Implementation Details

1.  **Event**: `push_event("reorder", %{from: old_idx, to: new_idx})`.
2.  **Logic**: `List.pop_at` + `List.insert_at`.

## Tips
- Avoid `phx-update="stream"` for complex drag-and-drop unless relying entirely on the client library or using specialized stream support, as reordering streams can be tricky.

## Challenge
Add a **Reset Order** button. Restores the list to its initial state `["Item 1", "Item 2", ...]`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("reset", _, socket) do
  {:noreply, assign(socket, items: initial_items)}
end
</code></pre>
</details>
