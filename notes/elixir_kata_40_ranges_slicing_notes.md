# Kata 40: Ranges & Slicing

## The Concept

**Ranges** are lightweight structs that represent sequences of integers. They are lazy (no list is created until needed), implement the Enumerable protocol, and pair naturally with Enum's slicing functions.

```elixir
1..10          # ascending range, step 1
10..1//-1      # descending range, step -1
1..20//3       # step range: 1, 4, 7, 10, 13, 16, 19
```

## Range Syntax

### Basic Ranges

```elixir
1..5           # => 1, 2, 3, 4, 5
5..1//-1       # => 5, 4, 3, 2, 1
```

### Step Ranges (Elixir 1.12+)

```elixir
1..10//2       # => 1, 3, 5, 7, 9     (odds in range)
0..20//5       # => 0, 5, 10, 15, 20  (every 5th)
10..1//-3      # => 10, 7, 4, 1       (descending by 3)
```

### Important: Descending Ranges

```elixir
# This produces an EMPTY sequence:
10..1          # => empty! (step defaults to 1, can't go from 10 to 1 by +1)

# You must specify the step:
10..1//-1      # => 10, 9, 8, ..., 1
```

## Range Properties

```elixir
range = 1..20//3

range.first    # => 1
range.last     # => 20
range.step     # => 3
Range.size(range)  # => 7 (elements: 1, 4, 7, 10, 13, 16, 19)

5 in 1..10     # => true  (membership check)
Range.disjoint?(1..5, 6..10)  # => true
```

## Ranges are Enumerable

All Enum and Stream functions work with ranges directly:

```elixir
Enum.to_list(1..5)        # => [1, 2, 3, 4, 5]
Enum.map(1..5, &(&1 * 2)) # => [2, 4, 6, 8, 10]
Enum.sum(1..100)           # => 5050
Enum.random(1..6)          # => random die roll
```

## Slicing Functions

### Enum.slice/2 (range-based)

```elixir
data = [:a, :b, :c, :d, :e, :f]

Enum.slice(data, 1..3)     # => [:b, :c, :d]    (indices 1 to 3)
Enum.slice(data, 2..4)     # => [:c, :d, :e]    (indices 2 to 4)
Enum.slice(data, -3..-1)   # => [:d, :e, :f]    (last 3 elements)
```

### Enum.slice/3 (start + count)

```elixir
Enum.slice(data, 1, 3)     # => [:b, :c, :d]    (from index 1, take 3)
```

### Enum.take/2 and Enum.drop/2

```elixir
Enum.take(data, 3)         # => [:a, :b, :c]    (first 3)
Enum.take(data, -2)        # => [:e, :f]         (last 2)
Enum.drop(data, 2)         # => [:c, :d, :e, :f] (skip first 2)
Enum.drop(data, -2)        # => [:a, :b, :c, :d] (remove last 2)
```

### Enum.split/2

```elixir
Enum.split(data, 3)        # => {[:a, :b, :c], [:d, :e, :f]}
Enum.split(data, -2)       # => {[:a, :b, :c, :d], [:e, :f]}
```

### Enum.take_while/2 and Enum.drop_while/2

```elixir
Enum.take_while([1, 2, 3, 4, 1], &(&1 < 4))  # => [1, 2, 3]
Enum.drop_while([1, 2, 3, 4, 1], &(&1 < 3))  # => [3, 4, 1]
```

## Practical Patterns

### Pagination

```elixir
def paginate(data, page, per_page) do
  data
  |> Enum.drop((page - 1) * per_page)
  |> Enum.take(per_page)
end

paginate(1..100, 3, 10)  # => [21, 22, 23, 24, 25, 26, 27, 28, 29, 30]
```

### Sliding Window

```elixir
Enum.chunk_every([1, 2, 3, 4, 5], 3, 1, :discard)
# => [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
```

### Sampling at Intervals

```elixir
# Every 5th element from 1 to 100
Enum.to_list(0..99//5)
# => [0, 5, 10, 15, 20, ...]
```

### Bounds Checking

```elixir
def valid_port?(port), do: port in 1..65535
def valid_http_status?(code), do: code in 100..599
```

## Range in Pattern Matching and Guards

```elixir
# In guards (Elixir 1.12+)
def categorize(n) when n in 1..10, do: :low
def categorize(n) when n in 11..100, do: :medium
def categorize(_), do: :high

# In case expressions
case score do
  n when n in 90..100 -> :A
  n when n in 80..89 -> :B
  n when n in 70..79 -> :C
  _ -> :F
end
```

## Common Pitfalls

1. **Empty descending ranges**: `10..1` with default step 1 is empty. Always use `10..1//-1` for descending.
2. **Step must match direction**: `1..10//-1` is empty because you can't go from 1 to 10 with step -1.
3. **Ranges are integer-only**: You cannot create ranges of floats. Use `Stream.iterate` for non-integer sequences.
4. **Slice bounds**: `Enum.slice/2` silently handles out-of-bounds indices (returns fewer elements), while `Enum.at/2` returns nil for out-of-bounds.
5. **Performance of negative take/drop**: `Enum.take(list, -n)` and `Enum.drop(list, -n)` must traverse the entire list first, so they are O(length).
