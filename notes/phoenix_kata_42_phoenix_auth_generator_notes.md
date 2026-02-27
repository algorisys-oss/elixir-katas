# Kata 42: Phoenix Auth Generator

## What is `mix phx.gen.auth`?

`mix phx.gen.auth` is a built-in Phoenix generator that creates a complete, production-ready authentication system. Unlike libraries you cannot modify, Phoenix **generates the code into your project** — it becomes yours to customize.

```bash
mix phx.gen.auth Accounts User users
```

- **Accounts** — the context module name
- **User** — the schema module name
- **users** — the database table name (plural, snake_case)

After running: `mix deps.get` (adds `bcrypt_elixir`) then `mix ecto.migrate`.

---

## Generator Options

```bash
# Default: generates LiveView-based auth pages
mix phx.gen.auth Accounts User users

# Controller-only auth (no LiveView):
mix phx.gen.auth Accounts User users --no-live

# Choose password hashing library:
mix phx.gen.auth Accounts User users --hashing-lib pbkdf2
# options: bcrypt (default), pbkdf2, argon2

# UUID primary keys instead of integer IDs:
mix phx.gen.auth Accounts User users --binary-id

# Custom table name:
mix phx.gen.auth Accounts User users --table auth_users
```

If an `Accounts` context already exists, the generator appends to it rather than overwriting.

---

## What Gets Generated

### Context & Schemas

| File | Purpose |
|------|---------|
| `lib/my_app/accounts.ex` | Accounts context — all auth business logic |
| `lib/my_app/accounts/user.ex` | User schema (email, hashed_password, confirmed_at) |
| `lib/my_app/accounts/user_token.ex` | UserToken schema for session/reset/confirm tokens |

### Web Layer

| File | Purpose |
|------|---------|
| `lib/my_app_web/user_auth.ex` | Plug functions + LiveView `on_mount` hooks |
| `lib/my_app_web/controllers/user_session_controller.ex` | Login/logout (POST) |
| `lib/my_app_web/live/user_registration_live.ex` | Registration form |
| `lib/my_app_web/live/user_login_live.ex` | Login form |
| `lib/my_app_web/live/user_settings_live.ex` | Email/password settings |
| `lib/my_app_web/live/user_forgot_password_live.ex` | Password reset request |
| `lib/my_app_web/live/user_reset_password_live.ex` | Password reset form |

### Migration (simplified)

```elixir
create table(:users) do
  add :email, :string, null: false
  add :hashed_password, :string, null: false
  add :confirmed_at, :naive_datetime
  timestamps()
end

create unique_index(:users, [:email])

create table(:users_tokens) do
  add :user_id, references(:users, on_delete: :delete_all)
  add :token, :binary, null: false
  add :context, :string, null: false
  add :sent_to, :string
  timestamps(updated_at: false)
end

create index(:users_tokens, [:user_id])
create unique_index(:users_tokens, [:context, :token])
```

---

## The User Schema

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    timestamps()
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_password(changeset, _opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> hash_password()
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)
    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  def valid_password?(%User{hashed_password: hashed}, password)
      when is_binary(hashed) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed)
  end
  def valid_password?(_, _), do: Bcrypt.no_user_verify()
  # ^ Always takes same time — prevents timing attacks
end
```

Key details: `virtual: true` means `:password` is not stored in the DB. `redact: true` hides the value in logs and `inspect/1`. `Bcrypt.no_user_verify()` runs a dummy hash when the user does not exist, preventing timing attacks.

---

## The Token System

Unlike simple session-ID authentication, `phx.gen.auth` uses **database-backed tokens**:

```
Login:
  1. Generate random 32-byte token
  2. Hash with SHA-256 → store HASH in users_tokens table
  3. Base64-encode ORIGINAL token → store in session cookie

Each request:
  1. Read token from session cookie
  2. Base64-decode → SHA-256 hash it
  3. Look up users_tokens by the hash
  4. Load the associated user
