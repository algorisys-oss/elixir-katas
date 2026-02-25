# Kata 32: Enum Basics

## The Concept

The `Enum` module is the primary tool for working with collections in Elixir. It provides eager (non-lazy) functions that process enumerables immediately and return results. The four foundational Enum functions are `map`, `filter`, `reduce`, and `each`.

## Enum.map/2

Applies a function to every element, returning a new list of the same length:

```elixir
Enum.map([1, 2, 3, 4, 5], fn x -> x * 2 end)
# [2, 4, 6, 8, 10]

Enum.map(["hello", "world"], &String.upcase/1)
# ["HELLO", "WORLD"]
```

Key properties:
- Output list always has the same length as input
- The original collection is unchanged (immutability)
- The function can return any type

## Enum.filter/2

Keeps only elements for which the function returns a truthy value:

```elixir
Enum.filter([1, 2, 3, 4, 5, 6], fn x -> rem(x, 2) == 0 end)
# [2, 4, 6]

Enum.filter(["", "hello", nil, "world"], & &1)
# ["hello", "world"]
```

Related: `Enum.reject/2` is the inverse (keeps elements where function returns falsy).

## Enum.reduce/3

Folds the entire collection into a single value using an accumulator:

```elixir
Enum.reduce([1, 2, 3, 4, 5], 0, fn x, acc -> x + acc end)
# 15

# reduce/2 uses the first element as initial accumulator
Enum.reduce([1, 2, 3, 4, 5], &+/2)
# 15
```

The accumulator can be any type (integer, list, map, tuple).

## Enum.each/2

Iterates over elements for side effects only. Always returns `:ok`:

```elixir
Enum.each(["a", "b", "c"], fn x -> IO.puts(x) end)
# Prints a, b, c
# Returns :ok
```

Use `each` for logging, IO, or sending messages. Use `map` when you need the results.

## The Enumerable Protocol

All Enum functions work with any data type implementing the Enumerable protocol:

```elixir
# Lists
Enum.map([1, 2, 3], &(&1 * 2))           # [2, 4, 6]

# Ranges
Enum.map(1..5, &(&1 * 2))                 # [2, 4, 6, 8, 10]

# Maps (as {key, value} tuples)
Enum.map(%{a: 1, b: 2}, fn {k, v} -> {k, v * 10} end)
# [a: 10, b: 20]

# MapSet
MapSet.new([1, 2, 3]) |> Enum.map(&(&1 * 2))  # [2, 4, 6]
```

## Eager vs Lazy

Enum functions are **eager**: they process the entire collection immediately. For lazy evaluation (processing elements on-demand), use the `Stream` module instead.

```elixir
# Eager: creates intermediate lists
1..1_000_000
|> Enum.map(&(&1 * 2))      # creates full list
|> Enum.filter(&(&1 > 100)) # creates another full list
|> Enum.take(5)              # only needed 5!

# Lazy (better for large collections):
1..1_000_000
|> Stream.map(&(&1 * 2))
|> Stream.filter(&(&1 > 100))
|> Enum.take(5)              # only processes what's needed
```

## Comparison Table

| Function | Purpose | Returns | Element Count |
|----------|---------|---------|---------------|
| `map` | Transform each element | New list | Same as input |
| `filter` | Keep matching elements | New list | Fewer or equal |
| `reduce` | Fold into single value | Any type | Single value |
| `each` | Side effects only | `:ok` | N/A |

## Common Patterns

```elixir
# Pipeline: map -> filter -> reduce
[1, 2, 3, 4, 5]
|> Enum.map(&(&1 * 2))       # [2, 4, 6, 8, 10]
|> Enum.filter(&(&1 > 4))    # [6, 8, 10]
|> Enum.reduce(0, &+/2)      # 24

# Capture operator shorthand
Enum.map(list, &(&1 * 2))    # same as fn x -> x * 2 end
Enum.filter(list, &(&1 > 0)) # same as fn x -> x > 0 end
Enum.reduce(list, 0, &+/2)   # same as fn x, acc -> x + acc end
```

## Common Pitfalls

1. **Using `each` when you need results**: `each` returns `:ok`, not the results. Use `map` for that.
2. **Forgetting immutability**: Enum functions never modify the original collection.
3. **Using `map` for side effects**: While it works, `each` makes intent clearer.
4. **Empty collection edge cases**: `reduce/2` (without initial acc) raises on empty collections; `reduce/3` returns the initial accumulator.
