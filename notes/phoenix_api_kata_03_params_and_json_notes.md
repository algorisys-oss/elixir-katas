# Kata 03: Params & JSON Encoding

## The Jason Library

Phoenix uses [Jason](https://hex.pm/packages/jason) as its default JSON library. It's configured in `config/config.exs`:

```elixir
config :phoenix, :json_library, Jason
```

### Encoding: Elixir to JSON

```elixir
# Maps with atom keys
Jason.encode!(%{name: "Alice", age: 30})
# => "{\"age\":30,\"name\":\"Alice\"}"

# Maps with string keys
Jason.encode!(%{"name" => "Alice", "age" => 30})
# => "{\"age\":30,\"name\":\"Alice\"}"

# Lists
Jason.encode!([1, 2, 3])
# => "[1,2,3]"

# Nested structures
Jason.encode!(%{user: %{name: "Alice", roles: ["admin", "editor"]}})
# => "{\"user\":{\"name\":\"Alice\",\"roles\":[\"admin\",\"editor\"]}}"

# Pretty printing
Jason.encode!(%{name: "Alice"}, pretty: true)
# => "{\n  \"name\": \"Alice\"\n}"
```

### Decoding: JSON to Elixir

```elixir
Jason.decode!(~s|{"name": "Alice", "age": 30}|)
# => %{"name" => "Alice", "age" => 30}

# Note: keys are ALWAYS strings after decode
# NOT atoms — this is intentional for safety

# Safe decode (returns {:ok, _} or {:error, _})
case Jason.decode(user_input) do
  {:ok, data} -> process(data)
  {:error, _} -> handle_bad_json()
end
```

### Why String Keys?

Atoms are never garbage collected in the BEAM VM. If user input could create atoms, a malicious client could exhaust memory by sending requests with millions of unique JSON keys. Phoenix intentionally keeps decoded JSON keys as strings.

---

## How Phoenix Parses JSON Bodies

When a request arrives with `Content-Type: application/json`, Phoenix's `Plug.Parsers` automatically decodes the body:

```elixir
# In your endpoint.ex (already configured by mix phx.new)
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library()
```

This means by the time your controller receives params, the JSON body is already an Elixir map.

---

## Params Merging: Path + Query + Body

Phoenix merges three sources of parameters into a single `params` map:

### 1. Path Parameters
Defined in the route with `:param_name`:

```elixir
# Route: PUT /api/users/:id
# Request: PUT /api/users/42
# Path params: %{"id" => "42"}
```

### 2. Query Parameters
From the URL query string:

```elixir
# Request: GET /api/users?page=2&sort=name
# Query params: %{"page" => "2", "sort" => "name"}
```

### 3. Body Parameters
From the JSON request body:

```elixir
# Request body: {"user": {"name": "Alice", "email": "alice@example.com"}}
# Body params: %{"user" => %{"name" => "Alice", "email" => "alice@example.com"}}
```

### The Merged Result

All three are merged into a single map:

```elixir
# PUT /api/users/42?admin=true
# Body: {"user": {"name": "Alice"}}

# Your controller receives:
%{
  "id" => "42",                    # path
  "admin" => "true",               # query (always strings!)
  "user" => %{"name" => "Alice"}   # body
}
```

**Priority**: Body params override query params, which override path params (though in practice, keys rarely collide).

---

## Pattern Matching Params in Controller Actions

The real power comes from Elixir's pattern matching:

```elixir
# Extract exactly what you need
def show(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)
  json(conn, %{data: user})
end

# Extract nested params
def create(conn, %{"user" => user_params}) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      conn |> put_status(:created) |> json(%{data: user})
    {:error, changeset} ->
      conn |> put_status(422) |> json(%{errors: format_errors(changeset)})
  end
end

# Extract multiple params at once
def update(conn, %{"id" => id, "user" => user_params}) do
  user = Accounts.get_user!(id)
  # id is from path, user_params from body
end

# Optional params with default
def index(conn, params) do
  page = Map.get(params, "page", "1") |> String.to_integer()
  per_page = Map.get(params, "per_page", "20") |> String.to_integer()

  users = Accounts.list_users(page: page, per_page: per_page)
  json(conn, %{data: users, meta: %{page: page, per_page: per_page}})
end
```

---

## Common Gotchas

### 1. All Values Are Strings

```elixir
# Query params are ALWAYS strings
# GET /api/users?page=2&active=true

%{"page" => "2", "active" => "true"}  # Not integer 2, not boolean true

# You must convert:
page = String.to_integer(params["page"])
active = params["active"] == "true"
```

### 2. JSON Numbers Stay Numbers

```elixir
# But JSON body values keep their types
# Body: {"age": 30, "score": 9.5, "active": true}

%{"age" => 30, "score" => 9.5, "active" => true}  # Integer, float, boolean
```

### 3. Missing Keys

```elixir
# If a client omits expected params, pattern match will fail
def create(conn, %{"user" => user_params}) do
  # Raises MatchError if body doesn't have "user" key
end

# Safer approach:
def create(conn, params) do
  case Map.fetch(params, "user") do
    {:ok, user_params} -> # process
    :error -> conn |> put_status(400) |> json(%{error: "Missing 'user' parameter"})
  end
end
```
