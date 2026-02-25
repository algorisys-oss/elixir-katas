# Kata 26: The Text Input

## The Concept
Standard HTML `<form>` submission is synchronous. LiveView intercepts this to provide **Real-time Form Handling**.
This kata explores binding data, handling change events, and the "Controlled Input" pattern.

## The Elixir Way
LiveView forms are explicitly bound to server state.
*   **The Struct**: We don't just pass strings to the view. We pass a `Phoenix.HTML.Form` struct.
*   **The Loop**: User types ➔ `handle_event` updates params ➔ socket re-assigns form ➔ Input value updates.

## Deep Dive

### 1. The `to_form/1` Helper
This function is your best friend. It converts a raw Map or an Ecto Changeset into a standardized struct that the `<.form>` component understands.
```elixir
assign(socket, form: to_form(%{"name" => "Alice"}))
```
It handles:
*   Indexing (`form[:name]`).
*   Errors (if using changesets).
*   Values (extracting from params).

### 2. Controlled Inputs
When you write `<input value={@form[:name].value}>`, you are asserting the server's truth onto the browser.
*   **Without `value`**: The input is "uncontrolled". It keeps whatever the user typed, even if the server is unaware.
*   **With `value`**: The input always reflects the server state. This is crucial for validation and masking.

### 3. `phx-change` vs `phx-submit`
*   `phx-change`: Fires on every keystroke (or blur, depending on `phx-debounce`). Used for validation and previews.
*   `phx-submit`: Fires on Enter key or clicking a specific "Submit" button. Used to persist data.

## Common Pitfalls

1.  **Losing Focus**: If you re-render the *entire* form on every keystroke without careful DOM diffing (or if IDs change), the input might lose focus while the user is typing. LiveView handles this well automatically, *provided* you don't continually change the ID of the input.
2.  **Latency Jitter**: For text inputs, updating the value from the server on every keystroke can feel "jumpy" if latency is high. Use `phx-debounce="300"` to smooth this out.
3.  **Atom vs String Keys**: `to_form` with a Map expects **String keys** for data (`%{"name" => "..."}`). If you use Atom keys, `form[:name].value` might return nil unexpectedly.
