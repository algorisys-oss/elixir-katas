# Kata 02: Arithmetic Lab

## The Concept

Elixir provides standard arithmetic operators, but with one key twist: the `/` operator **always** returns a float. For integer division, you use `div/2`.

## Operators

```elixir
10 + 3    # => 13   (addition)
10 - 3    # => 7    (subtraction)
10 * 3    # => 30   (multiplication)
10 / 3    # => 3.3333...  (ALWAYS a float!)
div(10, 3)  # => 3  (integer division)
rem(10, 3)  # => 1  (remainder/modulo)
```

## The Critical Insight: `/` vs `div`

This catches many newcomers:

```elixir
10 / 2      # => 5.0   (float, even though it divides evenly!)
div(10, 2)  # => 5     (integer)
```

The `/` operator in Elixir ALWAYS returns a float. This is different from most languages where `10 / 2` returns an integer `5`.

## Type Arithmetic

Elixir follows these rules:
- `integer + integer = integer`
- `integer + float = float`
- `float + float = float`
- `integer / anything = float` (always!)

```elixir
1 + 2       # => 3       (integer)
1 + 2.0     # => 3.0     (float)
1.0 + 2.0   # => 3.0     (float)
10 / 5      # => 2.0     (float!)
```

## Useful Functions

```elixir
abs(-5)          # => 5
round(3.7)       # => 4
trunc(3.7)       # => 3 (truncate, don't round)
ceil(3.2)        # => 4 (round up) — requires Kernel
floor(3.8)       # => 3 (round down) — requires Kernel
max(5, 10)       # => 10
min(5, 10)       # => 5
```

## Integer Size

Elixir integers have no fixed size limit:

```elixir
# This works fine!
999999999999999999999999999999 * 2
# => 1999999999999999999999999999998
```

No integer overflow, ever.

## Common Pitfalls

1. **`/` always returns float** — Use `div/2` when you need an integer result
2. **`rem` vs `mod`** — Elixir uses `rem/2` (remainder), which follows the sign of the dividend: `rem(-7, 3)` is `-1`
3. **Division by zero** — `10 / 0` and `div(10, 0)` both raise `ArithmeticError`
