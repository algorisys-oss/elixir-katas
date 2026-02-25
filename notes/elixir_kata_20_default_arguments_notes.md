# Kata 20: Default Arguments

## The Concept

Elixir functions can have default argument values using the `\\` operator. Each default generates an additional function clause.

```elixir
def greet(name, greeting \\ "Hello") do
  "#{greeting}, #{name}!"
end

greet("Alice")            # "Hello, Alice!"
greet("Alice", "Hola")   # "Hola, Alice!"
```

## Generated Arities

Each default argument creates an additional arity:

```elixir
def example(a, b \\ 1, c \\ 2)
# Generates: example/1, example/2, example/3
```

| Definition | Defaults | Generated Arities |
|-----------|----------|-------------------|
| `def f(a, b \\ 1)` | 1 | f/1, f/2 |
| `def f(a, b \\ 1, c \\ 2)` | 2 | f/1, f/2, f/3 |
| `def f(a \\ 1, b \\ 2, c \\ 3)` | 3 | f/0, f/1, f/2, f/3 |

## Multi-clause + Defaults

When combining multiple clauses with defaults, use a **bodyless function head**:

```elixir
def process(data, opts \\ [])

def process(data, opts) when is_list(data) do
  # handle list
end

def process(data, opts) when is_map(data) do
  # handle map
end
```

## The Options Pattern

A very common Elixir/Phoenix pattern uses keyword list defaults:

```elixir
def fetch(url, opts \\ []) do
  timeout = Keyword.get(opts, :timeout, 5000)
  headers = Keyword.get(opts, :headers, [])
  # ...
end

fetch("https://example.com")
fetch("https://example.com", timeout: 10_000)
```

## Evaluation Timing

Defaults are evaluated at **call time**, not definition time:

```elixir
def log(msg, timestamp \\ DateTime.utc_now()) do
  "#{timestamp}: #{msg}"
end
# Each call gets the current time
```

## Common Pitfalls

1. **Arity conflicts**: Defaults can create arities that conflict with other function definitions.
2. **Bodyless head required**: Multi-clause functions with defaults need a bodyless function head.
3. **Left-to-right filling**: Arguments are filled from left to right when fewer args are provided.
4. **Not the same as keyword args**: `\\ []` for keyword lists is the idiomatic Elixir "options" pattern.
