# Kata 09: The Match Operator

## The Concept

In Elixir, `=` is **not** an assignment operator — it's the **match operator**. It asserts that the left side matches the right side, and binds variables along the way.

```elixir
# This doesn't "assign 1 to x" — it matches x against 1
x = 1    # x is now bound to 1

# This succeeds because 1 matches 1
1 = x    # => 1

# This FAILS because 2 doesn't match 1
2 = x    # => ** (MatchError) no match of right hand side value: 1
```

## Binding vs Matching

When a **variable** appears on the left side, Elixir binds it to the corresponding value on the right:

```elixir
x = 1        # binds x to 1
{a, b} = {1, 2}  # binds a to 1, b to 2
[h | t] = [1, 2, 3]  # binds h to 1, t to [2, 3]
```

When a **literal value** appears on the left side, Elixir checks that it matches:

```elixir
1 = 1        # matches!
{1, b} = {1, 2}  # 1 matches 1, b binds to 2
{1, b} = {3, 2}  # ** (MatchError) — 1 doesn't match 3
```

## The Underscore `_`

The underscore `_` matches anything but doesn't bind:

```elixir
{_, b} = {1, 2}    # b = 2, first element ignored
[_ | tail] = [1, 2, 3]  # tail = [2, 3]
_ = "anything"     # always succeeds
```

## Why This Matters

Pattern matching is the foundation of Elixir. It's used everywhere:
- Function clause selection
- Case/cond/with expressions
- Destructuring data structures
- Error handling with tagged tuples

```elixir
# Real-world example: destructuring a function return
{:ok, contents} = File.read("config.txt")

# If the file doesn't exist, this crashes immediately
# (which is often what you want — fail fast!)
```

## Common Pitfalls

1. **Rebinding**: `x = 1` then `x = 2` works — Elixir rebinds `x`. Use `^x` (pin) to prevent this.
2. **Match on the right**: The right side is always evaluated first, then matched against the left.
3. **MatchError vs FunctionClauseError**: `=` raises MatchError; function head mismatches raise FunctionClauseError.
