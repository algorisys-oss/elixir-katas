# Kata 10: Tuple Matching

## The Concept

Tuples are Elixir's go-to for returning structured results. Pattern matching on tuples lets you destructure them cleanly and handle different cases.

```elixir
# Destructure a tuple
{a, b, c} = {1, "hello", :ok}
# a = 1, b = "hello", c = :ok
```

## Tagged Tuples

The most important Elixir convention: **tagged tuples** for success/failure:

```elixir
# Success
{:ok, result} = {:ok, 42}       # result = 42

# Failure
{:error, reason} = {:error, :not_found}  # reason = :not_found
```

## Matching in Case Expressions

This is where tuple matching truly shines:

```elixir
case File.read("data.txt") do
  {:ok, contents} ->
    IO.puts("Got: #{contents}")

  {:error, :enoent} ->
    IO.puts("File not found!")

  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

## Tuple Size Must Match

Unlike maps, tuple matching requires the **exact** number of elements:

```elixir
{a, b} = {1, 2, 3}     # ** (MatchError) — 2 elements vs 3
{a, b, _} = {1, 2, 3}  # Works! a = 1, b = 2
```

## Nested Tuple Matching

You can match nested tuples in one expression:

```elixir
{:ok, {name, age}} = {:ok, {"Alice", 30}}
# name = "Alice", age = 30

{:error, {code, message}} = {:error, {404, "Not Found"}}
# code = 404, message = "Not Found"
```

## Common Patterns

```elixir
# GenServer reply
{:reply, response, new_state}

# With expression
with {:ok, user} <- fetch_user(id),
     {:ok, profile} <- fetch_profile(user) do
  {:ok, profile}
end

# Ignore elements you don't need
{:ok, _headers, body} = HTTP.get(url)
```

## Common Pitfalls

1. **Forgetting to handle :error**: Always match both `{:ok, _}` and `{:error, _}` in production code.
2. **Atom tags must match exactly**: `{:ok, val}` won't match `{:success, val}`.
3. **Tuple size mismatch**: `{a, b} = {1}` fails — sizes must be equal.
