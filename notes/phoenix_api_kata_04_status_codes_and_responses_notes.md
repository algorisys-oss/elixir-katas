# Kata 04: Status Codes & Responses

## Why Status Codes Matter for APIs

Status codes tell clients what happened without parsing the response body. A well-designed API uses the right code for each situation — clients can branch on the status code before examining the body.

```
200 → Success, parse the data
201 → Created, parse the new resource
204 → Deleted, no body to parse
401 → Need to re-authenticate
404 → Resource doesn't exist
422 → Validation failed, show errors
500 → Server broke, retry later
```

---

## `put_status/2`

Phoenix uses `put_status/2` to set the HTTP status code on the connection:

```elixir
conn
|> put_status(:created)         # 201
|> json(%{data: user})

conn
|> put_status(:not_found)       # 404
|> json(%{error: "Not found"})

# Integer codes also work:
conn
|> put_status(422)
|> json(%{errors: errors})
```

If you don't call `put_status/2`, the default is `200 OK`.

---

## Atom Status Names

Phoenix maps atoms to HTTP status codes. These are more readable than integers:

### Success (2xx)

| Atom | Code | Use When |
|------|------|----------|
| `:ok` | 200 | GET, PUT, PATCH succeeded |
| `:created` | 201 | POST created a new resource |
| `:accepted` | 202 | Request accepted for async processing |
| `:no_content` | 204 | DELETE succeeded, no body |

### Redirection (3xx)

| Atom | Code | Use When |
|------|------|----------|
| `:moved_permanently` | 301 | Resource permanently moved |
| `:not_modified` | 304 | Client cache is still valid |

### Client Error (4xx)

| Atom | Code | Use When |
|------|------|----------|
| `:bad_request` | 400 | Malformed request (bad JSON) |
| `:unauthorized` | 401 | Missing/invalid auth token |
| `:forbidden` | 403 | Authenticated but not allowed |
| `:not_found` | 404 | Resource doesn't exist |
| `:conflict` | 409 | Conflicts with current state |
| `:unprocessable_entity` | 422 | Valid JSON but validation failed |
| `:too_many_requests` | 429 | Rate limit exceeded |

### Server Error (5xx)

| Atom | Code | Use When |
|------|------|----------|
| `:internal_server_error` | 500 | Unhandled exception |
| `:bad_gateway` | 502 | Upstream service error |
| `:service_unavailable` | 503 | Temporarily down |

---

## Proper Response Structure

### Successful Responses

```elixir
# Single resource
json(conn, %{data: %{id: 1, name: "Alice", email: "alice@example.com"}})

# Collection
json(conn, %{
  data: users,
  meta: %{total: 100, page: 1, per_page: 20}
})

# Created resource (always set 201 + location header)
conn
|> put_status(:created)
|> put_resp_header("location", ~p"/api/users/#{user}")
|> json(%{data: user})

# No content (DELETE)
send_resp(conn, :no_content, "")
```

### Error Responses

```elixir
# Single error message
conn
|> put_status(:not_found)
|> json(%{error: "User not found"})

# Validation errors (from changeset)
conn
|> put_status(:unprocessable_entity)
|> json(%{errors: %{
  email: ["has already been taken"],
  name: ["can't be blank"]
}})

# Generic error with detail
conn
|> put_status(:forbidden)
|> json(%{error: %{
  message: "You do not have permission to delete this resource",
  code: "FORBIDDEN"
}})
```

---

## `json/2` vs `send_resp/3`

### `json/2`

```elixir
json(conn, %{data: user})
```

- Automatically sets `Content-Type: application/json`
- Encodes the Elixir term to JSON using Jason
- Default status code is `200 OK`
- Use for all responses that return JSON data

### `send_resp/3`

```elixir
send_resp(conn, :no_content, "")
```

- Sends a raw response with no content-type assumptions
- The third argument is the response body as a string
- Use when you need no body (204) or non-JSON responses

### When to Use Each

| Scenario | Function |
|----------|----------|
| Return JSON data | `json/2` |
| 204 No Content | `send_resp/3` |
| Plain text response | `send_resp/3` with `put_resp_content_type` |
| File download | `send_download/3` |

---

## Complete Controller Example

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts
  action_fallback MyAppWeb.FallbackController

  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    users = Accounts.list_users(page: page)

    json(conn, %{data: users, meta: %{page: page}})  # 200
  end

  def show(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})  # 404

      user ->
        json(conn, %{data: user})  # 200
    end
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)  # 201
        |> put_resp_header("location", ~p"/api/users/#{user}")
        |> json(%{data: user})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)  # 422
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    Accounts.delete_user(user)
    send_resp(conn, :no_content, "")  # 204
  end
end
```
