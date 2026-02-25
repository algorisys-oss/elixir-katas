# Kata 33: Regex Formats

## Goal
Use Regular Expressions (Regex) to enforce specific formats for inputs like Email addresses and Phone numbers.

## Core Concepts

### 1. `String.match?/2`
Elixir's built-in function to check a string against a regex pattern (sigil `~r/.../`).

```elixir
email_regex = ~r/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/
String.match?(input, email_regex)
```

### 2. Conditional Classes
It is helpful to change the border color of the input to Red if it is invalid, providing immediate visual feedback.

## Implementation Details

1.  **State**: Form with `email` and `phone`.
2.  **Events**:
    *   `handle_event("validate", ...)`: Run regex checks.
    *   Accumulate errors list: `[{:field, {"Message", []}}]`.

## Tips
- Regex can be tricky. Use online tools to verify your patterns.
- For complex validation logic, consider moving it to a separate helper module or using `Ecto` (even without a database).

## Challenge
Add a **Zip Code** field that must be exactly **5 digits**.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Regex: ~r/^\d{5}$/

defp validate_zip(zip) do
  if String.match?(zip, ~r/^\d{5}$/), do: [], else: [{:zip, {"Must be 5 digits", []}}]
end
</code></pre>
</details>
