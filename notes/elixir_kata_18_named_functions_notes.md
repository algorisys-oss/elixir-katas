# Kata 18: Named Functions & Modules

## The Concept

Named functions live inside modules and are defined with `def` (public) or `defp` (private). Functions are identified by their name **and** arity.

```elixir
defmodule Math do
  def add(a, b), do: a + b        # Public: Math.add/2
  defp validate(n), do: n > 0     # Private: only callable within Math
end
```

## Module Definition

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, #{name}!"
  end

  def goodbye(name) do
    "Goodbye, #{name}!"
  end
end

Greeter.hello("Alice")     # "Hello, Alice!"
```

## Arity

Functions are identified by name AND number of arguments (arity):

```elixir
defmodule Example do
  def greet, do: "Hello!"             # greet/0
  def greet(name), do: "Hello, #{name}!" # greet/1
end

# These are TWO different functions!
Example.greet()        # "Hello!"
Example.greet("Bob")   # "Hello, Bob!"
```

## Public vs Private

```elixir
defmodule Account do
  def withdraw(balance, amount) do    # Public
    if valid_amount?(amount) do
      {:ok, balance - amount}
    else
      {:error, :invalid_amount}
    end
  end

  defp valid_amount?(amount) do       # Private
    amount > 0
  end
end
```

## One-line Syntax

Short functions can use the `do:` keyword syntax:

```elixir
def add(a, b), do: a + b
defp helper(x), do: x * 2
```

## Pattern Matching in Function Heads

```elixir
defmodule Geometry do
  def area(:circle, r), do: 3.14159 * r * r
  def area(:square, s), do: s * s
  def area(:rectangle, {w, h}), do: w * h
end
```

## Common Pitfalls

1. **Private function access**: `defp` functions can only be called from within the same module.
2. **Arity confusion**: `greet/0` and `greet/1` are completely different functions.
3. **Clause order matters**: Put specific patterns before general ones.
4. **Module nesting**: `defmodule A.B` doesn't require `defmodule A` to exist.
