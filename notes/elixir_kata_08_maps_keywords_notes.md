# Kata 08: Maps & Keyword Lists

## The Concept

Maps and keyword lists are Elixir's key-value data structures. Maps are the go-to for most cases, while keyword lists shine for options and ordered/duplicate keys.

## Maps

Maps are the primary key-value store. Keys can be any type:

```elixir
# Atom keys (most common)
%{name: "Alice", age: 30}

# Any-type keys
%{"name" => "Alice", 1 => "one", :key => "value"}

# Empty map
%{}
```

### Accessing Values

```elixir
user = %{name: "Alice", age: 30}

# Dot notation (atom keys only, raises on missing key)
user.name       # => "Alice"
user.email      # ** (KeyError)

# Bracket notation (any key type, returns nil on missing)
user[:name]     # => "Alice"
user[:email]    # => nil

# Map.get with default
Map.get(user, :name)           # => "Alice"
Map.get(user, :email, "n/a")   # => "n/a"

# Map.fetch for explicit {:ok, val} / :error
Map.fetch(user, :name)   # => {:ok, "Alice"}
Map.fetch(user, :email)  # => :error
```

### Updating Maps (Immutably)

```elixir
user = %{name: "Alice", age: 30}

# Update syntax (key must already exist!)
%{user | name: "Bob"}           # => %{name: "Bob", age: 30}
%{user | email: "a@b.com"}     # ** (KeyError) — can't add new keys this way!

# Map.put (adds or updates)
Map.put(user, :email, "a@b.com")  # => %{name: "Alice", age: 30, email: "a@b.com"}
Map.put(user, :name, "Bob")       # => %{name: "Bob", age: 30}

# Map.delete
Map.delete(user, :age)  # => %{name: "Alice"}

# Map.merge
Map.merge(%{a: 1, b: 2}, %{b: 3, c: 4})  # => %{a: 1, b: 3, c: 4}
```

### Map Module Highlights

```elixir
Map.keys(%{a: 1, b: 2})       # => [:a, :b]
Map.values(%{a: 1, b: 2})     # => [1, 2]
Map.to_list(%{a: 1, b: 2})    # => [a: 1, b: 2]
Map.has_key?(%{a: 1}, :a)     # => true
Map.update(%{a: 1}, :a, 0, &(&1 + 1))  # => %{a: 2}
```

## Keyword Lists

Keyword lists are lists of `{atom, value}` tuples with special syntax:

```elixir
# These are equivalent
[name: "Alice", age: 30]
[{:name, "Alice"}, {:age, 30}]
```

### Key Properties

1. **Ordered** — Keys maintain insertion order
2. **Duplicate keys allowed** — `[a: 1, a: 2]` is valid
3. **Keys must be atoms** — No string or integer keys

```elixir
opts = [timeout: 5000, retry: true, retry: false]

Keyword.get(opts, :timeout)       # => 5000
Keyword.get(opts, :retry)         # => true (first occurrence)
Keyword.get_values(opts, :retry)  # => [true, false] (all occurrences)
```

### Common Use: Function Options

Keyword lists are the convention for optional function arguments:

```elixir
# Last argument can omit brackets
String.split("a.b.c", ".", trim: true)
# Same as:
String.split("a.b.c", ".", [trim: true])

# Your own functions
def connect(host, opts \\ []) do
  port = Keyword.get(opts, :port, 443)
  timeout = Keyword.get(opts, :timeout, 5000)
  # ...
end

connect("example.com", port: 8080, timeout: 10_000)
```

## Maps vs Keyword Lists

| Feature | Map | Keyword List |
|---------|-----|--------------|
| Key types | Any | Atoms only |
| Duplicate keys | No | Yes |
| Ordered | No* | Yes |
| Pattern matching | Yes | Limited |
| Access speed | O(log n) | O(n) |
| Primary use | Data storage | Options/config |

*Maps preserve insertion order in practice (since OTP 26), but this isn't guaranteed by the spec.

### When to Use Which

**Use Maps when:**
- You need key-value storage
- Keys can be any type
- You need fast access
- You need pattern matching

**Use Keyword Lists when:**
- Passing options to functions
- You need duplicate keys
- You need ordered keys
- Working with existing APIs that expect them

## Common Pitfalls

1. **`%{user | key: val}` requires the key to exist** — Use `Map.put/3` to add new keys
2. **`user.key` raises on missing keys** — Use `user[:key]` or `Map.get/3` for safe access
3. **Keyword lists are lists** — They have O(n) access, not O(1) like maps
4. **Don't confuse `%{a: 1}` with `[a: 1]`** — Map vs keyword list, very different types
