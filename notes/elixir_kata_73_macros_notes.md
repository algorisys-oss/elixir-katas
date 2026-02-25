# Kata 73: Macros

## The Concept

**Macros** are compile-time code generators. They receive AST (Abstract Syntax Tree), transform it, and return new AST that the compiler injects in place of the macro call. Macros run at compile time, not at runtime.

```elixir
defmodule MyMacros do
  defmacro say_hello(name) do
    quote do
      "Hello, " <> unquote(name) <> "!"
    end
  end
end

import MyMacros
say_hello("world")
# => "Hello, world!"
```

## defmacro

Define macros with `defmacro`. Arguments arrive as AST, and the return value must be AST:

```elixir
defmacro unless(condition, do: body) do
  quote do
    if !unquote(condition) do
      unquote(body)
    end
  end
end

# Usage:
unless false do
  "This runs!"
end
# Expands to:
# if !false do
#   "This runs!"
# end
```

## Macro Expansion

Use `Macro.expand_once/2` to see what a macro expands to:

```elixir
ast = quote do
  unless true, do: :never
end

Macro.expand_once(ast, __ENV__) |> Macro.to_string()
# => "if(!true) do\n  :never\nend"
```

## Compile-Time Code Generation

Macros can generate multiple functions at compile time:

```elixir
defmodule JsonKeys do
  defmacro define_accessors(keys) do
    for key <- keys do
      quote do
        def unquote(key)(map) do
          Map.get(map, unquote(key))
        end
      end
    end
  end
end

defmodule User do
  import JsonKeys
  define_accessors [:name, :email, :age]
end

User.name(%{name: "Alice"})   # => "Alice"
User.email(%{email: "a@b.c"}) # => "a@b.c"
```

## Macro Hygiene

Elixir macros are **hygienic by default** -- variables defined inside a macro don't leak into the caller's scope:

```elixir
defmacro hygienic do
  quote do
    x = 42   # This x is scoped to the macro
  end
end

x = 1
hygienic()
x   # => 1 (unchanged!)
```

### Breaking Hygiene with var!

Use `var!` to intentionally access the caller's variables:

```elixir
defmacro set_x(value) do
  quote do
    var!(x) = unquote(value)
  end
end

x = 1
set_x(42)
x   # => 42 (modified!)
```

## bind_quoted

Use `bind_quoted` to ensure arguments are evaluated only once:

```elixir
# Without bind_quoted -- expression evaluated twice!
defmacro double_bad(expr) do
  quote do
    unquote(expr) + unquote(expr)
  end
end

# With bind_quoted -- expression evaluated once
defmacro double_good(expr) do
  quote bind_quoted: [expr: expr] do
    expr + expr
  end
end
```

## Built-in Macros

Many Elixir features are implemented as macros:

| Macro | What it does |
|-------|-------------|
| `if/unless` | Conditional branching |
| `def/defp` | Define functions |
| `defmodule` | Define modules |
| `defstruct` | Define structs |
| `use` | Invoke `__using__/1` macro |
| `\|>` | Pipe operator |
| `for` | Comprehensions |
| `with` | Chain pattern matches |
| `@` | Module attributes |

## When to Use Macros

**Use macros when you need:**
- Compile-time code generation (eliminating runtime overhead)
- Domain-specific language (DSL) creation
- Transforming code structure (not just values)
- Access to the caller's context (`__ENV__`, `__CALLER__`)

**Prefer functions when:**
- Runtime behavior is sufficient
- You don't need to transform code structure
- Simple computation or data transformation

## The Macro Workflow

```
1. Caller writes:     unless(false, do: :yes)
2. Compiler sees:     Macro call
3. Arguments as AST:  {false, [do: :yes]}
4. Macro transforms:  quote(do: if(!unquote(condition), do: unquote(body)))
5. Returns AST:       {:if, [], [{:!, [], [false]}, [do: :yes]]}
6. Compiler injects:  if(!false, do: :yes)
7. Runtime executes:  :yes
```

## Common Pitfalls

1. **Using macros when functions suffice**: This is the most common mistake. Functions are simpler, easier to test, and easier to debug.
2. **Forgetting bind_quoted**: Without it, unquoted expressions may be evaluated multiple times.
3. **Breaking hygiene unnecessarily**: Using `var!` makes macros harder to reason about.
4. **Complex macro logic**: Keep macro bodies simple. Move runtime logic into helper functions.
5. **Debugging difficulty**: Macro errors show in the expanded code, not the macro source. Use `Macro.expand_once/2` to debug.
