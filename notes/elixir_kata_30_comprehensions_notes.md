# Kata 30: Comprehensions

## The Concept

Comprehensions (`for`) provide a concise way to iterate over enumerables, optionally filter elements, transform them, and collect the results into a data structure. They combine the functionality of `Enum.map`, `Enum.filter`, and `Enum.into` in a single expression.

```elixir
for x <- 1..10, rem(x, 2) == 0, do: x * x
# [4, 16, 36, 64, 100]
```

## Anatomy of a Comprehension

```elixir
for generator, ..., filter, ..., into: collectable do
  body
end
```

- **Generator**: `pattern <- enumerable` - binds each element
- **Filter**: boolean expression - keeps only matching elements
- **:into**: target collectable (default: list)
- **Body**: transformation applied to each element

## Generators

A generator iterates over an enumerable and binds each element:

```elixir
# List generator
for x <- [1, 2, 3], do: x * 2
# [2, 4, 6]

# Range generator
for n <- 1..5, do: n * n
# [1, 4, 9, 16, 25]

# Binary generator (iterates over bytes)
for <<c <- "hello">>, do: c
# [104, 101, 108, 108, 111]
```

## Multiple Generators (Cartesian Product)

Multiple generators produce every combination of their values:

```elixir
for x <- [1, 2], y <- [:a, :b, :c], do: {x, y}
# [{1, :a}, {1, :b}, {1, :c}, {2, :a}, {2, :b}, {2, :c}]

# Useful for grids, pairs, permutations
for row <- 1..3, col <- 1..3, do: {row, col}
# [{1, 1}, {1, 2}, {1, 3}, {2, 1}, ...]
```

Later generators can reference earlier ones:

```elixir
for x <- 1..3, y <- x..3, do: {x, y}
# [{1, 1}, {1, 2}, {1, 3}, {2, 2}, {2, 3}, {3, 3}]
```

## Filters

Filters are boolean expressions that appear after generators:

```elixir
for x <- 1..20, rem(x, 3) == 0, rem(x, 5) == 0, do: x
# [15]  (FizzBuzz numbers!)

for x <- 1..10, y <- 1..10, x < y, x + y == 10, do: {x, y}
# [{1, 9}, {2, 8}, {3, 7}, {4, 6}]
```

## Pattern Matching in Generators

Non-matching elements are **silently skipped** (no error raised):

```elixir
for {:ok, val} <- [{:ok, 1}, {:error, "bad"}, {:ok, 3}], do: val
# [1, 3]  — :error tuples are silently skipped

for %{name: name, active: true} <- users, do: name
# Only active users' names
```

## The :into Option

By default, comprehensions return a list. Use `:into` for other collectables:

### Into a Map

```elixir
for {k, v} <- [a: 1, b: 2, c: 3], into: %{} do
  {k, v * 10}
end
# %{a: 10, b: 20, c: 30}
```

### Into a MapSet

```elixir
for x <- [1, 2, 2, 3, 3, 3], into: MapSet.new() do
  x
end
# MapSet.new([1, 2, 3])
```

### Into a String

```elixir
for <<c <- "hello">>, into: "" do
  <<c - 32>>
end
# "HELLO"
```

### Into an Existing Map

```elixir
for {k, v} <- [b: 2, c: 3], into: %{a: 1} do
  {k, v}
end
# %{a: 1, b: 2, c: 3}
```

## Comprehension vs Enum

| Use Case | Comprehension | Enum |
|----------|--------------|------|
| Simple map | `for x <- list, do: f(x)` | `Enum.map(list, &f/1)` |
| Filter + map | `for x <- list, pred(x), do: f(x)` | `Enum.filter(...) \|> Enum.map(...)` |
| Cartesian product | `for x <- a, y <- b, do: {x, y}` | `Enum.flat_map(a, fn x -> Enum.map(b, ...) end)` |
| Collect into map | `for ..., into: %{}, do: {k, v}` | `... \|> Map.new()` |
| Complex pipeline | Less readable | `\|>` chains are clearer |

**Rule of thumb**: Use comprehensions for Cartesian products and filter+map+into combos. Use `Enum` pipelines for complex multi-step transformations.

## The :reduce Option (Elixir 1.12+)

Comprehensions can also reduce:

```elixir
for x <- 1..10, reduce: 0 do
  acc -> acc + x
end
# 55
```

This is equivalent to `Enum.reduce(1..10, 0, fn x, acc -> acc + x end)`.

## The :uniq Option (Elixir 1.14+)

Remove duplicates from the result:

```elixir
for x <- [1, 2, 2, 3, 3, 3], uniq: true, do: x
# [1, 2, 3]
```

## Common Pitfalls

1. **Forgetting :into returns a list**: Without `:into`, you always get a list back.
2. **Pattern matching silently drops**: Non-matching generator patterns are skipped, not errored. This can hide bugs.
3. **Performance with multiple generators**: Cartesian products grow multiplicatively. `for x <- 1..1000, y <- 1..1000` generates 1,000,000 elements.
4. **Bitstring generators**: `<<c <- string>>` iterates over bytes, not graphemes. Use `String.graphemes/1` for Unicode-safe iteration.
