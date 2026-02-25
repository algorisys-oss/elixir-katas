# Kata 17: The Remover

## The Concept
Removing items from a collection highlights the importance of **Identity**. You can't just delete "the 3rd item" safely in a concurrent system; you need to delete "Item ID 42".

## The Elixir Way
*   **Immutable Deletion**: `Enum.reject/2`. We don't splice the array. We return a new list containing everything *except* the target.
*   **Pattern Matching**: We extract the ID directly from the event payload.

## Deep Dive

### 1. `phx-value-*`
Standard HTML buttons don't hold data. LiveView allows you to attach metadata to any event.
```html
<button phx-click="delete" phx-value-id={item.id}>Delete</button>
```
The server receives: `params = %{"id" => "123"}`.
**Note**: All values are **Strings**. Even if `item.id` was the integer `1`, the payload will be `"1"`.

### 2. Optimistic UI
When you verify deletion on the server, you remove it from assigns. LiveView re-renders the list.
Because of **DOM Diffing**, LiveView knows exactly which `<li>` to remove from the DOM without repainting the whole list.

## Common Pitfalls

1.  **String vs Integer IDs**: A classic bug.
    ```elixir
    # Bug!
    def handle_event("delete", %{"id" => id}, socket) do
      # id represents "1" (string), but item.id is 1 (integer)
      items = Enum.reject(items, & &1.id == id) # Fails to match
    end
    ```
    **Fix**: Always `String.to_integer(id)` if your data uses integers.
2.  **Race Conditions**: If two admins delete the same item at the same time, the second one might crash if your logic assumes existence. `Enum.reject` is safe (it just does nothing if ID not found).
