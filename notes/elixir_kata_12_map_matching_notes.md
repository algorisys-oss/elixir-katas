# Kata 12: Map Matching

## The Concept

Map pattern matching is **partial** — the pattern only needs to contain a subset of the map's keys. This is different from tuples and lists which require exact structure matches.

```elixir
%{name: name} = %{name: "Alice", age: 30, city: "NYC"}
# name = "Alice" — extra keys are ignored!
```

## Partial Matching

This is the key insight — you don't need to match all keys:

```elixir
# Match just what you need
%{status: status} = %{status: 200, body: "OK", headers: []}
# status = 200

# Empty map matches ANY map
%{} = %{a: 1, b: 2, c: 3}
# Always succeeds!
```

## String Keys vs Atom Keys

Be careful — the key type must match exactly:

```elixir
%{name: name} = %{name: "Alice"}        # Works (atom keys)
%{"name" => name} = %{"name" => "Alice"} # Works (string keys)
%{name: name} = %{"name" => "Alice"}     # ** (MatchError)!
```

## Nested Map Matching

Extract deeply nested values in one pattern:

```elixir
%{user: %{address: %{city: city}}} = %{
  user: %{
    name: "Alice",
    address: %{city: "NYC", zip: "10001"}
  }
}
# city = "NYC"
```

## Pattern Matching in Function Heads

Maps are commonly matched in function parameters:

```elixir
def greet(%{name: name, role: "admin"}) do
  "Hello, Admin #{name}!"
end

def greet(%{name: name}) do
  "Hello, #{name}!"
end

greet(%{name: "Alice", role: "admin"})  # "Hello, Admin Alice!"
greet(%{name: "Bob", role: "user"})     # "Hello, Bob!"
```

## The Update Syntax

`%{map | key: value}` updates an existing key (raises if key doesn't exist):

```elixir
user = %{name: "Alice", age: 30}
updated = %{user | age: 31}          # %{name: "Alice", age: 31}

%{user | height: 170}                # ** (KeyError) — key doesn't exist!
```

Use `Map.put/3` to add new keys:

```elixir
Map.put(user, :height, 170)  # %{name: "Alice", age: 30, height: 170}
```

## Matching with Guards

Combine map matching with guards for powerful dispatch:

```elixir
def process(%{type: "order", total: total}) when total > 100 do
  "Large order: $#{total}"
end

def process(%{type: "order"}) do
  "Standard order"
end
```

## Common Pitfalls

1. **Partial matching surprise**: `%{a: 1} = %{a: 1, b: 2}` succeeds — the extra key `b` is ignored.
2. **Can't match on map size**: There's no way to pattern match "a map with exactly 2 keys".
3. **Key type matters**: Atom keys and string keys are different — `%{name: _}` ≠ `%{"name" => _}`.
4. **Update syntax requires existing keys**: `%{map | new_key: val}` raises KeyError.
