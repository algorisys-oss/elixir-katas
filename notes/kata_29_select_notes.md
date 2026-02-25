# Kata 29: The Select Dropdown

## The Concept
The `<select>` element provides a compact way to choose one option from a list. LiveView simplifies the tedious task of marking the correct `<option>` as `selected` via helpers.

## The Elixir Way
We avoid writing `if selected ...` logic inside every option tag.
Instead, we use **Phoenix.HTML.Form** helpers to generate the options strings efficiently.

## Deep Dive

### 1. `options_for_select/2`
This is the workhorse helper.
```elixir
options = [Admin: "admin", User: "user"]
selected = "user"
Phoenix.HTML.Form.options_for_select(options, selected)
```
Output:
```html
<option value="admin">Admin</option>
<option value="user" selected>User</option>
```
It handles value comparison (string vs integer) accurately.

### 2. Empty Values
A common pattern in Elixir schemas is that an empty string `""` from a form should be treated as `nil`.
Ecto handles this "scrubbing" automatically.
When building manual forms, you might want a placeholder:
```html
<option value="">Please select...</option>
```
If selected, this sends `params["role"] => ""`.

## Common Pitfalls

1.  **Type Mismatches**: If your option values are Integers (`1`) but your form value is a String (`"1"`), `options_for_select` will NOT mark it selected.
    *   *Fix*: Ensure both sides are the same type (usually strings in forms).
2.  **UX**: Dropdowns hide options. For small lists (< 5 items), Radio Buttons are better UX. For large lists, consider a Typeahead/Searchable Select (which we build in later Katas with JS hooks).
