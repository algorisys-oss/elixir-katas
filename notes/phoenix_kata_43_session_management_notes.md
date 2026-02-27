# Kata 43: Session Management

## How Sessions Work in Phoenix

HTTP is stateless — every request is independent. Sessions solve this by storing a small piece of data (a token or encrypted payload) in a cookie that the browser sends with every request.

```
Login (POST /users/log_in):
  client --> server: email + password
  server --> client: Set-Cookie: _my_app_key=<signed_token>

Next request (GET /dashboard):
  client --> server: Cookie: _my_app_key=<signed_token>
  server: reads token from cookie → loads user from DB → renders page

Logout (DELETE /users/log_out):
  server: deletes token from DB
  server --> client: Set-Cookie: _my_app_key=<empty>; Max-Age=0
```

Phoenix uses `Plug.Session` under the hood, configured in the Endpoint. The session data is stored inside a **signed** (and optionally encrypted) cookie.

---

## Login Flow

```elixir
defmodule MyAppWeb.UserSessionController do
  use MyAppWeb, :controller

  def create(conn, %{"user" => %{"email" => email,
                                  "password" => password} = params}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        # Don't reveal whether the email exists:
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log_in")

      user ->
        conn
        |> configure_session(renew: true)    # prevent session fixation
        |> UserAuth.log_in_user(user, params)
    end
  end
end
```

Inside `UserAuth.log_in_user/3`:

```elixir
def log_in_user(conn, user, params \\ %{}) do
  token = Accounts.generate_user_session_token(user)
  user_return_to = get_session(conn, :user_return_to)

  conn
  |> renew_session()                               # new session ID
  |> put_session(:user_token, token)               # store token
  |> maybe_write_remember_me_cookie(token, params) # optional persistent cookie
  |> redirect(to: user_return_to || signed_in_path(conn))
end
```

**Critical: `configure_session(renew: true)`** regenerates the session ID on login, preventing **session fixation attacks** (where an attacker sets a known session ID before the victim logs in).

---

## Logout Flow

```elixir
def delete(conn, _params) do
  conn
  |> put_flash(:info, "Logged out successfully.")
  |> UserAuth.log_out_user()
end

# Inside UserAuth:
def log_out_user(conn) do
  # 1. Get the current session token:
  user_token = get_session(conn, :user_token)

  # 2. Delete it from the database (revoke the session):
  user_token && Accounts.delete_user_session_token(user_token)

  # 3. Clear session and delete remember-me cookie:
  conn
  |> renew_session()
  |> delete_resp_cookie(@remember_me_cookie)
  |> redirect(to: ~p"/")
end

defp renew_session(conn) do
  delete_csrf_token()          # invalidate old CSRF token
  conn
  |> configure_session(renew: true)  # new session ID
  |> clear_session()                 # remove all session data
end
```

The token is deleted from the database, not just from the cookie. This means even if someone copies the cookie before logout, the token is no longer valid.

---

## Session API

All functions from `Plug.Conn`:

```elixir
# Write to session:
put_session(conn, :user_token, token)
put_session(conn, :locale, "en")

# Read from session:
get_session(conn, :user_token)   # => "abc123..." or nil
get_session(conn, :locale)       # => "en" or nil

# Delete a single key:
delete_session(conn, :return_to)

# Clear all session data (keeps the session ID):
clear_session(conn)

# Session lifecycle control:
configure_session(conn, renew: true)   # new session ID, keeps data
configure_session(conn, drop: true)    # destroy session entirely
```

---

## Cookie Configuration

Configure session cookies in the Endpoint or directly with `Plug.Session`:

```elixir
# lib/my_app_web/endpoint.ex:
plug Plug.Session,
  store: :cookie,
  key: "_my_app_key",
  signing_salt: "some_signing_salt",
  # Security flags:
  same_site: "Lax",      # CSRF protection
  secure: true,           # HTTPS only (set in prod)
  http_only: true,        # JS cannot read cookie
  max_age: nil            # nil = session cookie (until browser closes)

# For encrypted sessions (hides data from user):
plug Plug.Session,
  store: :cookie,
  key: "_my_app_key",
  encryption_salt: "some_encryption_salt",
  signing_salt: "some_signing_salt"
```

### Cookie Flags Explained

| Flag | Value | Purpose |
|------|-------|---------|
| `HttpOnly` | `true` | JavaScript cannot read the cookie (protects against XSS) |
| `Secure` | `true` | Cookie is only sent over HTTPS connections |
| `SameSite` | `"Lax"` | Browser does not send cookie on cross-site POST (CSRF protection) |
| `SameSite` | `"Strict"` | Browser does not send cookie on any cross-site request |
| `SameSite` | `"None"` | No cross-site restriction (requires `Secure: true`) |
| `Max-Age` | `nil` | Session cookie — expires when browser closes |
| `Max-Age` | `86400` | Persistent cookie — lasts 1 day (in seconds) |

**Signed vs Encrypted cookies:**
- **Signed**: user can read the data but cannot modify it (tamper-proof)
- **Encrypted**: user cannot read or modify the data (confidential + tamper-proof)

---

## Session Token Flow

The `phx.gen.auth` system does not store user data in the cookie. It stores a **token** that maps to a database row:

