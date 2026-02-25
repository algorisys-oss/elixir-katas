# Kata 23: Tail Call Optimization

## The Concept

A **tail call** is when the recursive call is the very last operation in a function — nothing happens after it returns. The BEAM (Erlang VM) optimizes tail calls into constant-space loops.

## Naive vs Tail-Recursive

```elixir
# Naive: n + sum(...) — addition happens AFTER the recursive call returns
def sum(0), do: 0
def sum(n), do: n + sum(n - 1)       # NOT tail-recursive

# Tail-recursive: recursive call is the LAST thing
def sum(n), do: sum(n, 0)            # Public wrapper
defp sum(0, acc), do: acc            # Base case returns accumulator
defp sum(n, acc), do: sum(n - 1, acc + n)  # Tail call!
```

## The Accumulator Pattern

To convert naive recursion to tail-recursive:

1. **Add an accumulator parameter** initialized to the identity value
2. **Move work before the recursive call** (update acc instead of doing work after)
3. **Add a public wrapper** to hide the accumulator from callers

| Operation | Accumulator Init | Update |
|-----------|-----------------|--------|
| Sum | 0 | acc + n |
| Product/Factorial | 1 | acc * n |
| Reverse list | [] | [h \| acc] |
| Map | [] | [f.(h) \| acc], then reverse |
| Count/Length | 0 | acc + 1 |

## Stack Comparison

**Naive sum(5):** Stack grows to depth 6, then unwinds:
```
sum(5) → 5 + sum(4) → 5 + (4 + sum(3)) → ...  [depth: 6]
```

**Tail sum(5, 0):** Constant depth 1:
```
sum(5, 0) → sum(4, 5) → sum(3, 9) → sum(2, 12) → sum(1, 14) → sum(0, 15) → 15
```

## How the BEAM Optimizes

When the recursive call is the last operation, the current stack frame has no more work to do. The BEAM replaces it instead of pushing a new one — effectively turning recursion into a loop.

## When NOT Tail-Recursive

If **any** operation happens after the recursive call, it's not a tail call:

```elixir
n + sum(n - 1)           # + happens after → NOT tail
[h | my_map(t, fun)]     # cons happens after → NOT tail
sum(n - 1, acc + n)      # nothing after → IS tail
```

## Common Pitfalls

1. **Not all recursion needs TCO**: For small inputs, naive recursion is fine and often clearer.
2. **List building reversal**: Tail-recursive list building produces reversed results — call `Enum.reverse/1` at the end.
3. **Premature optimization**: `Enum` module functions are already optimized. Use recursion for learning, `Enum` for production.
