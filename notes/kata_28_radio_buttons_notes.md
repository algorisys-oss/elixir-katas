# Kata 28: Radio Buttons

## The Concept
**Mutually Exclusive** choices. Unlike checkboxes (N options), Radios enforce exactly "One of N".

## The Elixir Way
State management is simple: the field holds a *single* value.
The DOM requires multiple inputs sharing the same `name` attribute but having distinct `value` attributes. LiveView tracks which one matches the current state.

## Deep Dive

### 1. Grouping by Name
The `name` attribute is the grouping mechanism.
```html
<input name="plan" value="free" />
<input name="plan" value="pro" />
```
The browser ensures only one can be checked. LiveView receives `%{"plan" => "free"}` (single string).

### 2. Derived Checked State
In LiveView, you often derive the `checked` attribute dynamically:
```elixir
checked={@form[:plan].value == "pro"}
```
This implies you don't need a separate "checked" field in your state. The `value` of the form field is the single source of truth.

### 3. Accessibility (Labels)
Radio buttons are notoriously hard to click because they are tiny circles.
**Always** wrap them in a `<label>` or use `id` + `for`.
```html
<label>
  <input type="radio" ...>
  <span class="p-4 border">Clickable Area</span>
</label>
```
LiveView doesn't mandate this, but "The Elixir Way" encourages robust, accessible HTML.

## Common Pitfalls

1.  **Nil State**: If the field value is `nil` (initial state), *none* of the radio buttons will be checked. This is valid UI but might look broken. Always set a default value in `mount`.
2.  **String vs Atom**: As always, form values come back as Strings. If your state uses atoms (`:free`), you need to cast or convert `to_string` before comparing in the template.
