# Kata 10: Policy Modules

## The Problem with Role-Only Access Control

Role-based plugs answer: "Does this user have the right role for this **route**?"

But many real-world decisions require more context:
- Can this user edit **this specific post**? (ownership check)
- Can this user delete **this comment** on someone else's post? (relationship check)
- Can this user view **this draft post**? (resource state check)

**Policy modules** answer: "Can **this user** perform **this action** on **this specific resource**?"

---

## The authorize/3 Pattern

```elixir
defmodule MyApp.Policy do
  @doc """
  authorize(user, action, resource) -> :ok | {:error, :forbidden}
  """

  # Admin override — first clause, matches any action/resource
  def authorize(%{role: "admin"}, _action, _resource), do: :ok

  # Post policies
  def authorize(_user, :view, %Post{published: true}), do: :ok
  def authorize(%{id: uid}, :view, %Post{owner_id: uid}), do: :ok
  def authorize(%{id: uid}, :edit, %Post{owner_id: uid}), do: :ok
  def authorize(%{id: uid}, :delete, %Post{owner_id: uid}), do: :ok

  # Comment policies
  def authorize(_user, :view, %Comment{}), do: :ok
  def authorize(%{id: uid}, :edit, %Comment{owner_id: uid}), do: :ok
  def authorize(%{id: uid}, :delete, %Comment{owner_id: uid}), do: :ok

  # Catch-all: deny everything not explicitly allowed
  def authorize(_user, _action, _resource), do: {:error, :forbidden}
end
```

### How It Works

1. Elixir tries each clause **in order** from top to bottom
2. The first clause whose pattern matches wins
3. If no clause matches, the catch-all at the bottom denies access
4. **Default deny** — if you forget a clause, access is denied (safe failure mode)

---

## Ownership Checks

The `%{id: uid}` pattern in both user and resource is key:

```elixir
# The variable `uid` appears in BOTH patterns — Elixir requires them to be equal
def authorize(%{id: uid}, :edit, %Post{owner_id: uid}), do: :ok
#                   ^^^                           ^^^
#                   These must be the same value!
```

This is equivalent to:

```elixir
def authorize(%{id: uid}, :edit, %Post{owner_id: owner_id}) when uid == owner_id do
  :ok
end
```

---

## Admin Override

The admin clause uses underscore `_` to match any action and resource:

```elixir
def authorize(%{role: "admin"}, _action, _resource), do: :ok
```

This **must be the first clause** — if it were after the ownership checks, it would never be reached for non-owner admins.

### Why Pattern Order Matters

```elixir
# CORRECT: admin override first
def authorize(%{role: "admin"}, _action, _resource), do: :ok
def authorize(%{id: uid}, :edit, %Post{owner_id: uid}), do: :ok
def authorize(_user, _action, _resource), do: {:error, :forbidden}

# WRONG: catch-all first — nothing else ever runs!
def authorize(_user, _action, _resource), do: {:error, :forbidden}
def authorize(%{role: "admin"}, _action, _resource), do: :ok  # Dead code!
```

---

## Using Policies in Controllers

```elixir
defmodule MyAppWeb.Api.PostController do
  use MyAppWeb, :controller

  # action_fallback handles {:error, :forbidden}
  action_fallback MyAppWeb.FallbackController

  def update(conn, %{"id" => id, "post" => params}) do
    user = conn.assigns.current_user
    post = Posts.get_post!(id)

    # Policy check — returns :ok or {:error, :forbidden}
    with :ok <- Policy.authorize(user, :edit, post),
         {:ok, updated} <- Posts.update_post(post, params) do
      json(conn, %{data: updated})
    end
    # If authorize returns {:error, :forbidden},
    # FallbackController sends 403
  end
end
```

### FallbackController Integration

```elixir
defmodule MyAppWeb.FallbackController do
  use MyAppWeb, :controller

  # Handle policy denial
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: MyAppWeb.ErrorJSON)
    |> render(:"403")
  end

  # ... other error clauses
end
```

---

## Bodyguard-Style Policies

