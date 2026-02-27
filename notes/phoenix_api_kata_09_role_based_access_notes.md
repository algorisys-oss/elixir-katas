# Kata 09: Role-Based Access Control (RBAC)

## What is RBAC?

Role-Based Access Control assigns permissions to **roles**, not individual users. Users are assigned roles, and the system checks the role when deciding access.

```
User "Alice" → role: "admin" → can: read, write, delete
User "Bob"   → role: "editor" → can: read, write
User "Carol" → role: "viewer" → can: read
```

---

## Role Hierarchy

A common pattern is a **hierarchical** role model where higher roles include all permissions of lower roles:

```
admin (3) > editor (2) > viewer (1)
```

```elixir
@role_hierarchy %{
  "admin"  => 3,
  "editor" => 2,
  "viewer" => 1
}

defp has_role?(user_role, required_role) do
  user_level = Map.get(@role_hierarchy, user_role, 0)
  required_level = Map.get(@role_hierarchy, required_role, 0)
  user_level >= required_level
end
```

This means:
- `has_role?("admin", "viewer")` → true (admin can do everything a viewer can)
- `has_role?("viewer", "editor")` → false (viewer cannot do editor things)

---

## The RequireRole Plug

```elixir
defmodule MyAppWeb.Plugs.RequireRole do
  @behaviour Plug
  import Plug.Conn

  @role_hierarchy %{"admin" => 3, "editor" => 2, "viewer" => 1}

  def init(role) when is_binary(role), do: role

  def call(conn, required_role) do
    user = conn.assigns[:current_user]

    if user && has_role?(user.role, required_role) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> Phoenix.Controller.json(%{
        errors: %{detail: "Forbidden — requires #{required_role} role"}
      })
      |> halt()
    end
  end

  defp has_role?(user_role, required_role) do
    user_level = Map.get(@role_hierarchy, user_role, 0)
    required_level = Map.get(@role_hierarchy, required_role, 0)
    user_level >= required_level
  end
end
```

### Key Points

- `init/1` receives the role string from the plug declaration
- `call/2` reads `current_user` from `conn.assigns` (set by the auth plug)
- Returns 403 Forbidden (not 401 Unauthorized) — the user IS authenticated, just not authorized
- Uses `halt/1` to stop the pipeline

---

## Scope-Based Pipelines in the Router

Different routes require different minimum roles:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # Shared authentication
  pipeline :api_auth do
    plug MyAppWeb.Plugs.VerifyApiToken
  end

  # Role-specific pipelines
  pipeline :require_viewer do
    plug MyAppWeb.Plugs.RequireRole, "viewer"
  end

  pipeline :require_editor do
    plug MyAppWeb.Plugs.RequireRole, "editor"
  end

  pipeline :require_admin do
    plug MyAppWeb.Plugs.RequireRole, "admin"
  end

  # Read-only routes (viewer+)
  scope "/api", MyAppWeb.Api do
    pipe_through [:api, :api_auth, :require_viewer]

    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    get "/posts", PostController, :index
  end

  # Write routes (editor+)
  scope "/api", MyAppWeb.Api do
    pipe_through [:api, :api_auth, :require_editor]

    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
  end

  # Destructive routes (admin only)
  scope "/api", MyAppWeb.Api do
    pipe_through [:api, :api_auth, :require_admin]

    delete "/users/:id", UserController, :delete
    delete "/posts/:id", PostController, :delete
  end
end
```

---

## Combining Auth + Role Plugs

The plug pipeline runs in order:

```
Request
  ↓
:api pipeline        → Parses JSON, sets content-type
  ↓
VerifyApiToken       → Extracts Bearer token, assigns current_user
  ↓                    (halts with 401 if no/invalid token)
RequireRole("editor") → Checks current_user.role >= "editor"
  ↓                    (halts with 403 if insufficient role)
Controller action    → Runs if both plugs pass
```

### Order Matters!

```elixir
# CORRECT: auth first, then role check
pipe_through [:api, :api_auth, :require_admin]

# WRONG: role check before auth — current_user is nil!
pipe_through [:api, :require_admin, :api_auth]
```

---

## 401 vs 403

| Status | Name         | Meaning                              |
|--------|--------------|--------------------------------------|
| 401    | Unauthorized | Not authenticated — who are you?     |
| 403    | Forbidden    | Authenticated but not authorized     |

```elixir
# Auth plug failure (no/bad token)
conn |> put_status(:unauthorized) |> halt()   # 401

# Role plug failure (valid user, wrong role)
conn |> put_status(:forbidden) |> halt()      # 403
```

---

## Alternative: Controller-Level Role Checks

For finer-grained control, you can check roles in the controller:

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    if current_user.role == "admin" do
      user = Accounts.get_user!(id)
      Accounts.delete_user(user)
      send_resp(conn, :no_content, "")
    else
      conn
      |> put_status(:forbidden)
      |> json(%{errors: %{detail: "Only admins can delete users"}})
    end
  end
end
```

### When to Use Router vs Controller Level

| Approach         | Best For                                    |
|------------------|---------------------------------------------|
| Router pipeline  | Broad role requirements (all admin routes)  |
| Controller check | Conditional logic (owner OR admin)          |
| Policy module    | Complex rules (see Kata 10)                 |

---

## Testing Role-Based Access

```elixir
describe "RequireRole plug" do
  test "allows admin to access admin routes" do
    admin = %User{role: "admin"}
    conn =
      build_conn()
      |> assign(:current_user, admin)
      |> RequireRole.call("admin")

    refute conn.halted
  end

  test "blocks viewer from admin routes" do
    viewer = %User{role: "viewer"}
    conn =
      build_conn()
      |> assign(:current_user, viewer)
      |> RequireRole.call("admin")

    assert conn.halted
    assert conn.status == 403
  end

  test "allows editor to access viewer routes (hierarchy)" do
    editor = %User{role: "editor"}
    conn =
      build_conn()
      |> assign(:current_user, editor)
      |> RequireRole.call("viewer")

    refute conn.halted
  end
end
```
