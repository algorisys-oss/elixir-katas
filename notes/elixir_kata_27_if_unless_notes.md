# Kata 27: If / Unless

## The Concept

`if` and `unless` are the simplest conditional constructs in Elixir. They test a single condition and branch accordingly. Unlike most languages, they are **macros** defined in the `Kernel` module, not built-in special forms.

```elixir
if true do
  "this runs"
else
  "this doesn't"
end
# => "this runs"
```

## Truthy and Falsy

Elixir has a very simple truthy/falsy model:

- **Falsy**: only `nil` and `false`
- **Truthy**: literally everything else

```elixir
if 0, do: "truthy"          # => "truthy" (0 is truthy!)
if "", do: "truthy"          # => "truthy" (empty string is truthy!)
if [], do: "truthy"          # => "truthy" (empty list is truthy!)
if nil, do: "truthy"         # => nil (nil is falsy)
if false, do: "truthy"       # => nil (false is falsy)
```

This differs from many languages where `0`, `""`, and `[]` are falsy.

## Multi-line Form

```elixir
if condition do
  # truthy branch
  do_something()
else
  # falsy branch
  do_other_thing()
end
```

## One-line Form

Uses keyword list syntax with `do:` and `else:`:

```elixir
if x > 0, do: "positive", else: "non-positive"
```

Note the required commas after the condition and after `do:`.

## if Without else

When there is no else branch, the expression returns `nil` if the condition is falsy:

```elixir
result = if false, do: "hello"
result  # => nil
```

## unless

`unless` is the inverse of `if` — it executes when the condition is falsy:

```elixir
unless logged_in? do
  redirect_to_login()
end
```

**Avoid `unless` with `else`** — it reads confusingly. Use `if` instead:

```elixir
# Bad — confusing double negative
unless valid?, do: "invalid", else: "valid"

# Good — clear and direct
if valid?, do: "valid", else: "invalid"
```

## if Returns a Value

Everything in Elixir is an expression. `if` returns the value of whichever branch executes:

```elixir
status = if user.admin?, do: :admin, else: :user

message = if count > 0 do
  "Found #{count} items"
else
  "No items found"
end
```

## if / unless are Macros

`if` and `unless` are macros defined in `Kernel`, not special language constructs. Under the hood, they compile into `case`:

```elixir
# This:
if x > 0, do: "positive", else: "negative"

# Compiles roughly to:
case x > 0 do
  val when val in [false, nil] -> "negative"
  _ -> "positive"
end
```

This means you could technically implement your own `if` macro.

## When to Use if vs case vs cond

| Situation | Use |
|-----------|-----|
| Simple true/false check | `if` / `unless` |
| Matching on value structure | `case` |
| Multiple boolean conditions | `cond` |
| Chaining ok/error operations | `with` |

### Rule of thumb

Elixir is a pattern-matching language. Reach for `case` and multi-clause functions first. Use `if` only for truly simple boolean checks.

```elixir
# Prefer case for structural dispatch
case Map.fetch(map, :key) do
  {:ok, value} -> use_value(value)
  :error -> handle_missing()
end

# Use if for simple boolean checks
if String.contains?(name, "@"), do: :email, else: :username
```

## Common Pitfalls

1. **Assuming 0 or "" are falsy**: They are truthy in Elixir.
2. **Using unless/else**: Confusing to read. Use `if` with swapped branches.
3. **Deeply nested if/else**: Refactor to `case`, `cond`, or multi-clause functions.
4. **Forgetting if returns nil**: `if false, do: "x"` returns `nil`, not an error.
5. **Using if for pattern matching**: `if` cannot pattern match — use `case` instead.
