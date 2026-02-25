# Kata 33: Enum Transforms

## The Concept

Beyond map and filter, the Enum module provides powerful transformation functions for reordering, deduplicating, reshaping, and combining collections.

## Enum.sort/1,2

Sorts elements in ascending order by default. Accepts a comparator or `:asc`/`:desc`:

```elixir
Enum.sort([3, 1, 4, 1, 5, 9])
# [1, 1, 3, 4, 5, 9]

Enum.sort([3, 1, 4, 1, 5], :desc)
# [5, 4, 3, 1, 1]

# Custom comparator
Enum.sort([3, 1, 4], fn a, b -> a >= b end)
# [4, 3, 1]
```

## Enum.sort_by/2,3

Sorts by a derived key, which is cleaner for complex sorting:

```elixir
Enum.sort_by(["banana", "fig", "apple"], &String.length/1)
# ["fig", "apple", "banana"]

# Descending by key
Enum.sort_by(["banana", "fig", "apple"], &String.length/1, :desc)
# ["banana", "apple", "fig"]
```

## Enum.reverse/1

Reverses the order of elements:

```elixir
Enum.reverse([1, 2, 3, 4, 5])
# [5, 4, 3, 2, 1]

# Reverse a range
1..5 |> Enum.reverse()
# [5, 4, 3, 2, 1]
```

## Enum.uniq/1 and Enum.uniq_by/2

Removes duplicate elements, keeping first occurrences:

```elixir
Enum.uniq([1, 2, 2, 3, 3, 3, 4])
# [1, 2, 3, 4]

# Unique by derived key
Enum.uniq_by(["apple", "avocado", "banana"], &String.first/1)
# ["apple", "banana"]
```

## Enum.flat_map/2

Maps a function and flattens the result by one level. Essential when your function returns a list:

```elixir
Enum.flat_map([1, 2, 3], fn x -> [x, x * 10] end)
# [1, 10, 2, 20, 3, 30]

# vs regular map (nested lists):
Enum.map([1, 2, 3], fn x -> [x, x * 10] end)
# [[1, 10], [2, 20], [3, 30]]

# Splitting strings
Enum.flat_map(["hello world", "foo bar"], &String.split/1)
# ["hello", "world", "foo", "bar"]
```

## Enum.zip/2

Pairs elements from two enumerables into tuples. Stops at the shorter one:

```elixir
Enum.zip([1, 2, 3], [:a, :b, :c])
# [{1, :a}, {2, :b}, {3, :c}]

# Different lengths: stops at shorter
Enum.zip(1..5, 1..3)
# [{1, 1}, {2, 2}, {3, 3}]

# Unzip reverses it
Enum.unzip([{1, :a}, {2, :b}, {3, :c}])
# {[1, 2, 3], [:a, :b, :c]}
```

## Enum.chunk_every/2,3,4

Splits a collection into chunks of a given size:

```elixir
Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
# [[1, 2], [3, 4], [5, 6]]

# Last chunk may be smaller
Enum.chunk_every([1, 2, 3, 4, 5], 3)
# [[1, 2, 3], [4, 5]]

# With step (sliding window)
Enum.chunk_every([1, 2, 3, 4, 5], 3, 1, :discard)
# [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
```

## Other Useful Transforms

```elixir
# Take and drop
Enum.take([1, 2, 3, 4, 5], 3)    # [1, 2, 3]
Enum.drop([1, 2, 3, 4, 5], 2)    # [3, 4, 5]

# Slice
Enum.slice([1, 2, 3, 4, 5], 1..3) # [2, 3, 4]

# With index
Enum.with_index(["a", "b", "c"])
# [{"a", 0}, {"b", 1}, {"c", 2}]

# Intersperse
Enum.intersperse([1, 2, 3], 0)    # [1, 0, 2, 0, 3]

# Dedup (remove consecutive duplicates only)
Enum.dedup([1, 1, 2, 2, 1, 1])   # [1, 2, 1]
```

## Chaining Transforms

Transforms compose naturally with the pipe operator:

```elixir
[5, 3, 8, 1, 3, 9, 2, 5, 7, 1]
|> Enum.sort()         # [1, 1, 2, 3, 3, 5, 5, 7, 8, 9]
|> Enum.uniq()         # [1, 2, 3, 5, 7, 8, 9]
|> Enum.reverse()      # [9, 8, 7, 5, 3, 2, 1]
|> Enum.take(5)        # [9, 8, 7, 5, 3]
```

## Common Pitfalls

1. **sort vs sort_by**: Use `sort_by` when sorting by a derived value; it is more readable and evaluates the key function once per element.
2. **flat_map vs map + flatten**: `flat_map` is more efficient than `Enum.map(...) |> List.flatten()`.
3. **uniq vs dedup**: `uniq` removes all duplicates globally; `dedup` only removes consecutive duplicates.
4. **zip truncation**: `zip` silently drops extra elements from the longer list.
5. **chunk_every with remainder**: The last chunk may be smaller than the requested size unless you use padding.
