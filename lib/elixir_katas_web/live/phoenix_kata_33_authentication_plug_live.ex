defmodule ElixirKatasWeb.PhoenixKata33AuthenticationPlugLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # 1. FetchCurrentUser plug (runs on every request):
    defmodule MyAppWeb.Plugs.FetchCurrentUser do
      import Plug.Conn
      def init(opts), do: opts
      def call(conn, _opts) do
        if user_id = get_session(conn, :user_id) do
          case MyApp.Accounts.get_user(user_id) do
            nil   -> conn |> clear_session() |> assign(:current_user, nil)
            user  -> assign(conn, :current_user, user)
          end
        else
          assign(conn, :current_user, nil)
        end
      end
    end

    # 2. RequireAuth plug (runs on protected routes):
    defmodule MyAppWeb.Plugs.RequireAuth do
      import Plug.Conn
      import Phoenix.Controller
      def init(opts), do: opts
      def call(conn, _opts) do
        if conn.assigns.current_user do
          conn
        else
          conn
          |> put_flash(:error, "Please log in.")
          |> redirect(to: ~p"/login")
          |> halt()
        end
      end
    end

    # 3. UserAuth for LiveView (on_mount hooks):
    defmodule MyAppWeb.UserAuth do
      import Phoenix.LiveView

      def on_mount(:require_authenticated_user, _params, session, socket) do
        socket = assign_current_user(socket, session)
        if socket.assigns.current_user do
          {:cont, socket}
        else
          {:halt, socket |> put_flash(:error, "Log in.") |> redirect(to: ~p"/login")}
        end
      end

      def on_mount(:mount_current_user, _params, session, socket) do
        {:cont, assign_current_user(socket, session)}
      end

      defp assign_current_user(socket, session) do
        Phoenix.Component.assign_new(socket, :current_user, fn ->
          if id = session["user_id"], do: MyApp.Accounts.get_user!(id)
        end)
      end
    end

    # 4. Router wiring:
    defmodule MyAppWeb.Router do
      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug MyAppWeb.Plugs.FetchCurrentUser  # always
      end

      scope "/" do
        pipe_through :browser
        live_session :public,
          on_mount: [{UserAuth, :mount_current_user}] do
          live "/", HomeLive
        end
      end

      scope "/" do
        pipe_through [:browser, MyAppWeb.Plugs.RequireAuth]
        live_session :authenticated,
          on_mount: [{UserAuth, :require_authenticated_user}] do
          live "/dashboard", DashboardLive
        end
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "flow")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Authentication Plug</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Session-based auth: loading the current user from session, protecting routes, and exposing <code>current_user</code> to templates.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "fetch_user", "require_auth", "liveview", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400 border-b-2 border-teal-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["flow", "pipeline", "session"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Step 1: Login</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">User submits credentials. Verify and write user ID to session.</p>
            </div>
            <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800">
              <p class="text-sm font-semibold text-teal-700 dark:text-teal-300 mb-1">Step 2: Fetch User</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">On each request, read user ID from session and load user into <code>conn.assigns</code>.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Step 3: Require Auth</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">For protected routes, redirect to login if no current user.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- FetchCurrentUser -->
      <%= if @active_tab == "fetch_user" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>FetchCurrentUser</code> runs on every request. It loads the user from the session (if logged in) and stores them in <code>conn.assigns.current_user</code>.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{fetch_user_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">What it does</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li class="flex items-start gap-2"><span class="text-amber-500">1.</span> Read <code>user_id</code> from session</li>
                <li class="flex items-start gap-2"><span class="text-amber-500">2.</span> If present: load user from DB</li>
                <li class="flex items-start gap-2"><span class="text-amber-500">3.</span> Assign to <code>conn.assigns.current_user</code></li>
                <li class="flex items-start gap-2"><span class="text-amber-500">4.</span> If missing: assign <code>nil</code></li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Using current_user</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{using_current_user_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- RequireAuth -->
      <%= if @active_tab == "require_auth" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>RequireAuth</code> runs after <code>FetchCurrentUser</code>. It halts the pipeline if no user is logged in.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{require_auth_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Router Setup</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{router_auth_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Login / Logout</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{login_logout_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Redirect back after login</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{redirect_back_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- LiveView Auth -->
      <%= if @active_tab == "liveview" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            LiveView connections come through the router too, but the WebSocket upgrade needs special handling. Use <code>on_mount</code> hooks for LiveView auth.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{liveview_auth_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">on_mount Hook</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{on_mount_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">LiveView Router</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{liveview_router_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Why on_mount?</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Plug pipelines run on the initial HTTP request. But when LiveView reconnects over WebSocket, it bypasses the HTTP pipeline. <code>on_mount</code> hooks run on both the initial mount AND reconnects, ensuring auth is always enforced.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Auth System</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("overview"), do: "Overview"
  defp tab_label("fetch_user"), do: "FetchCurrentUser"
  defp tab_label("require_auth"), do: "RequireAuth"
  defp tab_label("liveview"), do: "LiveView Auth"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("flow"), do: "Auth Flow"
  defp topic_label("pipeline"), do: "Pipelines"
  defp topic_label("session"), do: "Session Data"

  defp overview_code("flow") do
    """
    # Session-based auth flow:

    # 1. User logs in (POST /login):
    def create(conn, %{"email" => email, "password" => pw}) do
      case Accounts.authenticate(email, pw) do
        {:ok, user} ->
          conn
          |> put_session(:user_id, user.id)
          |> redirect(to: ~p"/dashboard")

        {:error, _} ->
          conn
          |> put_flash(:error, "Invalid credentials")
          |> render(:new)
      end
    end

    # 2. Every request: FetchCurrentUser plug reads session
    #    and puts user in conn.assigns.current_user

    # 3. Protected routes: RequireAuth checks assigns
    #    and redirects to /login if nil\
    """
    |> String.trim()
  end

  defp overview_code("pipeline") do
    """
    defmodule MyAppWeb.Router do
      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug MyAppWeb.Plugs.FetchCurrentUser  # always runs
      end

      # Public routes (FetchCurrentUser still runs):
      scope "/" do
        pipe_through :browser
        get "/", PageController, :home
        get "/login", SessionController, :new
        post "/login", SessionController, :create
      end

      # Protected routes:
      scope "/" do
        pipe_through [:browser, :require_auth]
        get "/dashboard", DashboardController, :index
        resources "/orders", OrderController
      end

      defp require_auth(conn, _opts) do
        if conn.assigns.current_user do
          conn
        else
          conn
          |> redirect(to: ~p"/login")
          |> halt()
        end
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("session") do
    """
    # Session stores data across requests using signed cookies.
    # Phoenix uses :fetch_session plug to load session data.

    # Writing to session (on login):
    put_session(conn, :user_id, user.id)

    # Reading from session (in FetchCurrentUser):
    get_session(conn, :user_id)  # => 42 or nil

    # Clearing session (on logout):
    conn
    |> clear_session()
    |> configure_session(drop: true)

    # Regenerating session ID (prevents session fixation):
    configure_session(conn, renew: true)

    # Session data is signed but NOT encrypted by default
    # (users can read it, not modify it).
    # Use :plug_session encrypted for sensitive data.\
    """
    |> String.trim()
  end

  defp fetch_user_code do
    """
    defmodule MyAppWeb.Plugs.FetchCurrentUser do
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        user_id = get_session(conn, :user_id)

        cond do
          user_id == nil ->
            # Not logged in — assign nil
            assign(conn, :current_user, nil)

          user = MyApp.Accounts.get_user(user_id) ->
            # Found user — assign it
            assign(conn, :current_user, user)

          true ->
            # User ID in session but no user found
            # (deleted account) — clear session
            conn
            |> clear_session()
            |> assign(:current_user, nil)
        end
      end
    end

    # Register in :browser pipeline — runs on EVERY request
    pipeline :browser do
      # ... other plugs ...
      plug MyAppWeb.Plugs.FetchCurrentUser
    end\
    """
    |> String.trim()
  end

  defp using_current_user_code do
    """
    # In controllers:
    def index(conn, _params) do
      user = conn.assigns.current_user
      orders = Orders.list_for_user(user)
      render(conn, :index, orders: orders)
    end

    # In templates (HEEx):
    <%= if @current_user do %>
      <p>Hello, {@current_user.name}!</p>
      <.link href="/logout" method="delete">
        Log out
      </.link>
    <% else %>
      <.link navigate="/login">Log in</.link>
    <% end %>\
    """
    |> String.trim()
  end

  defp require_auth_code do
    """
    defmodule MyAppWeb.Plugs.RequireAuth do
      import Plug.Conn
      import Phoenix.Controller

      def init(opts), do: opts

      def call(conn, _opts) do
        case conn.assigns[:current_user] do
          nil ->
            # No user — redirect to login
            conn
            |> put_flash(:error, "You must be logged in.")
            |> redirect(to: "/login")
            |> halt()

          _user ->
            # User present — continue pipeline
            conn
        end
      end
    end

    # Or as a simple function plug in the router:
    defp require_auth(conn, _opts) do
      if conn.assigns.current_user do
        conn
      else
        conn
        |> Phoenix.Controller.put_flash(:error, "Please log in.")
        |> Phoenix.Controller.redirect(to: ~p"/login")
        |> halt()
      end
    end\
    """
    |> String.trim()
  end

  defp router_auth_code do
    """
    scope "/", MyAppWeb do
      pipe_through :browser  # includes FetchCurrentUser

      # Public
      get "/", PageController, :home
      resources "/sessions", SessionController,
        only: [:new, :create, :delete]
    end

    scope "/", MyAppWeb do
      pipe_through [:browser, :require_auth]

      # Protected
      get "/dashboard", DashboardController, :index
      resources "/orders", OrderController
      resources "/profile", ProfileController,
        singleton: true
    end

    scope "/admin", MyAppWeb.Admin, as: :admin do
      pipe_through [:browser, :require_auth, :require_admin]
      resources "/users", UserController
    end\
    """
    |> String.trim()
  end

  defp login_logout_code do
    """
    defmodule MyAppWeb.SessionController do
      use MyAppWeb, :controller

      # GET /login
      def new(conn, _params), do: render(conn, :new)

      # POST /login
      def create(conn, %{"email" => email, "password" => pw}) do
        case Accounts.authenticate_user(email, pw) do
          {:ok, user} ->
            conn
            |> configure_session(renew: true)  # prevent fixation
            |> put_session(:user_id, user.id)
            |> put_flash(:info, "Welcome back!")
            |> redirect(to: ~p"/dashboard")

          {:error, :invalid_credentials} ->
            conn
            |> put_flash(:error, "Invalid email or password.")
            |> render(:new)
        end
      end

      # DELETE /sessions/:id
      def delete(conn, _params) do
        conn
        |> clear_session()
        |> configure_session(drop: true)
        |> put_flash(:info, "Logged out.")
        |> redirect(to: ~p"/")
      end
    end\
    """
    |> String.trim()
  end

  defp redirect_back_code do
    """
    # Save the requested URL before redirecting to login:
    defp require_auth(conn, _opts) do
      if conn.assigns.current_user do
        conn
      else
        return_to = conn.request_path
        conn
        |> put_session(:return_to, return_to)
        |> redirect(to: ~p"/login")
        |> halt()
      end
    end

    # After successful login, redirect back:
    def create(conn, %{"email" => email, "password" => pw}) do
      case Accounts.authenticate_user(email, pw) do
        {:ok, user} ->
          return_to = get_session(conn, :return_to) || "/dashboard"

          conn
          |> configure_session(renew: true)
          |> put_session(:user_id, user.id)
          |> delete_session(:return_to)
          |> redirect(to: return_to)
      end
    end\
    """
    |> String.trim()
  end

  defp liveview_auth_code do
    """
    # LiveView auth uses on_mount hooks, not plug pipelines.
    # The plug pipeline runs on the initial HTTP request,
    # but LiveView reconnects via WebSocket (bypassing plugs).

    # on_mount/4 runs on both:
    #  1. Initial mount (from HTTP conn)
    #  2. WebSocket reconnect

    defmodule MyAppWeb.UserAuth do
      import Phoenix.LiveView

      def on_mount(:require_authenticated_user, _params,
                   session, socket) do
        socket = mount_current_user(socket, session)

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

      def on_mount(:mount_current_user, _params, session, socket) do
        {:cont, mount_current_user(socket, session)}
      end

      defp mount_current_user(socket, session) do
        Phoenix.Component.assign_new(socket, :current_user, fn ->
          if user_id = session["user_id"] do
            MyApp.Accounts.get_user!(user_id)
          end
        end)
      end
    end\
    """
    |> String.trim()
  end

  defp on_mount_code do
    """
    # Using on_mount in a LiveView:
    defmodule MyAppWeb.DashboardLive do
      use MyAppWeb, :live_view

      on_mount {MyAppWeb.UserAuth, :require_authenticated_user}

      def mount(_params, _session, socket) do
        # socket.assigns.current_user is available here!
        user = socket.assigns.current_user
        {:ok, assign(socket, orders: Orders.for_user(user))}
      end
    end

    # on_mount hooks run BEFORE mount/3.
    # If it halts, mount/3 never runs.\
    """
    |> String.trim()
  end

  defp liveview_router_code do
    """
    # Router: apply on_mount via live_session:
    scope "/", MyAppWeb do
      pipe_through :browser

      # Public LiveViews (current_user may be nil):
      live_session :public,
        on_mount: [{UserAuth, :mount_current_user}] do
        live "/", HomeLive
        live "/products", ProductLive.Index
      end

      # Protected LiveViews (must be logged in):
      live_session :authenticated,
        on_mount: [{UserAuth, :require_authenticated_user}] do
        live "/dashboard", DashboardLive
        live "/orders", OrderLive.Index
        live "/orders/:id", OrderLive.Show
      end
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # 1. FetchCurrentUser plug (runs on every request):
    defmodule MyAppWeb.Plugs.FetchCurrentUser do
      import Plug.Conn
      def init(opts), do: opts
      def call(conn, _opts) do
        if user_id = get_session(conn, :user_id) do
          case MyApp.Accounts.get_user(user_id) do
            nil   -> conn |> clear_session() |> assign(:current_user, nil)
            user  -> assign(conn, :current_user, user)
          end
        else
          assign(conn, :current_user, nil)
        end
      end
    end

    # 2. RequireAuth plug (runs on protected routes):
    defmodule MyAppWeb.Plugs.RequireAuth do
      import Plug.Conn
      import Phoenix.Controller
      def init(opts), do: opts
      def call(conn, _opts) do
        if conn.assigns.current_user do
          conn
        else
          conn
          |> put_flash(:error, "Please log in.")
          |> redirect(to: ~p"/login")
          |> halt()
        end
      end
    end

    # 3. UserAuth for LiveView:
    defmodule MyAppWeb.UserAuth do
      import Phoenix.LiveView

      def on_mount(:require_authenticated_user, _params, session, socket) do
        socket = assign_current_user(socket, session)
        if socket.assigns.current_user do
          {:cont, socket}
        else
          {:halt, socket |> put_flash(:error, "Log in.") |> redirect(to: ~p"/login")}
        end
      end

      def on_mount(:mount_current_user, _params, session, socket) do
        {:cont, assign_current_user(socket, session)}
      end

      defp assign_current_user(socket, session) do
        Phoenix.Component.assign_new(socket, :current_user, fn ->
          if id = session["user_id"], do: MyApp.Accounts.get_user!(id)
        end)
      end
    end

    # 4. Router wiring:
    defmodule MyAppWeb.Router do
      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug MyAppWeb.Plugs.FetchCurrentUser  # always
      end

      scope "/" do
        pipe_through :browser
        live_session :public,
          on_mount: [{UserAuth, :mount_current_user}] do
          live "/", HomeLive
        end
      end

      scope "/" do
        pipe_through [:browser, MyAppWeb.Plugs.RequireAuth]
        live_session :authenticated,
          on_mount: [{UserAuth, :require_authenticated_user}] do
          live "/dashboard", DashboardLive
          live "/orders", OrderLive.Index
        end
      end
    end\
    """
    |> String.trim()
  end
end