```

```elixir
defmodule MyApp.Accounts.UserToken do
  @hash_algorithm :sha256
  @rand_size 32
  @session_validity_in_days 60

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{token: hashed, context: "session", user_id: user.id}}
  end

  def verify_session_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded} ->
        hashed = :crypto.hash(@hash_algorithm, decoded)
        query =
          from t in __MODULE__,
            join: u in assoc(t, :user),
            where: t.token == ^hashed,
            where: t.context == "session",
            where: t.inserted_at > ago(^@session_validity_in_days, "day"),
            select: u
        {:ok, query}
      :error ->
        :error
    end
  end
end
```

### Token Types

| Context | Lifetime | Purpose |
|---------|----------|---------|
| `"session"` | 60 days | Browser login sessions |
| `"remember_me"` | 60 days | Persistent "keep me logged in" cookie |
| `"reset_password"` | 1 day | Password reset email link |
| `"confirm"` | 7 days | Email confirmation link |
| `"change_email"` | 7 days | Email change confirmation |

**Why hash tokens?** The cookie holds the original token; the DB holds only the SHA-256 hash. Even if the database is leaked, attackers cannot forge session cookies. Each token can be individually revoked by deleting its row.

---

## The UserAuth Module

The generated `UserAuth` module provides plugs for controllers and `on_mount` hooks for LiveView:

```elixir
defmodule MyAppWeb.UserAuth do
  use MyAppWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView
  alias MyApp.Accounts

  # --- Plugs (for HTTP requests) ---

  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn |> redirect(to: signed_in_path(conn)) |> halt()
    else
      conn
    end
  end

  # --- LiveView on_mount hooks ---

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(session, socket)
    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, socket |> put_flash(:error, "Log in to continue.") |> redirect(to: ~p"/users/log_in")}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(session, socket)
    if socket.assigns.current_user do
      {:halt, redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(session, socket) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end
    end)
  end
end
```

---

## Generated Routes

```elixir
# Public routes — redirect logged-in users away from login/register:
scope "/", MyAppWeb do
  pipe_through [:browser, :redirect_if_user_is_authenticated]

  live_session :redirect_if_user_is_authenticated,
    on_mount: [{UserAuth, :redirect_if_user_is_authenticated}] do
    live "/users/register", UserRegistrationLive, :new
    live "/users/log_in", UserLoginLive, :new
    live "/users/reset_password", UserForgotPasswordLive, :new
    live "/users/reset_password/:token", UserResetPasswordLive, :edit
  end

  post "/users/log_in", UserSessionController, :create
end

# Protected routes — require login:
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{UserAuth, :ensure_authenticated}] do
    live "/users/settings", UserSettingsLive, :edit
    live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
  end
end

# Routes accessible to anyone:
scope "/", MyAppWeb do
  pipe_through :browser
  delete "/users/log_out", UserSessionController, :delete
  get "/users/confirm/:token", UserConfirmationController, :edit
  post "/users/confirm", UserConfirmationController, :create
end
```

---

## Key Accounts Context Functions

```elixir
# Registration:
Accounts.register_user(%{email: "user@example.com", password: "secure_password"})

# Login (returns user or nil):
Accounts.get_user_by_email_and_password(email, password)

# Token management:
Accounts.generate_user_session_token(user)   # creates token, returns string
Accounts.get_user_by_session_token(token)    # looks up user by token
Accounts.delete_user_session_token(token)    # revokes a session (logout)

# Password reset:
Accounts.deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
Accounts.reset_user_password(user, %{password: "new_password"})

# Email confirmation:
Accounts.deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
Accounts.confirm_user(token)  # sets confirmed_at timestamp
```

---

## Key Takeaways

1. `mix phx.gen.auth` generates a **complete, customizable** auth system — the code is yours
2. It uses **token-based** auth (not just session IDs) — tokens are DB-backed and individually revocable
3. Passwords are hashed with **Bcrypt** by default (Argon2 and PBKDF2 also available via `--hashing-lib`)
4. The `UserAuth` module works for both **controller plug pipelines** and **LiveView `on_mount` hooks**
5. `hashed_password` has `redact: true` — it is hidden from logs and `inspect/1` output
6. `Bcrypt.no_user_verify()` prevents **timing attacks** by taking constant time when the user does not exist
7. All tokens stored in the DB are **SHA-256 hashed** — raw tokens only live in the session cookie
8. `assign_new/3` in LiveView hooks avoids redundant DB queries on WebSocket reconnects
