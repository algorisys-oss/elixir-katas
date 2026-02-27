# Kata 17: API Controller Tests

## Core Concept

Phoenix API controller tests verify the HTTP contract of your endpoints: correct status codes, response body structure, and headers. They use `Phoenix.ConnTest` helpers to simulate HTTP requests through the full plug pipeline without starting a server.

Controller tests are integration tests -- they exercise the router, plugs, controller, context, and JSON serialization together.

---

## ConnCase Setup

```elixir
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import MyAppWeb.ConnCase

      @endpoint MyAppWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

---

## Key ConnTest Helpers

| Helper | Description |
|--------|-------------|
| `build_conn()` | Creates a fresh test conn struct |
| `get(conn, path)` | Sends GET request through the router |
| `post(conn, path, params)` | Sends POST with params as body |
| `put(conn, path, params)` | Sends PUT with params |
| `delete(conn, path)` | Sends DELETE request |
| `json_response(conn, status)` | Asserts status code and parses JSON body |
| `response(conn, status)` | Asserts status code and returns raw body |
| `put_req_header(conn, key, value)` | Sets a request header |

---

## Test Patterns by CRUD Action

### Index (List)

```elixir
test "lists all posts", %{conn: conn} do
  insert(:post, title: "First")
  insert(:post, title: "Second")

  conn = get(conn, ~p"/api/posts")

  assert %{"data" => posts} = json_response(conn, 200)
  assert length(posts) == 2
end
```

### Show (Single)

```elixir
test "returns a post by id", %{conn: conn} do
  post = insert(:post, title: "My Post")

  conn = get(conn, ~p"/api/posts/#{post.id}")

  assert %{"data" => %{"id" => _, "title" => "My Post"}} =
    json_response(conn, 200)
end

test "returns 404 for non-existent post", %{conn: conn} do
  conn = get(conn, ~p"/api/posts/999999")
  assert json_response(conn, 404)
end
```

### Create

```elixir
test "creates post with valid data", %{conn: conn} do
  attrs = %{title: "New Post", body: "Content"}

  conn = post(conn, ~p"/api/posts", %{post: attrs})

  assert %{"data" => %{"id" => id}} = json_response(conn, 201)
  assert id != nil
end

test "returns errors with invalid data", %{conn: conn} do
  conn = post(conn, ~p"/api/posts", %{post: %{}})

  assert %{"errors" => %{"title" => ["can't be blank"]}} =
    json_response(conn, 422)
end
```

### Delete

```elixir
test "deletes the post", %{conn: conn} do
  post = insert(:post)

  conn = delete(conn, ~p"/api/posts/#{post.id}")
  assert response(conn, 204)

  # Verify deletion
  conn = get(build_conn(), ~p"/api/posts/#{post.id}")
  assert json_response(conn, 404)
end
```

---

## Testing with describe Blocks

Group tests by endpoint for better organization:

```elixir
defmodule MyAppWeb.Api.PostControllerTest do
  use MyAppWeb.ConnCase

  describe "GET /api/posts" do
    test "returns empty list", %{conn: conn} do
      # ...
    end

    test "returns all posts", %{conn: conn} do
      # ...
    end
  end

  describe "POST /api/posts" do
    test "creates with valid data", %{conn: conn} do
      # ...
    end

    test "rejects invalid data", %{conn: conn} do
      # ...
    end
  end
end
```

---

## Best Practices

1. **Test the HTTP contract**, not implementation details -- status codes, response structure, headers
2. **Use `describe` blocks** to group tests by endpoint
3. **Test both happy path and error cases** for every endpoint
4. **Use factories** (ex_machina) instead of manual inserts for test data
5. **Each test should be independent** -- don't rely on state from other tests
6. **Use `json_response/2`** -- it asserts status AND parses JSON in one call
7. **Test response structure with pattern matching** instead of exact equality

---

## Common Pitfalls

- **Reusing conn after a request**: `conn` is consumed after the first request. Use `build_conn()` for follow-up requests.
- **Not testing 404/422 cases**: Happy-path-only tests miss important error handling bugs.
- **Over-asserting**: Don't assert on every field -- focus on key fields and structure. Timestamps and IDs change between runs.
- **Skipping Content-Type headers**: POST/PUT tests should set `content-type: application/json` via `put_req_header/3`.
- **Hardcoded IDs**: Use the actual ID from the factory/insert, don't assume sequential IDs.
