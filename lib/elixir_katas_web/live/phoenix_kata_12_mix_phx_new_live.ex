defmodule ElixirKatasWeb.PhoenixKata12MixPhxNewLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Generate a new Phoenix project
    $ mix phx.new my_app
    $ cd my_app
    $ mix setup       # deps.get + ecto.setup + assets.setup
    $ mix phx.server  # → http://localhost:4000

    # Project structure (key files):
    #
    # mix.exs                        — Project definition & deps
    # lib/my_app/application.ex      — OTP app, supervision tree
    # lib/my_app/repo.ex             — Database repository
    # lib/my_app_web/endpoint.ex     — HTTP entry point (plug chain)
    # lib/my_app_web/router.ex       — URL → controller mapping
    # config/config.exs              — Shared config (all envs)
    # config/dev.exs                 — Development settings
    # config/runtime.exs             — Production runtime (env vars)

    # mix.exs — Project definition
    defmodule MyApp.MixProject do
      use Mix.Project

      def project do
        [app: :my_app, version: "0.1.0",
         elixir: "~> 1.14", deps: deps()]
      end

      def application do
        [mod: {MyApp.Application, []},
         extra_applications: [:logger]]
      end

      defp deps do
        [{:phoenix, "~> 1.7"},
         {:phoenix_ecto, "~> 4.4"},
         {:phoenix_live_view, "~> 0.20"},
         {:plug_cowboy, "~> 2.7"}]
      end
    end

    # application.ex — OTP supervision tree
    defmodule MyApp.Application do
      use Application

      def start(_type, _args) do
        children = [
          MyApp.Repo,           # Database pool
          MyAppWeb.Telemetry,   # Metrics
          {Phoenix.PubSub,
            name: MyApp.PubSub}, # PubSub
          MyAppWeb.Endpoint     # Web server
        ]
        Supervisor.start_link(children,
          strategy: :one_for_one)
      end
    end

    # Generator options:
    #   --no-ecto      Skip database
    #   --no-html      Skip HTML views (API only)
    #   --no-live      Skip LiveView
    #   --no-assets    Skip esbuild/tailwind
    #   --database sqlite3   Use SQLite
    #   --umbrella     Umbrella project
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "structure",
       expanded_dirs: MapSet.new(["lib/", "config/"])
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">mix phx.new</h2>
      <p class="text-gray-600 dark:text-gray-300">
        The project generator that creates a complete Phoenix application. Explore the directory structure and understand what each file does.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["structure", "keyfiles", "tasks", "options"]}
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

      <!-- Directory structure -->
      <%= if @active_tab == "structure" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Click directories to expand/collapse. Hover over files to see their purpose.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
            <div class="text-amber-400 font-bold mb-2">my_app/</div>
            <%= for entry <- directory_tree() do %>
              <%= if entry.type == :dir do %>
                <button
                  phx-click="toggle_dir"
                  phx-target={@myself}
                  phx-value-dir={entry.path}
                  class="flex items-center gap-1 hover:text-amber-300 cursor-pointer w-full text-left"
                  style={"padding-left: #{entry.depth * 20}px"}
                >
                  <span class="text-amber-500">
                    {if MapSet.member?(@expanded_dirs, entry.path), do: "▼", else: "▶"}
                  </span>
                  <span class="text-amber-400">{entry.name}/</span>
                  <span class="text-gray-600 text-xs ml-2">{entry.desc}</span>
                </button>
              <% else %>
                <%= if entry.parent == nil or MapSet.member?(@expanded_dirs, entry.parent) do %>
                  <div
                    class="flex items-center gap-1 group"
                    style={"padding-left: #{entry.depth * 20}px"}
                  >
                    <span class="text-gray-500">  </span>
                    <span class={file_color(entry.name)}>{entry.name}</span>
                    <span class="text-gray-600 text-xs ml-2 opacity-0 group-hover:opacity-100 transition-opacity">{entry.desc}</span>
                  </div>
                <% end %>
              <% end %>
            <% end %>
          </div>

          <!-- Two directories explanation -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
            <div class="p-4 rounded-lg border border-teal-200 dark:border-teal-800 bg-teal-50 dark:bg-teal-900/20">
              <h4 class="font-semibold text-teal-700 dark:text-teal-300 mb-2">lib/my_app/</h4>
              <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">Business logic — the core of your application</p>
              <ul class="text-xs text-gray-500 space-y-1">
                <li>Ecto schemas & migrations</li>
                <li>Contexts (business functions)</li>
                <li>Background jobs</li>
                <li>External API clients</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/20">
              <h4 class="font-semibold text-amber-700 dark:text-amber-300 mb-2">lib/my_app_web/</h4>
              <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">Web interface — how users interact</p>
              <ul class="text-xs text-gray-500 space-y-1">
                <li>Controllers & LiveViews</li>
                <li>Templates (HEEx)</li>
                <li>Router & pipelines</li>
                <li>Components</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Key files -->
      <%= if @active_tab == "keyfiles" do %>
        <div class="space-y-4">
          <%= for file <- key_files() do %>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <div class="flex items-center gap-2 mb-2">
                <span class={["px-2 py-0.5 rounded text-xs font-bold", file.badge_color]}>{file.badge}</span>
                <span class="font-mono text-sm font-semibold text-gray-800 dark:text-gray-200">{file.path}</span>
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-300 mb-3">{file.description}</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 overflow-x-auto whitespace-pre">{file.code}</div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Mix tasks -->
      <%= if @active_tab == "tasks" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Essential Mix tasks for working with Phoenix projects.
          </p>

          <%= for group <- task_groups() do %>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">{group.title}</h4>
              <div class="space-y-2">
                <%= for task <- group.tasks do %>
                  <div class="flex items-start gap-3">
                    <code class="text-xs bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded font-mono text-teal-600 dark:text-teal-400 whitespace-nowrap">{task.cmd}</code>
                    <span class="text-sm text-gray-500">{task.desc}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Generator options -->
      <%= if @active_tab == "options" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Customize the generator to create exactly the project you need.
          </p>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-200 dark:border-gray-700">
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Flag</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Effect</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Use when</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={opt <- generator_options()} class="border-b border-gray-100 dark:border-gray-800">
                  <td class="py-2 px-3 font-mono text-xs text-teal-600 dark:text-teal-400">{opt.flag}</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">{opt.effect}</td>
                  <td class="py-2 px-3 text-gray-500 text-xs">{opt.use_when}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- First run -->
          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <h4 class="font-semibold text-amber-700 dark:text-amber-300 mb-2">First Run</h4>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{first_run_code()}</div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("toggle_dir", %{"dir" => dir}, socket) do
    expanded = socket.assigns.expanded_dirs

    expanded =
      if MapSet.member?(expanded, dir) do
        MapSet.delete(expanded, dir)
      else
        MapSet.put(expanded, dir)
      end

    {:noreply, assign(socket, expanded_dirs: expanded)}
  end

  defp tab_label("structure"), do: "Directory Structure"
  defp tab_label("keyfiles"), do: "Key Files"
  defp tab_label("tasks"), do: "Mix Tasks"
  defp tab_label("options"), do: "Generator Options"

  defp directory_tree do
    [
      %{type: :dir, name: "config", path: "config/", parent: nil, depth: 1, desc: "Configuration"},
      %{type: :file, name: "config.exs", parent: "config/", depth: 2, desc: "Shared config (all envs)"},
      %{type: :file, name: "dev.exs", parent: "config/", depth: 2, desc: "Development settings"},
      %{type: :file, name: "test.exs", parent: "config/", depth: 2, desc: "Test settings"},
      %{type: :file, name: "prod.exs", parent: "config/", depth: 2, desc: "Production compile-time"},
      %{type: :file, name: "runtime.exs", parent: "config/", depth: 2, desc: "Production runtime (env vars)"},
      %{type: :dir, name: "lib", path: "lib/", parent: nil, depth: 1, desc: "Application code"},
      %{type: :dir, name: "my_app", path: "lib/my_app/", parent: "lib/", depth: 2, desc: "Business logic"},
      %{type: :file, name: "application.ex", parent: "lib/my_app/", depth: 3, desc: "OTP app, supervision tree"},
      %{type: :file, name: "repo.ex", parent: "lib/my_app/", depth: 3, desc: "Database repository"},
      %{type: :file, name: "mailer.ex", parent: "lib/my_app/", depth: 3, desc: "Email sending"},
      %{type: :dir, name: "my_app_web", path: "lib/my_app_web/", parent: "lib/", depth: 2, desc: "Web layer"},
      %{type: :file, name: "endpoint.ex", parent: "lib/my_app_web/", depth: 3, desc: "HTTP entry point (plug chain)"},
      %{type: :file, name: "router.ex", parent: "lib/my_app_web/", depth: 3, desc: "URL → controller mapping"},
      %{type: :file, name: "telemetry.ex", parent: "lib/my_app_web/", depth: 3, desc: "Metrics & monitoring"},
      %{type: :dir, name: "controllers", path: "lib/my_app_web/controllers/", parent: "lib/my_app_web/", depth: 3, desc: "Request handlers"},
      %{type: :dir, name: "components", path: "lib/my_app_web/components/", parent: "lib/my_app_web/", depth: 3, desc: "Shared UI components"},
      %{type: :dir, name: "priv", path: "priv/", parent: nil, depth: 1, desc: "Private data"},
      %{type: :dir, name: "repo", path: "priv/repo/", parent: "priv/", depth: 2, desc: "Database files"},
      %{type: :file, name: "seeds.exs", parent: "priv/repo/", depth: 3, desc: "Seed data script"},
      %{type: :dir, name: "static", path: "priv/static/", parent: "priv/", depth: 2, desc: "Served directly by Plug.Static"},
      %{type: :dir, name: "assets", path: "assets/", parent: nil, depth: 1, desc: "Frontend (compiled)"},
      %{type: :file, name: "app.js", parent: "assets/", depth: 2, desc: "JavaScript entry point"},
      %{type: :file, name: "app.css", parent: "assets/", depth: 2, desc: "CSS entry point"},
      %{type: :dir, name: "test", path: "test/", parent: nil, depth: 1, desc: "Tests"},
      %{type: :file, name: "mix.exs", parent: nil, depth: 1, desc: "Project definition & deps"},
      %{type: :file, name: "mix.lock", parent: nil, depth: 1, desc: "Locked dependency versions"},
      %{type: :file, name: ".formatter.exs", parent: nil, depth: 1, desc: "Code formatter config"}
    ]
  end

  defp file_color(name) do
    cond do
      String.ends_with?(name, ".ex") -> "text-green-400"
      String.ends_with?(name, ".exs") -> "text-yellow-400"
      String.ends_with?(name, ".js") -> "text-blue-400"
      String.ends_with?(name, ".css") -> "text-pink-400"
      String.ends_with?(name, ".heex") -> "text-purple-400"
      true -> "text-gray-400"
    end
  end

  defp key_files do
    [
      %{
        path: "mix.exs",
        badge: "PROJECT",
        badge_color: "bg-amber-100 dark:bg-amber-900 text-amber-700 dark:text-amber-300",
        description: "Defines the project name, version, dependencies, and build configuration.",
        code: key_file_mix()
      },
      %{
        path: "lib/my_app/application.ex",
        badge: "BOOT",
        badge_color: "bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300",
        description: "The OTP application module. Defines the supervision tree — what processes start when the app boots.",
        code: key_file_application()
      },
      %{
        path: "lib/my_app_web/endpoint.ex",
        badge: "ENTRY",
        badge_color: "bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300",
        description: "The HTTP entry point. Every request passes through this plug chain before reaching the router.",
        code: key_file_endpoint()
      },
      %{
        path: "lib/my_app_web/router.ex",
        badge: "ROUTES",
        badge_color: "bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300",
        description: "Maps URLs to controllers/LiveViews. Defines pipelines for different request types.",
        code: key_file_router()
      }
    ]
  end

  defp key_file_mix do
    """
    defmodule MyApp.MixProject do
      use Mix.Project

      def project do
        [app: :my_app, version: "0.1.0",
         elixir: "~> 1.14", deps: deps()]
      end

      def application do
        [mod: {MyApp.Application, []},
         extra_applications: [:logger]]
      end

      defp deps do
        [{:phoenix, "~> 1.7"},
         {:phoenix_ecto, "~> 4.4"},
         {:phoenix_live_view, "~> 0.20"},
         {:plug_cowboy, "~> 2.7"}]
      end
    end\
    """
    |> String.trim()
  end

  defp key_file_application do
    """
    defmodule MyApp.Application do
      use Application

      def start(_type, _args) do
        children = [
          MyApp.Repo,           # Database pool
          MyAppWeb.Telemetry,   # Metrics
          {Phoenix.PubSub,
            name: MyApp.PubSub}, # PubSub
          MyAppWeb.Endpoint     # Web server
        ]
        Supervisor.start_link(children,
          strategy: :one_for_one)
      end
    end\
    """
    |> String.trim()
  end

  defp key_file_endpoint do
    """
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      plug Plug.Static, ...
      plug Plug.RequestId
      plug Plug.Telemetry, ...
      plug Plug.Parsers, ...
      plug Plug.Session, ...
      plug MyAppWeb.Router  # Last plug!
    end\
    """
    |> String.trim()
  end

  defp key_file_router do
    """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
      end
    end\
    """
    |> String.trim()
  end

  defp task_groups do
    [
      %{title: "Getting Started", tasks: [
        %{cmd: "mix phx.new my_app", desc: "Generate a new project"},
        %{cmd: "mix setup", desc: "Install deps + create DB + setup assets"},
        %{cmd: "mix phx.server", desc: "Start the dev server on port 4000"},
        %{cmd: "iex -S mix phx.server", desc: "Start with interactive shell"}
      ]},
      %{title: "Database", tasks: [
        %{cmd: "mix ecto.create", desc: "Create the database"},
        %{cmd: "mix ecto.migrate", desc: "Run pending migrations"},
        %{cmd: "mix ecto.rollback", desc: "Rollback last migration"},
        %{cmd: "mix ecto.reset", desc: "Drop + create + migrate"},
        %{cmd: "mix ecto.gen.migration name", desc: "Generate a migration file"}
      ]},
      %{title: "Code Generation", tasks: [
        %{cmd: "mix phx.gen.auth", desc: "Generate authentication system"},
        %{cmd: "mix phx.gen.html", desc: "Generate HTML CRUD scaffold"},
        %{cmd: "mix phx.gen.live", desc: "Generate LiveView CRUD scaffold"},
        %{cmd: "mix phx.gen.json", desc: "Generate JSON API scaffold"},
        %{cmd: "mix phx.gen.context", desc: "Generate context (no web layer)"}
      ]},
      %{title: "Utilities", tasks: [
        %{cmd: "mix phx.routes", desc: "List all defined routes"},
        %{cmd: "mix test", desc: "Run the test suite"},
        %{cmd: "mix format", desc: "Auto-format all code"},
        %{cmd: "mix deps.get", desc: "Fetch dependencies"}
      ]}
    ]
  end

  defp generator_options do
    [
      %{flag: "--no-ecto", effect: "Skip database (no Ecto/Repo)", use_when: "API without persistence"},
      %{flag: "--no-html", effect: "Skip HTML views", use_when: "JSON API only"},
      %{flag: "--no-live", effect: "Skip LiveView", use_when: "Traditional server-rendered app"},
      %{flag: "--no-assets", effect: "Skip esbuild/tailwind", use_when: "API only, or custom frontend"},
      %{flag: "--no-mailer", effect: "Skip Swoosh mailer", use_when: "No email needed"},
      %{flag: "--database sqlite3", effect: "Use SQLite instead of PostgreSQL", use_when: "Simple apps, no Postgres"},
      %{flag: "--umbrella", effect: "Generate umbrella project", use_when: "Large apps with multiple OTP apps"}
    ]
  end

  defp first_run_code do
    """
    $ mix phx.new my_app
    $ cd my_app
    $ mix setup       # deps.get + ecto.setup + assets.setup
    $ mix phx.server  # → http://localhost:4000\
    """
    |> String.trim()
  end
end
