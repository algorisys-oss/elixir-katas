# Kata 05: Error Handling & Fallback Controllers

## The Problem: Scattered Error Handling

Without a structured approach, error handling gets duplicated across every action:

```elixir
# Bad: every action handles its own errors
def show(conn, %{"id" => id}) do
  case Accounts.get_user(id) do
    nil ->
      conn |> put_status(:not_found) |> json(%{error: "Not found"})
    user ->
      json(conn, %{data: user})
  end
end

def create(conn, %{"user" => params}) do
  case Accounts.create_user(params) do
    {:ok, user} ->
      conn |> put_status(:created) |> json(%{data: user})
    {:error, changeset} ->
      conn |> put_status(422) |> json(%{errors: format(changeset)})
  end
end

# Every action repeats the error handling pattern...
```

---

## `action_fallback/1`

Phoenix's `action_fallback` macro tells a controller: "If my action returns a non-conn value (like `{:error, _}`), pass it to this fallback controller."

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  action_fallback MyAppWeb.FallbackController

  # Clean! Only the happy path.
  def show(conn, %{"id" => id}) do
    with {:ok, user} <- Accounts.fetch_user(id) do
      json(conn, %{data: user})
    end
    # {:error, :not_found} automatically goes to FallbackController
  end

  def create(conn, %{"user" => params}) do
    with {:ok, user} <- Accounts.create_user(params) do
      conn |> put_status(:created) |> json(%{data: user})
    end
    # {:error, %Ecto.Changeset{}} automatically goes to FallbackController
  end
end
```

### How `with` Works Here

```elixir
with {:ok, user} <- Accounts.fetch_user(id) do
  # Only runs if fetch_user returns {:ok, user}
  json(conn, %{data: user})
end
# If fetch_user returns {:error, :not_found}, that value is returned
# from the action, and action_fallback kicks in
```

---

## The FallbackController Pattern

The FallbackController is a regular controller with `call/2` clauses that pattern match on error tuples:

```elixir
defmodule MyAppWeb.FallbackController do
  use MyAppWeb, :controller

  # Handle changeset validation errors → 422
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MyAppWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  # Handle not found → 404
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: MyAppWeb.ErrorJSON)
    |> render(:"404")
  end

  # Handle unauthorized → 401
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: MyAppWeb.ErrorJSON)
    |> render(:"401")
  end

  # Handle forbidden → 403
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: MyAppWeb.ErrorJSON)
    |> render(:"403")
  end
end
```

### Key Points

- Each clause matches a specific error shape
- `put_view/2` sets the JSON view module for rendering
- `render/2` or `render/3` delegates to `ErrorJSON.render/2`
- You can add new clauses as your app grows

---

## The ErrorJSON Module

This module renders error responses as JSON:

```elixir
defmodule MyAppWeb.ErrorJSON do
  # Changeset errors → detailed validation messages
  def render("error.json", %{changeset: changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    %{errors: errors}
  end

  # Catch-all for status templates (404.json, 500.json, etc.)
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
```

### What `traverse_errors` Produces

Given a changeset with these errors:

```elixir
# changeset.errors = [
#   name: {"can't be blank", [validation: :required]},
#   email: {"has already been taken", []},
#   age: {"must be greater than %{number}", [validation: :number, number: 0]}
# ]
```

`traverse_errors` produces:

```json
{
  "errors": {
    "name": ["can't be blank"],
    "email": ["has already been taken"],
    "age": ["must be greater than 0"]
  }
}
```

---

## Rendering Changeset Errors as JSON

The `traverse_errors/2` function is the standard way to convert changeset errors:

```elixir
# Simple version (raw messages)
Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

# Full version (interpolates values like %{count}, %{number})
Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
  Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
    opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
  end)
end)
```

### Nested Changeset Errors

For embedded schemas or associations:

```elixir
# If a User has_many :addresses with their own validations:
%{
  "errors": {
    "name": ["can't be blank"],
    "addresses": [
      %{"street": ["can't be blank"], "zip": ["is invalid"]},
      %{}  # second address is valid
    ]
  }
}
```

---

## Custom Error Responses

You can define richer error formats:

```elixir
defmodule MyAppWeb.ErrorJSON do
  # Custom error with code and message
  def render("error.json", %{changeset: changeset}) do
    %{
      error: %{
        code: "VALIDATION_ERROR",
        message: "The request data is invalid",
        fields: format_errors(changeset)
      }
    }
  end

  # Custom 404 with helpful message
  def render("404.json", _assigns) do
    %{
      error: %{
        code: "NOT_FOUND",
        message: "The requested resource was not found"
      }
    }
  end

  # Custom 401
  def render("401.json", _assigns) do
    %{
      error: %{
        code: "UNAUTHORIZED",
        message: "Valid authentication credentials are required"
      }
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
```

---

## Exception-Based Error Handling

Phoenix also handles exceptions automatically. `Ecto.NoResultsError` (raised by `Repo.get!`) is converted to 404:

```elixir
# In your controller:
def show(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)  # Raises if not found
  json(conn, %{data: user})
end

# If id doesn't exist, get_user! raises Ecto.NoResultsError
# Phoenix catches it and returns 404 automatically
```

This works because Phoenix's `ErrorJSON` has the catch-all `render/2` clause.

### Implementing `Plug.Exception` for Custom Errors

```elixir
defmodule MyApp.NotAuthorizedError do
  defexception message: "not authorized", plug_status: 403
end

# Now if your code raises this, Phoenix returns 403 automatically
raise MyApp.NotAuthorizedError
```

---

## Complete Error Handling Setup

```
Controller (happy path only)
    ↓ returns {:error, _}
action_fallback
    ↓ calls FallbackController.call/2
FallbackController
    ↓ puts status, sets view
ErrorJSON.render/2
    ↓ returns error map
JSON response to client
```

This gives you:
- **Controllers** that only handle the happy path
- **One place** for error-to-response mapping (FallbackController)
- **One place** for error formatting (ErrorJSON)
- **Consistent** error responses across your entire API
