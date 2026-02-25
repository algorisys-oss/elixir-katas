# Kata 38: Tag Input

## Goal
Create a specialized input that allows users to enter multiple items (tags) separate by commas or Enter key.

## Core Concepts

### 1. Custom Key Handling
We need to intercept "Enter" or "," to treat it as an "Add" command instead of a form submit.
This is often done with `phx-keydown` or checking the input value ending in a comma.

### 2. List State
The value is not a string, but a `List` of strings. We render this list as pills/badges.

## Implementation Details

1.  **State**: `tags` (List) and `current_input` (String).
2.  **Events**:
    *   `update_input`: Check if value ends with comma. If so, add tag.
    *   `add_tag`: Triggered on Enter. Add value to list, clear input.
    *   `remove_tag`: Remove item from list.

## Tips
- preventing default form submission on "Enter" can be tricky. Often putting the input *outside* a form or handling the submit event explicitly is required.

## Challenge
Enforce a **Max Tags** limit of 5. Don't allow adding more if the limit is reached.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">defp add_tag(socket, value) do
  if length(socket.assigns.tags) >= 5 do
    {:noreply, put_flash(socket, :error, "Max 5 tags allowed.")}
  else
    # existing logic
  end
end
</code></pre>
</details>
