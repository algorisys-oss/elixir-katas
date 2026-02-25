# Kata 16: Pattern Matching Challenges

## The Concept

This kata puts your pattern matching skills to the test with increasingly difficult challenges. Each challenge gives you a data structure and asks you to write a pattern that extracts specific values.

## Tips for Pattern Matching

### Start from the outside in
```elixir
# Given: {:ok, %{users: [%{name: "Alice"} | _]}}
# To extract "Alice":
# 1. Outer: {:ok, inner}
# 2. Inner: %{users: users}
# 3. Users: [first | _]
# 4. First: %{name: name}
# Combined: {:ok, %{users: [%{name: name} | _]}}
```

### Use `_` liberally
You don't need to match everything:
```elixir
# Only want the second element?
[_, second | _] = [1, 2, 3, 4, 5]
```

### Remember partial map matching
Maps only need the keys you care about:
```elixir
%{name: name} = %{name: "Alice", age: 30, email: "alice@example.com"}
```

### Pin when you need to assert
```elixir
expected_status = 200
{:ok, %{status: ^expected_status, body: body}} = response
```

## Difficulty Progression

1. **Basic**: Simple value extraction from tuples and lists
2. **Intermediate**: Map destructuring, head/tail patterns
3. **Advanced**: Nested structures, pin operator, multiple extractions
4. **Expert**: Complex real-world patterns (API responses, configs)

## Common Patterns to Know

```elixir
# Extract from tagged tuple
{:ok, value} = result

# Head and tail
[first | rest] = list

# Second element
[_, second | _] = list

# Nested map
%{outer: %{inner: value}} = data

# Function clause matching
def process({:ok, %{data: data}}), do: handle(data)
def process({:error, reason}), do: log(reason)
```

## When Matching Fails

A `MatchError` means your pattern doesn't match the data. Common causes:
- Wrong tuple size
- Missing map key
- Wrong literal value
- Type mismatch (atom vs string key)
