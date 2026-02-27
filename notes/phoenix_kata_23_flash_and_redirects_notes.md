# Kata 23: Flash Messages & Redirects

## Flash Messages

Flash messages are one-time notifications shown to the user after an action. They survive across one redirect and are then automatically cleared.

```elixir
def create(conn, %{"product" => params}) do
  case Catalog.create_product(params) do
    {:ok, product} ->
      conn
      |> put_flash(:info, "Product created successfully!")
      |> redirect(to: ~p"/products/#{product}")

    {:error, changeset} ->
      conn
      |> put_flash(:error, "Could not create product.")
      |> render(:new, changeset: changeset)
  end
end
```

### Flash Types

| Type | Purpose | Typical Style |
|------|---------|---------------|
| `:info` | Success messages | Green/blue |
| `:error` | Error messages | Red |

---

## Displaying Flash Messages

In your layout or template:

```heex
<.flash_group flash={@flash} />
```

Or manually:

```heex
<%= if info = Phoenix.Flash.get(@flash, :info) do %>
  <div class="alert alert-info">
    <%= info %>
  </div>
<% end %>

<%= if error = Phoenix.Flash.get(@flash, :error) do %>
  <div class="alert alert-error">
    <%= error %>
  </div>
<% end %>
```

---

## Redirects

### `redirect/2` — External Redirect

Sends a 302 response that tells the browser to navigate to a new URL:

```elixir
# Redirect to a path:
redirect(conn, to: ~p"/products")

# Redirect to an external URL:
redirect(conn, external: "https://example.com")
```

### Why Redirect After POST? (PRG Pattern)

**Post/Redirect/Get (PRG)** prevents duplicate form submissions:

```
1. User submits form     → POST /products
2. Server creates record → 302 redirect to /products/42
3. Browser follows       → GET /products/42
4. User hits refresh     → GET /products/42 (safe!)
```

Without redirect, hitting refresh would re-submit the POST form.

---

## Redirect Types

```elixir
# 302 Found (temporary redirect — default)
redirect(conn, to: ~p"/products")

# 301 Moved Permanently
conn
|> put_status(:moved_permanently)
|> redirect(to: ~p"/new-products")
```

---

## Flash + Redirect Patterns

### After Successful Create

```elixir
conn
|> put_flash(:info, "Product created!")
|> redirect(to: ~p"/products/#{product}")
```

### After Successful Update

```elixir
conn
|> put_flash(:info, "Product updated!")
|> redirect(to: ~p"/products/#{product}")
```

### After Delete

```elixir
conn
|> put_flash(:info, "Product deleted.")
|> redirect(to: ~p"/products")
```

### After Failed Validation (No Redirect!)

```elixir
# Re-render the form with errors — DON'T redirect
conn
|> put_flash(:error, "Please fix the errors below.")
|> render(:new, changeset: changeset)
```

---

## Flash in LiveView

LiveView uses `put_flash/3` on the socket:

```elixir
def handle_event("save", params, socket) do
  case Catalog.create_product(params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Saved!")
       |> push_navigate(to: ~p"/products/#{product}")}

    {:error, changeset} ->
      {:noreply,
       socket
       |> put_flash(:error, "Could not save.")
       |> assign(:changeset, changeset)}
  end
end
```

### Clearing Flash

```elixir
# Flash is auto-cleared after display, but you can manually:
clear_flash(socket)          # Clear all
clear_flash(socket, :info)   # Clear specific key
```

---

## Session Data

For data that needs to persist across multiple requests (not just one redirect):

```elixir
# Store in session:
conn
|> put_session(:user_id, user.id)
|> put_session(:return_to, conn.request_path)

# Read from session:
user_id = get_session(conn, :user_id)
return_to = get_session(conn, :return_to) || "/"

# Delete from session:
conn = delete_session(conn, :return_to)
```

### Redirect Back Pattern

```elixir
def create(conn, params) do
  return_to = get_session(conn, :return_to) || ~p"/products"

  conn
  |> delete_session(:return_to)
  |> put_flash(:info, "Created!")
  |> redirect(to: return_to)
end
```

---

## Key Takeaways

1. **Flash messages** survive one redirect, then auto-clear
2. Use `:info` for success, `:error` for failures
3. **PRG pattern**: Always redirect after POST to prevent duplicate submissions
4. Use `redirect(to: path)` for internal, `redirect(external: url)` for external
5. Don't redirect on validation failure — re-render the form instead
6. LiveView uses `put_flash/3` on the socket, not conn
7. Use **sessions** for data that persists beyond one redirect
