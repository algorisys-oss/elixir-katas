# Kata 08: The Accordion

## Goal
Manage the state for a **collection of items** where only one can be open at a time (mutually exclusive).

## Core Concepts

### 1. Active ID Pattern
Instead of storing a boolean for *every* item (which gets messy), store a single `active_id` in the socket.

- `active_id: "faq-1"` -> Item 1 is open.
- `active_id: nil` -> All items are closed.

### 2. Derived State in Template
In the template, we check if the current item's ID matches the active one.

```elixir
is_open = @active_id == item.id
class={if is_open, do: "h-auto opacity-100", else: "h-0 opacity-0"}
```

### 3. Event Parameters
Use `phx-value-*` to pass data (like an ID) to your event handler.

```html
<button phx-click="toggle" phx-value-id={item.id}>...</button>
```

## Implementation Details

1.  **State**: `active_id` (default `nil`).
2.  **UI**: Render a list of items (e.g., FAQs).
3.  **Logic**:
    - When an item is clicked:
        - If it is already active -> Set `active_id` to `nil` (close it).
        - If it is different -> Set `active_id` to the new ID (open it).

## Tips
- This pattern scales to lists of any size without increasing memory usage for state.
- CSS transitions on `max-height` or `grid-template-rows` are needed to animate height to "auto".

## Challenge
Allow **Multiple Items** to be open at once (instead of just one).

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Change state from `active_id` (string) to `active_ids` (MapSet or List).

def handle_event("toggle", %{"id" => id}, socket) do
  ids = socket.assigns.active_ids
  new_ids = 
    if MapSet.member?(ids, id) do
      MapSet.delete(ids, id)
    else
      MapSet.put(ids, id)
    end
  {:noreply, assign(socket, active_ids: new_ids)}
end</code></pre>
</details>
