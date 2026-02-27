defmodule ElixirKatasWeb.PhoenixKata42PhoenixAuthGeneratorLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # mix phx.gen.auth Accounts User users
    # Generates a complete token-based authentication system.

    # UserAuth plug + on_mount hooks (generated):
    defmodule MyAppWeb.UserAuth do
      use MyAppWeb, :verified_routes
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView
      alias MyApp.Accounts

      # --- Plugs ---
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
          |> put_flash(:error, "Log in to continue.")
          |> maybe_store_return_to()
          |> redirect(to: ~p"/users/log_in")
          |> halt()
        end
      end

      # --- LiveView on_mount ---
      def on_mount(:ensure_authenticated, _params, session, socket) do
        socket = mount_current_user(session, socket)
        if socket.assigns.current_user do
          {:cont, socket}
        else
          socket =
            socket
            |> put_flash(:error, "Log in to continue.")
            |> redirect(to: ~p"/users/log_in")
          {:halt, socket}
        end
      end

      def on_mount(:mount_current_user, _params, session, socket) do
        {:cont, mount_current_user(session, socket)}
      end

      defp mount_current_user(session, socket) do
        Phoenix.Component.assign_new(socket, :current_user, fn ->
          if user_token = session["user_token"] do
            Accounts.get_user_by_session_token(user_token)
          end
        end)
      end
    end

    # Token system — tokens are hashed in DB, can be revoked:
    defmodule MyApp.Accounts.UserToken do
      @hash_algorithm :sha256
      @rand_size 32

      def build_session_token(user) do
        token = :crypto.strong_rand_bytes(@rand_size)
        hashed = :crypto.hash(@hash_algorithm, token)
        {Base.url_encode64(token),
         %UserToken{token: hashed, context: "session", user_id: user.id}}
      end
    end

    # Generated routes:
    scope "/", MyAppWeb do
      pipe_through [:browser, :redirect_if_user_is_authenticated]
      live_session :redirect_if_user_is_authenticated,
        on_mount: [{UserAuth, :redirect_if_user_is_authenticated}] do
        live "/users/register", UserRegistrationLive, :new
        live "/users/log_in", UserLoginLive, :new
      end
    end

    scope "/", MyAppWeb do
      pipe_through [:browser, :require_authenticated_user]
      live_session :require_authenticated_user,
        on_mount: [{UserAuth, :ensure_authenticated}] do
        live "/users/settings", UserSettingsLive, :edit
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "command")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Phoenix Auth Generator</h2>
      <p class="text-gray-600 dark:text-gray-300">
        <code>mix phx.gen.auth</code> generates a complete authentication system with users, tokens, sessions, and LiveView hooks — all production-ready.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "generated", "accounts", "tokens", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-400 border-b-2 border-indigo-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["command", "options", "files"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-indigo-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Token-Based</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Uses secure tokens stored in the DB, not just session IDs. Tokens can be revoked.</p>
            </div>
            <div class="p-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 border border-indigo-200 dark:border-indigo-800">
              <p class="text-sm font-semibold text-indigo-700 dark:text-indigo-300 mb-1">LiveView Ready</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Generates <code>UserAuth</code> module with <code>on_mount</code> hooks for LiveView.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Fully Customizable</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Generated code is yours — modify schemas, controllers, templates freely.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Generated Files -->
      <%= if @active_tab == "generated" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>mix phx.gen.auth Accounts User users</code> creates many files. Here are the most important ones:
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Context & Schemas</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{generated_schemas_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Web Layer</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{generated_web_code()}</div>
            </div>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{generated_router_code()}</div>
        </div>
      <% end %>

      <!-- Accounts Context -->
      <%= if @active_tab == "accounts" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The generated <code>Accounts</code> context contains all the business logic for registration, login, password reset, and email confirmation.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{accounts_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">User Schema Features</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li class="flex items-start gap-2"><span class="text-amber-500">-</span> Bcrypt password hashing</li>
                <li class="flex items-start gap-2"><span class="text-amber-500">-</span> Email uniqueness validation</li>
                <li class="flex items-start gap-2"><span class="text-amber-500">-</span> Confirmed_at field for email verification</li>
                <li class="flex items-start gap-2"><span class="text-amber-500">-</span> Hashed password stored, plain text never</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">User Schema</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{user_schema_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Token System -->
      <%= if @active_tab == "tokens" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>phx.gen.auth</code> uses a token-based system instead of plain session IDs. Tokens are stored in a <code>users_tokens</code> table and can be revoked.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{token_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Token Types</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li class="flex items-start gap-2"><span class="text-green-500">-</span> <strong>session</strong>: browser login tokens</li>
                <li class="flex items-start gap-2"><span class="text-green-500">-</span> <strong>remember_me</strong>: persistent cookies</li>
                <li class="flex items-start gap-2"><span class="text-green-500">-</span> <strong>reset_password</strong>: password reset emails</li>
                <li class="flex items-start gap-2"><span class="text-green-500">-</span> <strong>confirm</strong>: email confirmation</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Security Benefits</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li class="flex items-start gap-2"><span class="text-blue-500">-</span> Tokens are hashed in DB (SHA-256)</li>
                <li class="flex items-start gap-2"><span class="text-blue-500">-</span> Can revoke specific sessions</li>
                <li class="flex items-start gap-2"><span class="text-blue-500">-</span> Automatic expiry</li>
                <li class="flex items-start gap-2"><span class="text-blue-500">-</span> "Sign out all devices" is trivial</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">UserAuth Module (key parts)</h4>
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
  defp tab_label("generated"), do: "Generated Files"
  defp tab_label("accounts"), do: "Accounts Context"
  defp tab_label("tokens"), do: "Token System"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("command"), do: "The Command"
  defp topic_label("options"), do: "Options"
  defp topic_label("files"), do: "Files Created"

  defp overview_code("command") do
    """
    # Run inside your Phoenix project:
    mix phx.gen.auth Accounts User users

    # Arguments:
    #   Accounts  - context module name
    #   User      - schema module name
    #   users     - table name (plural)

    # What it does:
    # 1. Generates User schema with email + hashed_password
    # 2. Generates UserToken schema for session/reset tokens
    # 3. Generates Accounts context with all auth functions
    # 4. Generates controllers: registration, session, password, settings
    # 5. Generates UserAuth plug module with on_mount hooks
    # 6. Adds routes to router.ex
    # 7. Creates migration files

    # After running:
    mix deps.get         # adds bcrypt_elixir dep
    mix ecto.migrate     # creates users + users_tokens tables\
    """
    |> String.trim()
  end

  defp overview_code("options") do
    """
    # --no-live  : generate controller-based auth (no LiveView)
    mix phx.gen.auth Accounts User users --no-live

    # --hashing-lib : choose password hashing library
    mix phx.gen.auth Accounts User users --hashing-lib pbkdf2
    # options: bcrypt (default), pbkdf2, argon2

    # --binary-id : use UUID primary keys
    mix phx.gen.auth Accounts User users --binary-id

    # --table : custom table name
    mix phx.gen.auth Accounts User users --table auth_users

    # Can add to existing context:
    # If Accounts context already exists, it appends to it\
    """
    |> String.trim()
  end

  defp overview_code("files") do
    """
    # Schemas:
    lib/my_app/accounts/user.ex
    lib/my_app/accounts/user_token.ex
    lib/my_app/accounts.ex

    # Web layer:
    lib/my_app_web/user_auth.ex          # plug + on_mount hooks
    lib/my_app_web/controllers/user_registration_controller.ex
    lib/my_app_web/controllers/user_session_controller.ex
    lib/my_app_web/controllers/user_settings_controller.ex
    lib/my_app_web/controllers/user_confirmation_controller.ex
    lib/my_app_web/controllers/user_reset_password_controller.ex

    # LiveView (if not --no-live):
    lib/my_app_web/live/user_registration_live.ex
    lib/my_app_web/live/user_login_live.ex
    lib/my_app_web/live/user_forgot_password_live.ex
    lib/my_app_web/live/user_reset_password_live.ex
    lib/my_app_web/live/user_settings_live.ex

    # Migrations:
    priv/repo/migrations/*_create_users_auth_tables.exs\
    """
    |> String.trim()
  end

  defp generated_schemas_code do
    """
    # lib/my_app/accounts/user.ex (simplified):
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :email, :string
        field :password, :string, virtual: true
        field :hashed_password, :string, redact: true
        field :confirmed_at, :naive_datetime
        timestamps()
      end

      def registration_changeset(user, attrs, opts \\\\ []) do
        user
        |> cast(attrs, [:email, :password])
        |> validate_email(opts)
        |> validate_password(opts)
      end

      defp validate_password(changeset, opts) do
        changeset
        |> validate_required([:password])
        |> validate_length(:password, min: 12, max: 72)
        |> maybe_hash_password(opts)
      end

      defp maybe_hash_password(changeset, opts) do
        if Keyword.get(opts, :hash_password, true) do
          changeset |> put_change(:hashed_password,
            Bcrypt.hash_pwd_salt(get_change(changeset, :password)))
        else
          changeset
        end
      end
    end\
    """
    |> String.trim()
  end

  defp generated_web_code do
    """
    # lib/my_app_web/user_auth.ex (key parts):
    defmodule MyAppWeb.UserAuth do
      use MyAppWeb, :verified_routes
      import Plug.Conn
      import Phoenix.Controller
      alias MyApp.Accounts

      # Log in user — creates session token:
      def log_in_user(conn, user, params \\\\ %{}) do
        token = Accounts.generate_user_session_token(user)
        user_return_to = get_session(conn, :user_return_to)

        conn
        |> renew_session()
        |> put_token_in_session(token)
        |> maybe_write_remember_me_cookie(token, params)
        |> redirect(to: user_return_to || signed_in_path(conn))
      end

      # Log out — deletes token from DB:
      def log_out_user(conn) do
        user_token = get_session(conn, :user_token)
        user_token && Accounts.delete_user_session_token(user_token)
        conn
        |> renew_session()
        |> delete_resp_cookie(@remember_me_cookie)
        |> redirect(to: ~p"/")
      end
    end\
    """
    |> String.trim()
  end

  defp generated_router_code do
    """
    # Generated routes added to router.ex:
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

    scope "/", MyAppWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{UserAuth, :ensure_authenticated}] do
        live "/users/settings", UserSettingsLive, :edit
        live "/users/settings/confirm_email/:token",
             UserSettingsLive, :confirm_email
      end
    end

    scope "/", MyAppWeb do
      pipe_through :browser
      delete "/users/log_out", UserSessionController, :delete
      get "/users/confirm/:token", UserConfirmationController, :edit
    end\
    """
    |> String.trim()
  end

  defp accounts_code do
    """
    # lib/my_app/accounts.ex (key functions):
    defmodule MyApp.Accounts do
      alias MyApp.Accounts.{User, UserToken}
      alias MyApp.Repo

      # Register a new user:
      def register_user(attrs) do
        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
      end

      # Authenticate user by email/password:
      def get_user_by_email_and_password(email, password)
          when is_binary(email) and is_binary(password) do
        user = Repo.get_by(User, email: email)
        if User.valid_password?(user, password), do: user
      end

      # Generate session token:
      def generate_user_session_token(user) do
        {token, user_token} =
          UserToken.build_session_token(user)
        Repo.insert!(user_token)
        token
      end

      # Get user from token:
      def get_user_by_session_token(token) do
        {:ok, query} =
          UserToken.verify_session_token_query(token)
        Repo.one(query)
      end

      # Delete token (logout):
      def delete_user_session_token(token) do
        Repo.delete_all(UserToken.by_token_and_context_query(
          token, "session"))
        :ok
      end
    end\
    """
    |> String.trim()
  end

  defp user_schema_code do
    """
    # Migration creates two tables:

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
    create unique_index(:users_tokens, [:context, :token])\
    """
    |> String.trim()
  end

  defp token_code do
    """
    # UserToken schema handles all token operations:
    defmodule MyApp.Accounts.UserToken do
      use Ecto.Schema

      @hash_algorithm :sha256
      @rand_size 32

      # How long different tokens last:
      @session_validity_in_days 60
      @confirm_validity_in_days 7
      @reset_password_validity_in_days 1
      @change_email_validity_in_days 7

      schema "users_tokens" do
        field :token, :binary
        field :context, :string
        field :sent_to, :string
        belongs_to :user, MyApp.Accounts.User
        timestamps(updated_at: false)
      end

      # Build a session token (stored hashed in DB):
      def build_session_token(user) do
        token = :crypto.strong_rand_bytes(@rand_size)
        hashed = :crypto.hash(@hash_algorithm, token)

        {Base.url_encode64(token),
         %UserToken{
           token: hashed,
           context: "session",
           user_id: user.id
         }}
      end

      # Verify a session token:
      def verify_session_token_query(token) do
        case Base.url_decode64(token, padding: false) do
          {:ok, decoded} ->
            hashed = :crypto.hash(@hash_algorithm, decoded)
            days = days_for_context("session")

            query =
              from t in __MODULE__,
                join: u in assoc(t, :user),
                where: t.token == ^hashed,
                where: t.context == "session",
                where: t.inserted_at > ago(^days, "day"),
                select: u

            {:ok, query}
          :error ->
            :error
        end
      end
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # UserAuth plug + on_mount hooks (generated):
    defmodule MyAppWeb.UserAuth do
      use MyAppWeb, :verified_routes
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView
      alias MyApp.Accounts

      # --- Plugs ---

      def fetch_current_user(conn, _opts) do
        {user_token, conn} =
          ensure_user_token(conn)
        user = user_token &&
               Accounts.get_user_by_session_token(user_token)
        assign(conn, :current_user, user)
      end

      def require_authenticated_user(conn, _opts) do
        if conn.assigns[:current_user] do
          conn
        else
          conn
          |> put_flash(:error, "Log in to continue.")
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

      # --- LiveView on_mount ---

      def on_mount(:mount_current_user, _params, session, socket) do
        {:cont, mount_current_user(session, socket)}
      end

      def on_mount(:ensure_authenticated, _params, session, socket) do
        socket = mount_current_user(session, socket)
        if socket.assigns.current_user do
          {:cont, socket}
        else
          socket =
            socket
            |> put_flash(:error, "Log in to continue.")
            |> redirect(to: ~p"/users/log_in")
          {:halt, socket}
        end
      end

      def on_mount(:redirect_if_user_is_authenticated,
                   _params, session, socket) do
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
    end\
    """
    |> String.trim()
  end
end
