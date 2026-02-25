# Kata 37: MapSet

## The Concept

A **MapSet** is an unordered collection of unique values, backed by a map internally. It provides efficient membership testing and classic set algebra operations.

```elixir
set = MapSet.new([1, 2, 3, 2, 1])
# MapSet.new([1, 2, 3])  — duplicates removed automatically
```

## Creating and Modifying

```elixir
# Create
MapSet.new()                    # empty set
MapSet.new([1, 2, 3])          # from list
MapSet.new(1..5)               # from range

# Add / Remove
MapSet.put(set, 4)             # add element (no-op if already exists)
MapSet.delete(set, 2)          # remove element (no-op if not present)
```

## Querying

```elixir
MapSet.member?(set, 2)         # true — O(log n) lookup
MapSet.size(set)               # 3
MapSet.equal?(set_a, set_b)    # structural equality (order-independent)
MapSet.subset?(small, big)     # true if small ⊆ big
MapSet.disjoint?(a, b)         # true if no shared elements
```

## Set Algebra Operations

These are the core power of MapSet:

```elixir
a = MapSet.new([1, 2, 3])
b = MapSet.new([2, 3, 4])

MapSet.union(a, b)             # MapSet.new([1, 2, 3, 4])  — all elements
MapSet.intersection(a, b)      # MapSet.new([2, 3])        — shared elements
MapSet.difference(a, b)        # MapSet.new([1])           — in a but not b
```

### Symmetric Difference

Elixir doesn't have a built-in symmetric difference, but it's easy to compose:

```elixir
# Elements in either set, but not both
sym_diff = MapSet.union(
  MapSet.difference(a, b),
  MapSet.difference(b, a)
)
# MapSet.new([1, 4])
```

## MapSet is Enumerable

Because MapSet implements the Enumerable protocol, you can use all Enum functions:

```elixir
MapSet.new([1, 2, 3, 4, 5])
|> Enum.filter(&(rem(&1, 2) == 0))    # [2, 4]
|> MapSet.new()                         # back to a set
```

## When to Use MapSet vs List vs Map

| Structure | Best For | Membership Check | Order |
|-----------|----------|-----------------|-------|
| **MapSet** | Unique values, set operations | O(log n) | Unordered |
| **List** | Ordered sequences, pattern matching | O(n) | Ordered |
| **Map** | Key-value pairs | O(log n) by key | Unordered |

### Use MapSet when:
- You need to ensure uniqueness (tags, permissions, visited nodes)
- You need fast membership testing
- You need union/intersection/difference operations
- Order doesn't matter

### Use List when:
- Order matters
- You need head/tail pattern matching
- Duplicates are meaningful
- You're processing sequentially

## Real-World Examples

```elixir
# Deduplication
emails = ["a@b.com", "c@d.com", "a@b.com"]
unique = MapSet.new(emails)   # no duplicates

# Permission checking
user_perms = MapSet.new([:read, :write])
required = MapSet.new([:read, :admin])
missing = MapSet.difference(required, user_perms)
# MapSet.new([:admin])

# Tag intersection (find common interests)
alice_tags = MapSet.new(["elixir", "rust", "python"])
bob_tags = MapSet.new(["python", "go", "elixir"])
common = MapSet.intersection(alice_tags, bob_tags)
# MapSet.new(["elixir", "python"])
```

## Common Pitfalls

1. **Don't rely on order**: MapSet iteration order is not guaranteed and may change between Elixir versions.
2. **Strict equality**: `MapSet.new([1])` and `MapSet.new([1.0])` are different because `1 !== 1.0`.
3. **Converting back**: Use `MapSet.to_list/1` to get a list, but remember the order is arbitrary.
4. **Not a replacement for lists**: If you need indexing, ordering, or duplicates, use a list.
