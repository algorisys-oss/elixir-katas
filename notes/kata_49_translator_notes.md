# Kata 49: Translator (i18n)

## The Concept
**Internationalization (i18n)**. Serving the same UI in multiple human languages.

## The Elixir Way
Phoenix uses **Gettext** as the industry standard.
*   **Extraction**: You write code `gettext("Welcome")`.
*   **Tasks**: `mix gettext.extract` scans code and finds strings.
*   **Translation**: You edit `.po` files to provide "Benvenuto".

## Deep Dive

### 1. LiveView `handle_info`
Switching languages dynamically usually involves:
1.  Updating the user's session/cookie.
2.  Updating the `Gettext` locale for the current process.
3.  Re-rendering the page.

```elixir
Gettext.put_locale(MyAppWeb.Gettext, "fr")
```
Since LiveView is a long-running process, changing the locale affects all future renders for *that process*.

### 2. Implementation in this Kata
We simulate Gettext with a simple Map for educational clarity.
```elixir
@translations %{
  "en" => %{"hello" => "Hello"},
  "es" => %{"hello" => "Hola"}
}
```
In real apps, use proper `.po` files to support pluralization rules ("1 item" vs "2 items"), which Gettext handles mathematically correctly for languages with complex plural rules (like Russian).

## Common Pitfalls

1.  **Interpolation**: Never concatenate strings for translation (`"Hello " <> name`). This prevents translators from moving the variable (some languages say "Alice Hello").
    *   **Bad**: `"Hello " <> name`
    *   **Good**: `gettext("Hello %{name}", name: name)`
