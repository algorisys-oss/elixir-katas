defmodule ElixirKatasWeb.PhoenixKata13EndpointAndConfigLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Endpoint — HTTP entry point, plug chain for every request
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      socket "/live", Phoenix.LiveView.Socket,
        websocket: [connect_info: [session: @session_options]]

      plug Plug.Static,
        at: "/", from: :my_app,
        only: MyAppWeb.static_paths()

      plug Plug.RequestId
      plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        json_decoder: Phoenix.json_library()

      plug Plug.MethodOverride
      plug Plug.Head
      plug Plug.Session, @session_options
      plug MyAppWeb.Router
    end

    # config/config.exs — Shared across all environments
    import Config

    config :my_app, MyAppWeb.Endpoint,
      url: [host: "localhost"],
      render_errors: [
        formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
        layout: false
      ],
      pubsub_server: MyApp.PubSub,
      live_view: [signing_salt: "abc123"]

    import_config "\#{config_env()}.exs"

    # config/dev.exs — Development settings
    config :my_app, MyAppWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4000],
      debug_errors: true,
      code_reloader: true

    # config/runtime.exs — Runs at STARTUP (not compile time)
    if config_env() == :prod do
      config :my_app, MyApp.Repo,
        url: System.get_env("DATABASE_URL"),
        pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

      config :my_app, MyAppWeb.Endpoint,
        url: [host: System.get_env("PHX_HOST"), port: 443, scheme: "https"],
        secret_key_base: System.get_env("SECRET_KEY_BASE")
    end

    # Loading order: config.exs → dev/test/prod.exs → runtime.exs
    # config.exs and env files run at COMPILE TIME
    # runtime.exs runs at STARTUP (can read env vars)

    # Accessing config at runtime:
    Application.get_env(:my_app, MyAppWeb.Endpoint)
    MyAppWeb.Endpoint.config(:url)
    MyAppWeb.Endpoint.url()  # => "http://localhost:4000"
    """
    |> String.trim()
  end

  @endpoint_plugs [
    %{name: "Plug.Static", desc: "Serve static files from priv/static/", color: "bg-blue-500", detail: "Checks if request matches a static file. If yes, serves it and STOPS — request never reaches the router. First because it's the most common request type."},
    %{name: "Plug.RequestId", desc: "Add X-Request-Id header", color: "bg-gray-500", detail: "Assigns a unique ID to every request for tracing through logs and distributed systems."},
    %{name: "Plug.Telemetry", desc: "Emit timing events", color: "bg-purple-500", detail: "Emits telemetry events that LiveDashboard and custom reporters use for performance monitoring."},
    %{name: "Plug.Parsers", desc: "Parse request body", color: "bg-green-500", detail: "Parses URL-encoded forms, multipart file uploads, and JSON bodies. After this, conn.body_params is populated."},
    %{name: "Plug.MethodOverride", desc: "Support _method param", color: "bg-amber-500", detail: "HTML forms only support GET/POST. Reads _method hidden field to simulate PUT/PATCH/DELETE."},
    %{name: "Plug.Head", desc: "Convert HEAD → GET", color: "bg-gray-400", detail: "Converts HEAD requests to GET (but strips response body). Browsers use HEAD to check if resources changed."},
    %{name: "Plug.Session", desc: "Load session from cookie", color: "bg-pink-500", detail: "Reads the signed/encrypted session cookie. After this, get_session/2 and put_session/3 work."},
    %{name: "MyAppWeb.Router", desc: "Route to controller/LiveView", color: "bg-teal-500", detail: "The LAST plug. By now we have: static files served, request ID, body parsed, session loaded. Routes to the right controller."}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "endpoint",
       selected_plug: 0,
       active_config: "shared"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Endpoint & Config</h2>
      <p class="text-gray-600 dark:text-gray-300">
        The HTTP entry point and configuration system. Every request passes through the Endpoint's plug chain.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["endpoint", "config", "boot"]}
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

      <!-- Endpoint plug chain -->
      <%= if @active_tab == "endpoint" do %>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Plug list -->
          <div class="space-y-2">
            <p class="text-sm text-gray-500 mb-3">Click a plug to see what it does:</p>
            <%= for {plug, idx} <- Enum.with_index(endpoint_plugs()) do %>
              <button
                phx-click="select_plug"
                phx-target={@myself}
                phx-value-idx={to_string(idx)}
                class={["flex items-center gap-3 w-full p-3 rounded-lg border text-left transition-all cursor-pointer",
                  if(@selected_plug == idx,
                    do: "border-teal-400 bg-teal-50 dark:bg-teal-900/20 ring-2 ring-teal-300",
                    else: "border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600")]}
              >
                <span class={["w-3 h-3 rounded-full flex-shrink-0", plug.color]}></span>
                <div>
                  <span class="font-mono text-sm font-semibold text-gray-800 dark:text-gray-200">{plug.name}</span>
                  <span class="text-xs text-gray-500 ml-2">{plug.desc}</span>
                </div>
                <%= if idx == length(endpoint_plugs()) - 1 do %>
                  <span class="ml-auto text-xs px-1.5 py-0.5 rounded bg-teal-100 dark:bg-teal-900 text-teal-600 dark:text-teal-400">LAST</span>
                <% end %>
              </button>
            <% end %>
          </div>

          <!-- Plug detail -->
          <div class="space-y-4">
            <% plug = Enum.at(endpoint_plugs(), @selected_plug) %>
            <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center gap-2 mb-3">
                <span class={["w-4 h-4 rounded-full", plug.color]}></span>
                <h4 class="font-mono font-bold text-gray-800 dark:text-gray-200">{plug.name}</h4>
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-300">{plug.detail}</p>
            </div>

            <!-- Flow arrow diagram -->
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase mb-2">Request flow position</p>
              <div class="flex items-center gap-1 text-xs font-mono overflow-x-auto">
                <%= for {p, i} <- Enum.with_index(endpoint_plugs()) do %>
                  <span class={["px-1.5 py-0.5 rounded whitespace-nowrap",
                    if(i == @selected_plug,
                      do: "bg-teal-600 text-white font-bold",
                      else: "bg-gray-200 dark:bg-gray-700 text-gray-500")]}>
                    {String.replace(p.name, "Plug.", "")}
                  </span>
                  <%= if i < length(endpoint_plugs()) - 1 do %>
                    <span class="text-gray-400">→</span>
                  <% end %>
                <% end %>
              </div>
            </div>

            <!-- Source code -->
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{endpoint_source()}</div>
          </div>
        </div>
      <% end %>

      <!-- Configuration -->
      <%= if @active_tab == "config" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix uses layered configuration. Each environment can override the base settings.
          </p>

          <!-- Config file selector -->
          <div class="flex flex-wrap gap-2">
            <button :for={cfg <- ["shared", "dev", "prod", "runtime"]}
              phx-click="set_config"
              phx-target={@myself}
              phx-value-config={cfg}
              class={["px-3 py-1.5 rounded-lg text-sm font-medium cursor-pointer transition-colors",
                if(@active_config == cfg,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")]}>
              {config_label(cfg)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{config_code(@active_config)}</div>

          <!-- Config layering diagram -->
          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Configuration Loading Order</p>
            <div class="flex items-center gap-2 text-sm font-mono">
              <span class="px-2 py-1 rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300">config.exs</span>
              <span class="text-gray-400">→</span>
              <span class="px-2 py-1 rounded bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300">dev/test/prod.exs</span>
              <span class="text-gray-400">→</span>
              <span class="px-2 py-1 rounded bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300">runtime.exs</span>
            </div>
            <p class="text-xs text-gray-500 mt-2">
              config.exs and env files run at <strong>compile time</strong>. runtime.exs runs at <strong>startup</strong> (can read env vars).
            </p>
          </div>
        </div>
      <% end %>

      <!-- Boot sequence -->
      <%= if @active_tab == "boot" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            What happens when you run <code>mix phx.server</code>.
          </p>

          <div class="space-y-0 max-w-lg mx-auto">
            <.boot_step num="1" title="Application.start/2" detail="OTP starts your application module" />
            <.boot_arrow />
            <.boot_step num="2" title="Supervisor starts children" detail="Repo, PubSub, Telemetry, Endpoint" />
            <.boot_arrow />
            <.boot_step num="3" title="Endpoint.init/2" detail="Reads config, compiles plug pipeline" />
            <.boot_arrow />
            <.boot_step num="4" title="Cowboy starts on port 4000" detail="Ranch listens, 100 acceptors ready" />
            <.boot_arrow />
            <.boot_step num="5" title="Ready!" detail="Accepting connections at http://localhost:4000" />
          </div>

          <!-- Accessing config -->
          <div class="mt-6">
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Accessing Config at Runtime</h4>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{runtime_access_code()}</div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :num, :string, required: true
  attr :title, :string, required: true
  attr :detail, :string, required: true

  defp boot_step(assigns) do
    ~H"""
    <div class="flex items-start gap-3 p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
      <span class="w-6 h-6 rounded-full bg-teal-500 text-white flex items-center justify-center text-xs flex-shrink-0">{@num}</span>
      <div>
        <p class="font-mono text-sm font-semibold text-gray-800 dark:text-gray-200">{@title}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{@detail}</p>
      </div>
    </div>
    """
  end

  defp boot_arrow(assigns) do
    ~H"""
    <div class="text-center text-gray-400 text-sm py-0.5 ml-3">|</div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_plug", %{"idx" => idx}, socket) do
    {:noreply, assign(socket, selected_plug: String.to_integer(idx))}
  end

  def handle_event("set_config", %{"config" => cfg}, socket) do
    {:noreply, assign(socket, active_config: cfg)}
  end

  defp endpoint_plugs, do: @endpoint_plugs

  defp tab_label("endpoint"), do: "Endpoint Plugs"
  defp tab_label("config"), do: "Configuration"
  defp tab_label("boot"), do: "Boot Sequence"

  defp config_label("shared"), do: "config.exs"
  defp config_label("dev"), do: "dev.exs"
  defp config_label("prod"), do: "prod.exs"
  defp config_label("runtime"), do: "runtime.exs"

  defp endpoint_source do
    """
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      socket "/live", Phoenix.LiveView.Socket,
        websocket: [connect_info: [session: @session_options]]

      plug Plug.Static,
        at: "/", from: :my_app,
        only: MyAppWeb.static_paths()

      plug Plug.RequestId
      plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        json_decoder: Phoenix.json_library()

      plug Plug.MethodOverride
      plug Plug.Head
      plug Plug.Session, @session_options
      plug MyAppWeb.Router
    end\
    """
    |> String.trim()
  end

  defp config_code("shared") do
    """
    # config/config.exs — Shared across all environments
    import Config

    config :my_app, MyAppWeb.Endpoint,
      url: [host: "localhost"],
      render_errors: [
        formats: [html: MyAppWeb.ErrorHTML,
                  json: MyAppWeb.ErrorJSON],
        layout: false
      ],
      pubsub_server: MyApp.PubSub,
      live_view: [signing_salt: "abc123"]

    config :my_app, MyApp.Repo,
      database: "my_app_dev"

    config :logger, :console,
      format: "$time $metadata[$level] $message\\n"

    # MUST be at the end:
    import_config "\#{config_env()}.exs"\
    """
    |> String.trim()
  end

  defp config_code("dev") do
    """
    # config/dev.exs — Development settings
    import Config

    config :my_app, MyAppWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4000],
      check_origin: false,
      debug_errors: true,
      code_reloader: true,
      watchers: [
        esbuild: {Esbuild, :install_and_run, [...]},
        tailwind: {Tailwind, :install_and_run, [...]}
      ]

    config :my_app, MyApp.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "my_app_dev",
      pool_size: 10\
    """
    |> String.trim()
  end

  defp config_code("prod") do
    """
    # config/prod.exs — Production compile-time
    import Config

    config :my_app, MyAppWeb.Endpoint,
      cache_static_manifest: "priv/static/cache_manifest.json"

    config :logger, level: :info

    # Runtime config is in runtime.exs
    # (secrets, env vars, etc.)\
    """
    |> String.trim()
  end

  defp config_code("runtime") do
    """
    # config/runtime.exs — Runs at STARTUP (not compile)
    import Config

    if config_env() == :prod do
      config :my_app, MyApp.Repo,
        url: System.get_env("DATABASE_URL"),
        pool_size:
          String.to_integer(
            System.get_env("POOL_SIZE") || "10")

      config :my_app, MyAppWeb.Endpoint,
        url: [host: System.get_env("PHX_HOST"),
              port: 443, scheme: "https"],
        secret_key_base:
          System.get_env("SECRET_KEY_BASE")
    end\
    """
    |> String.trim()
  end

  defp runtime_access_code do
    """
    # Read config in code:
    Application.get_env(:my_app, MyAppWeb.Endpoint)
    # => [url: [host: "localhost"], ...]

    # Endpoint helpers:
    MyAppWeb.Endpoint.config(:url)
    # => [host: "localhost"]

    MyAppWeb.Endpoint.url()
    # => "http://localhost:4000"\
    """
    |> String.trim()
  end
end
