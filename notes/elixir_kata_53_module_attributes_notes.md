# Kata 53: Module Attributes

## The Concept

Module attributes in Elixir serve multiple purposes:
1. **Documentation** (`@moduledoc`, `@doc`)
2. **Type specifications** (`@spec`, `@type`)
3. **Compile-time constants** (custom attributes)
4. **Temporary storage** during compilation (accumulating attributes)

## Documentation Attributes

### @moduledoc

Documents the entire module:

```elixir
defmodule MyApp.Calculator do
  @moduledoc """
  A simple calculator module for basic arithmetic operations.

  ## Examples

      iex> Calculator.add(1, 2)
      3

      iex> Calculator.multiply(3, 4)
      12
  """
end
```

Use `@moduledoc false` to hide a module from documentation generation.

### @doc

Documents a single function:

```elixir
@doc """
Adds two numbers together.

## Parameters
  - a: The first number
  - b: The second number

## Examples

    iex> Calculator.add(1, 2)
    3
"""
def add(a, b), do: a + b
```

Use `@doc false` to hide a function from documentation.

### Runtime access

Documentation is stored in the compiled BEAM file and accessible at runtime:

```elixir
{:docs_v1, _, :elixir, _, module_doc, _, function_docs} = Code.fetch_docs(Enum)
```

## Type Specifications

### @spec

Declares function argument and return types:

```elixir
@spec add(number(), number()) :: number()
def add(a, b), do: a + b

@spec divide(number(), number()) :: {:ok, float()} | {:error, String.t()}
def divide(_, 0), do: {:error, "division by zero"}
def divide(a, b), do: {:ok, a / b}
```

### @type, @typep, @opaque

Define custom types:

```elixir
defmodule User do
  @type t :: %__MODULE__{
    name: String.t(),
    email: String.t(),
    age: non_neg_integer()
  }

  @type role :: :admin | :user | :moderator

  @typep internal_id :: pos_integer()  # Private type

  @opaque token :: binary()  # Public name, hidden structure

  defstruct [:name, :email, :age]
end
```

**Conventions:**
- Use `t()` for the module's main type
- Use `@type` for types other modules should reference
- Use `@typep` for internal types
- Use `@opaque` when the structure is an implementation detail

### Common built-in types

```elixir
term()              # Any value
atom()              # Any atom
binary()            # Binary (including strings)
String.t()          # UTF-8 string
number()            # integer() | float()
integer()           # Any integer
non_neg_integer()   # 0 or positive
pos_integer()       # Positive only
boolean()           # true | false
list(t)             # List of type t
map()               # Any map
keyword()           # Keyword list
pid()               # Process ID
```

## Compile-Time Constants

Module attributes as constants are evaluated at compile time and inlined:

```elixir
defmodule Config do
  @max_retries 3
  @timeout_ms 5_000
  @api_url "https://api.example.com/v2"

  def fetch(path) do
    # @max_retries is replaced with 3 at compile time
    do_fetch("#{@api_url}/#{path}", @max_retries)
  end
end
```

### Computed at compile time

```elixir
defmodule BuildInfo do
  @compile_time DateTime.utc_now() |> DateTime.to_string()
  @env Mix.env()

  def compile_time, do: @compile_time  # Always returns the same time
  def env, do: @env
end
```

**Important**: The expression is evaluated once at compile time. `@compile_time` will always return when the module was compiled, not the current time.

### Warning about anonymous functions

Do NOT store anonymous functions in module attributes:

```elixir
# BAD -- anonymous functions in module attributes
@validator fn x -> x > 0 end

# GOOD -- use a named function
defp validator(x), do: x > 0
```

Anonymous functions in module attributes capture the compilation environment and can cause subtle issues.

## Accumulating Attributes

Build up lists during compilation:

```elixir
defmodule Router do
  Module.register_attribute(__MODULE__, :routes, accumulate: true)

  @routes {:get, "/users", :list_users}
  @routes {:post, "/users", :create_user}
  @routes {:get, "/users/:id", :get_user}

  def routes, do: @routes
  # Returns list in reverse order of declaration
end
```

### With @before_compile

Generate functions based on accumulated data:

```elixir
defmodule EventRegistry do
  Module.register_attribute(__MODULE__, :events, accumulate: true)

  @events :user_created
  @events :user_updated
  @events :user_deleted

  @before_compile __MODULE__

  defmacro __before_compile__(_env) do
    quote do
      def all_events, do: @events
      def event_count, do: length(@events)
    end
  end
end
```

## Special Module Attributes

| Attribute | Purpose |
|-----------|---------|
| `@moduledoc` | Module documentation |
| `@doc` | Function documentation |
| `@spec` | Type specification |
| `@type` / `@typep` / `@opaque` | Type definitions |
| `@behaviour` | Declare behaviour implementation |
| `@callback` | Behaviour callback definition |
| `@impl` | Mark callback implementation |
| `@enforce_keys` | Required struct fields |
| `@derive` | Derive protocol implementation |
| `@compile` | Compiler options |
| `@before_compile` | Hook before compilation finishes |
| `@after_compile` | Hook after compilation finishes |
| `@deprecated` | Mark function as deprecated |
| `@dialyzer` | Dialyzer options |
| `@external_resource` | Register external file dependency |

## Common Pitfalls

1. **Not constants at runtime**: Module attributes are compile-time only. `@value = something` does NOT update at runtime.
2. **Anonymous functions**: Never store anonymous functions in module attributes.
3. **Redefining without accumulate**: Without `accumulate: true`, each `@attr value` overwrites the previous value.
4. **Forgotten @doc false**: Internal helper functions show up in docs unless you use `@doc false`.
5. **@spec mismatch**: A wrong `@spec` won't cause a compile error but Dialyzer will catch it.
