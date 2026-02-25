# Kata 72: Quote & Unquote

## The Concept

`quote` converts Elixir code into its **AST (Abstract Syntax Tree)** -- a nested data structure of tuples and lists. This is the foundation of metaprogramming in Elixir, where code can be treated as data and manipulated programmatically.

```elixir
quote do
  1 + 2
end
# => {:+, [context: Elixir, imports: [{1, Kernel}]], [1, 2]}
```

## AST Node Structure

Every Elixir expression, when quoted, becomes one of:

### 1. Literals (represent themselves)
Atoms, numbers, strings, lists, and two-element tuples are their own AST:

```elixir
quote do: :hello     # => :hello
quote do: 42         # => 42
quote do: "hi"       # => "hi"
quote do: [1, 2]     # => [1, 2]
quote do: {1, 2}     # => {1, 2}
```

### 2. Three-element tuples
Everything else becomes `{name, metadata, arguments}`:

```elixir
# Variables
quote do: x
# => {:x, [], Elixir}

# Function calls
quote do: sum(1, 2, 3)
# => {:sum, [], [1, 2, 3]}

# Operators (are function calls)
quote do: 1 + 2
# => {:+, [], [1, 2]}
```

### 3. Blocks
Multiple expressions become `:__block__` nodes:

```elixir
quote do
  x = 1
  x + 2
end
# => {:__block__, [], [
#      {:=, [], [{:x, [], Elixir}, 1]},
#      {:+, [], [{:x, [], Elixir}, 2]}
#    ]}
```

## unquote

`unquote` injects an evaluated value into a `quote` block. Think of it like string interpolation, but for AST:

```elixir
# Without unquote: x is quoted as a variable reference
quote do: x
# => {:x, [], Elixir}

# With unquote: x's VALUE is injected
x = 42
quote do: unquote(x)
# => 42

# Practical example
name = :hello
quote do
  def unquote(name)() do
    "world"
  end
end
```

## unquote_splicing

Splices a list's elements as individual arguments:

```elixir
args = [1, 2, 3]

# unquote inserts the list as one argument
quote do: foo(unquote(args))
# => {:foo, [], [[1, 2, 3]]}

# unquote_splicing expands the list
quote do: foo(unquote_splicing(args))
# => {:foo, [], [1, 2, 3]}
```

## Useful Functions

```elixir
# Convert AST back to string
quote(do: 1 + 2 * 3) |> Macro.to_string()
# => "1 + 2 * 3"

# Evaluate AST
Code.eval_quoted(quote(do: 1 + 2))
# => {3, []}

# Expand macros in AST
Macro.expand_once(quote(do: unless(true, do: :no)), __ENV__)

# Walk the AST
Macro.prewalk(ast, fn node -> ... end)
Macro.postwalk(ast, fn node -> ... end)
```

## Homoiconicity

Elixir is **homoiconic** -- its code can be represented using its own data structures. This means:

1. **Code is data**: Any Elixir expression can be converted to tuples and lists
2. **Data is code**: Those tuples and lists can be compiled and executed
3. **Programs can write programs**: Macros receive AST, transform it, and return new AST

```elixir
# Code -> Data
ast = quote do: Enum.map([1, 2, 3], &(&1 * 2))

# Data -> Code
{result, _} = Code.eval_quoted(ast)
# result => [2, 4, 6]
```

## Quote Options

```elixir
# Include line numbers
quote line: 42, do: x
# => {:x, [line: 42], Elixir}

# Bind quoted to caller's context
quote bind_quoted: [x: 1 + 1] do
  x * x
end
# x is bound to 2 at quote time
```

## Common Pitfalls

1. **Confusing quote and eval**: `quote` doesn't execute code -- it transforms it into AST.
2. **Forgetting unquote**: Inside `quote`, variables refer to their AST form, not their values. Use `unquote` to inject values.
3. **Three-element tuples outside quote**: The tuple `{:foo, [], [1]}` looks like AST but is just data unless used in a macro context.
4. **Over-using metaprogramming**: Only use `quote`/`unquote` and macros when regular functions cannot solve the problem.
