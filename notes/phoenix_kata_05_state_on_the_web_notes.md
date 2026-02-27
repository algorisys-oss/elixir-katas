# Kata 05: State on the Web

## The Statelessness Problem

HTTP is **stateless** — the server has no memory of previous requests. Every request is treated as if it's the first one ever. The server doesn't know who you are, what you did before, or whether you're logged in.

But web apps need state! Shopping carts, login sessions, user preferences — all require the server to remember something about you across multiple requests.

So how do we add memory to a forgetful protocol? Three main approaches: **Cookies**, **Sessions**, and **Tokens**.

---

## Approach 1: Cookies

A **cookie** is a small piece of data that the server asks the browser to store. The browser then sends it back with every subsequent request to that server.

### How Cookies Work

```
┌──────────┐                          ┌──────────┐
│  Browser  │  1. POST /login          │  Server   │
│           │ ─────────────────────▶   │           │
│           │                          │           │
│           │  2. Response + Set-Cookie │           │
│           │ ◀─────────────────────   │           │
│           │  Set-Cookie: user=Alice   │           │
│           │                          │           │
│  [stores  │  3. GET /dashboard       │           │
│  cookie]  │ ─────────────────────▶   │           │
│           │  Cookie: user=Alice      │  [reads   │
│           │                          │  cookie]  │
│           │  4. "Welcome back, Alice" │           │
│           │ ◀─────────────────────   │           │
└──────────┘                          └──────────┘
```

### Setting Cookies (Server → Browser)

The server sets a cookie using the `Set-Cookie` header:

```
HTTP/1.1 200 OK
Set-Cookie: theme=dark; Path=/; Max-Age=86400
Set-Cookie: lang=en; Path=/; HttpOnly
```

### Sending Cookies (Browser → Server)

The browser automatically includes cookies in every request:

```
GET /dashboard HTTP/1.1
Host: example.com
Cookie: theme=dark; lang=en
```

### Cookie Attributes

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `Path` | Which URLs get this cookie | `Path=/admin` |
| `Max-Age` | Seconds until expiration | `Max-Age=86400` (1 day) |
| `Expires` | Exact expiration date | `Expires=Thu, 01 Jan 2026` |
| `HttpOnly` | JavaScript can't read it | Prevents XSS theft |
| `Secure` | Only sent over HTTPS | Prevents interception |
| `SameSite` | Cross-site request control | Prevents CSRF attacks |

### Cookie Limitations

- **Size**: ~4KB per cookie, ~20 cookies per domain
- **Security**: Sent with every request — keep them small
- **Privacy**: Users can view and delete cookies
- **Tampering**: Unless signed/encrypted, users can modify them

---

## Approach 2: Sessions

Sessions solve cookies' limitations by storing data **on the server** and only putting a small **session ID** in the cookie.

### How Sessions Work

```
Browser's Cookie:
  session_id = abc123

Server's Session Store:
  "abc123" → {user: "Alice", cart: ["Book", "Pen"], role: "admin"}
```

The cookie is just a key — all the actual data stays safely on the server.

### Sessions vs Cookies

| Aspect | Cookies | Sessions |
|--------|---------|----------|
| Data stored | In browser | On server |
| Size limit | ~4KB | Unlimited |
| Security | Visible to user | Hidden on server |
| Tampering | Possible (without signing) | Not possible |
| Server memory | None | Uses server memory/DB |

### Phoenix Sessions

Phoenix takes a clever approach — it stores session data **in the cookie itself**, but **signed and encrypted**:

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  secret_key_base: "super_secret_random_string..."

# The session cookie is encrypted — users can't read or modify it
# Even though it's in the cookie, it's as secure as server-side storage
```

Using sessions in Phoenix:

```elixir
# In a controller
def login(conn, %{"email" => email, "password" => password}) do
  case Accounts.authenticate(email, password) do
    {:ok, user} ->
      conn
      |> put_session(:user_id, user.id)    # Store user ID in session
      |> redirect(to: "/dashboard")

    :error ->
      conn
      |> put_flash(:error, "Invalid credentials")
      |> redirect(to: "/login")
  end
end

def dashboard(conn, _params) do
  user_id = get_session(conn, :user_id)    # Read from session
  user = Accounts.get_user!(user_id)
  render(conn, :dashboard, user: user)
end

def logout(conn, _params) do
  conn
  |> clear_session()                        # Delete all session data
  |> redirect(to: "/")
end
```

---

## Approach 3: Tokens (JWT / Bearer)

Tokens are **self-contained credentials** sent in the `Authorization` header. Unlike sessions, the server doesn't store anything — all information is encoded in the token itself.

### How Tokens Work

```
1. Login:
   POST /api/login  {email: "alice@ex.com", password: "..."}
   Response: {token: "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0Mn0.signature"}

2. Subsequent requests:
   GET /api/dashboard
   Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...

3. Server verifies the signature (not a database lookup!)
   → Knows it's user 42 (Alice)
```

### JWT Structure

A JWT (JSON Web Token) has three parts:

```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0Mn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
└──────── Header ──────┘└──── Payload ────┘└────────── Signature ──────────┘
```

- **Header**: Algorithm used for signing
- **Payload**: The data (user ID, expiration, etc.) — base64-encoded, NOT encrypted!
- **Signature**: Cryptographic proof that the token hasn't been tampered with

### When to Use Tokens

- **APIs** consumed by mobile apps or SPAs
- **Microservices** that need to verify identity without shared sessions
- **Stateless authentication** where server memory is a concern

### Phoenix Token Example

```elixir
# Generate a token
Phoenix.Token.sign(MyAppWeb.Endpoint, "user auth", user.id)
# => "SFMyNTY.g2gDaAJhBG..."

# Verify a token
Phoenix.Token.verify(MyAppWeb.Endpoint, "user auth", token, max_age: 86400)
# => {:ok, 42}  or  {:error, :expired}
```

---

## Which Approach to Use?

| Use Case | Recommended | Why |
|----------|-------------|-----|
| Web app login | **Sessions** | Secure, Phoenix default, easy |
| "Remember me" | Sessions + long-lived cookie | Persistent across browser restarts |
| Theme preference | **Cookie** | Small, non-sensitive data |
| API authentication | **Tokens** | Stateless, works with any client |
| Mobile app auth | **Tokens** | No browser cookie support |
| User preferences | **Cookie** or Session | Depends on sensitivity |

**Phoenix default**: Session-based auth using `mix phx.gen.auth`, with encrypted cookies. This is the right choice for most web apps.

---

## Key Takeaways

1. HTTP is **stateless** — the server forgets everything between requests
2. **Cookies**: Browser stores small data, sends it with every request
3. **Sessions**: Server stores data, browser only has a session ID cookie
4. **Tokens**: Self-contained credentials, server stores nothing
5. Phoenix uses **signed, encrypted cookies** for sessions by default
6. Use sessions for web apps, tokens for APIs
7. Always set `HttpOnly`, `Secure`, and `SameSite` on auth cookies
