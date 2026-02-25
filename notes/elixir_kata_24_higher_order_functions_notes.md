# Kata 24: Higher-Order Functions

## The Concept

A **higher-order function** is a function that takes other functions as arguments or returns functions. This is a cornerstone of functional programming and enables powerful composition patterns.

```elixir
# Takes a function as an argument
Enum.map([1, 2, 3], fn x -> x * 2 end)   # [2, 4, 6]

# Returns a function
def multiplier(factor) do
  fn x -> x * factor end
end

triple = multiplier(3)
triple.(10)   # 30
```

## Functions as Arguments

The most common use — passing behavior to generic functions:

```elixir
Enum.map([1, 2, 3], &(&1 * 2))          # Transform each
Enum.filter([1, 2, 3, 4], &(rem(&1, 2) == 0))  # Keep evens
Enum.reduce([1, 2, 3], 0, &(&1 + &2))   # Sum all
Enum.sort(["c", "a", "b"], &(&1 >= &2))  # Sort descending
```

## Functions Returning Functions

Functions can create and return new functions:

```elixir
def adder(n), do: fn x -> x + n end

add5 = adder(5)
add5.(10)   # 15
add5.(20)   # 25
```

## Function Composition

Chain functions together to build pipelines:

```elixir
# Manual composition
def compose(f, g), do: fn x -> f.(g.(x)) end

double = &(&1 * 2)
add_one = &(&1 + 1)

double_then_add = compose(add_one, double)
double_then_add.(5)   # 11 (5 * 2 = 10, then 10 + 1 = 11)
```

## The Middleware Pattern

Higher-order functions enable middleware/decorator patterns:

```elixir
def with_logging(fun) do
  fn args ->
    IO.puts("Calling with: #{inspect(args)}")
    result = fun.(args)
    IO.puts("Result: #{inspect(result)}")
    result
  end
end
```

## Common Higher-Order Functions in Elixir

| Function | Takes | Purpose |
|----------|-------|---------|
| `Enum.map/2` | `(elem -> new_elem)` | Transform each element |
| `Enum.filter/2` | `(elem -> boolean)` | Keep matching elements |
| `Enum.reduce/3` | `(elem, acc -> new_acc)` | Fold into single value |
| `Enum.sort_by/2` | `(elem -> comparable)` | Sort by derived key |
| `Enum.group_by/2` | `(elem -> key)` | Group into map by key |
| `Enum.each/2` | `(elem -> any)` | Side effects per element |

## Common Pitfalls

1. **Over-abstraction**: Don't create function factories when a simple function will do.
2. **Readability**: Deeply nested higher-order functions can be hard to read — use the pipe operator.
3. **Closure memory**: Returned functions hold references to captured variables.
4. **Arity awareness**: Make sure the function you pass has the right arity for the HOF.
