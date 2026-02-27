defmodule ElixirKatasWeb.PhoenixKata18PipelinesLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Pipelines — named plug chains for different request types

    # :browser — for HTML pages (6 plugs)
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
    end

    # :api — minimal, stateless (1 plug)
    pipeline :api do
      plug :accepts, ["json"]
    end

    # Custom auth pipeline
    pipeline :require_auth do
      plug MyAppWeb.Plugs.FetchCurrentUser
      plug MyAppWeb.Plugs.RequireAuth
    end

    # Custom module plug
    defmodule MyAppWeb.Plugs.RequireAuth do
      import Plug.Conn
      import Phoenix.Controller

      def init(opts), do: opts

      def call(conn, _opts) do
        if conn.assigns[:current_user] do
          conn
        else
          conn
          |> put_flash(:error, "Please log in")
          |> redirect(to: "/login")
          |> halt()  # Stop pipeline!
        end
      end
    end

    # API auth pipeline
    pipeline :api_auth do
      plug MyAppWeb.Plugs.VerifyAPIKey
      plug MyAppWeb.Plugs.FetchAPIUser
    end

    # Chaining multiple pipelines (run in order):
    scope "/admin", MyAppWeb.Admin do
      pipe_through [:browser, :require_auth, :require_admin]
      #              ↑ 6 plugs  ↑ 2 plugs     ↑ 1 plug
      #              = 9 plugs total, in order
      get "/", DashboardController, :index
    end

    # Using pipelines in a complete router
    scope "/", MyAppWeb do
      pipe_through :browser
      get "/", PageController, :home
    end

    scope "/", MyAppWeb do
      pipe_through [:browser, :require_auth]
      resources "/orders", OrderController
    end

    scope "/api", MyAppWeb.API do
      pipe_through [:api, :api_auth]
      resources "/orders", OrderController
    end
    """
    |> String.trim()
  end

  @browser_plugs [
    %{name: ":accepts", arg: "[\"html\"]", desc: "Only accept HTML format", halts: false},
    %{name: ":fetch_session", arg: nil, desc: "Load session from signed cookie", halts: false},
    %{name: ":fetch_live_flash", arg: nil, desc: "Enable flash messages for LiveView", halts: false},
    %{name: ":put_root_layout", arg: "html: {Layouts, :root}", desc: "Set the root HTML layout", halts: false},
    %{name: ":protect_from_forgery", arg: nil, desc: "Validate CSRF token", halts: true},
    %{name: ":put_secure_browser_headers", arg: nil, desc: "Add X-Frame-Options, CSP, etc.", halts: false}
  ]

  @api_plugs [
    %{name: ":accepts", arg: "[\"json\"]", desc: "Only accept JSON format", halts: false}
  ]

  @auth_plugs [
    %{name: "FetchCurrentUser", arg: nil, desc: "Load user from session into assigns", halts: false},
    %{name: "RequireAuth", arg: nil, desc: "Redirect to /login if no user", halts: true}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "browser",
       selected_plug: 0,
       sim_step: 0,
       sim_halted: false
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Pipelines</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Named plug chains that filter requests before they reach controllers. Each scope gets a pipeline.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["browser", "api", "custom", "flow", "code"]}
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

      <!-- Browser pipeline -->
      <%= if @active_tab == "browser" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The <code>:browser</code> pipeline handles HTML requests. Click a plug to learn what it does.
          </p>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Plug list -->
            <div class="space-y-2">
              <%= for {plug, idx} <- Enum.with_index(browser_plugs()) do %>
                <button
                  phx-click="select_plug"
                  phx-target={@myself}
                  phx-value-idx={to_string(idx)}
                  class={["flex items-center gap-3 w-full p-3 rounded-lg border text-left transition-all cursor-pointer",
                    if(@selected_plug == idx,
                      do: "border-teal-400 bg-teal-50 dark:bg-teal-900/20 ring-2 ring-teal-300",
                      else: "border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600")]}
                >
                  <span class={["w-2 h-2 rounded-full flex-shrink-0",
                    if(plug.halts, do: "bg-red-500", else: "bg-green-500")]}></span>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <span class="font-mono text-sm font-semibold text-gray-800 dark:text-gray-200">{plug.name}</span>
                      <%= if plug.halts do %>
                        <span class="text-[10px] px-1.5 py-0.5 rounded bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400">can halt</span>
                      <% end %>
                    </div>
                    <p class="text-xs text-gray-500 truncate">{plug.desc}</p>
                  </div>
                </button>
              <% end %>
            </div>

            <!-- Detail panel -->
            <div class="space-y-4">
              <% plug = Enum.at(browser_plugs(), @selected_plug) %>
              <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                <h4 class="font-mono font-bold text-gray-800 dark:text-gray-200 mb-2">{plug.name}</h4>
                <p class="text-sm text-gray-600 dark:text-gray-300 mb-3">{plug.desc}</p>
                <%= if plug.halts do %>
                  <div class="p-2 rounded bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
                    <p class="text-xs text-red-600 dark:text-red-400">
                      This plug can <strong>halt</strong> the pipeline — if it fails (e.g., invalid CSRF token),
                      no further plugs or controllers run.
                    </p>
                  </div>
                <% end %>
              </div>

              <!-- Pipeline code -->
              <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{browser_pipeline_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- API pipeline -->
      <%= if @active_tab == "api" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The <code>:api</code> pipeline is minimal — APIs are stateless, no sessions or CSRF needed.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/20">
              <h4 class="font-semibold text-green-700 dark:text-green-300 mb-2">:browser (6 plugs)</h4>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <%= for plug <- browser_plugs() do %>
                  <li class="flex items-center gap-2 font-mono text-xs">
                    <span class="text-green-500">+</span> {plug.name}
                  </li>
                <% end %>
              </ul>
            </div>

            <div class="p-4 rounded-lg border border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20">
              <h4 class="font-semibold text-blue-700 dark:text-blue-300 mb-2">:api (1 plug)</h4>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <%= for plug <- api_plugs() do %>
                  <li class="flex items-center gap-2 font-mono text-xs">
                    <span class="text-blue-500">+</span> {plug.name}
                  </li>
                <% end %>
              </ul>
              <p class="text-xs text-gray-500 mt-3">No sessions, no CSRF, no layouts — just JSON.</p>
            </div>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{api_pipeline_code()}</div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Why so few plugs?</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              APIs don't need sessions (they use tokens), CSRF (no forms), layouts (no HTML), or flash messages.
              Authentication is handled by custom plugs (API keys, JWT tokens).
            </p>
          </div>
        </div>
      <% end %>

      <!-- Custom pipelines -->
      <%= if @active_tab == "custom" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Create your own pipelines for authentication, rate limiting, and more.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Auth Pipeline</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{auth_pipeline_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Module Plug</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{module_plug_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">API Auth Pipeline</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{api_auth_pipeline_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Chaining Pipelines</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{chaining_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Flow visualization -->
      <%= if @active_tab == "flow" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Step through a request to see how pipelines execute. Watch what happens when a plug halts.
          </p>

          <div class="flex gap-2">
            <button phx-click="sim_step" phx-target={@myself}
              class="px-4 py-2 rounded-lg text-sm font-medium bg-teal-600 text-white hover:bg-teal-700 cursor-pointer disabled:opacity-50"
              disabled={@sim_step >= sim_total_steps() || @sim_halted}>
              Next Step
            </button>
            <button phx-click="sim_reset" phx-target={@myself}
              class="px-4 py-2 rounded-lg text-sm font-medium bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 cursor-pointer">
              Reset
            </button>
            <button phx-click="sim_halt" phx-target={@myself}
              class="px-4 py-2 rounded-lg text-sm font-medium bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 hover:bg-red-200 cursor-pointer">
              Simulate Halt
            </button>
          </div>

          <!-- Pipeline flow -->
          <div class="space-y-1">
            <.flow_step name="Request arrives" idx={0} current={@sim_step} halted={@sim_halted} halt_at={-1} />
            <.flow_arrow />

            <p class="text-xs font-semibold text-gray-500 uppercase ml-3 mt-2 mb-1">:browser pipeline</p>
            <%= for {plug, idx} <- Enum.with_index(browser_plugs()) do %>
              <.flow_step name={plug.name} idx={idx + 1} current={@sim_step} halted={@sim_halted} halt_at={if(@sim_halted, do: 5, else: -1)} />
              <.flow_arrow />
            <% end %>

            <p class="text-xs font-semibold text-gray-500 uppercase ml-3 mt-2 mb-1">:require_auth pipeline</p>
            <%= for {plug, idx} <- Enum.with_index(auth_plugs()) do %>
              <.flow_step name={plug.name} idx={idx + 7} current={@sim_step} halted={@sim_halted} halt_at={if(@sim_halted, do: 5, else: -1)} />
              <.flow_arrow />
            <% end %>

            <.flow_step name="Controller action" idx={9} current={@sim_step} halted={@sim_halted} halt_at={if(@sim_halted, do: 5, else: -1)} />
            <.flow_arrow />
            <.flow_step name="Response sent" idx={10} current={@sim_step} halted={@sim_halted} halt_at={if(@sim_halted, do: 5, else: -1)} />
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Router with Custom Pipelines</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_router_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :idx, :integer, required: true
  attr :current, :integer, required: true
  attr :halted, :boolean, required: true
  attr :halt_at, :integer, required: true

  defp flow_step(assigns) do
    ~H"""
    <div class={["flex items-center gap-3 p-2 rounded-lg transition-all",
      cond do
        @halted and @idx > @halt_at and @halt_at >= 0 -> "opacity-30 line-through"
        @idx < @current -> "bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800"
        @idx == @current -> "bg-teal-50 dark:bg-teal-900/20 border-2 border-teal-400 ring-2 ring-teal-200"
        true -> "bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700"
      end]}>
      <span class={["w-5 h-5 rounded-full flex items-center justify-center text-[10px] flex-shrink-0",
        cond do
          @halted and @idx == @halt_at -> "bg-red-500 text-white"
          @idx < @current -> "bg-green-500 text-white"
          @idx == @current -> "bg-teal-500 text-white"
          true -> "bg-gray-300 dark:bg-gray-600 text-gray-500"
        end]}>
        <%= if @halted and @idx == @halt_at do %>!<% else %>{@idx}<% end %>
      </span>
      <span class={["text-sm font-mono",
        if(@idx <= @current, do: "text-gray-800 dark:text-gray-200 font-semibold", else: "text-gray-400")]}>{@name}</span>
      <%= if @halted and @idx == @halt_at do %>
        <span class="text-xs px-1.5 py-0.5 rounded bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 font-semibold ml-auto">HALTED</span>
      <% end %>
    </div>
    """
  end

  defp flow_arrow(assigns) do
    ~H"""
    <div class="text-center text-gray-300 dark:text-gray-600 text-xs ml-5">|</div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab, selected_plug: 0)}
  end

  def handle_event("select_plug", %{"idx" => idx}, socket) do
    {:noreply, assign(socket, selected_plug: String.to_integer(idx))}
  end

  def handle_event("sim_step", _params, socket) do
    {:noreply, assign(socket, sim_step: socket.assigns.sim_step + 1)}
  end

  def handle_event("sim_reset", _params, socket) do
    {:noreply, assign(socket, sim_step: 0, sim_halted: false)}
  end

  def handle_event("sim_halt", _params, socket) do
    {:noreply, assign(socket, sim_halted: true, sim_step: 6)}
  end

  defp tab_label("browser"), do: ":browser"
  defp tab_label("api"), do: ":api"
  defp tab_label("custom"), do: "Custom"
  defp tab_label("flow"), do: "Flow"
  defp tab_label("code"), do: "Source Code"

  defp browser_plugs, do: @browser_plugs
  defp api_plugs, do: @api_plugs
  defp auth_plugs, do: @auth_plugs
  defp sim_total_steps, do: 11

  defp browser_pipeline_code do
    """
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
    end\
    """
    |> String.trim()
  end

  defp api_pipeline_code do
    """
    pipeline :api do
      plug :accepts, ["json"]
    end

    scope "/api", MyAppWeb.API do
      pipe_through :api

      get "/users", UserController, :index
      get "/products", ProductController, :index
    end\
    """
    |> String.trim()
  end

  defp auth_pipeline_code do
    """
    pipeline :require_auth do
      plug MyAppWeb.Plugs.FetchCurrentUser
      plug MyAppWeb.Plugs.RequireAuth
    end

    scope "/", MyAppWeb do
      pipe_through [:browser, :require_auth]
      resources "/orders", OrderController
    end\
    """
    |> String.trim()
  end

  defp module_plug_code do
    """
    defmodule MyAppWeb.Plugs.RequireAuth do
      import Plug.Conn
      import Phoenix.Controller

      def init(opts), do: opts

      def call(conn, _opts) do
        if conn.assigns[:current_user] do
          conn
        else
          conn
          |> put_flash(:error, "Please log in")
          |> redirect(to: "/login")
          |> halt()  # Stop pipeline!
        end
      end
    end\
    """
    |> String.trim()
  end

  defp api_auth_pipeline_code do
    """
    pipeline :api_auth do
      plug MyAppWeb.Plugs.VerifyAPIKey
      plug MyAppWeb.Plugs.FetchAPIUser
    end

    scope "/api", MyAppWeb.API do
      pipe_through [:api, :api_auth]
      resources "/products", ProductController
    end\
    """
    |> String.trim()
  end

  defp chaining_code do
    """
    # Multiple pipelines run in order:
    scope "/admin", MyAppWeb.Admin do
      pipe_through [:browser, :require_auth, :require_admin]
      #              ↑ 6 plugs  ↑ 2 plugs     ↑ 1 plug
      #              = 9 plugs total, in order

      get "/", DashboardController, :index
    end\
    """
    |> String.trim()
  end

  defp full_router_code do
    """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      # Built-in pipelines
      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      # Custom pipelines
      pipeline :require_auth do
        plug MyAppWeb.Plugs.FetchCurrentUser
        plug MyAppWeb.Plugs.RequireAuth
      end

      pipeline :require_admin do
        plug MyAppWeb.Plugs.RequireAdmin
      end

      pipeline :api_auth do
        plug MyAppWeb.Plugs.VerifyAPIKey
      end

      # Public (browser only)
      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
        resources "/products", ProductController, only: [:index, :show]
      end

      # Authenticated (browser + auth)
      scope "/", MyAppWeb do
        pipe_through [:browser, :require_auth]
        resources "/orders", OrderController
      end

      # Admin (browser + auth + admin)
      scope "/admin", MyAppWeb.Admin, as: :admin do
        pipe_through [:browser, :require_auth, :require_admin]
        get "/", DashboardController, :index
        resources "/users", UserController
      end

      # Public API
      scope "/api", MyAppWeb.API do
        pipe_through :api
        resources "/products", ProductController, only: [:index, :show]
      end

      # Authenticated API
      scope "/api", MyAppWeb.API do
        pipe_through [:api, :api_auth]
        resources "/orders", OrderController
      end
    end\
    """
    |> String.trim()
  end
end
