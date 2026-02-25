# Kata 07: Lists

## The Concept

Lists are the workhorse data structure in Elixir. They're linked lists — each element points to the next — which means prepending is O(1) but appending is O(n). Understanding this is key to writing performant Elixir.

## List Basics

```elixir
[1, 2, 3]
["hello", :world, 42]   # mixed types
[]                        # empty list
```

## Head and Tail

Every non-empty list has a **head** (first element) and a **tail** (the rest):

```elixir
list = [1, 2, 3, 4]

hd(list)   # => 1        (the head)
tl(list)   # => [2, 3, 4] (the tail)

# Pattern matching syntax
[head | tail] = [1, 2, 3, 4]
head  # => 1
tail  # => [2, 3, 4]

# Multiple elements
[a, b | rest] = [1, 2, 3, 4]
a     # => 1
b     # => 2
rest  # => [3, 4]
```

## Prepending (O(1) — Fast!)

```elixir
list = [2, 3, 4]
[1 | list]    # => [1, 2, 3, 4]
```

Prepending is **constant time** because we just create a new node pointing to the existing list. The original list is shared.

## Appending (O(n) — Slow!)

```elixir
list = [1, 2, 3]
list ++ [4]   # => [1, 2, 3, 4]
```

Appending requires copying the **entire** list because linked lists can only be traversed from the head. For a list of 1000 elements, that's 1000 copies.

## Concatenation and Subtraction

```elixir
[1, 2, 3] ++ [4, 5]    # => [1, 2, 3, 4, 5]
[1, 2, 3, 2] -- [2]    # => [1, 3, 2]  (removes first occurrence)
[1, 2, 3] -- [2, 3]    # => [1]
```

## Length

```elixir
length([1, 2, 3])  # => 3
length([])          # => 0
```

**Note:** `length/1` is O(n) — it traverses the entire list. If you need to check emptiness, use pattern matching:

```elixir
# Good — O(1)
case list do
  [] -> "empty"
  [_ | _] -> "not empty"
end

# Avoid for emptiness check — O(n)
if length(list) == 0, do: "empty"
```

## Lists Are Immutable

```elixir
original = [1, 2, 3]
new_list = [0 | original]

original  # => [1, 2, 3]  (unchanged!)
new_list  # => [0, 1, 2, 3]
```

## The Performance Rule

| Operation | Time | Why |
|-----------|------|-----|
| Prepend `[x \| list]` | O(1) | Just add a new head node |
| Append `list ++ [x]` | O(n) | Must copy entire list |
| Length `length(list)` | O(n) | Must traverse all nodes |
| Access `Enum.at(list, i)` | O(i) | Must walk i nodes |
| Head `hd(list)` | O(1) | Just read the first node |
| Tail `tl(list)` | O(1) | Just return the pointer |

**The Elixir idiom:** Build lists by prepending, then reverse at the end if order matters.

```elixir
# Building a list efficiently
list = []
list = [3 | list]   # [3]
list = [2 | list]   # [2, 3]
list = [1 | list]   # [1, 2, 3]
# Already in order! Or use Enum.reverse/1 if needed.
```

## Common Pitfalls

1. **Don't append in a loop** — `list ++ [item]` in a loop is O(n^2). Prepend and reverse instead.
2. **`length/1` is O(n)** — Don't use `length(list) == 0` to check emptiness; pattern match on `[]`
3. **`[head | tail]` is destructuring** — `tail` is always a list (even if it's `[]`)
4. **Single element list** — `[x | []]` is the same as `[x]`
