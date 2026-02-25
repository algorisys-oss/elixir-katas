# Kata 23: The Multi-Select

## Goal
Manage a set of selected items (e.g., for tagging or filtering).

## Core Concepts

### 1. MapSet
Use `MapSet` instead of `List` for the selected collection.
- Lookups (`member?`) are O(1).
- Uniqueness is guaranteed automatically.

### 2. Toggling Logic
In the event handler, check membership:
- **If present**: `MapSet.delete/2`
- **If absent**: `MapSet.put/2`

### 3. Conditional Styling
Check membership to apply "active" styles.

```elixir
class={if MapSet.member?(@selected, item), do: "bg-blue-100", else: "bg-white"}
```

## Implementation Details

1.  **State**: `items` (available), `selected` (MapSet).
2.  **UI**:
    - Buttons for each item.
    - Visual indicator of selection.
3.  **Events**:
    - `toggle`: The main interaction.
    - `clear`: `MapSet.new()`.

## Tips
- When rendering the list of selected items for specific display order, remember that MapSets are not ordered. You may need `MapSet.to_list(selected) |> Enum.sort()`.

## Challenge
Enforce a **Limit**. Allow the user to select at most **3 items**. If they try to select a 4th, ignore the action (or show a flash message).

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("toggle", %{"item" => item}, socket) do
  # check size before adding
  selected = socket.assigns.selected
  if MapSet.size(selected) &lt; 3 or MapSet.member?(selected, item) do
     # proceed with toggle logic...
  else
     {:noreply, put_flash(socket, :error, "Max 3 items allowed!")}
  end
end</code></pre>
</details>
