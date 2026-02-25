# Kata 80: Nested Data Access

## The Concept

Elixir provides a set of kernel functions and the **Access** module for navigating and transforming deeply nested data structures without verbose pattern matching. These tools work with maps, keyword lists, structs, lists, and tuples.

```elixir
data = %{
  users: [
    %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},
    %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}
  ],
  settings: %{theme: "dark", notifications: %{email: true, sms: false}}
}

# Get a deeply nested value
get_in(data, [:settings, :notifications, :email])
# => true

# Get all user names
get_in(data, [:users, Access.all(), :name])
# => ["Alice", "Bob"]
```

## Core Access Functions

### get_in/2

Retrieves a value from a nested structure using a list of keys:

```elixir
data = %{a: %{b: %{c: 42}}}

get_in(data, [:a, :b, :c])
# => 42

# Returns nil for missing keys
get_in(data, [:a, :x, :y])
# => nil
```

### put_in/3

Puts a value into a nested structure at the given path:

```elixir
data = %{settings: %{theme: "dark"}}

put_in(data, [:settings, :theme], "light")
# => %{settings: %{theme: "light"}}

# Works with Access functions for lists
data = %{users: [%{name: "Alice"}, %{name: "Bob"}]}
put_in(data, [:users, Access.at(0), :name], "Alicia")
# => %{users: [%{name: "Alicia"}, %{name: "Bob"}]}
```

### update_in/3

Updates a value by applying a function:

```elixir
data = %{stats: %{views: 10, likes: 5}}

update_in(data, [:stats, :views], &(&1 + 1))
# => %{stats: %{views: 11, likes: 5}}

# Transform all elements
data = %{scores: [10, 20, 30]}
update_in(data, [:scores, Access.all()], &(&1 * 2))
# => %{scores: [20, 40, 60]}
```

### pop_in/2

Removes a key and returns both the value and the updated structure:

```elixir
data = %{settings: %{theme: "dark", lang: "en"}}

pop_in(data, [:settings, :lang])
# => {"en", %{settings: %{theme: "dark"}}}

# Pop from a list
data = %{items: ["a", "b", "c"]}
pop_in(data, [:items, Access.at(1)])
# => {"b", %{items: ["a", "c"]}}
```

## The Access Module

The `Access` module provides functions that act as dynamic path components within `get_in`, `put_in`, `update_in`, and `pop_in`.

### Access.key/2

Accesses a map key with an optional default:

```elixir
data = %{user: %{name: "Alice"}}

get_in(data, [Access.key(:user), Access.key(:name)])
# => "Alice"

get_in(data, [Access.key(:user), Access.key(:age, 0)])
# => 0 (default value)
```

### Access.key!/1

Accesses a map key, raising `KeyError` if missing:

```elixir
data = %{user: %{name: "Alice"}}

get_in(data, [Access.key!(:user), Access.key!(:name)])
# => "Alice"

get_in(data, [Access.key!(:user), Access.key!(:missing)])
# ** (KeyError) key :missing not found
```

### Access.elem/1

Accesses a tuple element by index:

```elixir
data = %{result: {:ok, "hello"}}

get_in(data, [:result, Access.elem(1)])
# => "hello"
```

### Access.at/1

Accesses a list element by index (supports negative indices):

```elixir
data = %{items: ["a", "b", "c", "d"]}

get_in(data, [:items, Access.at(0)])
# => "a"

get_in(data, [:items, Access.at(-1)])
# => "d"
```

### Access.all/0

Traverses all elements in a list:

```elixir
data = %{users: [%{name: "Alice"}, %{name: "Bob"}]}

get_in(data, [:users, Access.all(), :name])
# => ["Alice", "Bob"]

update_in(data, [:users, Access.all(), :name], &String.upcase/1)
# => %{users: [%{name: "ALICE"}, %{name: "BOB"}]}
```

### Access.filter/1

Filters list elements by a predicate:

