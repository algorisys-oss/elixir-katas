defmodule ElixirKatasWeb.PhoenixApiKata01ApiPipelineLive do
  use ElixirKatasWeb, :live_component

  @browser_plugs [
    %{name: ":accepts", args: ~s(["html"]), desc: "Accept HTML responses", api: false},
    %{name: ":fetch_session", args: "", desc: "Load session data from cookie", api: false},
    %{name: ":fetch_live_flash", args: "", desc: "Load flash messages for LiveView", api: false},
    %{name: ":put_root_layout", args: "html: {Layouts, :root}", desc: "Set the HTML layout template", api: false},
    %{name: ":protect_from_forgery", args: "", desc: "Add CSRF token verification", api: false},
    %{name: ":put_secure_browser_headers", args: "", desc: "Add security headers (X-Frame-Options, etc.)", api: false}
  ]

  @api_plugs [
    %{name: ":accepts", args: ~s(["json"]), desc: "Accept JSON responses only", api: true}
  ]

  def phoenix_source do
    """
    # Phoenix Router — Browser vs API Pipelines
    #
    # Pipelines are groups of plugs that process requests.
    # The :browser pipeline is for HTML pages (sessions, CSRF, flash).
    # The :api pipeline is minimal — just JSON, no sessions.

    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      # Browser pipeline: full session + CSRF + flash support
      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      # API pipeline: minimal, stateless, JSON-only
      pipeline :api do
        plug :accepts, ["json"]
      end

      # Browser routes — rendered HTML pages
      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
      end

      # API routes — JSON responses, no sessions
      scope "/api", MyAppWeb.Api do
        pipe_through :api
        resources "/users", UserController, except: [:new, :edit]
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(selected_pipeline: "browser")
     |> assign(browser_plugs: @browser_plugs)
     |> assign(api_plugs: @api_plugs)
     |> assign(request_type: nil)
     |> assign(conn_log: [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">API Pipeline vs Browser Pipeline</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Compare what happens when a request flows through the <code>:browser</code> vs <code>:api</code> pipeline.
      </p>

      <div class="flex gap-3 mb-4">
        <button
          phx-click="select_pipeline"
          phx-value-pipeline="browser"
          phx-target={@myself}
          class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
            if(@selected_pipeline == "browser",
              do: "bg-indigo-600 text-white",
              else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")
          ]}
        >
          :browser pipeline
        </button>
        <button
          phx-click="select_pipeline"
          phx-value-pipeline="api"
          phx-target={@myself}
          class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
            if(@selected_pipeline == "api",
              do: "bg-rose-600 text-white",
              else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")
          ]}
        >
          :api pipeline
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Pipeline Visualization -->
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">
            Pipeline: <code class={if(@selected_pipeline == "api", do: "text-rose-600", else: "text-indigo-600")}>
              :{@selected_pipeline}
            </code>
          </h3>
          <div class="space-y-2">
            <%= for plug <- if(@selected_pipeline == "api", do: @api_plugs, else: @browser_plugs) do %>
              <div class="flex items-start gap-3 p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                <div class="flex-shrink-0 w-8 h-8 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
                  <svg class="w-4 h-4 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </div>
                <div>
                  <div class="font-mono text-sm font-bold text-gray-900 dark:text-white">
                    plug {plug.name}<%= if plug.args != "" do %>, {plug.args}<% end %>
                  </div>
                  <div class="text-sm text-gray-500 dark:text-gray-400">{plug.desc}</div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Comparison -->
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Key Differences</h3>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-200 dark:border-gray-700">
                  <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">Feature</th>
                  <th class="text-center py-2 px-3 text-indigo-600 dark:text-indigo-400">:browser</th>
                  <th class="text-center py-2 px-3 text-rose-600 dark:text-rose-400">:api</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr>
                  <td class="py-2 px-3 text-gray-700 dark:text-gray-300">Content type</td>
                  <td class="py-2 px-3 text-center font-mono">text/html</td>
                  <td class="py-2 px-3 text-center font-mono">application/json</td>
                </tr>
                <tr>
                  <td class="py-2 px-3 text-gray-700 dark:text-gray-300">Sessions</td>
                  <td class="py-2 px-3 text-center text-emerald-600">Yes</td>
                  <td class="py-2 px-3 text-center text-red-500">No</td>
                </tr>
                <tr>
                  <td class="py-2 px-3 text-gray-700 dark:text-gray-300">CSRF protection</td>
                  <td class="py-2 px-3 text-center text-emerald-600">Yes</td>
                  <td class="py-2 px-3 text-center text-red-500">No</td>
                </tr>
                <tr>
                  <td class="py-2 px-3 text-gray-700 dark:text-gray-300">Flash messages</td>
                  <td class="py-2 px-3 text-center text-emerald-600">Yes</td>
                  <td class="py-2 px-3 text-center text-red-500">No</td>
                </tr>
                <tr>
                  <td class="py-2 px-3 text-gray-700 dark:text-gray-300">HTML layout</td>
                  <td class="py-2 px-3 text-center text-emerald-600">Yes</td>
                  <td class="py-2 px-3 text-center text-red-500">No</td>
                </tr>
                <tr>
                  <td class="py-2 px-3 text-gray-700 dark:text-gray-300">Auth method</td>
                  <td class="py-2 px-3 text-center">Cookie/session</td>
                  <td class="py-2 px-3 text-center">Bearer token</td>
                </tr>
                <tr>
                  <td class="py-2 px-3 text-gray-700 dark:text-gray-300">Plug count</td>
                  <td class="py-2 px-3 text-center font-bold">6 plugs</td>
                  <td class="py-2 px-3 text-center font-bold">1 plug</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="mt-4 p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <h4 class="font-semibold text-amber-800 dark:text-amber-300 mb-1">Why so minimal?</h4>
            <p class="text-sm text-amber-700 dark:text-amber-400">
              API clients (mobile apps, SPAs, other servers) don't need sessions, CSRF tokens, or HTML layouts.
              They send a token in the <code>Authorization</code> header and expect JSON back. Keeping the pipeline
              lean means faster response times and less overhead.
            </p>
          </div>
        </div>
      </div>

      <!-- Simulate Request -->
      <div class="mt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Simulate a Request</h3>
        <div class="flex gap-3">
          <button
            phx-click="simulate"
            phx-value-type="browser"
            phx-target={@myself}
            class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors cursor-pointer"
          >
            Send Browser Request
          </button>
          <button
            phx-click="simulate"
            phx-value-type="api"
            phx-target={@myself}
            class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-medium transition-colors cursor-pointer"
          >
            Send API Request
          </button>
        </div>

        <%= if @conn_log != [] do %>
          <div class="mt-4 bg-gray-900 rounded-lg p-4 font-mono text-sm space-y-1">
            <%= for {step, i} <- Enum.with_index(@conn_log) do %>
              <div class={"text-#{step.color}-400"}>
                <span class="text-gray-500">{String.pad_leading("#{i + 1}", 2)}.</span> {step.text}
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("select_pipeline", %{"pipeline" => pipeline}, socket) do
    {:noreply, assign(socket, selected_pipeline: pipeline)}
  end

  def handle_event("simulate", %{"type" => "browser"}, socket) do
    log = [
      %{text: "→ GET /users (Accept: text/html)", color: "yellow"},
      %{text: "  plug :accepts [\"html\"] — ✓ HTML accepted", color: "green"},
      %{text: "  plug :fetch_session — loaded session from cookie", color: "cyan"},
      %{text: "  plug :fetch_live_flash — loaded flash messages", color: "cyan"},
      %{text: "  plug :put_root_layout — set layout to :root", color: "cyan"},
      %{text: "  plug :protect_from_forgery — verified CSRF token", color: "cyan"},
      %{text: "  plug :put_secure_browser_headers — added X-Frame-Options, CSP", color: "cyan"},
      %{text: "  → UserController.index/2", color: "amber"},
      %{text: "  ← 200 OK (text/html, 2.4kb)", color: "green"}
    ]
    {:noreply, assign(socket, conn_log: log, request_type: "browser")}
  end

  def handle_event("simulate", %{"type" => "api"}, socket) do
    log = [
      %{text: "→ GET /api/users (Accept: application/json)", color: "yellow"},
      %{text: "  plug :accepts [\"json\"] — ✓ JSON accepted", color: "green"},
      %{text: "  → Api.UserController.index/2", color: "amber"},
      %{text: "  ← 200 OK (application/json, 342 bytes)", color: "green"}
    ]
    {:noreply, assign(socket, conn_log: log, request_type: "api")}
  end
end
