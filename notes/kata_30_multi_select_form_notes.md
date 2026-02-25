# Kata 30: The Multi-Select

## The Concept
Selecting zero, one, or n items. This introduces **Collection Handling** in forms.

## The Elixir Way
The server expects a **List** of values, not a single value.
To achieve this, the HTML input name must end in `[]`.

## Deep Dive

### 1. The `[]` Naming Convention
```html
<select name="interests[]" multiple>
```
*   **Standard Name**: `name="interest"` -> sends the *last* selected value only.
*   **Array Name**: `name="interests[]"` -> tells the form serializer (and Phoenix) to accumulate all selected values into a list.
Payload: `%{"interests" => ["music", "coding"]}`.

### 2. Handling Lists in `to_form`
When your data is a list (`["a", "b"]`), `to_form` ensures that `form[:interests].value` returns that list correctly so helpers like `options_for_select` can verify membership for multiple items.

### 3. UX Challenges
The native `<select multiple>` is historically difficult to use (requires holding Ctrl/Cmd).
In modern Elixir apps, we often replace this with:
*   **Checkbox Groups**: List of checkboxes with `name="interests[]"`.
*   **Tag Inputs**: Custom JS components (see Kata 38).
However, understanding the underlying array-param mechanic is essential for all of them.

## Common Pitfalls

1.  **Empty List**: If nothing is selected, the browser might send... nothing. `params["interests"]` might be `nil` instead of `[]`.
    *   *Fix*: Provide a default in your handle_event: `params["interests"] || []`.
2.  **Casting**: `Ecto.Changeset.cast` handles lists if the schema field is `{:array, :string}`. Manual casting requires `Enum.map`.
