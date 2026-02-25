# Kata 14: Multi-clause Matching

## The Concept

Elixir functions can have **multiple clauses**. When called, Elixir tries each clause in order and executes the first one that matches. This replaces if/else chains with declarative pattern matching.

```elixir
def greet(:english), do: "Hello!"
def greet(:spanish), do: "¡Hola!"
def greet(:french), do: "Bonjour!"
def greet(_), do: "👋"
```

## First Match Wins

Clauses are tried **top to bottom**. The first matching clause executes:

```elixir
def describe(0), do: "zero"
def describe(n) when n > 0, do: "positive"
def describe(n) when n < 0, do: "negative"
```

Order matters! If you put a catch-all first, it shadows everything below:

```elixir
# BAD — catch-all first, other clauses are unreachable!
def describe(_), do: "something"
def describe(0), do: "zero"       # Never reached!
```

## Guards

Guards add conditions beyond pattern matching:

```elixir
def classify(n) when is_integer(n) and n > 0, do: "positive integer"
def classify(n) when is_integer(n) and n < 0, do: "negative integer"
def classify(0), do: "zero"
def classify(n) when is_float(n), do: "float: #{n}"
def classify(_), do: "other"
```

## Allowed Guard Expressions

Only certain expressions are allowed in guards:
- Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`, `===`, `!==`
- Boolean: `and`, `or`, `not` (not `&&`, `||`, `!`)
- Arithmetic: `+`, `-`, `*`, `/`
- Type checks: `is_integer/1`, `is_binary/1`, `is_atom/1`, etc.
- `in` operator: `x in [1, 2, 3]`

**Not allowed**: custom functions, `String.length/1`, `Enum` functions, etc.

## Multi-clause with Different Arities

Functions are identified by name AND arity:

```elixir
def area(:circle, r), do: 3.14159 * r * r
def area(:square, s), do: s * s
def area(:rectangle, {w, h}), do: w * h
```

## FizzBuzz Example

The classic, done the Elixir way:

```elixir
def fizzbuzz(n) when rem(n, 15) == 0, do: "FizzBuzz"
def fizzbuzz(n) when rem(n, 3) == 0, do: "Fizz"
def fizzbuzz(n) when rem(n, 5) == 0, do: "Buzz"
def fizzbuzz(n), do: to_string(n)
```

## Common Pitfalls

1. **Clause order**: Put specific patterns before general ones. Compiler warns about unreachable clauses.
2. **Guard limitations**: Only built-in functions allowed in guards — no custom functions.
3. **FunctionClauseError**: If no clause matches, you get this error (not MatchError).
4. **Same arity required**: All clauses of a function must have the same arity.
