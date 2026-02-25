# Kata 13: The Pin Operator

## The Concept

By default, `=` rebinds variables on the left side. The **pin operator** `^` prevents rebinding — instead, it matches against the variable's current value.

```elixir
x = 1
x = 2      # Rebinds x to 2 (no error!)

x = 1
^x = 1     # Matches: 1 = 1 ✓
^x = 2     # ** (MatchError): 2 doesn't match 1
```

## Why Pin Exists

Without pin, variables on the left side always rebind:

```elixir
x = 1
{x, y} = {2, 3}
# x is now 2 (rebound!), y is 3
```

With pin, you can assert the value:

```elixir
x = 1
{^x, y} = {1, 3}   # Succeeds: x stays 1, y = 3
{^x, y} = {2, 3}   # Fails: 2 ≠ 1
```

## Pin in Case Expressions

One of the most common uses:

```elixir
expected = :ok

case get_result() do
  ^expected -> "Got what we expected!"
  other -> "Got #{inspect(other)} instead"
end
```

Without pin, `expected` would just rebind to whatever the result is.

## Pin in Function Clauses

Match against a value passed as a parameter:

```elixir
def check(value, value), do: "Same!"
def check(_, _), do: "Different!"

# But what about matching against a variable?
def check_against(expected, ^expected), do: "Match!"
def check_against(_, _), do: "No match!"
```

## Pin with Map Keys

Pin operator works with dynamic map keys:

```elixir
key = :name
%{^key => value} = %{name: "Alice"}
# value = "Alice"
```

## Pin in Comprehensions

```elixir
target = 3
for ^target <- [1, 2, 3, 3, 4], do: :match
# [:match, :match]
```

## Common Pitfalls

1. **Forgetting pin in case**: Without `^`, case patterns always rebind variables.
2. **Pin only works on bound variables**: `^x = 1` fails if `x` is unbound.
3. **Pin is left-side only**: `x = ^y` is not valid; `^y = x` or `^y` in a pattern is.
4. **Can't pin inside guards**: `when ^x > 0` doesn't work — use a regular variable and guard.
