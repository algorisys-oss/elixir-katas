# Kata 35: Changesets & Validation

## What is a Changeset?

An `Ecto.Changeset` is a data structure that:

1. **Casts** incoming parameters (filtering permitted fields, type-converting values)
2. **Validates** the data (accumulating errors without raising exceptions)
3. **Tracks** which fields have changed relative to the original struct

A changeset is NOT saved to the database. It is just a data container that describes what should change and whether that change is valid.

```elixir
import Ecto.Changeset

user = %MyApp.Accounts.User{}
attrs = %{email: "alice@example.com", username: "alice"}

changeset = user
|> cast(attrs, [:email, :username])
|> validate_required([:email, :username])
|> validate_format(:email, ~r/@/)

changeset.valid?   # => true or false
changeset.errors   # => [] or [{:email, {"is invalid", []}}]
changeset.changes  # => %{email: "alice@example.com", username: "alice"}
```

---

## cast/4

`cast/4` is the entry point for most changesets. It:

- Filters out fields NOT in the permitted list
- Converts string keys to atom keys
- Type-converts values (e.g. `"25"` to `25` for `:integer` fields)

```elixir
# Signature:
cast(data_or_changeset, params, permitted_fields, opts \\ [])

user = %User{}
params = %{
  "email"   => "alice@example.com",
  "username" => "alice",
  "role"    => "admin",    # not in permitted — dropped
  "foo"     => "bar"       # not in schema at all — dropped
}

cs = cast(user, params, [:email, :username])
cs.changes  # => %{email: "alice@example.com", username: "alice"}
```

### get_field vs get_change

```elixir
# get_field: returns changed value OR original struct value
email = get_field(changeset, :email)

# get_change: only returns if in changeset.changes, else nil
email = get_change(changeset, :email)
```

---

## validate_required/3

Fields that must be present and non-empty:

```elixir
|> validate_required([:email, :username])

# With custom message:
|> validate_required([:email], message: "Email is required")
```

A field is considered blank if:
- It is `nil`
- It is an empty string `""`
- It is a string with only whitespace

---

## validate_format/4

The field value must match a regular expression:

```elixir
|> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
|> validate_format(:phone, ~r/^\d{10}$/,
     message: "must be 10 digits")
```

---

## validate_length/3

Works for strings (character count) and lists (element count):

```elixir
|> validate_length(:username, min: 2, max: 30)
|> validate_length(:password, min: 8)
|> validate_length(:bio, max: 500)
|> validate_length(:tags, min: 1, max: 10)  # list

# is: exact length
|> validate_length(:code, is: 6)
```

---

## validate_number/3

For integer, float, and decimal fields:

```elixir
|> validate_number(:age, greater_than_or_equal_to: 13)
|> validate_number(:price, greater_than: 0)
|> validate_number(:discount, less_than_or_equal_to: 100)

# Options:
# :less_than, :greater_than
# :less_than_or_equal_to, :greater_than_or_equal_to
# :equal_to
```

---

## validate_inclusion / validate_exclusion

```elixir
# Must be one of these values:
|> validate_inclusion(:role, ["admin", "editor", "viewer"])
|> validate_inclusion(:status, [:active, :suspended])

# Must NOT be one of these:
|> validate_exclusion(:username, ["admin", "root", "system"])
```

---

## validate_confirmation/3

Two fields must match (classic password confirmation):

```elixir
schema "users" do
  field :password,              :string, virtual: true
  field :password_confirmation, :string, virtual: true
end

def changeset(user, attrs) do
  user
  |> cast(attrs, [:password, :password_confirmation])
  |> validate_confirmation(:password, required: true)
end
```

If `:password` is `"secret"` but `:password_confirmation` is `"Secret"`, the changeset is invalid.

---

## validate_acceptance/3

Used for checkbox fields (like "I agree to the terms"):

```elixir
field :terms_accepted, :boolean, virtual: true

|> validate_acceptance(:terms_accepted)
# Invalid unless terms_accepted is true
```

---

## Custom Validators

### Method 1: validate_change/3

