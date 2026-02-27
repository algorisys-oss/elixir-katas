defmodule ElixirKatasWeb.PhoenixKata11ComposingPlugsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Endpoint — top-level plug chain (every request)
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      plug Plug.Static, at: "/", from: :my_app
      plug Plug.RequestId
      plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        json_decoder: Phoenix.json_library()
      plug Plug.MethodOverride
      plug Plug.Head
      plug Plug.Session, @session_options
      plug MyAppWeb.Router   # ← Router is the LAST plug
    end

    # Router — pipelines compose plugs by name
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
      end

      scope "/admin", MyAppWeb do
        pipe_through [:browser, :require_admin]
        get "/dashboard", AdminController, :dashboard
      end
    end

    # Halting a plug — stops the pipeline
    defp require_auth(conn, _opts) do
      if conn.assigns[:current_user] do
        conn  # Authenticated → continue to next plug
      else
        conn
        |> put_status(401)
        |> put_view(ErrorHTML)
        |> render(:"401")
        |> halt()  # STOP — no more plugs run
      end
    end

    # Custom module plug with Plug.Builder
    defmodule MyApp.Pipeline do
      use Plug.Builder

      plug Plug.Logger
      plug Plug.RequestId
      plug :add_server_header
      plug MyApp.Router

      def add_server_header(conn, _) do
        put_resp_header(conn, "server", "MyApp/1.0")
      end
    end

    # Custom CORS plug
    defmodule MyAppWeb.Plugs.CORS do
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        conn
        |> put_resp_header("access-control-allow-origin", "*")
        |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE")
        |> put_resp_header("access-control-allow-headers", "content-type, authorization")
      end
    end
    """
    |> String.trim()
  end

  @pipeline_plugs [
    %{name: "Plug.Static", category: :endpoint, desc: "Check if static file", halts: false},
    %{name: "Plug.RequestId", category: :endpoint, desc: "Add X-Request-Id header", halts: false},
    %{name: "Plug.Parsers", category: :endpoint, desc: "Parse request body", halts: false},
    %{name: "Plug.Session", category: :endpoint, desc: "Load session from cookie", halts: false},
    %{name: ":accepts", category: :browser, desc: "Verify Accept header", halts: false},
    %{name: ":fetch_session", category: :browser, desc: "Load session data", halts: false},
    %{name: ":protect_from_forgery", category: :browser, desc: "Check CSRF token", halts: false},
    %{name: ":put_secure_headers", category: :browser, desc: "Add security headers", halts: false},
    %{name: ":require_auth", category: :controller, desc: "Check authentication", halts: true},
    %{name: "Controller.index/2", category: :action, desc: "Your code!", halts: false}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "flow",
       pipeline_step: 0,
       pipeline_halted: false,
       is_authenticated: true,
       plug_log: []
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Composing Plugs</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Chain simple plugs into powerful pipelines. See how Endpoint, Router, and Controller plugs compose together.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["flow", "halt", "patterns", "code"]}
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

      <!-- Full request flow -->
      <%= if @active_tab == "flow" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Step through the complete plug chain for a browser request. Each plug transforms the conn before passing it along.
          </p>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Pipeline visualization -->
            <div class="space-y-1">
              <%= for {plug, idx} <- Enum.with_index(pipeline_plugs()) do %>
                <!-- Category header -->
                <%= if idx == 0 || Enum.at(pipeline_plugs(), idx - 1).category != plug.category do %>
                  <div class={["text-xs font-bold uppercase mt-3 mb-1 px-2",
                    category_color(plug.category)]}>
                    {category_label(plug.category)}
                  </div>
                <% end %>

                <div class={["flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition-all",
                  cond do
                    @pipeline_halted && idx >= @pipeline_step -> "bg-red-50 dark:bg-red-900/10 opacity-30 line-through"
                    idx < @pipeline_step -> "bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800"
                    idx == @pipeline_step -> "bg-teal-50 dark:bg-teal-900/20 border-2 border-teal-400 ring-1 ring-teal-300"
                    true -> "bg-gray-50 dark:bg-gray-800 opacity-40"
                  end]}>
                  <span class={["w-5 h-5 rounded-full flex items-center justify-center text-xs text-white flex-shrink-0",
                    cond do
                      @pipeline_halted && idx >= @pipeline_step -> "bg-red-400"
                      idx < @pipeline_step -> "bg-green-500"
                      idx == @pipeline_step -> "bg-teal-500"
                      true -> "bg-gray-400"
                    end]}>
                    <%= if idx < @pipeline_step do %>✓<% else %>{idx + 1}<% end %>
                  </span>
                  <div class="flex-1 min-w-0">
                    <span class="font-mono text-xs font-semibold text-gray-800 dark:text-gray-200">{plug.name}</span>
                    <span class="text-xs text-gray-500 ml-2">{plug.desc}</span>
                  </div>
                  <%= if plug.halts do %>
                    <span class="text-xs px-1.5 py-0.5 rounded bg-red-100 dark:bg-red-900 text-red-600 dark:text-red-400">can halt</span>
                  <% end %>
                </div>
              <% end %>
            </div>

            <!-- Log -->
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-xs overflow-x-auto min-h-[300px]">
              <p class="text-gray-500 mb-2"># Plug pipeline log</p>
              <%= for entry <- @plug_log do %>
                <div class={entry.color}>{entry.text}</div>
              <% end %>
              <%= if @plug_log == [] do %>
                <p class="text-gray-600">Click "Next Plug" to start...</p>
              <% end %>
            </div>
          </div>

          <!-- Controls -->
          <div class="flex items-center gap-3">
            <button phx-click="flow_next" phx-target={@myself}
              disabled={@pipeline_step >= length(pipeline_plugs()) || @pipeline_halted}
              class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
                if(@pipeline_step >= length(pipeline_plugs()) || @pipeline_halted,
                  do: "bg-gray-200 text-gray-400 cursor-not-allowed",
                  else: "bg-teal-600 hover:bg-teal-700 text-white")]}>
              Next Plug
            </button>
            <button phx-click="flow_reset" phx-target={@myself}
              class="px-4 py-2 rounded-lg font-medium bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 transition-colors cursor-pointer">
              Reset
            </button>
            <%= if @pipeline_halted do %>
              <span class="text-sm text-red-500 font-semibold">Pipeline HALTED at :require_auth</span>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Halt demo -->
      <%= if @active_tab == "halt" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Toggle authentication to see how <code>halt()</code> short-circuits the plug pipeline.
          </p>

          <div class="flex items-center gap-4 p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <label class="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" checked={@is_authenticated}
                phx-click="toggle_auth" phx-target={@myself}
                class="rounded border-gray-300 text-teal-600 focus:ring-teal-500" />
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">User is authenticated</span>
            </label>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Authenticated flow -->
            <div class={["p-4 rounded-lg border-2 transition-all",
              if(@is_authenticated, do: "border-green-300 dark:border-green-700 bg-green-50 dark:bg-green-900/20", else: "border-gray-200 dark:border-gray-700 opacity-50")]}>
              <h4 class="font-semibold text-green-700 dark:text-green-300 mb-3">Authenticated</h4>
              <div class="space-y-1 text-sm font-mono">
                <div class="text-green-600">✓ Plug.Session</div>
                <div class="text-green-600">✓ :fetch_session</div>
                <div class="text-green-600">✓ :protect_from_forgery</div>
                <div class="text-green-600">✓ :require_auth (passes)</div>
                <div class="text-green-600">✓ Controller.index</div>
                <div class="mt-2 text-green-700 font-bold">→ 200 OK</div>
              </div>
            </div>

            <!-- Unauthenticated flow -->
            <div class={["p-4 rounded-lg border-2 transition-all",
              if(!@is_authenticated, do: "border-red-300 dark:border-red-700 bg-red-50 dark:bg-red-900/20", else: "border-gray-200 dark:border-gray-700 opacity-50")]}>
              <h4 class="font-semibold text-red-700 dark:text-red-300 mb-3">Unauthenticated</h4>
              <div class="space-y-1 text-sm font-mono">
                <div class="text-green-600">✓ Plug.Session</div>
                <div class="text-green-600">✓ :fetch_session</div>
                <div class="text-green-600">✓ :protect_from_forgery</div>
                <div class="text-red-600 font-bold">✗ :require_auth → halt()</div>
                <div class="text-red-400 line-through">  Controller.index (SKIPPED)</div>
                <div class="mt-2 text-red-700 font-bold">→ 401 Unauthorized</div>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{halt_example_code()}</div>
        </div>
      <% end %>

      <!-- Pipeline patterns -->
      <%= if @active_tab == "patterns" do %>
        <div class="space-y-6">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Common plug composition patterns used in Phoenix applications.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Browser Pipeline</h4>
              <p class="text-xs text-gray-500 mb-3">For server-rendered HTML pages</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{browser_pipeline_code()}</div>
            </div>

            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">API Pipeline</h4>
              <p class="text-xs text-gray-500 mb-3">For JSON API endpoints</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{api_pipeline_code()}</div>
            </div>

            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Admin Pipeline</h4>
              <p class="text-xs text-gray-500 mb-3">Stacked on top of :browser</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{admin_pipeline_code()}</div>
            </div>

            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Plug.Builder</h4>
              <p class="text-xs text-gray-500 mb-3">Compose plugs into a module</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{builder_code()}</div>
            </div>
          </div>

          <!-- Design principles -->
          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <h4 class="font-semibold text-amber-700 dark:text-amber-300 mb-3">Design Principles</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm text-gray-600 dark:text-gray-300">
              <div>
                <p class="font-semibold text-amber-800 dark:text-amber-200">Single Responsibility</p>
                <p>Each plug does ONE thing well</p>
              </div>
              <div>
                <p class="font-semibold text-amber-800 dark:text-amber-200">Order Matters</p>
                <p>Parsers before readers, auth before logic</p>
              </div>
              <div>
                <p class="font-semibold text-amber-800 dark:text-amber-200">Fail Fast</p>
                <p>Auth/rate-limit early to reject quickly</p>
              </div>
              <div>
                <p class="font-semibold text-amber-800 dark:text-amber-200">Keep Plugs Pure</p>
                <p>Transform conn, avoid side effects</p>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code examples -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-6">
          <div>
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Phoenix Endpoint (Top-Level)</h4>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{endpoint_code()}</div>
          </div>

          <div>
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Router with Pipelines</h4>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{router_code()}</div>
          </div>

          <div>
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Custom CORS Plug</h4>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{cors_plug_code()}</div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("toggle_auth", _, socket) do
    {:noreply, assign(socket, is_authenticated: !socket.assigns.is_authenticated)}
  end

  def handle_event("flow_next", _, socket) do
    step = socket.assigns.pipeline_step
    plugs = pipeline_plugs()

    if step < length(plugs) do
      plug = Enum.at(plugs, step)
      {halted, log_entry} = plug_log_entry(plug, step)

      {:noreply,
       assign(socket,
         pipeline_step: step + 1,
         pipeline_halted: halted,
         plug_log: socket.assigns.plug_log ++ [log_entry]
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("flow_reset", _, socket) do
    {:noreply,
     assign(socket,
       pipeline_step: 0,
       pipeline_halted: false,
       plug_log: []
     )}
  end

  defp pipeline_plugs, do: @pipeline_plugs

  defp plug_log_entry(plug, _step) do
    log = %{
      text: "[#{String.pad_leading(plug.name, 24)}] #{plug.desc}",
      color: category_text_color(plug.category)
    }

    {false, log}
  end

  defp tab_label("flow"), do: "Request Flow"
  defp tab_label("halt"), do: "Halt Demo"
  defp tab_label("patterns"), do: "Patterns"
  defp tab_label("code"), do: "Source Code"

  defp category_label(:endpoint), do: "Endpoint Plugs"
  defp category_label(:browser), do: "Pipeline :browser"
  defp category_label(:controller), do: "Controller Plugs"
  defp category_label(:action), do: "Action"

  defp category_color(:endpoint), do: "text-blue-600 dark:text-blue-400"
  defp category_color(:browser), do: "text-purple-600 dark:text-purple-400"
  defp category_color(:controller), do: "text-amber-600 dark:text-amber-400"
  defp category_color(:action), do: "text-green-600 dark:text-green-400"

  defp category_text_color(:endpoint), do: "text-blue-400"
  defp category_text_color(:browser), do: "text-purple-400"
  defp category_text_color(:controller), do: "text-amber-400"
  defp category_text_color(:action), do: "text-green-400"

  defp halt_example_code do
    """
    defp require_auth(conn, _opts) do
      if conn.assigns[:current_user] do
        conn  # Authenticated → continue to next plug
      else
        conn
        |> put_status(401)
        |> put_view(ErrorHTML)
        |> render(:"401")
        |> halt()  # STOP — no more plugs run
      end
    end\
    """
    |> String.trim()
  end

  defp browser_pipeline_code do
    """
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, ...
      plug :protect_from_forgery
      plug :put_secure_headers
    end\
    """
    |> String.trim()
  end

  defp api_pipeline_code do
    """
    pipeline :api do
      plug :accepts, ["json"]
      plug MyApp.Plugs.ApiAuth
      plug MyApp.Plugs.RateLimiter
    end\
    """
    |> String.trim()
  end

  defp admin_pipeline_code do
    """
    pipeline :admin do
      plug :require_auth
      plug :require_role, :admin
      plug :put_layout, ...
    end

    scope "/admin" do
      pipe_through [:browser, :admin]
      get "/", AdminController, :home
    end\
    """
    |> String.trim()
  end

  defp builder_code do
    """
    defmodule MyApp.Pipeline do
      use Plug.Builder

      plug Plug.Logger
      plug Plug.RequestId
      plug :add_server_header
      plug MyApp.Router

      def add_server_header(conn, _) do
        put_resp_header(conn,
          "server", "MyApp/1.0")
      end
    end\
    """
    |> String.trim()
  end

  defp endpoint_code do
    """
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      plug Plug.Static,
        at: "/", from: :my_app,
        only: ~w(assets fonts images favicon.ico)

      plug Plug.RequestId
      plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Phoenix.json_library()

      plug Plug.MethodOverride
      plug Plug.Head
      plug Plug.Session, @session_options
      plug MyAppWeb.Router   # ← Router is the LAST plug
    end\
    """
    |> String.trim()
  end

  defp router_code do
    """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      # Browser routes use the :browser pipeline
      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
        resources "/products", ProductController
      end

      # API routes use the :api pipeline
      scope "/api", MyAppWeb do
        pipe_through :api
        resources "/users", UserController
      end

      # Admin routes use BOTH :browser and :admin
      scope "/admin", MyAppWeb do
        pipe_through [:browser, :require_admin]
        get "/dashboard", AdminController, :dashboard
      end
    end\
    """
    |> String.trim()
  end

  defp cors_plug_code do
    """
    defmodule MyAppWeb.Plugs.CORS do
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        conn
        |> put_resp_header("access-control-allow-origin", "*")
        |> put_resp_header("access-control-allow-methods",
             "GET, POST, PUT, DELETE")
        |> put_resp_header("access-control-allow-headers",
             "content-type, authorization")
      end
    end

    # Usage: plug MyAppWeb.Plugs.CORS\
    """
    |> String.trim()
  end
end
