# Kata 69: CRUD

## Goal
Create, Read, Update, Delete. The fundamental operations of most apps.

## Core Concepts

### 1. List Management
State is a List of items.
- **Create**: `[new | items]`
- **Delete**: `List.delete_at(items, index)`
- **Update**: `List.replace_at(items, index, new)`

## Implementation Details

1.  **State**: `items` (List).
2.  **Events**: `create_item`, `delete_item` (currently implemented).

## Tips
- Assign unique IDs to items in real apps to avoid index-based bugs (e.g., deleting the wrong item if the list shifts).

## Challenge
Implement **Update**. Add an "Edit" button next to "Delete".
When clicked, replace the text span with an input field.
Add a "Save" button to commit the change.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># You need tracking state: `editing_index` (default nil).
# Render:
# if @editing_index == idx do
#   <input ... phx-blur="save_edit" />
# else
#   <span>...</span>
# end
</code></pre>
</details>
