# Kata 35: Enum Search

## The Concept

Search functions locate, test, and select elements from collections. Many employ short-circuit evaluation, stopping as soon as the answer is determined, which is important for performance on large collections.

## Enum.find/2,3

Returns the first element matching a predicate, or a default value:

```elixir
Enum.find([2, 4, 6, 7, 8], &(rem(&1, 2) != 0))
# 7

# With default
Enum.find([2, 4, 6], :not_found, &(rem(&1, 2) != 0))
# :not_found

# Default is nil when not specified
Enum.find([2, 4, 6], &(rem(&1, 2) != 0))
# nil
```

Related: `Enum.find_index/2` returns the position instead of the value. `Enum.find_value/2` returns the return value of the function (not the element).

## Enum.any?/2

Returns `true` if at least one element satisfies the predicate:

```elixir
Enum.any?([1, 2, 3, 4], &(&1 > 3))
# true

Enum.any?([1, 2, 3], &(&1 > 5))
# false

# Empty list
Enum.any?([], &(&1 > 0))
# false
```

Short-circuits: returns `true` immediately on the first match.

## Enum.all?/2

Returns `true` only if every element satisfies the predicate:

```elixir
Enum.all?([2, 4, 6, 8], &(rem(&1, 2) == 0))
# true

Enum.all?([2, 4, 5, 8], &(rem(&1, 2) == 0))
# false

# Empty list: vacuous truth
Enum.all?([], &(&1 > 0))
# true
```

Short-circuits: returns `false` immediately on the first non-match.

## Enum.member?/2

Checks if an element exists using equality:

```elixir
Enum.member?([1, 2, 3, 4, 5], 3)
# true

Enum.member?([1, 2, 3], 7)
# false

# Also works with the `in` operator
3 in [1, 2, 3, 4, 5]
# true
```

Note: For lists, `member?` is O(n). For frequent membership checks, use `MapSet`:

```elixir
set = MapSet.new([1, 2, 3, 4, 5])
MapSet.member?(set, 3)  # O(1) on average
```

## Enum.take_while/2

Takes elements from the front as long as the predicate holds:

```elixir
Enum.take_while([1, 2, 3, 4, 5, 1], &(&1 < 4))
# [1, 2, 3]

# All match
Enum.take_while([1, 2, 3], &(&1 < 10))
# [1, 2, 3]

# First element fails
Enum.take_while([5, 1, 2, 3], &(&1 < 4))
# []
```

Note: `take_while` stops at the first failure. It does NOT resume for later elements that match.

## Enum.drop_while/2

Drops elements from the front as long as the predicate holds, keeping the rest:

```elixir
Enum.drop_while([1, 2, 3, 4, 5], &(&1 < 3))
# [3, 4, 5]

# Only drops from the front
Enum.drop_while([1, 2, 3, 1, 2], &(&1 < 3))
# [3, 1, 2]  -- note: 1, 2 at the end are kept!

# Nothing dropped
Enum.drop_while([5, 4, 3], &(&1 > 10))
# [5, 4, 3]
```

## Short-Circuit Behavior

Several search functions stop early when the result is determined:

| Function | Stops when | Checks all if |
|----------|-----------|--------------|
| `find` | First match found | No match exists |
| `any?` | First truthy result | No element matches |
| `all?` | First falsy result | All elements match |
| `member?` | Element found | Element not in list |
| `take_while` | First false predicate | All elements pass |

This matters for:
- **Large collections**: Finding one item in a million-element list is fast if it is near the front.
- **Expensive predicates**: Avoids running costly checks on every element.

## Combining Search Functions

```elixir
data = [10, 25, 3, 42, 7, 18, 33, 5, 29, 14]

# Find, then check
first_big = Enum.find(data, &(&1 > 30))
# 42

# Are there any negatives?
Enum.any?(data, &(&1 < 0))
# false

# Are all positive?
Enum.all?(data, &(&1 > 0))
# true

# Take from sorted until threshold
data |> Enum.sort() |> Enum.take_while(&(&1 < 20))
# [3, 5, 7, 10, 14, 18]
```

## Common Pitfalls

1. **find returns nil by default**: If `nil` is a valid value in your collection, use `find/3` with an explicit default to distinguish "not found" from "found nil".
2. **all? on empty**: `Enum.all?([], predicate)` returns `true` (vacuous truth). This is mathematically correct but can surprise beginners.
3. **take_while vs filter**: `take_while` stops at the first failure; `filter` checks every element. They produce different results when matching elements are not contiguous.
4. **member? performance**: O(n) for lists. Use MapSet for O(1) lookups when checking membership frequently.
