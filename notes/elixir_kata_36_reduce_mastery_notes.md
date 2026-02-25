# Kata 36: Reduce Mastery

## The Concept

`Enum.reduce/3` is the most fundamental and powerful Enum function. It processes a collection element by element, threading an accumulator through each step. Every other Enum function (map, filter, sum, max, frequencies, group_by) can be implemented using reduce.

## How Reduce Works

```elixir
Enum.reduce(enumerable, initial_accumulator, fn element, accumulator ->
  new_accumulator
end)
```

The function receives each element and the current accumulator, and must return the new accumulator value.

```elixir
Enum.reduce([1, 2, 3, 4, 5], 0, fn x, acc -> x + acc end)
# Step 1: x=1, acc=0  -> 1
# Step 2: x=2, acc=1  -> 3
# Step 3: x=3, acc=3  -> 6
# Step 4: x=4, acc=6  -> 10
# Step 5: x=5, acc=10 -> 15
# Result: 15
```

## reduce/2 vs reduce/3

```elixir
# reduce/3: explicit initial accumulator
Enum.reduce([1, 2, 3], 0, &+/2)   # 6

# reduce/2: first element becomes the initial accumulator
Enum.reduce([1, 2, 3], &+/2)       # 6
# Equivalent to: Enum.reduce([2, 3], 1, &+/2)
```

**Warning**: `reduce/2` raises `Enum.EmptyError` on empty collections. Always use `reduce/3` if the collection might be empty.

## Implementing Map with Reduce

```elixir
# Enum.map equivalent
my_map = fn list, fun ->
  list
  |> Enum.reduce([], fn x, acc -> [fun.(x) | acc] end)
  |> Enum.reverse()
end

my_map.([1, 2, 3], &(&1 * 2))
# [2, 4, 6]
```

Note: We prepend with `[item | acc]` (O(1)) instead of `acc ++ [item]` (O(n)), then reverse at the end. This is a common Elixir pattern for building lists efficiently.

## Implementing Filter with Reduce

```elixir
my_filter = fn list, predicate ->
  list
  |> Enum.reduce([], fn x, acc ->
    if predicate.(x), do: [x | acc], else: acc
  end)
  |> Enum.reverse()
end

my_filter.([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))
# [2, 4, 6]
```

## Implementing Max with Reduce

```elixir
# Using reduce/2 (first element as initial max)
Enum.reduce([3, 7, 2, 9, 4], fn x, acc ->
  if x > acc, do: x, else: acc
end)
# 9
```

## Accumulator Types

The accumulator can be any Elixir data type:

### Integer Accumulator (sum, count, product)

```elixir
Enum.reduce([1, 2, 3, 4, 5], 0, &+/2)          # sum: 15
Enum.reduce([1, 2, 3], 0, fn _, acc -> acc + 1 end)  # count: 3
Enum.reduce([1, 2, 3, 4], 1, &*/2)              # product: 24
```

### List Accumulator (map, filter, reverse)

```elixir
Enum.reduce([1, 2, 3, 4], [], fn x, acc -> [x | acc] end)
# [4, 3, 2, 1]  (reverse)
```

### Map Accumulator (frequencies, group_by, index)

```elixir
# Frequencies
Enum.reduce(["a", "b", "a", "c", "b", "a"], %{}, fn x, acc ->
  Map.update(acc, x, 1, &(&1 + 1))
end)
# %{"a" => 3, "b" => 2, "c" => 1}

# Index by key
Enum.reduce(users, %{}, fn user, acc ->
  Map.put(acc, user.id, user)
end)
```

### Tuple Accumulator (multiple values at once)

```elixir
# Compute sum and count in a single pass
{sum, count} = Enum.reduce(1..10, {0, 0}, fn x, {sum, count} ->
  {sum + x, count + 1}
end)
average = sum / count
# 5.5
```

### String Accumulator

```elixir
Enum.reduce(["Hello", "World", "Elixir"], "", fn word, acc ->
  if acc == "", do: word, else: acc <> " " <> word
end)
# "Hello World Elixir"
```

## When to Use Reduce

Use reduce when:
1. **No built-in function fits** your specific aggregation logic
2. **Multiple aggregations** needed in a single pass (use tuple accumulator)
3. **Complex transformations** that combine map/filter/aggregate logic
4. **Building custom data structures** from a collection

Prefer specialized functions when they exist:

| Task | Reduce | Better Alternative |
|------|--------|-------------------|
| Sum | `reduce(list, 0, &+/2)` | `Enum.sum(list)` |
| Transform | `reduce(list, [], ...)` | `Enum.map(list, f)` |
| Select | `reduce(list, [], ...)` | `Enum.filter(list, p)` |
| Maximum | `reduce(list, fn ...)` | `Enum.max(list)` |
| Count values | `reduce(list, %{}, ...)` | `Enum.frequencies(list)` |
| Group | `reduce(list, %{}, ...)` | `Enum.group_by(list, f)` |

## Advanced: reduce_while

`Enum.reduce_while/3` allows early termination:

```elixir
Enum.reduce_while(1..100, 0, fn x, acc ->
  if acc + x > 50 do
    {:halt, acc}
  else
    {:cont, acc + x}
  end
end)
# 45 (1+2+3+...+9 = 45, adding 10 would exceed 50)
```

## Common Pitfalls

1. **Appending to lists**: `acc ++ [x]` is O(n) per step, making the overall reduce O(n^2). Use `[x | acc]` and reverse at the end.
2. **reduce/2 on empty collections**: Raises an error. Use reduce/3 with an explicit initial value.
3. **Forgetting to return the accumulator**: The function must always return the new accumulator value.
4. **Overusing reduce**: If a built-in function exists (sum, map, filter), prefer it for readability.
