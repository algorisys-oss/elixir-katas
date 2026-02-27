# Kata 00: REST Fundamentals

## What is a REST API?

**REST** (Representational State Transfer) is an architectural style for building web APIs. A REST API lets clients (browsers, mobile apps, other servers) communicate with your backend using standard HTTP methods and conventions.

### REST vs Server-Rendered Web Apps

| Aspect | Server-Rendered (Phoenix Web) | REST API (Phoenix API) |
|--------|-------------------------------|------------------------|
| Response format | HTML pages | JSON data |
| Client | Browser renders HTML | Any client parses JSON |
| State | Server manages sessions | Stateless (tokens) |
| Pipeline | `:browser` (sessions, CSRF) | `:api` (accepts JSON) |

---

## RESTful Resource Design

REST treats everything as a **resource** — a noun that can be created, read, updated, or deleted:

```
Resource: Users
URL:      /api/users

GET    /api/users          → List all users
GET    /api/users/42       → Get user 42
POST   /api/users          → Create a new user
PUT    /api/users/42       → Replace user 42
PATCH  /api/users/42       → Partially update user 42
DELETE /api/users/42       → Delete user 42
```

### URL Design Principles

```
✅ Good                          ❌ Bad
/api/users                       /api/getUsers
/api/users/42                    /api/user?id=42
/api/users/42/posts              /api/getUserPosts?userId=42
/api/posts?status=published      /api/getPublishedPosts
```

**Rules:**
- Use **nouns**, not verbs (the HTTP method is the verb)
- Use **plural** resource names (`/users`, not `/user`)
- Use **nesting** for relationships (`/users/42/posts`)
- Use **query params** for filtering, sorting, pagination

---

## HTTP Methods & Their Meaning

| Method | Purpose | Idempotent? | Has Body? | Success Code |
|--------|---------|-------------|-----------|--------------|
| GET | Read resource(s) | Yes | No | 200 |
| POST | Create resource | No | Yes | 201 |
| PUT | Replace resource | Yes | Yes | 200 |
| PATCH | Partial update | Yes | Yes | 200 |
| DELETE | Remove resource | Yes | No | 204 |

**Idempotent** means calling it multiple times produces the same result. `POST` is not idempotent — calling it 3 times creates 3 resources.

---

## JSON Response Patterns

### Single Resource

```json
{
  "data": {
    "id": 42,
    "type": "user",
    "attributes": {
      "name": "Alice",
      "email": "alice@example.com",
      "inserted_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

### Collection

```json
{
  "data": [
    {"id": 1, "name": "Alice", "email": "alice@example.com"},
    {"id": 2, "name": "Bob", "email": "bob@example.com"}
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "per_page": 20
  }
}
```

### Error Response

```json
{
  "errors": {
    "email": ["has already been taken"],
    "name": ["can't be blank"]
  }
}
```

---

## Phoenix API Pipeline

Phoenix has a built-in `:api` pipeline that's different from the `:browser` pipeline:

```elixir
# router.ex
pipeline :api do
  plug :accepts, ["json"]
  # No session, no CSRF, no flash — just JSON
end

scope "/api", MyAppWeb.Api do
  pipe_through :api

  resources "/users", UserController, except: [:new, :edit]
  # Only generates: index, show, create, update, delete
  # Skips :new and :edit (those are HTML form pages)
end
```

### API Controller Pattern

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    json(conn, %{data: users})
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    json(conn, %{data: user})
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/users/#{user}")
        |> json(%{data: user})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    Accounts.delete_user(user)
    send_resp(conn, :no_content, "")
  end
end
```

---

## Status Codes Quick Reference

### Success (2xx)
- **200 OK** — GET, PUT, PATCH succeeded
- **201 Created** — POST created a resource
- **204 No Content** — DELETE succeeded (no body)

### Client Errors (4xx)
- **400 Bad Request** — Malformed request
- **401 Unauthorized** — Not authenticated (no/invalid token)
- **403 Forbidden** — Authenticated but not allowed
- **404 Not Found** — Resource doesn't exist
- **422 Unprocessable Entity** — Validation failed

### Server Errors (5xx)
- **500 Internal Server Error** — Something broke

---

## Content Negotiation

APIs typically use the `Accept` and `Content-Type` headers:

```
# Client sends:
POST /api/users HTTP/1.1
Content-Type: application/json    ← "I'm sending JSON"
Accept: application/json          ← "I want JSON back"

{"name": "Alice", "email": "alice@example.com"}
```

Phoenix's `:api` pipeline handles this with `plug :accepts, ["json"]`.

---

## What's Next?

In the following katas, you'll build each piece hands-on:
- **Kata 01**: The `:api` pipeline and how it differs from `:browser`
- **Kata 02**: Resource routes and controller actions
- **Kata 03-05**: Request handling, status codes, and error responses
- **Kata 06-08**: Authentication (Bearer tokens, JWT, API keys)
- **Kata 09-10**: Authorization (roles and policies)
- **Kata 11-14**: File uploads, downloads, filtering, pagination
- **Kata 15-16**: Rate limiting, CORS, security
- **Kata 17-18**: Testing your APIs
- **Kata 19**: Webhooks, OpenAPI, and advanced patterns