```elixir
|> validate_change(:username, fn :username, value ->
  if String.contains?(value, " ") do
    [username: "cannot contain spaces"]
  else
    []  # no errors — empty list means valid
  end
end)
```

### Method 2: Private function returning changeset

```elixir
defp validate_password_strength(changeset) do
  validate_change(changeset, :password, fn _, pw ->
    cond do
      String.length(pw) < 8 ->
        [password: "must be at least 8 characters"]
      not String.match?(pw, ~r/[0-9]/) ->
        [password: "must contain at least one number"]
      not String.match?(pw, ~r/[A-Z]/) ->
        [password: "must contain at least one uppercase letter"]
      true ->
        []
    end
  end)
end
```

### Method 3: add_error/4

```elixir
defp check_reserved_username(changeset) do
  reserved = ["admin", "root", "system", "support"]
  username = get_field(changeset, :username)

  if username in reserved do
    add_error(changeset, :username, "is reserved")
  else
    changeset
  end
end
```

---

## DB Constraints

Constraints are checked at the database level (when `Repo.insert/update` is called). They convert DB errors into changeset errors. A matching constraint must exist in the database.

```elixir
# Requires a unique index in the migration:
# create unique_index(:users, [:email])
|> unique_constraint(:email)

# Composite unique constraint:
|> unique_constraint([:user_id, :post_id],
     name: :user_post_likes_pkey)

# Foreign key constraint:
|> foreign_key_constraint(:user_id)

# CHECK constraint in DB:
|> check_constraint(:age,
     name: :age_must_be_positive,
     message: "must be greater than 0")
```

---

## put_change / force_change

```elixir
# put_change: set a field without going through cast
changeset = put_change(changeset, :slug, "my-post-title")

# force_change: set even if the value hasn't changed
# Useful to trigger database triggers or touch updated_at
changeset = force_change(changeset, :updated_at, DateTime.utc_now())
```

---

## cast_assoc / cast_embed

For nested associations and embedded schemas:

```elixir
# cast_assoc: for has_many/belongs_to associations
def changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body])
  |> cast_assoc(:comments, with: &Comment.changeset/2)
end

# cast_embed: for embedded schemas
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name])
  |> cast_embed(:address,
       with: &Address.changeset/2,
       required: true)
end
```

---

## Multiple Changeset Functions

It is idiomatic Ecto to have **multiple changeset functions** for different contexts:

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email,    :string
    field :username, :string
    field :role,     :string, default: "member"
    field :password_hash, :string
    field :password, :string, virtual: true
  end

  # For new user registration:
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password])
    |> validate_required([:email, :username, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 8)
    |> hash_password()
    |> unique_constraint(:email)
  end

  # For profile updates (no password required):
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> validate_length(:username, min: 2, max: 30)
  end

  # For admin operations (can change role):
  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :role])
    |> validate_inclusion(:role, ["admin", "editor", "member"])
    |> unique_constraint(:email)
  end

  defp hash_password(%{valid?: true, changes: %{password: pw}} = cs) do
    put_change(cs, :password_hash, Bcrypt.hash_pwd_salt(pw))
  end
  defp hash_password(cs), do: cs
end
```

---

## Reading Errors

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    # persist succeeded
    {:ok, user}

  {:error, changeset} ->
    # changeset.errors has all errors:
    changeset.errors
    # => [email: {"has already been taken", [constraint: :unique, ...]},
    #     username: {"can't be blank", [validation: :required]}]

    # Traverse to a flat map (useful for API responses):
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    # => %{email: ["has already been taken"], username: ["can't be blank"]}
end
```

In Phoenix, `CoreComponents` provides `translate_errors/1` which does the traversal automatically for use in forms.

---

## Key Takeaways

1. Changesets **separate** validation logic from persistence — valid? does not query the DB
2. `cast/4` is the security gate — only permitted fields pass through
3. Validation errors **accumulate** — all fields are checked, not just the first invalid one
4. **DB constraints** (unique_constraint, foreign_key_constraint) are checked at `Repo.insert` time
5. Use **multiple changeset functions** for different operations (registration, profile update, admin)
6. Custom validators are just functions: take a changeset, return a changeset
7. `add_error/4` and `validate_change/3` are the two ways to add errors manually
