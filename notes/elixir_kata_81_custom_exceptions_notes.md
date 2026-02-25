# Kata 81: Custom Exceptions

## The Concept

Elixir exceptions are structs defined with `defexception`. They implement the `Exception` behaviour, which requires a `:message` field and optionally provides `exception/1` and `message/1` callbacks for custom construction and formatting.

```elixir
defmodule ValidationError do
  defexception [:message, :field, :value]

  @impl true
  def message(%{field: field, value: value}) do
    "Validation failed for #{field}: got #{inspect(value)}"
  end
end

raise ValidationError, field: :email, value: "not-an-email"
# ** (ValidationError) Validation failed for email: got "not-an-email"
```

## Built-in Exception Types

### Common Exceptions

| Exception | Raised When |
|-----------|-------------|
| `RuntimeError` | `raise "string"` (default type) |
| `ArgumentError` | Invalid function argument |
| `KeyError` | Missing key in map (`Map.fetch!`, `map.key`) |
| `FunctionClauseError` | No matching function clause |
| `ArithmeticError` | Invalid arithmetic (e.g., division by zero) |
| `MatchError` | Pattern match failure |
| `CaseClauseError` | No matching case clause |
| `UndefinedFunctionError` | Calling a function that doesn't exist |
| `Protocol.UndefinedError` | Protocol not implemented for a type |

### Examples

```elixir
# RuntimeError (default)
raise "something went wrong"

# ArgumentError
raise ArgumentError, message: "expected a positive integer"

# Rescuing specific types
try do
  Map.fetch!(%{}, :missing)
rescue
  e in KeyError -> "Key error: #{Exception.message(e)}"
end
```

## Defining Custom Exceptions

### Basic Exception

The simplest form defines only a default message:

```elixir
defmodule NotFoundError do
  defexception message: "resource not found"
end

raise NotFoundError
# ** (NotFoundError) resource not found

raise NotFoundError, message: "user 42 not found"
# ** (NotFoundError) user 42 not found
```

### Custom Fields

Exceptions can carry structured data beyond the message:

```elixir
defmodule ApiError do
  defexception [:message, :status_code, :endpoint]

  @impl true
  def exception(opts) do
    status = Keyword.get(opts, :status_code, 500)
    endpoint = Keyword.get(opts, :endpoint, "unknown")
    msg = "API error #{status} at #{endpoint}"
    %__MODULE__{message: msg, status_code: status, endpoint: endpoint}
  end
end

try do
  raise ApiError, status_code: 404, endpoint: "/users/99"
rescue
  e in ApiError ->
    IO.puts("Status: #{e.status_code}")  # => 404
    IO.puts("Endpoint: #{e.endpoint}")    # => /users/99
end
```

### The message/1 Callback

Instead of computing the message in `exception/1`, you can define `message/1` for lazy message generation:

```elixir
defmodule InsufficientFundsError do
  defexception [:balance, :amount]

  @impl true
  def message(%{balance: balance, amount: amount}) do
    "Cannot withdraw #{amount}: only #{balance} available"
  end
end

raise InsufficientFundsError, balance: 50, amount: 100
# ** (InsufficientFundsError) Cannot withdraw 100: only 50 available
```

### The exception/1 Callback

Controls how `raise ExceptionType, opts` constructs the exception struct:

```elixir
defmodule ParseError do
  defexception [:message, :line, :column]

  @impl true
  def exception(opts) do
    line = Keyword.get(opts, :line, 0)
    column = Keyword.get(opts, :column, 0)
    input = Keyword.get(opts, :input, "")
    msg = "Parse error at #{line}:#{column} near '#{input}'"
    %__MODULE__{message: msg, line: line, column: column}
  end
end
```

## raise, rescue, and reraise

### raise/1 and raise/2

```elixir
# raise/1 with a string creates a RuntimeError
raise "something broke"

# raise/1 with an exception struct
raise %ArgumentError{message: "bad input"}

# raise/2 with a module and options
raise ArgumentError, message: "expected integer, got string"
raise ApiError, status_code: 503, endpoint: "/health"
```

