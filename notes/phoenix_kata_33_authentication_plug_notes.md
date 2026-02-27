# Kata 33: Authentication Plug

## Session-Based Authentication Overview

Phoenix uses **session-based authentication** by default. The flow:

1. User submits credentials → verify against DB
2. On success, write user ID to the encrypted session cookie
3. On every request, a plug reads the session and loads the user
4. Protected routes check `conn.assigns.current_user` and redirect if nil

```
Request
  └── :browser pipeline
        ├── :fetch_session         (load session from cookie)
        ├── FetchCurrentUser       (read user_id → load user → assign)
        └── ... more plugs

Protected scope
  └── [:browser, :require_auth]
        ├── FetchCurrentUser       (already ran)
        └── RequireAuth            (redirect if current_user is nil)

Controller
  └── conn.assigns.current_user    (available everywhere)
```

---

## FetchCurrentUser Plug

This plug runs on **every request** (inside the `:browser` pipeline) and loads the current user from the session:

```elixir
defmodule MyAppWeb.Plugs.FetchCurrentUser do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    cond do
      user_id == nil ->
        assign(conn, :current_user, nil)

      user = MyApp.Accounts.get_user(user_id) ->
        assign(conn, :current_user, user)

      true ->
        # user_id exists in session but user was deleted
        conn
        |> clear_session()
        |> assign(:current_user, nil)
    end
  end
end
```

Register in the `:browser` pipeline so it runs on all browser requests:

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug MyAppWeb.Plugs.FetchCurrentUser   # always runs last
end
```

---

## RequireAuth Plug

This plug only runs on **protected routes**. It redirects to login if no user is found:

```elixir
defmodule MyAppWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: ~p"/login")
        |> halt()

      _user ->
        conn   # let the pipeline continue
    end
  end
end
```

As a simple function plug in the router:

```elixir
defp require_auth(conn, _opts) do
  if conn.assigns.current_user do
    conn
  else
    conn
    |> put_flash(:error, "Please log in.")
    |> redirect(to: ~p"/login")
    |> halt()
  end
end
```

---

## Login and Logout Controller

```elixir
defmodule MyAppWeb.SessionController do
  use MyAppWeb, :controller

  def new(conn, _params), do: render(conn, :new)

  def create(conn, %{"email" => email, "password" => password}) do
    case MyApp.Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> configure_session(renew: true)   # prevent session fixation
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back, #{user.name}!")
        |> redirect(to: ~p"/dashboard")

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> render(:new)
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: ~p"/")
  end
end
```

**`configure_session(renew: true)`** regenerates the session ID on login to prevent session fixation attacks.

---

## Protecting Routes in the Router

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MyAppWeb.Plugs.FetchCurrentUser
  end

  # Public routes — current_user may be nil
  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
    resources "/products", ProductController, only: [:index, :show]
  end

  # Protected routes — requires logged-in user
  scope "/", MyAppWeb do
    pipe_through [:browser, MyAppWeb.Plugs.RequireAuth]

    get "/dashboard", DashboardController, :index
    resources "/orders", OrderController
    resources "/profile", ProfileController, singleton: true
  end

  # Admin routes — requires admin role
  scope "/admin", MyAppWeb.Admin, as: :admin do
    pipe_through [:browser, MyAppWeb.Plugs.RequireAuth,
                  MyAppWeb.Plugs.RequireAdmin]

    resources "/users", UserController
    get "/dashboard", DashboardController, :index
  end
end
```

---

## Using current_user in Templates and Controllers

```elixir
# In a controller:
def index(conn, _params) do
  user = conn.assigns.current_user
  orders = Orders.list_for_user(user)
  render(conn, :index, orders: orders, page_title: "My Orders")
end

# In a controller plug (only for some actions):
plug :verify_owner when action in [:edit, :update, :delete]

defp verify_owner(conn, _opts) do
  item = conn.assigns.item
  if item.user_id == conn.assigns.current_user.id do
    conn
  else
    conn
    |> put_flash(:error, "Not authorized")
    |> redirect(to: ~p"/items")
    |> halt()
  end
end
```

```heex
<%# In any template — current_user comes from assigns: %>
<%= if @current_user do %>
  <nav>
    <span>Hello, {@current_user.name}!</span>
    <.link href={~p"/logout"} method="delete">Log out</.link>
  </nav>
<% else %>
  <nav>
    <.link navigate={~p"/login"}>Log in</.link>
    <.link navigate={~p"/register"}>Sign up</.link>
  </nav>
<% end %>
```

---

## LiveView Authentication

Plug pipelines run on HTTP requests, but LiveView reconnects over WebSocket — **bypassing the plug pipeline**. Use `on_mount` hooks instead:

```elixir
defmodule MyAppWeb.UserAuth do
  import Phoenix.LiveView

  # Mount user without requiring auth (for public pages):
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, assign_current_user(socket, session)}
  end

  # Require auth — redirect to login if not authenticated:
  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Log in to continue.")
        |> redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  defp assign_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["user_id"] do
        MyApp.Accounts.get_user!(user_id)
      end
    end)
  end
end
```

Apply via `live_session` in the router:

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  # Public — user may or may not be logged in
  live_session :public,
    on_mount: [{UserAuth, :mount_current_user}] do
    live "/", HomeLive
    live "/products", ProductLive.Index
  end

  # Protected — must be logged in
  live_session :authenticated,
    on_mount: [{UserAuth, :require_authenticated_user}] do
    live "/dashboard", DashboardLive
    live "/orders", OrderLive.Index
    live "/orders/:id", OrderLive.Show
  end
end
```

`assign_new/3` is important here — it only assigns `current_user` if it hasn't been set yet, avoiding a DB query on reconnects if the value is already in the socket.

---

## Redirect Back After Login

```elixir
# In RequireAuth: save the intended destination
defp require_auth(conn, _opts) do
  if conn.assigns.current_user do
    conn
  else
    conn
    |> put_session(:return_to, conn.request_path)
    |> redirect(to: ~p"/login")
    |> halt()
  end
end

# In SessionController.create: redirect back
def create(conn, %{"email" => email, "password" => pw}) do
  case Accounts.authenticate_user(email, pw) do
    {:ok, user} ->
      return_to = get_session(conn, :return_to) || ~p"/dashboard"

      conn
      |> configure_session(renew: true)
      |> put_session(:user_id, user.id)
      |> delete_session(:return_to)
      |> redirect(to: return_to)
  end
end
```

---

## Key Takeaways

1. **FetchCurrentUser** runs on every request — loads user from session into `conn.assigns.current_user`
2. **RequireAuth** runs only on protected routes — halts and redirects if `current_user` is nil
3. Use `configure_session(renew: true)` on login to prevent session fixation
4. Use `clear_session()` + `configure_session(drop: true)` on logout
5. For **LiveView**, use `on_mount` hooks in `live_session` — plug pipelines don't run on WebSocket reconnects
6. `assign_new/3` in LiveView prevents redundant DB queries on reconnects
7. Always `halt/1` after redirecting to stop the pipeline from continuing
