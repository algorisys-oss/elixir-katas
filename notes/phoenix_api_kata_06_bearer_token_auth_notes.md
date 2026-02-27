# Kata 06: Bearer Token Authentication

## The Authorization Header

The `Authorization` header is the standard HTTP mechanism for sending credentials:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Format Rules

- **Scheme**: `Bearer` (case-sensitive, capital B)
- **Separator**: Single space between scheme and token
- **Token**: Any opaque string (JWT, API key, session token, etc.)

```elixir
# Extracting from Plug.Conn
case get_req_header(conn, "authorization") do
  ["Bearer " <> token] -> {:ok, String.trim(token)}
  [_other]             -> {:error, :invalid_format}
  []                   -> {:error, :missing_token}
end
```

### Why `get_req_header/2` Returns a List

HTTP allows multiple values for the same header. `get_req_header/2` always returns a list:

```elixir
get_req_header(conn, "authorization")
# => ["Bearer abc123"]     — one value
# => []                    — header not present
# => ["Bearer a", "Bearer b"] — multiple (rare, invalid for auth)
```

---

## The Module Plug Pattern

Phoenix plugs come in two forms: **function plugs** and **module plugs**.

### Function Plug

```elixir
# Simple — a function with arity 2
def my_plug(conn, _opts) do
  assign(conn, :foo, "bar")
end
```

### Module Plug

```elixir
# Structured — implements init/1 and call/2
defmodule MyAppWeb.Plugs.VerifyApiToken do
  @behaviour Plug
  import Plug.Conn

  # init/1 runs at COMPILE TIME
  # Use it to validate and transform options
  def init(opts) do
    # Example: ensure a required option is present
    Keyword.fetch!(opts, :token_source)
    opts
  end

  # call/2 runs at REQUEST TIME
  # Must return a %Plug.Conn{}
  def call(conn, opts) do
    source = Keyword.get(opts, :token_source, :header)
    # ... extract and validate token ...
    conn
  end
end
```

### init/1 vs call/2

| Aspect       | `init/1`                    | `call/2`                     |
|--------------|-----------------------------|------------------------------|
| When         | Compile time                | Every request                |
| Receives     | Options from `plug MyPlug, opts` | `conn` + result of `init/1` |
| Returns      | Transformed options         | `%Plug.Conn{}`               |
| Performance  | Run once                    | Must be fast                 |

---

## Halting the Connection

When authentication fails, you must **halt** the connection to prevent the request from reaching the controller:

```elixir
def call(conn, _opts) do
  case authenticate(conn) do
    {:ok, user} ->
      assign(conn, :current_user, user)

    {:error, reason} ->
      conn
      |> put_status(:unauthorized)
      |> Phoenix.Controller.json(%{errors: %{detail: reason}})
      |> halt()
      # ^ THIS IS CRITICAL — without halt(), the next plug still runs!
  end
end
```

### What `halt/1` Does

```elixir
halt(conn)
# Sets conn.halted = true
# Downstream plugs check this flag and skip execution
# The response is sent from THIS plug
```

### Common Mistake: Forgetting `halt/1`

```elixir
# BAD — responds with 401 but STILL runs the controller!
def call(conn, _opts) do
  conn
  |> put_status(:unauthorized)
  |> json(%{error: "nope"})
  # Missing halt()!
end

# GOOD — halts the pipeline
def call(conn, _opts) do
  conn
  |> put_status(:unauthorized)
  |> json(%{error: "nope"})
  |> halt()
end
```

---

## Returning 401 Unauthorized

The 401 status code means "not authenticated" (despite the name "Unauthorized"):

```elixir
conn
|> put_status(:unauthorized)  # 401
|> Phoenix.Controller.json(%{
  errors: %{detail: "Missing or invalid token"}
})
|> halt()
```

### 401 vs 403

| Code | Meaning           | When to Use                              |
|------|-------------------|------------------------------------------|
| 401  | Not authenticated | Missing/invalid token, expired session   |
| 403  | Not authorized    | Valid token, but user lacks permission   |

---

## Complete Token Verification Flow

```
Client sends request
    ↓
Authorization header present?
    ├─ No  → 401 "Missing Authorization header"
    ↓
Format is "Bearer <token>"?
    ├─ No  → 401 "Must use Bearer scheme"
    ↓
Token valid? (DB lookup, JWT verify, etc.)
    ├─ No  → 401 "Token is invalid or expired"
    ↓
assign(conn, :current_user, user)
    ↓
Controller action runs with conn.assigns.current_user
```

---

## Using the Plug in Your Router

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # Pipeline for authenticated API routes
  pipeline :api_auth do
    plug MyAppWeb.Plugs.VerifyApiToken
  end

  # Public API (no auth required)
  scope "/api", MyAppWeb.Api do
    pipe_through [:api]

    post "/auth/login", AuthController, :login
    post "/auth/register", AuthController, :register
  end

  # Protected API (auth required)
  scope "/api", MyAppWeb.Api do
    pipe_through [:api, :api_auth]

    resources "/users", UserController
    resources "/posts", PostController
  end
end
```

### Accessing the Current User in Controllers

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    # The plug already verified auth — current_user is guaranteed
    current_user = conn.assigns.current_user
    users = Accounts.list_users()
    json(conn, %{data: users})
  end
end
```

---

## Testing Token Auth

```elixir
defmodule MyAppWeb.Plugs.VerifyApiTokenTest do
  use MyAppWeb.ConnCase

  describe "call/2" do
    test "allows request with valid token" do
      user = insert(:user)
      token = generate_token(user)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyApiToken.call([])

      assert conn.assigns.current_user.id == user.id
      refute conn.halted
    end

    test "rejects request without token" do
      conn =
        build_conn()
        |> VerifyApiToken.call([])

      assert conn.status == 401
      assert conn.halted
    end

    test "rejects request with invalid token" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer invalid")
        |> VerifyApiToken.call([])

      assert conn.status == 401
      assert conn.halted
    end
  end
end
```