### try/rescue

```elixir
try do
  dangerous_operation()
rescue
  e in SpecificError ->
    # Handle specific exception
    Logger.error("Specific: #{Exception.message(e)}")
    :error

  e in [TypeError, ArgumentError] ->
    # Handle multiple types in one clause
    Logger.error("Type/Arg: #{Exception.message(e)}")
    :error

  _ ->
    # Catch-all (usually discouraged)
    :unknown_error
end
```

### try/rescue/after

The `after` block always executes, regardless of whether an exception occurred:

```elixir
file = File.open!("data.txt")
try do
  IO.read(file, :all)
rescue
  e -> {:error, Exception.message(e)}
after
  File.close(file)  # Always runs, but return value is discarded
end
```

### reraise/3

Preserves the original stacktrace when re-raising:

```elixir
try do
  some_operation()
rescue
  e ->
    Logger.error("Failed: #{Exception.message(e)}")
    reraise e, __STACKTRACE__
end
```

Without `reraise`, using `raise e` would create a new stacktrace pointing to the rescue block instead of the original error location.

## Exceptions vs Tagged Tuples

### Tagged Tuple Pattern (Idiomatic Elixir)

```elixir
# Function returns {:ok, _} or {:error, _}
case File.read("config.json") do
  {:ok, content} -> Jason.decode(content)
  {:error, reason} -> {:error, "File error: #{reason}"}
end

# Using 'with' for chaining
with {:ok, content} <- File.read("config.json"),
     {:ok, data} <- Jason.decode(content) do
  {:ok, data}
else
  {:error, reason} -> {:error, reason}
end
```

### Exception Pattern (Bang Functions)

```elixir
# Functions ending in ! raise on failure
try do
  content = File.read!("config.json")
  Jason.decode!(content)
rescue
  e in File.Error -> {:error, Exception.message(e)}
  e in Jason.DecodeError -> {:error, Exception.message(e)}
end
```

### When to Use Each

| Use Tagged Tuples When... | Use Exceptions When... |
|--------------------------|----------------------|
| Errors are expected and normal | Errors are bugs or unexpected |
| Caller should decide how to handle | Something is fundamentally broken |
| You want composable pipelines (with) | You want to crash and let supervisor restart |
| Writing library APIs | Writing scripts or one-off tools |
| Multiple error types need distinct handling | The error should propagate up immediately |

### The Elixir Convention

Most standard library functions offer both patterns:

```elixir
# Tagged tuple version
File.read("path")        # => {:ok, content} | {:error, reason}
Map.fetch(map, key)      # => {:ok, value} | :error
Integer.parse("123")     # => {123, ""} | :error

# Exception (bang) version
File.read!("path")       # => content | raises File.Error
Map.fetch!(map, key)     # => value | raises KeyError
String.to_integer("123") # => 123 | raises ArgumentError
```

## "Let It Crash" Philosophy

In Elixir/OTP, you don't need to defensively catch every possible error:

```elixir
# DON'T do this (defensive, Java-style)
def process_user(id) do
  try do
    user = fetch_user!(id)
    try do
      send_email!(user)
    rescue
      _ -> Logger.error("email failed")
    end
  rescue
    _ -> Logger.error("user not found")
  end
end

# DO this (let it crash, supervisor restarts)
def process_user(id) do
  user = fetch_user!(id)
  send_email!(user)
end
```

The supervisor tree handles process failures. Only rescue when you have a **meaningful recovery strategy** -- not just to log and continue.

## Common Pitfalls

1. **Over-rescuing**: Don't wrap everything in try/rescue. Let processes crash and supervisors handle recovery.
2. **Using exceptions for control flow**: Exceptions are for exceptional situations, not for expected branching logic.
3. **Bare rescue**: Avoid `rescue _ ->` without specific types. It hides bugs.
4. **Forgetting reraise**: Using `raise e` instead of `reraise e, __STACKTRACE__` loses the original error location.
5. **Missing message field**: Custom exceptions must include `:message` in their fields or provide a default via `defexception message: "default"`.
