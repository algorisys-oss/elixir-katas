# Kata 22: Recursion

## The Concept

Elixir has no traditional loops (`for`, `while`). Instead, it uses **recursion** — functions that call themselves. Every recursive function needs a **base case** (when to stop) and a **recursive case** (how to make progress).

```elixir
def countdown(0), do: "Done!"
def countdown(n) when n > 0 do
  IO.puts(n)
  countdown(n - 1)
end
```

## The Pattern: Base Case + Recursive Case

```elixir
# Sum numbers from n to 0
def sum(0), do: 0                    # Base case
def sum(n), do: n + sum(n - 1)       # Recursive case

sum(5)   # 5 + 4 + 3 + 2 + 1 + 0 = 15
```

## Recursion Over Lists

Lists are the most natural data structure for recursion:

```elixir
# Length of a list
def length([]), do: 0                      # Base: empty list
def length([_ | tail]), do: 1 + length(tail)  # Recursive: peel off head

# Map over a list
def my_map([], _fun), do: []
def my_map([h | t], fun), do: [fun.(h) | my_map(t, fun)]
```

## How the Call Stack Works

```
sum(3)
  3 + sum(2)
    3 + (2 + sum(1))
      3 + (2 + (1 + sum(0)))
        3 + (2 + (1 + 0))     ← base case hit
      3 + (2 + 1)             ← unwinding
    3 + 3
  6                            ← result
```

## Common Recursive Patterns

```elixir
# Factorial
def factorial(0), do: 1
def factorial(n), do: n * factorial(n - 1)

# Fibonacci
def fib(0), do: 0
def fib(1), do: 1
def fib(n), do: fib(n - 1) + fib(n - 2)

# Filter
def filter([], _fun), do: []
def filter([h | t], fun) do
  if fun.(h), do: [h | filter(t, fun)], else: filter(t, fun)
end
```

## Common Pitfalls

1. **Missing base case**: Infinite recursion → stack overflow.
2. **No progress**: The recursive case must move toward the base case.
3. **Stack growth**: Naive recursion grows the stack with each call. Use tail recursion (next kata!) for large inputs.
4. **Inefficient patterns**: Naive Fibonacci is exponential — `fib(40)` takes forever.
