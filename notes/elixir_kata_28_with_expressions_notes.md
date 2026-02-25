# Kata 28: With Expressions

## The Concept

`with` is Elixir's tool for chaining multiple operations along the "happy path." Each step must pattern-match successfully for the next to execute. If any step fails, the chain short-circuits.

```elixir
with {:ok, user} <- find_user(name),
     {:ok, session} <- create_session(user) do
  {:ok, session}
else
  {:error, reason} -> {:error, reason}
end
```

## Basic Syntax

```elixir
with pattern1 <- expression1,
     pattern2 <- expression2,
     pattern3 <- expression3 do
  # Runs only if ALL patterns match
  success_body
else
  # Pattern match on the FIRST non-matching value
  error_pattern1 -> error_body1
  error_pattern2 -> error_body2
end
```

## How It Works Step by Step

1. Evaluate `expression1`, try to match against `pattern1`
2. If match succeeds, evaluate `expression2`, try to match against `pattern2`
3. Continue until all clauses match, then execute the `do` block
4. If any match **fails**, stop immediately:
   - Without `else`: return the non-matching value directly
   - With `else`: pattern-match the non-matching value against else clauses

## Without else

When there is no `else` block, the unmatched value is returned as-is:

```elixir
with {:ok, a} <- {:ok, 1},
     {:ok, b} <- {:error, :not_found},
     {:ok, c} <- {:ok, 3} do
  a + b + c
end
# => {:error, :not_found}
```

The second clause fails (`:error` doesn't match `:ok`), so `{:error, :not_found}` is returned directly. The third clause and `do` block never execute.

## With else

The `else` block lets you transform or normalize error values:

```elixir
with {:ok, content} <- File.read("config.json"),
     {:ok, parsed} <- Jason.decode(content) do
  {:ok, parsed}
else
  {:error, :enoent} -> {:error, "File not found"}
  {:error, %Jason.DecodeError{}} -> {:error, "Invalid JSON"}
  {:error, reason} -> {:error, "Unknown: #{inspect(reason)}"}
end
```

**Important**: If you use `else`, it must be exhaustive. An unhandled value in `else` raises `WithClauseError`.

## Variable Binding

Variables bound in earlier clauses are available in later clauses and the `do` block:

```elixir
with {:ok, user} <- find_user(id),
     {:ok, profile} <- load_profile(user),
     {:ok, avatar} <- fetch_avatar(profile) do
  # user, profile, and avatar are all available here
  %{user: user, profile: profile, avatar: avatar}
end
```

## Bare Expressions (=)

You can mix regular `=` assignments in with clauses:

```elixir
with {:ok, raw} <- fetch_data(),
     decoded = Base.decode64!(raw),
     {:ok, parsed} <- Jason.decode(decoded) do
  parsed
end
```

Bare `=` expressions always match (they raise on mismatch like regular pattern matching).

## Guards in with

You can add `when` guards to `<-` clauses:

```elixir
with {:ok, n} when n > 0 <- get_count(),
     {:ok, items} <- fetch_items(n) do
  {:ok, items}
end
```

## Refactoring Nested Case into with

### Before: Nested case (the "pyramid of doom")

```elixir
case fetch_user(id) do
  {:ok, user} ->
    case validate(user) do
      {:ok, valid} ->
        case save(valid) do
          {:ok, saved} -> {:ok, saved}
          {:error, r} -> {:error, r}
        end
      {:error, r} -> {:error, r}
    end
  {:error, r} -> {:error, r}
end
```

### After: with (flat and clear)

```elixir
with {:ok, user} <- fetch_user(id),
     {:ok, valid} <- validate(user),
     {:ok, saved} <- save(valid) do
  {:ok, saved}
else
  {:error, reason} -> {:error, reason}
end
```

The `with` version is:
- **Flat**: no nesting
- **Linear**: reads top-to-bottom
- **DRY**: error handling in one place
- **Extensible**: easy to add more steps

## When to Use with

| Use `with` when... | Use something else when... |
|---|---|
| Chaining {:ok, _} / {:error, _} operations | Simple true/false check (`if`) |
| Multiple steps that depend on each other | Matching one value against patterns (`case`) |
| Avoiding deeply nested case | Independent boolean conditions (`cond`) |
| Each step can fail independently | Single pattern match (`=`) |

## Common Patterns

### API request pipeline

```elixir
with {:ok, response} <- HTTPClient.get(url),
     {:ok, body} <- Jason.decode(response.body),
     {:ok, data} <- extract_data(body) do
  {:ok, data}
end
```

### Form validation

```elixir
with {:ok, params} <- validate_required(raw_params),
     {:ok, params} <- validate_types(params),
     {:ok, params} <- validate_business_rules(params) do
  create_record(params)
end
```

### Database transaction steps

```elixir
with {:ok, user} <- Repo.insert(user_changeset),
     {:ok, profile} <- Repo.insert(profile_changeset(user)),
     {:ok, _} <- send_welcome_email(user) do
  {:ok, user}
end
```

## Common Pitfalls

1. **Non-exhaustive else**: If you use `else`, handle ALL possible non-matching values or include `_ ->`.
2. **Overusing with**: For a single operation, just use `case`. `with` shines with 2+ chained steps.
3. **Forgetting <- vs =**: Use `<-` for operations that might not match; `=` for assignments that must succeed.
4. **Ignoring the return**: Without `else`, the raw non-matching value leaks out. Make sure callers handle it.
5. **Too many clauses**: If your `with` has 8+ clauses, consider breaking it into smaller functions.
