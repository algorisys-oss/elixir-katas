# Kata 19: Guards

## The Concept

Guards add conditions to pattern matching using `when` clauses. They refine which function clause matches beyond just structure.

```elixir
def classify(n) when is_integer(n) and n > 0, do: "positive"
def classify(n) when is_integer(n) and n < 0, do: "negative"
def classify(0), do: "zero"
```

## Guard Syntax

Guards appear after `when` in function heads, case clauses, and receive blocks:

```elixir
# In function heads
def abs(n) when n < 0, do: -n
def abs(n), do: n

# In case expressions
case value do
  x when is_binary(x) -> "string: #{x}"
  x when is_integer(x) -> "integer: #{x}"
  _ -> "other"
end
```

## Allowed Guard Expressions

Only a limited set of expressions are allowed in guards:

- **Type checks**: `is_integer/1`, `is_float/1`, `is_binary/1`, `is_atom/1`, `is_list/1`, `is_map/1`, `is_tuple/1`, `is_boolean/1`, `is_nil/1`
- **Comparison**: `==`, `!=`, `===`, `!==`, `<`, `>`, `<=`, `>=`
- **Boolean**: `and`, `or`, `not` (NOT `&&`, `||`, `!`)
- **Arithmetic**: `+`, `-`, `*`, `/`, `div`, `rem`, `abs`
- **Type conversion**: `is_number/1`, `round/1`, `trunc/1`
- **String/binary**: `byte_size/1`, `bit_size/1`
- **Tuple**: `tuple_size/1`, `elem/2`
- **Map**: `map_size/1`, `is_map_key/2`
- **`in` operator**: `x in [1, 2, 3]`

## NOT Allowed in Guards

- Custom functions
- `String.length/1`, `Enum` functions
- `&&`, `||`, `!` (use `and`, `or`, `not` instead)
- Side-effecting functions (IO, etc.)

## Guard Failures

Guards that raise errors simply cause that clause to not match (no crash):

```elixir
def safe(x) when length(x) > 0, do: "list"
def safe(_), do: "other"

safe(42)     # "other" — length(42) fails silently, moves to next clause
safe([1])    # "list"
```

## Common Pitfalls

1. **Using `&&` instead of `and`**: Only `and`/`or`/`not` work in guards.
2. **Custom functions in guards**: You can't call your own functions — use `defguard` for reusable guards.
3. **Guard failure ≠ crash**: A failing guard just means the clause doesn't match.
4. **Limited expressions**: Most standard library functions are not allowed.
