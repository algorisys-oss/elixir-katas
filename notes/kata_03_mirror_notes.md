# Kata 03: The Mirror

## Goal
Create a text input that mirrors its content to another part of the page in real-time. This concept is often called **Unidirectional Data Flow** or "Form Binding".

## Core Concepts

### 1. `phx-change`
Unlike `phx-click` (which triggers on action), `phx-change` triggers whenever a form input's value changes.

```html
<form phx-change="mirror">
  <input type="text" name="user_text" />
</form>
```

### 2. Handling Form Params
The second argument of `handle_event/3` receives the form data as a map.

```elixir
def handle_event("mirror", %{"user_text" => val}, socket) do
  {:noreply, assign(socket, text: val)}
end
```

### 3. Debouncing
For text inputs, sending an event on every keystroke can be expensive. Use `phx-debounce` to limit the rate.

```html
<input phx-debounce="300" ... />
```

## Implementation Details

1.  **State**: Initialize `text` to `""`.
2.  **UI**:
    - A `<form>` with a text input.
    - A display area showing `{@text}`.
3.  **Events**:
    - `handle_event("mirror", ...)`: Updates the `text` assign with the input value.

## Tips
- Always wrap inputs in a `<form>` tag when using `phx-change`.
- If you need to clear the input programmatically, you would need to bind `value={@text}` (Controlled Input).

## Challenge
Modify the `handle_event` so that the mirrored text is always **UPPERCASE**, regardless of how the user typed it.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("mirror", %{"user_text" => val}, socket) do
  {:noreply, assign(socket, text: String.upcase(val))}
end</code></pre>
</details>
