# Kata 47: Structs

## The Concept

**Structs** are extensions built on top of maps that provide compile-time checks, default values, and polymorphic dispatch. They are defined inside a module using `defstruct`.

```elixir
defmodule User do
  defstruct [:name, :email, :age]
end

%User{name: "Alice", email: "alice@example.com", age: 30}
```

## Defining Structs

### Atom list (nil defaults)

```elixir
defmodule Basic do
  defstruct [:name, :email]
end

%Basic{}  #=> %Basic{name: nil, email: nil}
```

### Keyword list (with defaults)

```elixir
defmodule Config do
  defstruct host: "localhost", port: 4000, ssl: false
end

%Config{}  #=> %Config{host: "localhost", port: 4000, ssl: false}
```

### Mixed (some with defaults, some without)

```elixir
defmodule Order do
  defstruct [:product, :quantity, status: :pending, total: 0.0]
end
```

## @enforce_keys

Force certain fields to be provided at creation time:

```elixir
defmodule Invoice do
  @enforce_keys [:customer, :amount]
  defstruct [:customer, :amount, paid: false]
end

%Invoice{}  # ** (ArgumentError) the following keys must also be given...
%Invoice{customer: "Alice", amount: 100}  # Works!
```

## Update Syntax

Create a new struct with modified fields (the original is unchanged):

```elixir
user = %User{name: "Alice", email: "alice@example.com", age: 30}
updated = %User{user | name: "Bob", age: 25}

# user is still %User{name: "Alice", ...}
# updated is %User{name: "Bob", email: "alice@example.com", age: 25}
```

**Important**: The update syntax only works with an existing struct of the same type. You cannot use it to add new fields.

## Pattern Matching on Structs

```elixir
def greet(%User{name: name}), do: "Hello, #{name}!"

def admin?(%User{role: :admin}), do: true
def admin?(%User{}), do: false

# Match on struct type without destructuring
def is_user?(%User{}), do: true
def is_user?(_), do: false
```

## Struct vs Map

| Feature | Struct | Map |
|---------|--------|-----|
| Type checking | Compile-time field checking | No field restrictions |
| Default values | Built-in via defstruct | No built-in defaults |
| Unknown keys | Compile error | Silently allowed |
| Enumerable | Not by default | Yes |
| Access protocol | Not by default | Yes |
| Underlying type | Map with `__struct__` key | Plain map |

### The __struct__ key

A struct is just a map with a special `__struct__` key:

```elixir
%User{name: "Alice"} == %{__struct__: User, name: "Alice", email: nil, age: nil}
# true
```

This means you can use map functions, but it's discouraged:

```elixir
Map.keys(%User{})  # [:__struct__, :name, :email, :age]
```

## Structs and Protocols

Structs can implement protocols, which is how you make them work with the rest of the Elixir ecosystem:

```elixir
defimpl String.Chars, for: User do
  def to_string(user), do: "#{user.name} <#{user.email}>"
end

"#{%User{name: "Alice", email: "a@b.com"}}"  #=> "Alice <a@b.com>"
```

## Common Patterns

### Struct as a module's main type

```elixir
defmodule User do
  defstruct [:name, :email, :age]

  @type t :: %__MODULE__{
    name: String.t(),
    email: String.t(),
    age: non_neg_integer()
  }

  @spec new(String.t(), String.t(), non_neg_integer()) :: t()
  def new(name, email, age) do
    %__MODULE__{name: name, email: email, age: age}
  end
end
```

## Common Pitfalls

1. **Structs are not maps for Access**: `user[:name]` does not work by default. Use `user.name` instead.
2. **Structs are not enumerable**: `Enum.map(%User{}, ...)` raises unless you implement `Enumerable`.
3. **Update syntax requires same type**: `%User{some_map | name: "x"}` fails if `some_map` is not a `%User{}`.
4. **Module scope**: Structs can only be defined inside a module, and only one struct per module.
