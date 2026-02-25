# Kata 18: The Editor

## The Concept
**Inline Editing** (CRUD in place). Instead of navigating to a separate "Edit Page", we swap the static text for an input field on the fly.

## The Elixir Way
We use **Conditional Rendering** inside the loop.
```elixir
<%= if @editing_id == item.id do %>
  <.form ...> <input ...> </.form>
<% else %>
  <span>{item.text}</span>
<% end %>
```
The state `editing_id` determines which row is "hot".

## Deep Dive

### 1. State: `editing_id`
We track a single ID.
*   `nil`: View mode.
*   `"123"`: Row 123 is editable.
This implicitly enforcing that **only one row** can be edited at a time (which simplifies things greatly).

### 2. Focus Management
When the input appears, the user expects to type immediately.
HTML5 `<input autofocus>` works for the *initial* page load, but sometimes fails in dynamic updates.
**Solution**: A simple Client Hook (JS) or strict `autofocus` attribute usage is often needed to ensure the cursor lands in the new input.

### 3. Escape Hatches (`phx-click-away`)
To cancel editing when clicking outside, you can use `phx-click-away`.
```html
<div phx-click-away="cancel">
  <input ... />
</div>
```
This requires a wrapping container to detect the "outside" click.

## Common Pitfalls

1.  **Loss of Focus**: As you type, if the server validates and re-renders the list, the input might be replaced by a *fresh* input element, causing the caret to jump to the start or lose focus.
    *   **Fix**: Maintain a stable DOM ID for the input (`id={"input-#{item.id}"}`) so LiveView can patch it intelligently instead of replacing it.
