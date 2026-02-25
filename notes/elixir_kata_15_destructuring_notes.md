# Kata 15: Destructuring in Practice

## The Concept

Real-world Elixir code often involves complex nested data structures. Destructuring lets you reach into these structures and extract exactly what you need in a single pattern.

## Nested Map Destructuring

```elixir
response = %{
  user: %{
    name: "Alice",
    address: %{
      city: "NYC",
      zip: "10001"
    }
  },
  meta: %{
    request_id: "abc123"
  }
}

# Extract city in one pattern
%{user: %{address: %{city: city}}} = response
# city = "NYC"
```

## API Response Destructuring

```elixir
{:ok, %{status: status, body: %{"data" => data, "meta" => %{"total" => total}}}} =
  api_response

# Now you have: status, data, total
```

## Keyword List Destructuring

```elixir
opts = [host: "localhost", port: 5432, database: "mydb"]

# In function arguments
def connect(opts) do
  host = Keyword.get(opts, :host, "localhost")
  port = Keyword.get(opts, :port, 5432)
  # ...
end

# Or pattern match (first key only):
[{:host, host} | _] = opts
```

## Chained Extraction with `with`

When you need to extract from multiple sources:

```elixir
with {:ok, %{body: body}} <- HTTP.get(url),
     {:ok, %{"users" => [first | _]}} <- Jason.decode(body),
     %{"name" => name, "email" => email} <- first do
  "#{name} <#{email}>"
else
  {:error, reason} -> "Failed: #{reason}"
end
```

## Function Head Destructuring

Extract and dispatch in one step:

```elixir
def handle_event("save", %{"user" => %{"name" => name, "email" => email}}, socket) do
  # name and email are already extracted!
end

def handle_info({:user_joined, %{name: name}}, socket) do
  # Destructured the message and payload
end
```

## Struct Destructuring

```elixir
%User{name: name, role: role} = current_user
# Also validates that current_user is a %User{} struct
```

## Common Pitfalls

1. **Over-destructuring**: Don't extract everything — only what you need. Use `_` for the rest.
2. **String vs atom keys**: API responses typically use string keys (`"name"`), Elixir structs use atoms (`:name`).
3. **Missing keys**: If a key doesn't exist in the map, the match fails — use `Map.get/3` for optional keys.
4. **Deep nesting**: If extraction is too deep, consider intermediate variables for readability.
