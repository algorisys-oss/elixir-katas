# Kata 18: Authenticated Endpoint Tests

## Core Concept

Testing authenticated API endpoints requires setting up test users, generating tokens, and attaching them to the test conn. You need to test the full auth matrix: valid token, expired token, no token, wrong role, and malformed token.

Each scenario exercises a different branch in your auth plug pipeline, and missing any one of them can lead to security vulnerabilities.

---

## Auth Test Helper Approaches

### 1. Setup Block Helper

Create a named setup function and reference it with `setup [:setup_auth]`:

```elixir
defmodule MyAppWeb.ConnCase do
  def setup_auth(%{conn: conn}) do
    user = insert(:user, role: "editor")
    token = MyApp.Auth.generate_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")

    %{conn: conn, user: user, token: token}
  end
end

# Usage:
describe "authenticated endpoints" do
  setup [:setup_auth]

  test "returns posts", %{conn: conn, user: user} do
    # conn already has the Bearer token
  end
end
```

### 2. Test Tags

Use `@tag` to control which auth scenario runs:

```elixir
setup context do
  conn = build_conn() |> put_req_header("accept", "application/json")

  case context[:auth] do
    :admin ->
      user = insert(:user, role: "admin")
      token = MyApp.Auth.generate_token(user)
      %{conn: put_req_header(conn, "authorization", "Bearer #{token}"), user: user}

    :editor ->
      user = insert(:user, role: "editor")
      token = MyApp.Auth.generate_token(user)
      %{conn: put_req_header(conn, "authorization", "Bearer #{token}"), user: user}

    _ ->
      %{conn: conn}
  end
end

@tag auth: :admin
test "admin can delete", %{conn: conn} do
  # ...
end
```

### 3. Inline Helper Function

```elixir
defp authenticate(conn, role \\ "editor") do
  user = insert(:user, role: role)
  token = MyApp.Auth.generate_token(user)
  put_req_header(conn, "authorization", "Bearer #{token}")
end

test "editor creates post", %{conn: conn} do
  conn =
    conn
    |> authenticate("editor")
    |> post(~p"/api/posts", %{post: %{title: "New"}})

  assert json_response(conn, 201)
end
```

---

## The Auth Test Matrix

Every authenticated endpoint should have tests for these scenarios:

| Scenario | Expected Status | What It Tests |
|----------|----------------|---------------|
| Valid token | 200/201/204 | Happy path -- auth plug passes |
| Expired token | 401 | Token TTL validation |
| No token | 401 | Missing Authorization header |
| Malformed token | 401 | Invalid token format handling |
| Wrong role | 403 | Role-based access control |

---

## Example Test Suite

```elixir
defmodule MyAppWeb.Api.PostControllerTest do
  use MyAppWeb.ConnCase

  describe "GET /api/posts (authenticated)" do
    test "returns posts with valid token", %{conn: conn} do
      insert(:post, title: "Test")
      conn = conn |> authenticate("editor") |> get(~p"/api/posts")
      assert %{"data" => [_]} = json_response(conn, 200)
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, ~p"/api/posts")
      assert json_response(conn, 401)
    end

    test "returns 401 with expired token", %{conn: conn} do
      user = insert(:user)
      token = MyApp.Auth.generate_token(user, ttl: -3600)
      conn = conn |> put_req_header("authorization", "Bearer #{token}") |> get(~p"/api/posts")
      assert json_response(conn, 401)
    end

    test "returns 401 with malformed token", %{conn: conn} do
      conn = conn |> put_req_header("authorization", "Bearer garbage") |> get(~p"/api/posts")
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/posts/:id (admin only)" do
    test "admin can delete", %{conn: conn} do
      post = insert(:post)
      conn = conn |> authenticate("admin") |> delete(~p"/api/posts/#{post.id}")
      assert response(conn, 204)
    end

    test "editor gets 403", %{conn: conn} do
      post = insert(:post)
      conn = conn |> authenticate("editor") |> delete(~p"/api/posts/#{post.id}")
      assert json_response(conn, 403)
    end

    test "viewer gets 403", %{conn: conn} do
      post = insert(:post)
      conn = conn |> authenticate("viewer") |> delete(~p"/api/posts/#{post.id}")
      assert json_response(conn, 403)
    end
  end
end
```

---

## Best Practices

1. **Test every auth boundary** -- valid, expired, missing, malformed, wrong role
2. **Use helper functions** to keep auth setup DRY across tests
3. **Test that `conn.assigns.current_user` is set** after successful auth
4. **Test that `conn.halted` is true** after auth failure
5. **Verify error message content** to ensure helpful error responses
6. **Test role escalation** -- ensure lower roles cannot access higher-role endpoints

---

## Common Pitfalls

- **Only testing the happy path**: Auth bugs are security bugs. Always test failure cases.
- **Sharing tokens across tests**: Each test should generate its own token for isolation.
- **Not testing `conn.halted`**: A 401 response without `halt()` lets the request continue to the controller.
- **Hardcoding tokens**: Use your actual `generate_token/1` function to create test tokens, not hardcoded strings.
- **Forgetting `Plug.Crypto.secure_compare/2`**: When building custom auth, use timing-safe comparison for tokens.
