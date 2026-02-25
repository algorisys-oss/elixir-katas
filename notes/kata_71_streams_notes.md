# Kata 71: Streams

## The Concept
**Handling Large Data**.
Rendering a list of 5,000 items using `assign(socket, items: list)` is a disaster. LiveView stores the entire list in the process memory and resends it on change.
**Streams** solve this by managing the list on the **Client (Browser)**, not the Server.

## The Elixir Way
*   `stream(socket, :name, items)`: Tells LiveView "Here are some items to add/update. Forget about them after sending."
*   **Server Base State**: Empty! The server doesn't hold the list.
*   **Client State**: The DOM holds the list.

## Deep Dive

### 1. The `dom_id` Requirement
Every item in a stream must have a unique DOM ID (e.g., "item-42").
LiveView uses this to find the row to update or delete.
By default, it uses `#{name}-#{item.id}`.

### 2. `phx-update="stream"`
This attribute on the container is magic.
It tells the diff engine: "Do NOT replace the children of this container. Only append/prepend/update specific IDs based on the stream instructions."

### 3. Insert and Delete
*   `stream_insert(socket, :items, item)`: Adds or Updates.
*   `stream_delete(socket, :items, item)`: Removes.
*   `stream_delete_by_dom_id(...)`: Removes by string ID.

## Common Pitfalls

1.  **State Reset**: Since the server doesn't know what's in the list, if you crash or refresh, you lose the client state. For persistent lists, you must re-fetch from the DB in `mount`.
2.  **Sorting**: You cannot "re-sort" a stream easily from the server side without resetting it. Streams are append/prepend optimized.
3.  **Missing ID**: If your data doesn't have an `id` field, you must provide a custom function to generate one.
