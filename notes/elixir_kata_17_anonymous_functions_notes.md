# Kata 17: Anonymous Functions

## The Concept

Anonymous functions (also called lambdas) are first-class values in Elixir. They can be stored in variables, passed as arguments, and returned from other functions.

```elixir
add = fn a, b -> a + b end
add.(3, 4)   # 7
```

## Syntax

```elixir
# Basic anonymous function
greet = fn name -> "Hello, #{name}!" end
greet.("Alice")   # "Hello, Alice!"

# Multi-line
calculate = fn a, b ->
  sum = a + b
  sum * 2
end
```

## Calling with the Dot

Anonymous functions **must** be called with a dot: `fun.(args)`. This distinguishes them from named function calls.

```elixir
add = fn a, b -> a + b end
add.(1, 2)   # 3
add(1, 2)    # CompileError! Looks like a named function call
```

## Closures

Anonymous functions "close over" variables from the enclosing scope. The value is captured at definition time.

```elixir
x = 10
doubler = fn -> x * 2 end
x = 99          # Rebinding x does NOT affect the closure
doubler.()      # 20 — still uses x=10 from definition time
```

## Multi-clause Anonymous Functions

Pattern matching works in anonymous functions too:

```elixir
handle = fn
  {:ok, value}    -> "Success: #{value}"
  {:error, reason} -> "Error: #{reason}"
  _               -> "Unknown"
end

handle.({:ok, 42})        # "Success: 42"
handle.({:error, "oops"}) # "Error: oops"
```

## Functions as Values

Anonymous functions are values just like integers or strings:

```elixir
# In a list
ops = [fn a, b -> a + b end, fn a, b -> a * b end]
Enum.at(ops, 0).(3, 4)   # 7

# Passed to Enum.map
double = fn x -> x * 2 end
Enum.map([1, 2, 3], double)   # [2, 4, 6]
```

## Common Pitfalls

1. **Forgetting the dot**: `fun(args)` instead of `fun.(args)` causes a compile error.
2. **Closure confusion**: Closures capture the value, not a reference. Rebinding the outer variable doesn't change the closure.
3. **Arity mismatch**: Calling with wrong number of arguments gives `BadArityError`.
4. **Multi-clause must have same arity**: All clauses of an anonymous function must accept the same number of arguments.
