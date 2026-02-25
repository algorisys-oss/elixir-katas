# Kata 31: Try / Rescue / Catch

## The Concept

Elixir provides `try/rescue` for handling exceptions, but idiomatic Elixir favors **tagged tuples** (`{:ok, value}` / `{:error, reason}`) and the **"let it crash"** philosophy over defensive exception handling.

## raise and reraise

```elixir
# Raise a RuntimeError with a message
raise "something went wrong"

# Raise a specific error type
raise ArgumentError, message: "expected a positive integer"

# Reraise preserving the original stacktrace
try do
  dangerous()
rescue
  e -> reraise e, __STACKTRACE__
end
```

## try/rescue

`rescue` catches exceptions (values raised with `raise`):

```elixir
try do
  String.to_integer("abc")
rescue
  e in ArgumentError ->
    "Bad argument: #{e.message}"
  e in RuntimeError ->
    "Runtime error: #{e.message}"
  e ->
    "Unknown error: #{inspect(e)}"
end
```

You can match specific exception types or catch all with a bare variable.

## try/rescue/after

`after` always runs, regardless of whether an exception was raised:

```elixir
try do
  file = File.open!("data.txt")
  process(file)
rescue
  e -> IO.puts("Error: #{e.message}")
after
  File.close(file)
  IO.puts("Cleanup complete")
end
```

Use `after` for cleanup: closing files, releasing connections, etc.

## try/catch

`catch` handles `throw` values and `exit` signals:

```elixir
# Catching throw
try do
  throw(:abort)
catch
  :throw, value -> "Caught throw: #{inspect(value)}"
end

# Catching exit
try do
  exit(:shutdown)
catch
  :exit, reason -> "Caught exit: #{inspect(reason)}"
end
```

**throw** and **exit** are rarely used directly in application code.

## Common Error Types

| Error | Caused By | Example |
|-------|-----------|---------|
| `RuntimeError` | `raise "msg"` | General-purpose error |
| `ArgumentError` | Bad function argument | `String.to_integer("abc")` |
| `ArithmeticError` | Invalid arithmetic | `1 / 0` |
| `FunctionClauseError` | No matching clause | `List.first(:not_a_list)` |
| `KeyError` | Missing map key (dot access) | `%{a: 1}.b` |
| `MatchError` | Failed pattern match | `{:ok, _} = {:error, "oops"}` |
| `CaseClauseError` | No matching case clause | `case x do ... end` with no match |
| `UndefinedFunctionError` | Module/function doesn't exist | `Foo.bar()` |

## Tagged Tuples vs try/rescue

### The Elixir Convention

Most Elixir functions come in pairs:

| Returns tuples | Raises (bang !) | Example |
|---------------|----------------|---------|
| `File.read/1` | `File.read!/1` | `{:ok, content}` or `{:error, reason}` |
| `Map.fetch/2` | `Map.fetch!/2` | `{:ok, value}` or `:error` |
| `Integer.parse/1` | `String.to_integer/1` | `{integer, rest}` or `:error` |
| `Jason.decode/1` | `Jason.decode!/1` | `{:ok, data}` or `{:error, reason}` |

### When to Use Each

**Tagged tuples** (preferred for expected failures):
```elixir
case File.read("config.txt") do
  {:ok, content} -> process(content)
  {:error, :enoent} -> "File not found"
  {:error, reason} -> "Error: #{reason}"
end
```

**try/rescue** (for truly unexpected situations):
```elixir
try do
  # Third-party code that might blow up
  ExternalLib.do_something(data)
rescue
  e -> Logger.error("Unexpected: #{inspect(e)}")
end
```

**Bang functions** (when failure should crash):
```elixir
# In a script or where failure is unrecoverable
content = File.read!("required.txt")
config = Jason.decode!(content)
```

## The "Let It Crash" Philosophy

Elixir inherits Erlang's approach to fault tolerance:

1. **Processes are isolated**: A crash in one process doesn't affect others.
2. **Processes are cheap**: Creating a new one is fast (microseconds).
3. **Supervisors restart crashed processes**: Clean state on restart.
4. **Don't defend against bugs**: If there's a programming error, let it crash and fix the bug.

### The Decision Tree

```
Is the failure expected?
├── YES → Use tagged tuples {:ok, _} / {:error, _}
│         Pattern match on the result
└── NO → Is it a programming error (bug)?
    ├── YES → Let it crash. Fix the bug.
    └── NO → Is local recovery possible?
        ├── YES → Use try/rescue for cleanup
        └── NO → Let it crash, supervisor restarts
```

### Anti-pattern: Defensive Rescue

```elixir
# BAD: Hiding bugs behind rescue
def process(data) do
  try do
    do_work(data)
  rescue
    _ -> {:error, "something went wrong"}  # Hides the actual error
  end
end

# GOOD: Let it crash, or handle expected failures
def process(data) do
  case validate(data) do
    {:ok, valid_data} -> do_work(valid_data)
    {:error, reason} -> {:error, reason}
  end
end
```

## with + Tagged Tuples (The Preferred Pattern)

Instead of nested try/rescue, use `with` for chaining operations:

```elixir
with {:ok, content} <- File.read(path),
     {:ok, data} <- Jason.decode(content),
     {:ok, result} <- process(data) do
  {:ok, result}
else
  {:error, :enoent} -> {:error, "File not found"}
  {:error, %Jason.DecodeError{}} -> {:error, "Invalid JSON"}
  {:error, reason} -> {:error, reason}
end
```

## Custom Exceptions

Define your own exception types:

```elixir
defmodule MyApp.NotFoundError do
  defexception [:message, :resource]

  @impl true
  def exception(opts) do
    resource = Keyword.fetch!(opts, :resource)
    msg = "#{resource} not found"
    %__MODULE__{message: msg, resource: resource}
  end
end

# Usage
raise MyApp.NotFoundError, resource: "User #42"
```

## Common Pitfalls

1. **Over-rescuing**: Don't wrap everything in try/rescue. It hides bugs and makes debugging harder.
2. **Rescuing too broadly**: `rescue _ ->` catches everything, including bugs you want to see.
3. **Ignoring after**: The `after` block's return value is ignored; the try/rescue block's value is returned.
4. **Confusing raise/throw/exit**: `raise` is for exceptions, `throw` for non-local returns, `exit` for process termination.
5. **Not using bang functions**: When failure should crash (e.g., missing required config), use `File.read!/1` instead of handling {:error, _}.
