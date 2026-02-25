# Kata 38: Streams - Lazy Evaluation

## The Concept

**Streams** are lazy, composable enumerables. While `Enum` functions process collections eagerly (computing everything immediately), Stream functions build up a *recipe* of computations that only execute when you consume them with an `Enum` function.

```elixir
# Eager: processes ALL 1 million, then takes 3
1..1_000_000 |> Enum.map(&(&1 * 2)) |> Enum.take(3)
# => [2, 4, 6]  but computed all 1 million first!

# Lazy: only processes 3 elements total
1..1_000_000 |> Stream.map(&(&1 * 2)) |> Enum.take(3)
# => [2, 4, 6]  only touched 3 elements!
```

## Eager vs Lazy

### Enum (Eager)
- Each step creates a new intermediate list
- Processes ALL elements at each step
- Simple and fast for small collections

### Stream (Lazy)
- No intermediate lists are created
- Elements flow through the entire pipeline one at a time
- Only computes what's needed
- Must be "consumed" by an Enum function to produce results

## How Streams Work

Stream functions return a `%Stream{}` struct, not a computed result:

```elixir
stream = Stream.map(1..5, &(&1 * 2))
# => #Stream<[enum: 1..5, funs: [#Function<...>]]>

# Nothing computed yet! To get results:
Enum.to_list(stream)    # => [2, 4, 6, 8, 10]
```

## Common Stream Functions

| Stream Function | Enum Equivalent | Purpose |
|----------------|----------------|---------|
| `Stream.map/2` | `Enum.map/2` | Transform each element lazily |
| `Stream.filter/2` | `Enum.filter/2` | Filter elements lazily |
| `Stream.take/2` | `Enum.take/2` | Take first N (halts early) |
| `Stream.drop/2` | `Enum.drop/2` | Skip first N lazily |
| `Stream.take_while/2` | `Enum.take_while/2` | Take while predicate true |
| `Stream.flat_map/2` | `Enum.flat_map/2` | Map and flatten lazily |
| `Stream.chunk_every/2` | `Enum.chunk_every/2` | Group into chunks lazily |
| `Stream.uniq/1` | `Enum.uniq/1` | Remove duplicates lazily |

## Memory Efficiency

```elixir
# Enum: creates 3 intermediate lists
1..1_000_000
|> Enum.map(&(&1 * 2))      # List of 1M elements
|> Enum.filter(&(rem(&1, 3) == 0))  # Another list
|> Enum.take(10)             # Final list

# Stream: only final result in memory
1..1_000_000
|> Stream.map(&(&1 * 2))      # Recipe only
|> Stream.filter(&(rem(&1, 3) == 0))  # Recipe only
|> Enum.take(10)               # Processes elements one at a time
```

## Early Termination

Streams can halt processing early, which is especially powerful with large or infinite data:

```elixir
# Only processes 5 elements from the million-element range
1..1_000_000
|> Stream.filter(&(rem(&1, 100) == 0))
|> Enum.take(5)
# => [100, 200, 300, 400, 500]
```

## When to Use Streams vs Enum

### Use Enum when:
- Working with small collections (< 10,000 elements)
- You need the full result anyway
- Simplicity matters more than memory
- Performance is not a concern

### Use Streams when:
- Working with large collections
- You only need a portion of the results (take, first, etc.)
- Working with infinite sequences
- Chaining many transformations (avoids intermediate lists)
- Reading large files line by line

## Composing Streams

Streams compose beautifully - build complex pipelines from simple steps:

```elixir
1..1_000_000
|> Stream.map(&(&1 * 3))
|> Stream.filter(&(rem(&1, 2) == 0))
|> Stream.map(&div(&1, 2))
|> Stream.take(5)
|> Enum.to_list()
# => [3, 6, 9, 12, 15]
```

Each `Stream.*` call adds to the recipe. The final `Enum.to_list()` triggers all computation.

## Common Pitfalls

1. **Forgetting to consume**: `Stream.map(list, &(&1 * 2))` returns a Stream struct, not a list. You must call an Enum function to get results.
2. **Multiple consumption**: Each time you consume a stream, it re-runs from the beginning. Store the result if you need it multiple times.
3. **Not always faster**: For small collections, Enum is often faster due to less overhead.
4. **Debugging**: Streams are harder to inspect mid-pipeline. Use `Enum.to_list/1` temporarily to see intermediate values.
