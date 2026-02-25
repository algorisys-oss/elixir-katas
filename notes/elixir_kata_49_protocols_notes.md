# Kata 49: Protocols

## The Concept

**Protocols** are Elixir's mechanism for polymorphism. They define a contract (set of functions) that any data type can implement. The runtime dispatches to the correct implementation based on the first argument's type.

```elixir
# Define the contract
defprotocol Displayable do
  @doc "Returns a human-readable string"
  def display(data)
end

# Implement for different types
defimpl Displayable, for: BitString do
  def display(str), do: "String: #{str}"
end

defimpl Displayable, for: Integer do
  def display(n), do: "Number: #{n}"
end
```

## Defining Protocols

```elixir
defprotocol MyProtocol do
  @doc "A function that all implementations must provide"
  def my_function(data)

  @doc "Protocols can have multiple functions"
  def another_function(data, opts)
end
```

Key points:
- The **first argument** determines which implementation to use
- All functions in a protocol must take the dispatched type as their first argument
- Protocols can have multiple functions

## Implementing Protocols

### For structs

```elixir
defmodule User do
  defstruct [:name, :email]
end

defimpl Displayable, for: User do
  def display(%User{name: name, email: email}) do
    "#{name} <#{email}>"
  end
end
```

### For built-in types

```elixir
defimpl Displayable, for: Integer do
  def display(n), do: "Number: #{n}"
end

defimpl Displayable, for: Atom do
  def display(atom), do: "Atom: #{atom}"
end

defimpl Displayable, for: List do
  def display(list), do: "List with #{length(list)} items"
end
```

### Available types for `for:`

- `Atom`, `BitString`, `Float`, `Integer`
- `List`, `Map`, `Tuple`
- `Function`, `PID`, `Port`, `Reference`
- Any struct module name (e.g., `User`, `Order`)
- `Any` (fallback)

## How Protocol Dispatch Works

1. You call `Displayable.display(data)`
2. The runtime checks the type of `data`
3. It looks up the implementation module (e.g., `Displayable.User`)
4. It calls that module's `display/1` function
5. The result is returned

This dispatch is **cached** after the first call, so subsequent calls are fast.

## Fallback to Any

```elixir
defprotocol Describable do
  @fallback_to_any true
  def describe(data)
end

defimpl Describable, for: Any do
  def describe(data) do
    "A #{inspect(data.__struct__)}"
  end
end
```

Without `@fallback_to_any true`, calling a protocol on a type without an implementation raises `Protocol.UndefinedError`.

## @derive

Opt a struct into using the `Any` implementation at compile time:

```elixir
defprotocol Serializable do
  @fallback_to_any true
  def serialize(data)
end

defimpl Serializable, for: Any do
  def serialize(data), do: inspect(data)
end

defmodule Order do
  @derive [Serializable]  # Use Any's implementation
  defstruct [:id, :total]
end
```

**@derive vs @fallback_to_any:**
- `@fallback_to_any true` -- blanket fallback for ALL types without implementations
- `@derive` -- opt-in per struct, more explicit and intentional

## Protocol Consolidation

In production (Mix releases), Elixir **consolidates** protocols at compile time. Instead of runtime dispatch, it creates a lookup table, making protocol calls as fast as regular function calls.

```elixir
# In mix.exs, consolidation happens automatically in :prod
def project do
  [
    # ...
    consolidate_protocols: Mix.env() != :test
  ]
end
```

## Protocols vs Interfaces (OOP)

| Feature | Elixir Protocols | OOP Interfaces |
|---------|-----------------|----------------|
| Definition | Outside the type | Inside the class |
| Extension | Anyone can add impls | Class author decides |
| Dispatch | Runtime type check | vtable/compile-time |
| Coupling | Loose | Tight |

## Common Pitfalls

1. **Only first argument dispatches**: `defprotocol Combinable do def combine(a, b) end` -- only `a`'s type matters.
2. **Structs vs maps**: A protocol implementation for `Map` does NOT apply to structs. Structs need their own implementation.
3. **Forgetting @fallback_to_any**: Without it, calling on an unimplemented type raises at runtime.
4. **Performance in dev**: Protocol dispatch is slower in development mode (no consolidation). Don't benchmark protocols in dev.
