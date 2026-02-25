# Kata 51: Behaviours

## The Concept

**Behaviours** define a set of functions (callbacks) that a module must implement. They provide compile-time contract checking, ensuring that implementing modules conform to an expected interface.

```elixir
# Define a behaviour
defmodule Parser do
  @callback parse(String.t()) :: {:ok, term()} | {:error, String.t()}
  @callback extensions() :: [String.t()]
end

# Implement it
defmodule JsonParser do
  @behaviour Parser

  @impl Parser
  def parse(input), do: Jason.decode(input)

  @impl Parser
  def extensions, do: [".json"]
end
```

## Defining Behaviours

Use `@callback` to declare required functions:

```elixir
defmodule Storage do
  @callback store(key :: String.t(), value :: term()) :: :ok | {:error, term()}
  @callback fetch(key :: String.t()) :: {:ok, term()} | {:error, :not_found}
  @callback delete(key :: String.t()) :: :ok
end
```

Callback specs use the same type syntax as `@spec`, with named parameters for documentation:

```elixir
@callback process(
  input :: binary(),
  opts :: keyword()
) :: {:ok, result :: term()} | {:error, reason :: String.t()}
```

## Implementing Behaviours

```elixir
defmodule FileStorage do
  @behaviour Storage

  @impl Storage
  def store(key, value) do
    File.write(key, :erlang.term_to_binary(value))
  end

  @impl Storage
  def fetch(key) do
    case File.read(key) do
      {:ok, data} -> {:ok, :erlang.binary_to_term(data)}
      {:error, _} -> {:error, :not_found}
    end
  end

  @impl Storage
  def delete(key), do: File.rm(key)
end
```

### The @impl attribute

`@impl` serves two purposes:
1. **Documentation**: Clearly marks which functions fulfill behaviour callbacks
2. **Validation**: The compiler warns if `@impl` is used on a non-callback function

```elixir
@impl Storage
def store(key, value), do: ...  # Good

@impl Storage
def helper(x), do: ...  # Warning: helper/1 is not a callback
```

## Compile-Time Checking

If you forget to implement a callback, the compiler warns:

```elixir
defmodule IncompleteStorage do
  @behaviour Storage

  @impl Storage
  def store(key, value), do: :ok
  # Missing fetch/1 and delete/1!
end

# Compiler output:
# warning: function fetch/1 required by behaviour Storage is not implemented
# warning: function delete/1 required by behaviour Storage is not implemented
```

## Optional Callbacks

Mark callbacks as optional using `@optional_callbacks`:

```elixir
defmodule EventHandler do
  @callback init(opts :: keyword()) :: {:ok, state :: term()}
  @callback handle_event(event :: term(), state :: term()) :: {:ok, state :: term()}
  @callback terminate(reason :: term(), state :: term()) :: :ok

  @optional_callbacks terminate: 2
end
```

Implementing modules won't get warnings for missing optional callbacks.

## Dynamic Dispatch

Behaviours enable dynamic dispatch via module names:

```elixir
# Configuration
config :my_app, storage_backend: FileStorage

# Usage
defmodule MyApp do
  def store(key, value) do
    backend = Application.get_env(:my_app, :storage_backend)
    backend.store(key, value)
  end
end
```

This is a powerful pattern for:
- **Testing**: Swap real implementations for mocks
- **Configuration**: Choose implementations at deploy time
- **Strategy pattern**: Select algorithms at runtime

## Default Implementations with `use`

Combine behaviours with `__using__` to provide defaults:

```elixir
defmodule Serializer do
  @callback serialize(term()) :: binary()
  @callback deserialize(binary()) :: {:ok, term()} | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Serializer

      @impl Serializer
      def serialize(term), do: :erlang.term_to_binary(term)

      defoverridable serialize: 1
    end
  end
end

defmodule CustomSerializer do
  use Serializer

  # serialize/1 has a default, only need deserialize/1
  @impl Serializer
  def deserialize(binary) do
    {:ok, :erlang.binary_to_term(binary)}
  end
end
```

## Real-World Examples

Elixir and its ecosystem use behaviours extensively:

| Behaviour | Callbacks | Used for |
|-----------|-----------|----------|
| `GenServer` | `init/1`, `handle_call/3`, `handle_cast/2`, ... | Server processes |
| `Supervisor` | `init/1` | Supervision trees |
| `Application` | `start/2`, `stop/1` | OTP applications |
| `Plug` | `init/1`, `call/2` | HTTP middleware |
| `Phoenix.Controller` | Various | Web controllers |
| `Ecto.Type` | `type/0`, `cast/1`, `dump/1`, `load/1` | Custom DB types |

## Common Pitfalls

1. **Behaviours vs Protocols**: Behaviours are for module-level contracts. Protocols are for data-type polymorphism. Don't confuse them.
2. **No runtime enforcement**: Behaviours only check at compile time. A module could technically not implement all callbacks if warnings are ignored.
3. **@impl is optional but recommended**: Without `@impl`, callback functions look like regular functions, hurting readability.
4. **One module, multiple behaviours**: A module can implement multiple behaviours, but this can lead to callback name collisions.
