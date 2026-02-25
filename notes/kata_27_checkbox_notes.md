# Kata 27: The Checkbox

## The Concept
Handling Boolean values in HTML forms is surprisingly tricky. This kata explains the "Checkbox Quirk" and how Phoenix/LiveView solves it elegantly.

## The Elixir Way
Elixir treats form parameters as strings `("true", "false")`.
Phoenix automatically injects a hidden input for every checkbox to ensure that "unchecked" states are explicitly sent to the server.

## Deep Dive

### 1. The "Hidden Input" Trick
In standard HTML, if a checkbox is *unchecked*, the browser sends... **nothing**. The key is simply missing from the payload.
This is a problem for `Ecto` or Maps waiting for updates—they wouldn't know if the field was missing or just unchecked.
**Phoenix Solution**:
```html
<input name="newsletter" type="hidden" value="false">
<input name="newsletter" type="checkbox" value="true">
```
*   If checked: Browser sends `newsletter=true` (overriding the hidden one).
*   If unchecked: Browser sends `newsletter=false`.
The server receives a consistent value either way.

### 2. Casting Params
Forms send strings.
`%{"newsletter" => "true"}` or `%{"newsletter" => "false"}`.
*   **With Changesets**: `cast(data, params, [:newsletter])` automatically converts `"true"` -> `true`.
*   **Without Changesets**: You must manually convert.
    ```elixir
    truthy? = params["newsletter"] == "true"
    ```

### 3. Normalizing Value
The checked attribute requires a strict boolean.
`checked={@form[:term].value == true}`
Simply passing the string "true" to `checked` might not work as expected in all browsers/helpers. Always normalize your data to booleans in the assign.

## Common Pitfalls

1.  **Multiple Values**: If you have a list of checkboxes with the same name (e.g., `tags[]`), the Hidden Input trick doesn't apply the same way. Unchecking *all* tags results in an empty list or missing key.
2.  **String "false" is Truthy**: In Elixir, `"false"` (the string) is not `nil` or `false`, so it evaluates to `true` in `if` statements. Always check `val == "true"`.
