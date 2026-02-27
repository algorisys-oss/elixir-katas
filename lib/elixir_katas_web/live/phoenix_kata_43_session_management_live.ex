defmodule ElixirKatasWeb.PhoenixKata43SessionManagementLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Session Management — Complete Lifecycle

    defmodule MyAppWeb.UserAuth do
      import Plug.Conn
      import Phoenix.Controller
      alias MyApp.Accounts

      @remember_me_cookie "_app_remember_me"
      @remember_me_options [sign: true, max_age: 60 * 60 * 24 * 60,
                             same_site: "Lax"]

      # --- Login ---
      def log_in_user(conn, user, params \\\\ %{}) do
        token = Accounts.generate_user_session_token(user)
        return_to = get_session(conn, :user_return_to)
        conn
        |> renew_session()
        |> put_session(:user_token, token)
        |> maybe_write_remember_me_cookie(token, params)
        |> redirect(to: return_to || ~p"/")
      end

      # --- Logout ---
      def log_out_user(conn) do
        token = get_session(conn, :user_token)
        token && Accounts.delete_user_session_token(token)
        conn
        |> renew_session()
        |> delete_resp_cookie(@remember_me_cookie)
        |> redirect(to: ~p"/")
      end

      # --- Plugs ---
      def fetch_current_user(conn, _opts) do
        {token, conn} = ensure_user_token(conn)
        user = token && Accounts.get_user_by_session_token(token)
        assign(conn, :current_user, user)
      end

      def require_authenticated_user(conn, _opts) do
        if conn.assigns[:current_user] do
          conn
        else
          conn
          |> put_flash(:error, "You must log in.")
          |> maybe_store_return_to()
          |> redirect(to: ~p"/users/log_in")
          |> halt()
        end
      end

      # --- Remember Me ---
      defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
        put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
      end
      defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

      defp ensure_user_token(conn) do
        if token = get_session(conn, :user_token) do
          {token, conn}
        else
          conn = fetch_cookies(conn, signed: [@remember_me_cookie])
          if token = conn.cookies[@remember_me_cookie] do
            {token, put_session(conn, :user_token, token)}
          else
            {nil, conn}
          end
        end
      end

      # --- Session Fixation Prevention ---
      defp renew_session(conn) do
        delete_csrf_token()
        conn |> configure_session(renew: true) |> clear_session()
      end
    end

    # --- Cookie Configuration (config/config.exs) ---
    config :my_app, MyAppWeb.Endpoint,
      session_options: [
        store: :cookie,
        key: "_my_app_key",
        signing_salt: "some_signing_salt",
        same_site: "Lax",
        secure: true,
        http_only: true,
        max_age: 24 * 60 * 60
      ]

    # --- Session Token Flow ---
    # 1. Generate random 32-byte token on login
    # 2. Hash it and store hash in users_tokens table
    # 3. Store ORIGINAL (unhashed) token in session cookie
    # 4. On next request: hash cookie token, look up DB by hash
    # => Even if DB is compromised, tokens can't be forged
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "login")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Session Management</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Login, logout, remember me, session tokens, and cookie security — the building blocks of stateful web authentication.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "cookies", "remember_me", "security", "code"]}
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
            <button :for={topic <- ["login", "logout", "token"]}
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
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Session Cookie</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Signed cookie holds a token. Token maps to user in the DB.</p>
            </div>
            <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800">
              <p class="text-sm font-semibold text-teal-700 dark:text-teal-300 mb-1">Renew on Login</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Always call <code>configure_session(renew: true)</code> to prevent session fixation.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Clear on Logout</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Delete session token from DB, then drop the session cookie.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Cookie Security -->
      <%= if @active_tab == "cookies" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix sessions use signed (and optionally encrypted) cookies. Understanding cookie flags is critical for security.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{cookie_config_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Cookie Flags</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>HttpOnly</strong>: JS cannot read the cookie (XSS protection)</li>
                <li><strong>Secure</strong>: only sent over HTTPS</li>
                <li><strong>SameSite=Lax</strong>: blocks cross-site POST (CSRF protection)</li>
                <li><strong>Max-Age</strong>: when it expires (session = until browser closes)</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Reading the Session</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{session_read_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Remember Me -->
      <%= if @active_tab == "remember_me" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            "Remember me" extends the session beyond the browser session using a long-lived cookie.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{remember_me_code()}</div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">How it Works</p>
            <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
              <li>1. On login with "remember me" checked, write a separate persistent cookie</li>
              <li>2. On each request, if no session token, check the remember-me cookie</li>
              <li>3. Use that cookie token to load the user and create a new session</li>
              <li>4. On logout, delete both the session cookie and remember-me cookie</li>
            </ul>
          </div>
        </div>
      <% end %>

      <!-- Security -->
      <%= if @active_tab == "security" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Session security best practices built into Phoenix.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Session Fixation Prevention</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{fixation_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Sign Out All Devices</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{signout_all_code()}</div>
            </div>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{session_security_code()}</div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Session Management</h4>
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
  defp tab_label("cookies"), do: "Cookie Security"
  defp tab_label("remember_me"), do: "Remember Me"
  defp tab_label("security"), do: "Security"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("login"), do: "Login"
  defp topic_label("logout"), do: "Logout"
  defp topic_label("token"), do: "Session Token"

  defp overview_code("login") do
    """
    defmodule MyAppWeb.UserSessionController do
      use MyAppWeb, :controller

      def create(conn, %{"user" => %{"email" => email,
                                     "password" => password} = params}) do
        case Accounts.get_user_by_email_and_password(email, password) do
          nil ->
            # Don't reveal whether the email exists!
            conn
            |> put_flash(:error, "Invalid email or password.")
            |> put_flash(:email, String.slice(email, 0, 160))
            |> redirect(to: ~p"/users/log_in")

          user ->
            # Renew session to prevent fixation attack:
            conn
            |> configure_session(renew: true)
            |> UserAuth.log_in_user(user, params)
        end
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("logout") do
    """
    def delete(conn, _params) do
      conn
      |> put_flash(:info, "Logged out successfully.")
      |> UserAuth.log_out_user()
    end

    # UserAuth.log_out_user/1:
    def log_out_user(conn) do
      # 1. Get the current session token:
      user_token = get_session(conn, :user_token)

      # 2. Delete it from the database:
      user_token && Accounts.delete_user_session_token(user_token)

      # 3. Clear the session and remember-me cookie:
      conn
      |> renew_session()
      |> delete_resp_cookie(@remember_me_cookie)
      |> redirect(to: ~p"/")
    end

    defp renew_session(conn) do
      delete_csrf_token()
      conn
      |> configure_session(renew: true)
      |> clear_session()
    end\
    """
    |> String.trim()
  end

  defp overview_code("token") do
    """
    # Session token flow:
    # 1. On login, generate a random 32-byte token:
    token = :crypto.strong_rand_bytes(32)

    # 2. Hash it and store the hash in users_tokens table:
    hashed = :crypto.hash(:sha256, token)
    Repo.insert!(%UserToken{
      token: hashed,
      context: "session",
      user_id: user.id
    })

    # 3. Store the ORIGINAL (unhashed) token in the session cookie:
    encoded = Base.url_encode64(token, padding: false)
    conn |> put_session(:user_token, encoded)

    # 4. On next request, fetch token from session, hash it,
    #    look up users_tokens by hash:
    {:ok, decoded} = Base.url_decode64(token_from_session)
    hashed = :crypto.hash(:sha256, decoded)
    user_token = Repo.get_by(UserToken, token: hashed)

    # The token in the cookie never equals the DB value —
    # even if the DB is compromised, tokens can't be forged.\
    """
    |> String.trim()
  end

  defp cookie_config_code do
    """
    # Endpoint configuration (config/config.exs):
    config :my_app, MyAppWeb.Endpoint,
      url: [host: "localhost"],
      secret_key_base: System.get_env("SECRET_KEY_BASE"),
      # Session cookie settings:
      live_view: [signing_salt: "some_salt"],
      session_options: [
        store: :cookie,
        key: "_my_app_key",
        signing_salt: "some_signing_salt",
        # Options passed to Set-Cookie header:
        same_site: "Lax",     # Lax, Strict, or None
        secure: true,          # HTTPS only (set in prod)
        http_only: true,       # JS can't read it
        max_age: 24 * 60 * 60  # 1 day (nil = session cookie)
      ]

    # For encrypted sessions (hide data from user):
    session_options: [
      store: :cookie,
      key: "_my_app_key",
      encryption_salt: "some_encryption_salt",
      signing_salt: "some_signing_salt"
    ]

    # Phoenix uses Plug.Session — options:
    # https://hexdocs.pm/plug/Plug.Session.COOKIE.html\
    """
    |> String.trim()
  end

  defp session_read_code do
    """
    # Plug pipeline includes :fetch_session:
    plug :fetch_session

    # Writing to session:
    conn = put_session(conn, :user_token, token)
    conn = put_session(conn, :locale, "en")

    # Reading from session:
    user_token = get_session(conn, :user_token)
    locale = get_session(conn, :locale)

    # Deleting a key:
    conn = delete_session(conn, :return_to)

    # Clearing entire session:
    conn = clear_session(conn)

    # Dropping session (prevents re-creation):
    conn = configure_session(conn, drop: true)\
    """
    |> String.trim()
  end

  defp remember_me_code do
    """
    @remember_me_cookie "_my_app_user_remember_me"
    @remember_me_options [sign: true, max_age: 60 * 60 * 24 * 60,
                          same_site: "Lax"]

    def log_in_user(conn, user, params \\\\ %{}) do
      token = Accounts.generate_user_session_token(user)
      user_return_to = get_session(conn, :user_return_to)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> maybe_write_remember_me_cookie(token, params)
      |> redirect(to: user_return_to || ~p"/")
    end

    defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
      put_resp_cookie(conn, @remember_me_cookie, token,
        @remember_me_options)
    end
    defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

    # On each request — check remember-me cookie if no session:
    defp ensure_user_token(conn) do
      if token = get_session(conn, :user_token) do
        {token, conn}
      else
        conn = fetch_cookies(conn, signed: [@remember_me_cookie])
        if token = conn.cookies[@remember_me_cookie] do
          {token, put_session(conn, :user_token, token)}
        else
          {nil, conn}
        end
      end
    end

    # Login form:
    # <input type="checkbox" name="user[remember_me]" value="true" />
    # <label>Keep me logged in for 60 days</label>\
    """
    |> String.trim()
  end

  defp fixation_code do
    """
    # Session fixation: attacker sets a known session ID
    # before victim logs in, then uses it afterward.

    # PREVENTION: always renew session on login:
    def log_in_user(conn, user, params) do
      conn
      |> renew_session()   # regenerates session ID!
      |> put_session(:user_token, token)
      |> redirect(to: ~p"/")
    end

    defp renew_session(conn) do
      delete_csrf_token()     # clear CSRF token too
      conn
      |> configure_session(renew: true)  # new session ID
      |> clear_session()                 # remove old data
    end\
    """
    |> String.trim()
  end

  defp signout_all_code do
    """
    # Delete ALL session tokens for a user:
    # (sign out of all devices at once)
    def delete_all_user_session_tokens(user) do
      Repo.delete_all(
        from t in UserToken,
          where: t.user_id == ^user.id,
          where: t.context == "session"
      )
    end

    # Or in a settings controller:
    def delete(conn, _params) do
      Accounts.delete_all_user_session_tokens(
        conn.assigns.current_user
      )
      conn
      |> put_flash(:info, "All sessions terminated.")
      |> UserAuth.log_out_user()
    end\
    """
    |> String.trim()
  end

  defp session_security_code do
    """
    # Security checklist for sessions:

    # 1. HTTPS only in production (Secure flag):
    config :my_app, MyAppWeb.Endpoint,
      force_ssl: [rewrite_on: [:x_forwarded_proto]]

    # 2. HttpOnly cookie (JS can't steal it):
    #    set http_only: true in session_options

    # 3. SameSite=Lax (CSRF protection for cookies):
    #    set same_site: "Lax" in session_options

    # 4. Renew session ID on login (fixation prevention):
    configure_session(conn, renew: true)

    # 5. Short-lived sessions for sensitive operations:
    #    Use step-up auth for /admin routes

    # 6. Log session creation/deletion for audit:
    Logger.info("Session created for user \#{user.id}")

    # 7. Rotate secret_key_base periodically:
    #    New key invalidates all existing sessions\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete session lifecycle:

    defmodule MyAppWeb.UserAuth do
      import Plug.Conn
      import Phoenix.Controller
      alias MyApp.Accounts

      @remember_me_cookie "_app_remember_me"
      @remember_me_options [sign: true,
                             max_age: 60 * 60 * 24 * 60,
                             same_site: "Lax"]

      # Called after password verification:
      def log_in_user(conn, user, params \\\\ %{}) do
        token = Accounts.generate_user_session_token(user)
        return_to = get_session(conn, :user_return_to)
        conn
        |> renew_session()
        |> put_session(:user_token, token)
        |> maybe_write_remember_me_cookie(token, params)
        |> redirect(to: return_to || ~p"/")
      end

      # Called on logout:
      def log_out_user(conn) do
        token = get_session(conn, :user_token)
        token && Accounts.delete_user_session_token(token)
        conn
        |> renew_session()
        |> delete_resp_cookie(@remember_me_cookie)
        |> redirect(to: ~p"/")
      end

      # fetch_current_user plug:
      def fetch_current_user(conn, _opts) do
        {token, conn} = ensure_user_token(conn)
        user = token && Accounts.get_user_by_session_token(token)
        assign(conn, :current_user, user)
      end

      # require_authenticated_user plug:
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

      defp ensure_user_token(conn) do
        if token = get_session(conn, :user_token) do
          {token, conn}
        else
          conn = fetch_cookies(conn, signed: [@remember_me_cookie])
          if token = conn.cookies[@remember_me_cookie] do
            {token, put_session(conn, :user_token, token)}
          else
            {nil, conn}
          end
        end
      end

      defp renew_session(conn) do
        delete_csrf_token()
        conn |> configure_session(renew: true) |> clear_session()
      end

      defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
        put_resp_cookie(conn, @remember_me_cookie, token,
          @remember_me_options)
      end
      defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

      defp maybe_store_return_to(%{method: "GET"} = conn) do
        put_session(conn, :user_return_to, current_path(conn))
      end
      defp maybe_store_return_to(conn), do: conn
    end\
    """
    |> String.trim()
  end
end