```elixir
# On login:
# 1. Generate random 32 bytes:
token = :crypto.strong_rand_bytes(32)

# 2. Hash and store in users_tokens:
hashed = :crypto.hash(:sha256, token)
Repo.insert!(%UserToken{token: hashed, context: "session", user_id: user.id})

# 3. Store ORIGINAL (unhashed) token in cookie:
encoded = Base.url_encode64(token, padding: false)
put_session(conn, :user_token, encoded)

# On each request:
# 4. Read token from session, hash it, look up in DB:
{:ok, decoded} = Base.url_decode64(encoded, padding: false)
hashed = :crypto.hash(:sha256, decoded)
# Find user_token row where token == hashed AND not expired
```

The cookie never contains the same value as the database. Even if the database is compromised, tokens cannot be forged.

---

## Remember Me

"Remember me" extends the session beyond the browser session using a separate long-lived cookie.

```elixir
@remember_me_cookie "_my_app_user_remember_me"
@remember_me_options [
  sign: true,
  max_age: 60 * 60 * 24 * 60,  # 60 days
  same_site: "Lax"
]

defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
  put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
end
defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn
```

On each request, if the session does not contain a token, check the remember-me cookie:

```elixir
defp ensure_user_token(conn) do
  if token = get_session(conn, :user_token) do
    {token, conn}
  else
    conn = fetch_cookies(conn, signed: [@remember_me_cookie])
    if token = conn.cookies[@remember_me_cookie] do
      # Restore session from remember-me cookie:
      {token, put_session(conn, :user_token, token)}
    else
      {nil, conn}
    end
  end
end
```

The HTML form checkbox:

```html
<.input type="checkbox" name="user[remember_me]" value="true"
        label="Keep me logged in for 60 days" />
```

The flow:
1. On login with "remember me" checked, write a persistent cookie (60-day `max_age`)
2. On each request, if no session token exists, check the remember-me cookie
3. If the cookie token is valid, restore the session from it
4. On logout, delete both the session cookie and the remember-me cookie

---

## Session Fixation Prevention

**Session fixation attack**: an attacker sets a known session ID on the victim's browser before the victim logs in. After login, the attacker uses the same session ID to hijack the authenticated session.

**Prevention: always regenerate the session ID on login:**

```elixir
defp renew_session(conn) do
  delete_csrf_token()                 # invalidate old CSRF token
  conn
  |> configure_session(renew: true)   # generate new session ID
  |> clear_session()                  # clear old session data
end
```

After `renew: true`, the session gets a completely new ID. The old session ID (which the attacker might know) no longer maps to anything.

---

## Sign Out All Devices

Because tokens are stored in the database, you can revoke all of a user's sessions at once:

```elixir
def delete_all_user_session_tokens(user) do
  Repo.delete_all(
    from t in UserToken,
      where: t.user_id == ^user.id,
      where: t.context == "session"
  )
end

# In a settings controller:
def delete_all_sessions(conn, _params) do
  Accounts.delete_all_user_session_tokens(conn.assigns.current_user)

  conn
  |> put_flash(:info, "All sessions terminated.")
  |> UserAuth.log_out_user()
end
```

This is a major advantage of token-based sessions over plain session-ID cookies — you cannot selectively revoke sessions that only live in cookies.

---

## Store Return URL

When a user is redirected to login, save where they were trying to go:

```elixir
# In RequireAuth — save intended destination:
defp maybe_store_return_to(%{method: "GET"} = conn) do
  put_session(conn, :user_return_to, current_path(conn))
end
defp maybe_store_return_to(conn), do: conn

# After login — redirect back:
def log_in_user(conn, user, params \\ %{}) do
  token = Accounts.generate_user_session_token(user)
  return_to = get_session(conn, :user_return_to) || ~p"/"

  conn
  |> renew_session()
  |> put_session(:user_token, token)
  |> maybe_write_remember_me_cookie(token, params)
  |> redirect(to: return_to)
end
```

Only GET requests are saved as return URLs — you would not want to replay a POST after login.

---

## Security Checklist

1. **Force HTTPS** in production: `force_ssl: [rewrite_on: [:x_forwarded_proto]]`
2. **HttpOnly cookies**: JavaScript cannot steal the session cookie
3. **SameSite=Lax**: prevents cross-site POST with cookies (CSRF protection)
4. **Renew session ID** on login: prevents session fixation attacks
5. **Clear session** on logout: `clear_session()` + delete DB token
6. **Short-lived tokens**: sessions expire after 60 days by default
7. **Rotate `secret_key_base`** periodically: invalidates all existing signed cookies

---

## Key Takeaways

1. Sessions use **signed cookies** — the user can decode the data but cannot modify it without the server's secret
2. **Always call `configure_session(renew: true)`** on login to prevent session fixation
3. **Always delete the DB token** on logout — clearing the cookie alone is not enough
4. "Remember me" is a **separate long-lived cookie** with its own DB token
5. Store **minimal data** in the session — just a token string, never the full user object
6. DB-backed tokens enable **"sign out all devices"** by deleting all token rows for a user
7. The `HttpOnly` flag is essential — it prevents JavaScript from reading the session cookie
8. Only save **GET request paths** as return URLs — never replay POST requests after login
