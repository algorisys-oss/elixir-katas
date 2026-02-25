# Kata 25: Case Expressions

## The Concept

`case` evaluates a value against a series of patterns. The first pattern that matches executes its body, and the result of that body is returned.

```elixir
case {:ok, 42} do
  {:ok, n} -> "Got: #{n}"
  {:error, reason} -> "Failed: #{reason}"
end
# => "Got: 42"
```

## Basic Syntax

```elixir
case expression do
  pattern1 -> body1
  pattern2 -> body2
  _ -> catch_all_body
end
```

The `_` wildcard matches anything. Without it, a `CaseClauseError` is raised if no pattern matches.

## Pattern Types in Case

Case uses the same pattern matching rules as `=`:

```elixir
# Atoms
case :ok do
  :ok -> "success"
  :error -> "failure"
end

# Tuples
case File.read("file.txt") do
  {:ok, content} -> "Read: #{content}"
  {:error, reason} -> "Error: #{reason}"
end

# Lists
case [1, 2, 3] do
  [] -> "empty"
  [x] -> "just #{x}"
  [h | _] -> "starts with #{h}"
end

# Maps (partial matching)
case %{name: "Alice", role: :admin} do
  %{role: :admin} -> "admin user"
  %{role: :user} -> "regular user"
  _ -> "unknown"
end
```

## Guards in Case

Add `when` clauses for extra conditions beyond structural matching:

```elixir
case value do
  x when is_integer(x) and x > 0 -> "positive integer"
  x when is_integer(x) and x < 0 -> "negative integer"
  0 -> "zero"
  x when is_binary(x) -> "string: #{x}"
  _ -> "something else"
end
```

Guards in `case` follow the same rules as function head guards: only a limited set of expressions is allowed.

## First-Match-Wins

Elixir evaluates clauses top-to-bottom and uses the **first** match:

```elixir
case [1, 2, 3] do
  [1 | _] -> "starts with 1"      # This matches!
  [_ | _] -> "non-empty list"      # Also matches, but never reached
  _ -> "something else"
end
# => "starts with 1"
```

### Ordering Guidelines

1. Put **specific** patterns before **general** ones
2. Put literal matches before variable matches
3. Put guarded clauses before unguarded ones with the same pattern
4. Always end with `_` to prevent `CaseClauseError`

## Case Returns a Value

Like everything in Elixir, `case` is an expression that returns a value:

```elixir
message = case status do
  :ok -> "All good"
  :error -> "Something broke"
  _ -> "Unknown"
end

IO.puts(message)
```

## Variable Binding in Patterns

Variables in patterns bind to matched values:

```elixir
case {:user, "Alice", 30} do
  {:user, name, age} ->
    "#{name} is #{age} years old"
  _ ->
    "not a user"
end
# => "Alice is 30 years old"
```

## Pin Operator in Case

Use `^` to match against an existing variable's value instead of rebinding:

```elixir
expected = :ok

case response do
  ^expected -> "got what we expected"
  other -> "got #{inspect(other)} instead"
end
```

## Nested Case

Case expressions can be nested, but consider using `with` (Kata 28) for cleaner multi-step matching:

```elixir
case outer do
  {:ok, value} ->
    case validate(value) do
      :valid -> "good"
      :invalid -> "bad"
    end
  {:error, _} -> "failed"
end
```

## When to Use Case

| Use `case` when... | Use something else when... |
|---|---|
| Matching on a single value's structure | Multiple independent conditions (`cond`) |
| Pattern matching is needed | Simple true/false check (`if`) |
| Guards refine the match | Chaining multiple operations (`with`) |
| Dispatching on tagged tuples | Multi-clause function definitions |

## Common Pitfalls

1. **Missing catch-all**: Forgetting `_` causes `CaseClauseError` at runtime.
2. **Wrong clause order**: A general pattern shadows specific ones below it.
3. **Unused variables**: Use `_prefix` for variables you don't need to avoid warnings.
4. **Confusing `=` and `==`**: Case uses pattern matching (`=`), not equality checking.