The [Bodyguard](https://github.com/schrockwell/bodyguard) library formalizes this pattern with a `@behaviour`:

```elixir
defmodule MyApp.Posts.Policy do
  @behaviour Bodyguard.Policy

  def authorize(:create, %User{role: role}, _post) when role in ["admin", "editor"] do
    :ok
  end

  def authorize(:edit, %User{id: uid}, %Post{owner_id: uid}), do: :ok
  def authorize(:edit, %User{role: "admin"}, _post), do: :ok

  def authorize(:delete, %User{id: uid}, %Post{owner_id: uid}), do: :ok
  def authorize(:delete, %User{role: "admin"}, _post), do: :ok

  def authorize(_, _, _), do: {:error, :forbidden}
end
```

Usage:

```elixir
# In the controller:
with :ok <- Bodyguard.permit(MyApp.Posts.Policy, :edit, user, post) do
  # ...
end
```

### Per-Resource vs Centralized Policies

| Approach                | Pros                            | Cons                        |
|------------------------|---------------------------------|-----------------------------|
| One Policy module       | Single source of truth          | Can get large               |
| Per-resource policies   | Focused, smaller modules        | Spread across many files    |
| Bodyguard behaviour     | Standardized interface          | Extra dependency            |

---

## Complex Policy Examples

### Conditional on Resource State

```elixir
# Can only edit published posts (not archived)
def authorize(%{id: uid}, :edit, %Post{owner_id: uid, status: :published}), do: :ok
def authorize(%{id: uid}, :edit, %Post{owner_id: uid, status: :draft}), do: :ok
# Archived posts cannot be edited by anyone except admins
def authorize(_user, :edit, %Post{status: :archived}), do: {:error, :forbidden}
```

### Relationship-Based Access

```elixir
# Team members can view team resources
def authorize(%{team_id: tid}, :view, %Project{team_id: tid}), do: :ok

# Organization admins can manage any team in their org
def authorize(%{org_id: oid, role: "org_admin"}, _action, %Team{org_id: oid}), do: :ok
```

### Time-Based Access

```elixir
def authorize(user, :edit, %Post{} = post) do
  # Can only edit posts less than 24 hours old
  age = DateTime.diff(DateTime.utc_now(), post.inserted_at, :hour)
  if age < 24, do: :ok, else: {:error, :forbidden}
end
```

---

## Testing Policies

Policy modules are pure functions — easy to test:

```elixir
defmodule MyApp.PolicyTest do
  use ExUnit.Case

  describe "Post policies" do
    test "admin can do anything" do
      admin = %{id: 1, role: "admin"}
      post = %Post{owner_id: 99}

      assert :ok = Policy.authorize(admin, :edit, post)
      assert :ok = Policy.authorize(admin, :delete, post)
    end

    test "owner can edit their own post" do
      user = %{id: 42, role: "viewer"}
      own_post = %Post{owner_id: 42}
      other_post = %Post{owner_id: 99}

      assert :ok = Policy.authorize(user, :edit, own_post)
      assert {:error, :forbidden} = Policy.authorize(user, :edit, other_post)
    end

    test "viewer cannot delete others' posts" do
      viewer = %{id: 1, role: "viewer"}
      post = %Post{owner_id: 2}

      assert {:error, :forbidden} = Policy.authorize(viewer, :delete, post)
    end

    test "anyone can view published posts" do
      user = %{id: 1, role: "viewer"}
      published = %Post{published: true, owner_id: 99}
      draft = %Post{published: false, owner_id: 99}

      assert :ok = Policy.authorize(user, :view, published)
      assert {:error, :forbidden} = Policy.authorize(user, :view, draft)
    end
  end
end
```

---

## Summary: The Authorization Stack

```
Request
  ↓
Auth Plug (VerifyApiToken)     — WHO are you? (401 if not authenticated)
  ↓
Role Plug (RequireRole)        — WHAT role do you have? (403 if wrong role)
  ↓
Controller loads resource
  ↓
Policy Module (authorize/3)    — CAN you do THIS to THIS? (403 if not allowed)
  ↓
Business logic runs
```

Each layer adds more specificity:
1. **Auth plug**: Identity
2. **Role plug**: Broad permissions
3. **Policy module**: Resource-level decisions
