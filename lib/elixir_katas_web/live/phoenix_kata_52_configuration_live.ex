defmodule ElixirKatasWeb.PhoenixKata52ConfigurationLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Configuration — runtime.exs, Environment Variables, Secrets

    # --- config/runtime.exs (read at startup, NOT compile time) ---
    import Config

    if System.get_env("PHX_SERVER") do
      config :my_app, MyAppWeb.Endpoint, server: true
    end

    if config_env() == :prod do
      # Database
      database_url =
        System.get_env("DATABASE_URL") ||
          raise "DATABASE_URL env var is missing!"

      config :my_app, MyApp.Repo,
        url: database_url,
        pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
        ssl: true

      # Endpoint
      secret_key_base =
        System.get_env("SECRET_KEY_BASE") ||
          raise "SECRET_KEY_BASE env var is missing!"

      host = System.get_env("PHX_HOST") || "example.com"
      port = String.to_integer(System.get_env("PORT") || "4000")

      config :my_app, MyAppWeb.Endpoint,
        url: [host: host, port: 443, scheme: "https"],
        http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
        secret_key_base: secret_key_base,
        force_ssl: [rewrite_on: [:x_forwarded_proto]]

      # Mailer
      config :my_app, MyApp.Mailer,
        adapter: Swoosh.Adapters.SMTP,
        relay: "smtp.sendgrid.net",
        username: "apikey",
        password: System.fetch_env!("SENDGRID_API_KEY"),
        tls: :always, port: 587

      # External services
      config :my_app, :stripe,
        secret_key: System.fetch_env!("STRIPE_SECRET_KEY"),
        webhook_secret: System.fetch_env!("STRIPE_WEBHOOK_SECRET")
    end

    # --- Config layers (merged in order) ---
    # 1. config/config.exs       (base, all envs)
    # 2. config/dev|prod|test.exs (env-specific, compile-time)
    # 3. config/runtime.exs      (runtime, any env)
    # Later values OVERRIDE earlier ones.

    # --- Accessing config at runtime ---
    Application.get_env(:my_app, MyApp.Repo)
    Application.fetch_env!(:my_app, :stripe)

    # Compile-time config (module attribute):
    @feature_flags Application.compile_env(:my_app, :feature_flags, [])

    # --- Secrets management ---
    # Use System.fetch_env!/1 in runtime.exs (fails fast if missing)
    # Generate keys: mix phx.gen.secret
    # Never hardcode secrets in config files
    # Use .env files in dev (add to .gitignore)
    # Use cloud secret managers in production
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "runtime")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Configuration</h2>
      <p class="text-gray-600 dark:text-gray-300">
        config/runtime.exs, environment variables, secrets — how Phoenix manages configuration across environments.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "runtime", "secrets", "envs", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-slate-50 dark:bg-slate-900/30 text-slate-700 dark:text-slate-400 border-b-2 border-slate-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["runtime", "compile", "layers"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-slate-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Config Files</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><code>config/config.exs</code> — all environments</li>
                <li><code>config/dev.exs</code> — development only</li>
                <li><code>config/prod.exs</code> — production (compile-time)</li>
                <li><code>config/test.exs</code> — test environment</li>
                <li><code>config/runtime.exs</code> — runtime (any env)</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Rule of Thumb</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>Never hardcode secrets in config files</li>
                <li>Use <code>System.get_env/1</code> in runtime.exs</li>
                <li>Use <code>System.fetch_env!/1</code> to fail fast if missing</li>
                <li>Keep config/prod.exs minimal</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Runtime Config -->
      <%= if @active_tab == "runtime" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>config/runtime.exs</code> runs when the application starts (not at compile time). This is where environment-specific secrets belong.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{runtime_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Runtime vs Compile-time</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>Compile-time</strong>: config.exs, dev.exs, prod.exs</li>
                <li>Baked into the binary during <code>mix compile</code></li>
                <li><strong>Runtime</strong>: runtime.exs</li>
                <li>Read from env vars when app starts</li>
                <li>Same binary, different environments!</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Accessing Config at Runtime</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{accessing_config_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Secrets -->
      <%= if @active_tab == "secrets" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Managing secrets safely — never commit sensitive values to version control.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{secrets_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <p class="text-sm font-semibold text-red-700 dark:text-red-300 mb-2">Never Do This</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{bad_secrets_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Do This Instead</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{good_secrets_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Environments -->
      <%= if @active_tab == "envs" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Environment-specific configuration patterns for dev, test, and production.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{env_config_code()}</div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">The 12-Factor App</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Phoenix follows the 12-Factor App principles: store config in environment variables, not in code. The same Docker image runs in dev, staging, and production — only env vars differ.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete runtime.exs for Production</h4>
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
  defp tab_label("runtime"), do: "runtime.exs"
  defp tab_label("secrets"), do: "Secrets"
  defp tab_label("envs"), do: "Environments"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("runtime"), do: "Runtime Config"
  defp topic_label("compile"), do: "Compile-time"
  defp topic_label("layers"), do: "Config Layers"

  defp overview_code("runtime") do
    """
    # config/runtime.exs — read at startup, not compile time:
    import Config

    # Only run in production:
    if config_env() == :prod do
      database_url = System.fetch_env!("DATABASE_URL")
      # ^^^ fails immediately if missing — fail fast!

      config :my_app, MyApp.Repo,
        url: database_url,
        pool_size: String.to_integer(
          System.get_env("POOL_SIZE") || "10")

      secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
      config :my_app, MyAppWeb.Endpoint,
        secret_key_base: secret_key_base,
        http: [port: System.get_env("PORT") || 4000]
    end\
    """
    |> String.trim()
  end

  defp overview_code("compile") do
    """
    # config/config.exs — compile-time, all environments:
    import Config

    config :my_app,
      ecto_repos: [MyApp.Repo]

    config :my_app, MyAppWeb.Endpoint,
      url: [host: "localhost"],
      render_errors: [
        formats: [html: MyAppWeb.ErrorHTML,
                  json: MyAppWeb.ErrorJSON],
        layout: false
      ],
      pubsub_server: MyApp.PubSub,
      live_view: [signing_salt: "abc123"]

    # Import environment config at the end:
    import_config "\#{config_env()}.exs"

    # This loads config/dev.exs or config/prod.exs etc.\
    """
    |> String.trim()
  end

  defp overview_code("layers") do
    """
    # Config is merged from multiple files in order:
    #
    # 1. config/config.exs     (base config)
    # 2. config/dev.exs        (if MIX_ENV=dev)
    #    OR config/prod.exs    (if MIX_ENV=prod)
    #    OR config/test.exs    (if MIX_ENV=test)
    # 3. config/runtime.exs   (always, at startup)
    #
    # Later values OVERRIDE earlier ones:
    # config.exs:   [pool_size: 10]
    # prod.exs:     [pool_size: 20]
    # runtime.exs:  [pool_size: 50]
    # => result:    [pool_size: 50]
    #
    # You can check current env:
    config_env()          # in config files
    Mix.env()             # in mix tasks
    Application.get_env(:my_app, :env)  # in app code\
    """
    |> String.trim()
  end

  defp runtime_code do
    """
    # config/runtime.exs — full example:
    import Config

    # Runs in ALL environments at startup
    if System.get_env("PHX_SERVER") do
      config :my_app, MyAppWeb.Endpoint, server: true
    end

    if config_env() == :prod do
      # Database:
      database_url = System.fetch_env!("DATABASE_URL")
      maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1),
        do: [:inet6], else: []

      config :my_app, MyApp.Repo,
        url: database_url,
        socket_options: maybe_ipv6,
        pool_size: String.to_integer(
          System.get_env("POOL_SIZE") || "10")

      # Endpoint:
      secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
      host = System.get_env("PHX_HOST") || "example.com"
      port = String.to_integer(
        System.get_env("PORT") || "4000")

      config :my_app, MyAppWeb.Endpoint,
        url: [host: host, port: 443, scheme: "https"],
        http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
        secret_key_base: secret_key_base

      # Mailer:
      config :my_app, MyApp.Mailer,
        adapter: Swoosh.Adapters.Postmark,
        api_key: System.fetch_env!("POSTMARK_API_KEY")
    end\
    """
    |> String.trim()
  end

  defp accessing_config_code do
    """
    # Read config at runtime in your app code:

    # Read at call-time (for runtime.exs values):
    Application.get_env(:my_app, MyApp.Repo)
    Application.get_env(:my_app, :feature_flags, [])

    # Read a nested key:
    Application.get_env(:my_app, MyAppWeb.Endpoint)
    |> Keyword.get(:secret_key_base)

    # Or use module attribute for compile-time config:
    @feature_flags Application.compile_env(
      :my_app, :feature_flags, [])

    # fetch_env!/2 raises if key is missing:
    Application.fetch_env!(:my_app, :payment_key)\
    """
    |> String.trim()
  end

  defp secrets_code do
    """
    # Secrets management strategies:

    # 1. Environment variables (simplest):
    SECRET_KEY_BASE=abc123 mix phx.server
    export DATABASE_URL=postgres://...
    # Or use .env file (never commit!):
    # Add to .gitignore: .env

    # 2. Generate secure keys:
    mix phx.gen.secret          # 64-char hex key
    mix phx.gen.secret 32       # 32-char key

    # 3. Cloud secret managers:
    # AWS Secrets Manager, GCP Secret Manager,
    # HashiCorp Vault, Fly.io secrets

    # 4. .env file in dev (dotenv pattern):
    # $ cp .env.example .env
    # $ echo "SECRET_KEY_BASE=$(mix phx.gen.secret)" >> .env

    # 5. Fly.io secrets:
    # fly secrets set SECRET_KEY_BASE=abc123
    # fly secrets set DATABASE_URL=postgres://...
    # Secrets are injected as env vars in the container.\
    """
    |> String.trim()
  end

  defp bad_secrets_code do
    """
    # NEVER do this in any config file:
    config :my_app, MyApp.Repo,
      password: "my_real_password"  # BAD!

    config :my_app, MyAppWeb.Endpoint,
      secret_key_base:
        "abc123..."  # BAD! Committed to git!

    # Also bad — compile-time env var baked in:
    config :my_app, :stripe_key,
      live: System.get_env("STRIPE_KEY")\
    """
    |> String.trim()
  end

  defp good_secrets_code do
    """
    # In config/runtime.exs — read at startup:
    if config_env() == :prod do
      config :my_app, MyApp.Repo,
        password: System.fetch_env!("DB_PASSWORD")

      config :my_app, MyAppWeb.Endpoint,
        secret_key_base:
          System.fetch_env!("SECRET_KEY_BASE")

      config :my_app, :stripe_key,
        live: System.fetch_env!("STRIPE_LIVE_KEY")
    end

    # System.fetch_env!/1 raises at startup if missing
    # Better than a nil crash deep in production!\
    """
    |> String.trim()
  end

  defp env_config_code do
    """
    # config/dev.exs:
    import Config

    config :my_app, MyApp.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "my_app_dev",
      show_sensitive_data_on_connection_error: true,
      pool_size: 10

    config :my_app, MyAppWeb.Endpoint,
      debug_errors: true,
      code_reloader: true,
      check_origin: false,
      watchers: [
        esbuild: {Esbuild, :install_and_run,
                  [:my_app, ~w(--bundle --watch)]}
      ]

    # config/test.exs:
    config :my_app, MyApp.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "my_app_test\#{System.get_env("MIX_TEST_PARTITION")}",
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: System.schedulers_online() * 2

    config :my_app, MyAppWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4002],
      server: false  # don't start HTTP server in tests\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # config/runtime.exs — production-ready:
    import Config

    # For mix phx.server or release:
    if System.get_env("PHX_SERVER") do
      config :my_app, MyAppWeb.Endpoint, server: true
    end

    if config_env() == :prod do
      # ---- DATABASE ----
      database_url =
        System.get_env("DATABASE_URL") ||
          raise "DATABASE_URL env var is missing!"

      config :my_app, MyApp.Repo,
        url: database_url,
        pool_size: String.to_integer(
          System.get_env("POOL_SIZE") || "10"),
        ssl: true

      # ---- ENDPOINT ----
      secret_key_base =
        System.get_env("SECRET_KEY_BASE") ||
          raise "SECRET_KEY_BASE env var is missing!"

      host = System.get_env("PHX_HOST") || "example.com"
      port = String.to_integer(
        System.get_env("PORT") || "4000")

      config :my_app, MyAppWeb.Endpoint,
        url: [host: host, port: 443, scheme: "https"],
        http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
        secret_key_base: secret_key_base,
        force_ssl: [rewrite_on: [:x_forwarded_proto]]

      # ---- MAILER ----
      config :my_app, MyApp.Mailer,
        adapter: Swoosh.Adapters.SMTP,
        relay: "smtp.sendgrid.net",
        username: "apikey",
        password: System.fetch_env!("SENDGRID_API_KEY"),
        tls: :always,
        port: 587

      # ---- EXTERNAL SERVICES ----
      config :my_app, :stripe,
        secret_key: System.fetch_env!("STRIPE_SECRET_KEY"),
        webhook_secret:
          System.fetch_env!("STRIPE_WEBHOOK_SECRET")
    end\
    """
    |> String.trim()
  end
end
