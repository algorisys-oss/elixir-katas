# Kata 48: Struct Validation

## The Concept

Raw struct creation (`%User{name: "Alice"}`) performs no runtime validation on field values. **Constructor patterns** wrap struct creation in functions that validate inputs and return `{:ok, struct}` or `{:error, reason}`.

```elixir
# Without validation -- anything goes
%User{name: nil, age: -5}  # Silently creates an invalid struct

# With validation -- invalid data is caught
User.new(%{name: nil, age: -5})
#=> {:error, "name is required and must be non-empty"}
```

## The new/1 Constructor Pattern

The most common pattern is a `new/1` function that validates inputs:

```elixir
defmodule Email do
  @enforce_keys [:address]
  defstruct [:address]

  def new(address) when is_binary(address) do
    if String.contains?(address, "@") do
      {:ok, %Email{address: address}}
    else
      {:error, "invalid email: missing @"}
    end
  end

  def new(_), do: {:error, "address must be a string"}
end
```

## Validation with `with`

Chain multiple validations using `with`. The first failure short-circuits:

```elixir
defmodule User do
  @enforce_keys [:name, :email, :age]
  defstruct [:name, :email, :age, role: :user]

  def new(attrs) do
    with {:ok, name}  <- validate_name(attrs),
         {:ok, email} <- validate_email(attrs),
         {:ok, age}   <- validate_age(attrs) do
      {:ok, %User{name: name, email: email, age: age,
                   role: Map.get(attrs, :role, :user)}}
    end
  end

  defp validate_name(%{name: name}) when is_binary(name) and byte_size(name) > 0,
    do: {:ok, name}
  defp validate_name(_), do: {:error, "name is required"}

  defp validate_email(%{email: email}) when is_binary(email) do
    if String.contains?(email, "@"), do: {:ok, email},
      else: {:error, "email must contain @"}
  end
  defp validate_email(_), do: {:error, "email is required"}

  defp validate_age(%{age: age}) when is_integer(age) and age > 0 and age < 150,
    do: {:ok, age}
  defp validate_age(_), do: {:error, "age must be 1-149"}
end
```

## Bang (!) Variants

Provide both `new/1` (returns tuple) and `new!/1` (raises on error):

```elixir
def new!(attrs) do
  case new(attrs) do
    {:ok, struct}    -> struct
    {:error, reason} -> raise ArgumentError, reason
  end
end
```

**When to use which:**
- `new/1` -- when invalid input is expected (user input, external data)
- `new!/1` -- when invalid input is a programming error (internal data)

## Collecting All Errors

Sometimes you need all validation errors at once (e.g., form validation):

```elixir
def new(attrs) do
  errors =
    []
    |> validate_username(attrs)
    |> validate_email(attrs)
    |> validate_password(attrs)

  case errors do
    []     -> {:ok, build_struct(attrs)}
    errors -> {:error, Enum.reverse(errors)}
  end
end

defp validate_username(errors, %{username: u})
  when is_binary(u) and byte_size(u) >= 3, do: errors
defp validate_username(errors, _),
  do: ["username must be at least 3 chars" | errors]
```

## @enforce_keys vs Constructor Validation

| Feature | @enforce_keys | Constructor (new/1) |
|---------|--------------|-------------------|
| When checked | Compile time | Runtime |
| What's checked | Field presence | Field values |
| Error type | ArgumentError | {:error, reason} |
| Can validate values | No | Yes |
| Can validate relationships | No | Yes |

**Best practice**: Use both together for maximum safety:

```elixir
defmodule Money do
  @enforce_keys [:amount, :currency]   # Compile-time: fields must exist
  defstruct [:amount, :currency]

  def new(amount, currency) do         # Runtime: values must be valid
    with {:ok, a} <- validate_amount(amount),
         {:ok, c} <- validate_currency(currency) do
      {:ok, %Money{amount: a, currency: c}}
    end
  end
end
```

## Validation Pipeline Pattern

For complex validations, build a pipeline:

```elixir
defmodule Validator do
  def validate(data, validations) do
    Enum.reduce(validations, {:ok, data}, fn
      validation, {:ok, data} -> validation.(data)
      _validation, error -> error
    end)
  end
end

# Usage:
Validator.validate(attrs, [
  &validate_name/1,
  &validate_email/1,
  &validate_age/1
])
```

## Common Pitfalls

1. **Forgetting to validate**: If your struct has a `new/1`, consider making `defstruct` private or documenting that direct creation bypasses validation.
2. **Inconsistent return types**: Always return `{:ok, _}` or `{:error, _}` from constructors. Don't mix raising and returning.
3. **Over-validation**: Not every struct needs a constructor. Simple data containers can use `defstruct` directly.
4. **Mutable mindset**: Remember that validation creates a new struct -- it doesn't "fix" the input data.
