# Kata 50: Built-in Protocols

## The Concept

Elixir ships with several important protocols that you can implement for your own types. The most commonly used are **String.Chars**, **Inspect**, and **Enumerable**.

## String.Chars

Converts a term to a string. Powers `to_string/1` and string interpolation.

```elixir
defmodule Temperature do
  defstruct [:degrees, :unit]
end

defimpl String.Chars, for: Temperature do
  def to_string(%Temperature{degrees: d, unit: :celsius}), do: "#{d}°C"
  def to_string(%Temperature{degrees: d, unit: :fahrenheit}), do: "#{d}°F"
end

temp = %Temperature{degrees: 100, unit: :celsius}
"Water boils at #{temp}"  #=> "Water boils at 100°C"
to_string(temp)           #=> "100°C"
```

**When to implement**: When your type needs to be displayed to users or used in string interpolation.

**Already implemented for**: atoms, integers, floats, binaries (strings), `Date`, `DateTime`, `Time`, `URI`, etc.

## Inspect

Converts a term to an algebra document for pretty-printing. Powers `inspect/1`, `IO.inspect/1`, and IEx display.

```elixir
defmodule SecretKey do
  defstruct [:key, :name]
end

defimpl Inspect, for: SecretKey do
  def inspect(%SecretKey{name: name}, _opts) do
    "#SecretKey<#{name}, key: [REDACTED]>"
  end
end

key = %SecretKey{key: "super-secret-123", name: "API Key"}
inspect(key)  #=> "#SecretKey<API Key, key: [REDACTED]>"
```

**When to implement**: When you want to hide sensitive data or improve debug output.

**Important**: The `inspect/2` callback receives an `Inspect.Opts` struct as the second argument. Use `Inspect.Algebra` for proper formatting:

```elixir
defimpl Inspect, for: MyStruct do
  import Inspect.Algebra

  def inspect(%MyStruct{name: name, items: items}, opts) do
    concat([
      "#MyStruct<",
      to_doc(name, opts),
      ", items: ",
      to_doc(items, opts),
      ">"
    ])
  end
end
```

## Enumerable

Makes a data type work with all `Enum` and `Stream` functions. This is the most complex built-in protocol.

```elixir
defprotocol Enumerable do
  def count(enumerable)
  def member?(enumerable, element)
  def reduce(enumerable, acc, fun)
  def slice(enumerable)
end
```

### Implementing Enumerable

The key function is `reduce/3`. The others can delegate to list-based implementations:

```elixir
defmodule Countdown do
  defstruct [:from]

  defimpl Enumerable do
    def count(%Countdown{from: n}), do: {:ok, n + 1}

    def member?(%Countdown{from: n}, elem) do
      {:ok, is_integer(elem) and elem >= 0 and elem <= n}
    end

    def reduce(%Countdown{from: n}, acc, fun) do
      Enumerable.List.reduce(Enum.to_list(n..0//-1), acc, fun)
    end

    def slice(%Countdown{from: n}) do
      {:ok, n + 1, fn start, len, _step ->
        Enum.to_list(n..0//-1) |> Enum.slice(start, len)
      end}
    end
  end
end

countdown = %Countdown{from: 5}
Enum.to_list(countdown)          #=> [5, 4, 3, 2, 1, 0]
Enum.map(countdown, &(&1 * 10))  #=> [50, 40, 30, 20, 10, 0]
Enum.filter(countdown, &(&1 > 3)) #=> [5, 4]
```

**When to implement**: When your type represents a collection that should work with Enum functions.

## Collectable

The inverse of Enumerable -- lets you build a collection. Powers `Enum.into/2` and `for` comprehensions.

```elixir
defimpl Collectable, for: MyCollection do
  def into(original) do
    collector_fun = fn
      collection, {:cont, elem} -> add(collection, elem)
      collection, :done -> collection
      _collection, :halt -> :ok
    end

    {original, collector_fun}
  end
end

# Now you can do:
Enum.into([1, 2, 3], %MyCollection{})
```

## List.Chars

Converts to a charlist. Mainly for Erlang interop:

```elixir
defimpl List.Chars, for: MyType do
  def to_charlist(data), do: to_string(data) |> String.to_charlist()
end
```

## Summary Table

| Protocol | Purpose | Powers | Implement for |
|----------|---------|--------|--------------|
| String.Chars | User display | `to_string/1`, interpolation | User-facing types |
| Inspect | Debug display | `inspect/1`, IEx | All custom types |
| Enumerable | Iteration | `Enum.*`, `Stream.*` | Collection types |
| Collectable | Building | `Enum.into/2`, `for` | Collection types |
| List.Chars | Charlist | `to_charlist/1` | Erlang interop |

## Common Pitfalls

1. **String.Chars vs Inspect**: String.Chars is for users, Inspect is for developers. Don't confuse them.
2. **Enumerable complexity**: Implementing Enumerable correctly (especially `reduce/3`) is tricky. Test thoroughly.
3. **Inspect and sensitive data**: The default Inspect shows all fields. Always implement custom Inspect for types with secrets.
4. **Performance**: Enumerable implementations that convert to lists first lose the benefit of lazy evaluation.
