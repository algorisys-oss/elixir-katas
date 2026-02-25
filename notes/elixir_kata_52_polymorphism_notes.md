# Kata 52: Polymorphism Patterns

## The Concept

Elixir provides three main ways to achieve polymorphism:
1. **Protocols** -- type-based dispatch, open for extension
2. **Behaviours** -- module-based contracts with compile-time checking
3. **Pattern Matching** -- value-based dispatch, simplest and fastest

Each has different trade-offs. Choosing the right one depends on your specific needs.

## Protocols

Best for: **Extending behavior for types you don't own.**

```elixir
defprotocol Area do
  def calculate(shape)
end

defimpl Area, for: Circle do
  def calculate(%Circle{radius: r}), do: :math.pi() * r * r
end

defimpl Area, for: Rectangle do
  def calculate(%Rectangle{w: w, h: h}), do: w * h
end

# Third parties can add implementations without modifying Area!
defimpl Area, for: Triangle do
  def calculate(%Triangle{base: b, height: h}), do: 0.5 * b * h
end
```

**Key properties:**
- Open: anyone can add implementations
- Dispatches on first argument's type
- Runtime dispatch (cached)
- Raises if no implementation exists

## Behaviours

Best for: **Defining contracts that modules must fulfill.**

```elixir
defmodule Storage do
  @callback store(String.t(), term()) :: :ok
  @callback fetch(String.t()) :: {:ok, term()} | :error
end

defmodule S3Storage do
  @behaviour Storage
  @impl Storage
  def store(key, value), do: # ...
  @impl Storage
  def fetch(key), do: # ...
end

# Dynamic dispatch via module name
storage = Application.get_env(:app, :storage)
storage.store("key", "value")
```

**Key properties:**
- Closed: implementing modules must declare `@behaviour`
- Compile-time checking
- Dispatch via module names
- Great for dependency injection and testing

## Pattern Matching

Best for: **Simple dispatch on a fixed set of known shapes.**

```elixir
defmodule Formatter do
  def format({:ok, value}), do: "Success: #{inspect(value)}"
  def format({:error, reason}), do: "Error: #{reason}"
  def format(:loading), do: "Loading..."
end

defmodule Shape do
  def area(:circle, %{radius: r}), do: :math.pi() * r * r
  def area(:rect, %{w: w, h: h}), do: w * h
  def area(:triangle, %{base: b, height: h}), do: 0.5 * b * h
end
```

**Key properties:**
- Closed: adding types requires modifying the function
- Fastest: compiled clauses, no runtime lookup
- Simplest: no boilerplate
- Cannot be extended by third parties

## Decision Tree

```
Do external modules need to add implementations?
  YES → Use a Protocol
  NO  ↓

Do you need compile-time checking of implementations?
  YES → Use a Behaviour
  NO  ↓

Are you dispatching on a fixed set of known shapes?
  YES → Use Pattern Matching
  NO  ↓

Do you need to dispatch on the data's type?
  YES → Use a Protocol
  NO  → Use a Behaviour or Pattern Matching
```

## Side-by-Side Comparison

| Feature | Protocol | Behaviour | Pattern Match |
|---------|----------|-----------|---------------|
| Extension | Open | Closed | Closed |
| Dispatch | Type at runtime | Module at runtime | Compile-time |
| Checking | Runtime error | Compile warning | Runtime error |
| Performance | Dynamic (cached) | Direct call | Fastest |
| Use case | Type polymorphism | Module contracts | Value branching |

## Real-World Examples in Phoenix

Phoenix uses all three:

### Protocols in Phoenix
```elixir
# Phoenix.Param -- converts data to URL parameters
defimpl Phoenix.Param, for: MyStruct do
  def to_param(%MyStruct{id: id}), do: to_string(id)
end

# Phoenix.HTML.Safe -- marks content as safe HTML
defimpl Phoenix.HTML.Safe, for: MyStruct do
  def to_iodata(%MyStruct{name: name}), do: name
end
```

### Behaviours in Phoenix
```elixir
# Phoenix.Controller is a behaviour
defmodule MyController do
  use Phoenix.Controller  # Sets up @behaviour
end

# Plug is a behaviour
defmodule MyPlug do
  @behaviour Plug
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end
```

### Pattern Matching in Phoenix
```elixir
# Router pattern matching
get "/users/:id", UserController, :show
post "/users", UserController, :create

# Controller action matching
def show(conn, %{"id" => id}), do: ...
def index(conn, %{"page" => page}), do: ...
def index(conn, _params), do: ...
```

## Guidelines

1. **Start simple**: Begin with pattern matching. Escalate when needed.
2. **Use protocols for data types**: When the same operation should work on different types.
3. **Use behaviours for modules**: When you need swappable implementations of the same contract.
4. **Combine approaches**: A behaviour can use protocols internally. Pattern matching works everywhere.

## Common Pitfalls

1. **Over-engineering**: Don't use protocols for a fixed set of types -- pattern matching is simpler.
2. **Protocol for module dispatch**: Protocols dispatch on data types, not modules. Use behaviours for module-level contracts.
3. **Behaviour for type dispatch**: Behaviours don't know about data types. Use protocols for type-based polymorphism.
4. **Ignoring pattern matching**: It's the simplest tool and often the best choice.
