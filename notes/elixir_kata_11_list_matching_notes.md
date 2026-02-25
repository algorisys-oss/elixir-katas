# Kata 11: List Matching

## The Concept

Lists in Elixir are linked lists, and pattern matching reflects their structure: a **head** element linked to a **tail** (the rest of the list).

```elixir
[head | tail] = [1, 2, 3, 4]
# head = 1
# tail = [2, 3, 4]
```

## The Cons Operator `|`

The `|` operator splits a list into head and tail:

```elixir
[h | t] = [1, 2, 3]     # h = 1, t = [2, 3]
[h | t] = [1]            # h = 1, t = []
[h | t] = []             # ** (MatchError) — empty list has no head!
```

## Fixed-Length Matching

You can match exact list lengths:

```elixir
[a, b, c] = [1, 2, 3]       # a=1, b=2, c=3
[a, b, c] = [1, 2]          # ** (MatchError) — wrong length
[a, b] = [1, 2, 3]          # ** (MatchError) — wrong length
```

## Multiple Head Elements

Extract several elements at once:

```elixir
[first, second | rest] = [1, 2, 3, 4, 5]
# first = 1, second = 2, rest = [3, 4, 5]

[_, second | _] = [1, 2, 3, 4, 5]
# second = 2 (ignore first and rest)
```

## Matching with Literals

Combine literals and variables:

```elixir
[1 | rest] = [1, 2, 3]      # rest = [2, 3] — first must be 1
[1 | rest] = [2, 3, 4]      # ** (MatchError) — 2 ≠ 1

[:ok, value] = [:ok, 42]    # value = 42
```

## Nested List Matching

Match inside nested lists:

```elixir
[[first_of_first | _] | _] = [[1, 2], [3, 4]]
# first_of_first = 1

[head | _] = [[1, 2], [3, 4]]
# head = [1, 2]
```

## Recursion with Pattern Matching

This is how Elixir processes lists recursively:

```elixir
defmodule MyList do
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)
end

MyList.sum([1, 2, 3])  # => 6
# sum([1 | [2, 3]]) = 1 + sum([2 | [3]])
#                    = 1 + 2 + sum([3 | []])
#                    = 1 + 2 + 3 + sum([])
#                    = 1 + 2 + 3 + 0 = 6
```

## Common Pitfalls

1. **Empty list has no head**: `[h | t] = []` fails — always handle the empty case.
2. **Charlists confusion**: `[104, 101]` displays as `~c"he"` — these are still lists.
3. **Performance**: Pattern matching on the head is O(1), but accessing the nth element is O(n).
