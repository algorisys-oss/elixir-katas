# Kata 29: Pipe Operator

## The Concept

The **pipe operator** `|>` takes the result of the expression on its left and passes it as the **first argument** to the function on its right. It transforms deeply nested function calls into readable, linear pipelines.

```elixir
# These are identical:
String.upcase(String.trim("  hello  "))

"  hello  "
|> String.trim()
|> String.upcase()
# "HELLO"
```

## How It Works

The compiler rewrites `|>` at compile time:

```elixir
value |> function(arg2, arg3)
# becomes:
function(value, arg2, arg3)
```

This is purely syntactic sugar — there is no runtime cost.

## Nested vs Piped

Nested calls read inside-out, which gets confusing with many steps:

```elixir
# Nested: read inside-out (hard with many steps)
Enum.join(Enum.map(String.split("hello world"), &String.capitalize/1), " ")

# Piped: read top-to-bottom (follows the data flow)
"hello world"
|> String.split()
|> Enum.map(&String.capitalize/1)
|> Enum.join(" ")
```

## Common Pipe Patterns

### Enum Pipeline (filter, transform, aggregate)

```elixir
1..100
|> Enum.filter(&(rem(&1, 3) == 0))   # multiples of 3
|> Enum.map(&(&1 * &1))              # square them
|> Enum.take(5)                       # first 5
|> Enum.sum()                         # total
```

### String Processing Pipeline

```elixir
"  Hello, World!  "
|> String.trim()
|> String.downcase()
|> String.replace(~r/[^a-z0-9\s]/, "")
|> String.split()
|> Enum.join("-")
# "hello-world"
```

### Map Transformation Pipeline

```elixir
%{name: "alice", role: :user}
|> Map.put(:active, true)
|> Map.update!(:name, &String.capitalize/1)
|> Map.put(:joined, Date.utc_today())
```

## then/1 and tap/1

### then/1 — Pipe Into Any Position

When you need the piped value somewhere other than the first argument:

```elixir
42
|> then(fn x -> "The answer is: #{x}" end)
# "The answer is: 42"

# Useful when the function doesn't take the subject as first arg
"hello"
|> String.length()
|> then(fn len -> String.pad_leading("x", len, ".") end)
```

### tap/1 — Side Effects Without Changing the Value

`tap/1` executes a function for its side effects and returns the original value:

```elixir
[3, 1, 4, 1, 5]
|> tap(fn data -> IO.inspect(data, label: "input") end)
|> Enum.sort()
|> tap(fn data -> IO.inspect(data, label: "sorted") end)
|> Enum.take(3)
# Prints debug info, returns [1, 1, 3]
```

## Why Elixir Loves Pipes

Elixir's standard library is intentionally designed for piping:

| Module | Pattern | Example |
|--------|---------|---------|
| `String` | `String.fun(string, ...)` | `String.trim(str)` |
| `Enum` | `Enum.fun(enumerable, ...)` | `Enum.map(list, fun)` |
| `Map` | `Map.fun(map, ...)` | `Map.put(map, key, val)` |
| `List` | `List.fun(list, ...)` | `List.flatten(list)` |

The "subject" is always the first argument.

## Best Practices

1. **Start with a raw value**, not a function call
2. **Don't pipe into a single function** — `a |> f()` is less clear than `f(a)`
3. **Keep pipelines focused** — one logical transformation per pipeline
4. **Use `then/1`** when the value needs to go into a non-first argument
5. **Use `tap/1`** for debugging, not `IO.inspect` inline
6. **Avoid side effects** in the middle of pipelines (except `tap`)

## Common Pitfalls

1. **Piping into operators**: `x |> +1` doesn't work. Use `x |> Kernel.+(1)` or `then`.
2. **Piping nil**: If any step returns nil, downstream steps may crash.
3. **Mixed return types**: Ensure each step returns the type the next step expects.
4. **Too-long pipelines**: If a pipeline is very long, consider breaking it into named steps.

## Pipe Operator vs Function Composition

```elixir
# Pipe operator: applies immediately
result = data |> step1() |> step2() |> step3()

# Function composition: builds a new function (no built-in operator)
composed = fn x -> x |> step1() |> step2() |> step3() end
result = composed.(data)
```

Unlike Haskell's `.` or F#'s `>>`, Elixir's `|>` is an immediate application, not function composition. Use anonymous functions or libraries if you need lazy composition.
