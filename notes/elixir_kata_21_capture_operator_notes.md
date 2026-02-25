# Kata 21: The Capture Operator

## The Concept

The capture operator `&` converts named functions into anonymous functions that can be passed as arguments. It has three forms.

## Form 1: &Module.function/arity

Captures a named function from a module:

```elixir
Enum.map(["hello", "world"], &String.upcase/1)
# ["HELLO", "WORLD"]

Enum.map([1, 2, 3], &Integer.to_string/1)
# ["1", "2", "3"]
```

## Form 2: &function/arity

Captures a local or imported function:

```elixir
defmodule MyModule do
  def double(x), do: x * 2

  def run do
    Enum.map([1, 2, 3], &double/1)
    # [2, 4, 6]
  end
end
```

## Form 3: &(expression) — Shorthand

Creates an inline anonymous function using positional parameters `&1`, `&2`, etc.:

```elixir
Enum.map([1, 2, 3], &(&1 * 2))         # [2, 4, 6]
Enum.filter(1..10, &(rem(&1, 2) == 0))  # [2, 4, 6, 8, 10]
Enum.reduce([1, 2, 3], 0, &(&1 + &2))   # 6
```

## Positional Parameters

`&1` is the first argument, `&2` the second, etc. The highest number determines the arity:

```elixir
&(&1 * 2)           # fn x -> x * 2 end          (arity 1)
&(&1 + &2)          # fn x, y -> x + y end        (arity 2)
&(&1 + &2 + &3)     # fn x, y, z -> x + y + z end (arity 3)
```

## Side-by-Side Comparison

| Anonymous Function | Capture |
|-------------------|---------|
| `fn x -> String.upcase(x) end` | `&String.upcase/1` |
| `fn x -> x * 2 end` | `&(&1 * 2)` |
| `fn x -> rem(x, 2) == 0 end` | `&(rem(&1, 2) == 0)` |
| `fn a, b -> a + b end` | `&(&1 + &2)` |

## Common Pitfalls

1. **&(&1) is invalid**: You can't just wrap `&1` — use `Function.identity/1` or `fn x -> x end`.
2. **No control flow**: Can't use `if`/`case`/`cond` inside `&()` — use `fn` instead.
3. **Arity must match**: `&String.split/2` needs 2 args; if you want partial application, use the shorthand form.
4. **Readability**: For complex logic, `fn` is clearer than deeply nested `&()` expressions.