```elixir
data = %{users: [
  %{name: "Alice", active: true},
  %{name: "Bob", active: false},
  %{name: "Carol", active: true}
]}

get_in(data, [:users, Access.filter(& &1.active), :name])
# => ["Alice", "Carol"]
```

## Dynamic Paths

Since access paths are just lists, they can be built at runtime:

```elixir
data = %{a: %{b: %{c: "found!"}}}

# Build path dynamically
path = [:a, :b, :c]
get_in(data, path)
# => "found!"

# Conditional path building
field = :name
get_in(%{user: %{name: "Alice"}}, [:user, field])
# => "Alice"
```

## Pattern Matching vs get_in/put_in

### Pattern Matching Approach

```elixir
# Reading deeply nested data
%{users: [%{address: %{city: city}} | _]} = data
# city => "Portland"

# Updating deeply nested data (verbose!)
%{users: [first | rest]} = data
updated_address = %{first.address | city: "Eugene"}
updated_first = %{first | address: updated_address}
%{data | users: [updated_first | rest]}
```

### get_in/put_in Approach

```elixir
# Reading deeply nested data
get_in(data, [:users, Access.at(0), :address, :city])
# => "Portland"

# Updating deeply nested data (concise!)
put_in(data, [:users, Access.at(0), :address, :city], "Eugene")
```

| Aspect | Pattern Matching | get_in / put_in |
|--------|-----------------|-----------------|
| Readability | Verbose for deep nesting | Concise path syntax |
| Dynamic paths | Not possible | Paths are lists, built at runtime |
| Missing keys | MatchError or need defaults | Returns nil gracefully |
| Compile-time checks | Pattern validated at compile time | Runtime only |
| List traversal | Manual Enum required | Access.all() / Access.filter() |

## Practical Patterns

### Navigating API Responses

```elixir
response = %{
  "data" => %{
    "users" => [
      %{"id" => 1, "profile" => %{"avatar" => "alice.png"}},
      %{"id" => 2, "profile" => %{"avatar" => "bob.png"}}
    ]
  }
}

# Get all avatars
get_in(response, ["data", "users", Access.all(), "profile", "avatar"])
# => ["alice.png", "bob.png"]
```

### Config Map Navigation

```elixir
config = %{
  database: %{host: "localhost", port: 5432, pool_size: 10},
  cache: %{ttl: 3600, max_size: 1000}
}

# Read with defaults
get_in(config, [:database, Access.key(:timeout, 5000)])
# => 5000

# Update nested config
update_in(config, [:database, :pool_size], &(&1 + 5))
# => %{database: %{host: "localhost", port: 5432, pool_size: 15}, ...}
```

### Combining Access Functions

```elixir
data = %{
  departments: [
    %{name: "Engineering", employees: [
      %{name: "Alice", salary: 100_000},
      %{name: "Bob", salary: 90_000}
    ]},
    %{name: "Marketing", employees: [
      %{name: "Carol", salary: 85_000}
    ]}
  ]
}

# Get all employee names across all departments
get_in(data, [:departments, Access.all(), :employees, Access.all(), :name])
# => [["Alice", "Bob"], ["Carol"]]

# Give everyone a 10% raise
update_in(data, [:departments, Access.all(), :employees, Access.all(), :salary], &round(&1 * 1.1))
```

## Common Pitfalls

1. **Structs and Access**: Structs don't implement the Access behaviour by default. Use `Access.key/1` or implement the `Access` behaviour explicitly.
2. **Nil propagation**: `get_in` returns `nil` on missing keys, which can hide bugs. Use `Access.key!/1` for required keys.
3. **Nested lists return nested results**: `Access.all()` inside `Access.all()` returns nested lists, not flat lists. Use `List.flatten/1` if needed.
4. **put_in creates intermediate maps**: `put_in(%{}, [:a, :b], 1)` raises because `:a` doesn't exist yet. The path must already exist for intermediate keys.
