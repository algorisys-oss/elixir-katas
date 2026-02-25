# Kata 26: Cond Expressions

## The Concept

`cond` evaluates a series of boolean conditions and executes the body of the first one that evaluates to a truthy value. It is Elixir's equivalent of `else if` chains in other languages.

```elixir
cond do
  score >= 90 -> "A"
  score >= 80 -> "B"
  score >= 70 -> "C"
  true -> "F"
end
```

## Basic Syntax

```elixir
cond do
  condition1 -> body1
  condition2 -> body2
  true -> catch_all_body
end
```

Each condition is any expression that returns a truthy or falsy value. The `true` at the end acts as a catch-all (like `_` in `case`).

## First-True-Wins

Conditions are evaluated top-to-bottom. The first truthy condition wins:

```elixir
x = 15
cond do
  rem(x, 15) == 0 -> "FizzBuzz"   # This matches first!
  rem(x, 3) == 0 -> "Fizz"        # Also true, but never reached
  rem(x, 5) == 0 -> "Buzz"        # Also true, but never reached
  true -> x
end
# => "FizzBuzz"
```

## The true -> Catch-All

Without a catch-all, `cond` raises `CondClauseError` when nothing matches:

```elixir
# DANGEROUS — will crash if x is 0
cond do
  x > 0 -> "positive"
  x < 0 -> "negative"
end

# SAFE — always has a match
cond do
  x > 0 -> "positive"
  x < 0 -> "negative"
  true -> "zero"
end
```

## Case vs Cond

| Feature | `case` | `cond` |
|---------|--------|--------|
| Evaluates | One value against patterns | Multiple boolean conditions |
| Pattern matching | Yes | No |
| Variable binding | Yes (from patterns) | No (conditions are standalone) |
| Guards | Yes (`when` clauses) | Not needed (conditions ARE boolean) |
| Catch-all | `_` | `true` |
| Best for | Structural dispatch | Range checks, multi-variable logic |

### When to use case

```elixir
# Dispatching on structure
case result do
  {:ok, value} -> handle_success(value)
  {:error, reason} -> handle_error(reason)
end
```

### When to use cond

```elixir
# Checking ranges or multiple variables
cond do
  age >= 65 -> :senior
  age >= 18 -> :adult
  age >= 13 -> :teen
  true -> :child
end
```

## FizzBuzz with Cond

The classic FizzBuzz is a natural `cond` use case:

```elixir
def fizzbuzz(n) do
  cond do
    rem(n, 15) == 0 -> "FizzBuzz"
    rem(n, 3) == 0 -> "Fizz"
    rem(n, 5) == 0 -> "Buzz"
    true -> to_string(n)
  end
end

Enum.map(1..15, &fizzbuzz/1)
# => ["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz",
#     "11", "Fizz", "13", "14", "FizzBuzz"]
```

**Order matters**: `rem(n, 15) == 0` must come before `rem(n, 3)` and `rem(n, 5)` because 15 is divisible by both 3 and 5.

## Cond Returns a Value

Like all Elixir expressions, `cond` returns a value:

```elixir
label = cond do
  temperature > 30 -> "hot"
  temperature > 20 -> "warm"
  temperature > 10 -> "cool"
  true -> "cold"
end

IO.puts("It's #{label} outside")
```

## Truthy and Falsy in Cond

In cond conditions, only `nil` and `false` are falsy. Everything else is truthy:

```elixir
cond do
  nil -> "never"          # falsy
  false -> "never"        # falsy
  0 -> "zero is truthy!"  # truthy! (unlike many other languages)
  "" -> "empty string too" # truthy!
  true -> "catch-all"
end
# => "zero is truthy!"
```

## Common Pitfalls

1. **Missing catch-all**: Always end with `true ->` to avoid `CondClauseError`.
2. **Wrong condition order**: More specific conditions must come first.
3. **Using cond for pattern matching**: If you need to match on structure, use `case` instead.
4. **Expecting 0 or "" to be falsy**: In Elixir, only `nil` and `false` are falsy.
