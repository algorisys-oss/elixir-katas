# Kata 06: Tuples

## The Concept

Tuples are ordered collections of values stored contiguously in memory. They're one of Elixir's most important data structures, especially for function return values.

## Tuple Basics

```elixir
{1, 2, 3}
{"hello", :world, 42}
{:ok, "success"}
{:error, "not found"}
```

Tuples can hold any mix of types and are typically small (2-4 elements).

## Accessing Elements

```elixir
tuple = {:a, :b, :c, :d}

elem(tuple, 0)    # => :a
elem(tuple, 1)    # => :b
elem(tuple, 3)    # => :d

tuple_size(tuple) # => 4
```

**Zero-indexed!** The first element is at index 0.

## Updating Elements (Immutably)

```elixir
tuple = {:a, :b, :c}

put_elem(tuple, 1, :x)  # => {:a, :x, :c}

# The original is unchanged (immutable!)
tuple  # => {:a, :b, :c}
```

`put_elem/3` returns a NEW tuple. The original is never modified.

## The `{:ok, value}` / `{:error, reason}` Convention

This is THE most common Elixir pattern. Functions that can fail return tagged tuples:

```elixir
# Success
File.read("exists.txt")     # => {:ok, "file contents"}
Integer.parse("42")          # => {42, ""}

# Failure
File.read("nope.txt")       # => {:error, :enoent}
Integer.parse("abc")         # => :error
```

You pattern match on the tag to handle both cases:

```elixir
case File.read("config.txt") do
  {:ok, content}    -> "Got: #{content}"
  {:error, reason}  -> "Error: #{reason}"
end
```

## When to Use Tuples

**Use tuples for:**
- Fixed-size collections with known positions
- Function return values: `{:ok, result}`, `{:error, reason}`
- Small groupings: `{latitude, longitude}`, `{width, height}`

**Don't use tuples for:**
- Large collections (use lists instead)
- Collections that grow/shrink (use lists)
- Key-value data (use maps)

## Tuples vs Lists

| Feature | Tuple | List |
|---------|-------|------|
| Access by index | O(1) fast | O(n) slow |
| Prepend element | O(n) slow | O(1) fast |
| Size | Fixed | Dynamic |
| Memory | Contiguous | Linked |
| Typical use | Return values, coords | Collections, sequences |

## Common Pitfalls

1. **Zero-indexed** — `elem(tuple, 0)` gets the first element, not `elem(tuple, 1)`
2. **Immutable** — `put_elem` returns a new tuple; it doesn't modify the original
3. **Not for large data** — Updating a tuple copies the entire thing; use lists or maps for large collections
4. **Pattern match, don't `elem`** — Prefer `{:ok, value} = result` over `elem(result, 1)`
