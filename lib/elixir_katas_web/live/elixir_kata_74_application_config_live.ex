defmodule ElixirKatasWeb.ElixirKata74ApplicationConfigLive do
  use ElixirKatasWeb, :live_component

  @config_files [
    %{
      id: "config_exs",
      title: "config/config.exs",
      description: "Shared configuration loaded at compile time. Used for settings common across all environments.",
      code: "# config/config.exs\nimport Config\n\nconfig :my_app,\n  ecto_repos: [MyApp.Repo],\n  generators: [timestamp_type: :utc_datetime]\n\nconfig :my_app, MyAppWeb.Endpoint,\n  url: [host: \"localhost\"],\n  adapter: Bandit.Adapter,\n  render_errors: [\n    formats: [html: MyAppWeb.ErrorHTML],\n    layout: false\n  ]\n\n# Import environment specific config\nimport_config \"\#{config_env()}.exs\"",
      when_loaded: "Compile time",
      use_for: "Shared defaults, structure definitions"
    },
    %{
      id: "dev_exs",
      title: "config/dev.exs",
      description: "Development-specific configuration. Loaded at compile time for the :dev environment.",
      code: "# config/dev.exs\nimport Config\n\nconfig :my_app, MyApp.Repo,\n  username: \"postgres\",\n  password: \"postgres\",\n  hostname: \"localhost\",\n  database: \"my_app_dev\"\n\nconfig :my_app, MyAppWeb.Endpoint,\n  http: [ip: {127, 0, 0, 1}, port: 4000],\n  debug_errors: true,\n  code_reloader: true",
      when_loaded: "Compile time (dev only)",
      use_for: "Dev database, debug settings, local ports"
    },
    %{
      id: "test_exs",
      title: "config/test.exs",
      description: "Test-specific configuration. Loaded at compile time for the :test environment.",
      code: "# config/test.exs\nimport Config\n\nconfig :my_app, MyApp.Repo,\n  username: \"postgres\",\n  password: \"postgres\",\n  hostname: \"localhost\",\n  database: \"my_app_test\#{System.get_env(\"MIX_TEST_PARTITION\")}\",\n  pool: Ecto.Adapters.SQL.Sandbox\n\nconfig :my_app, MyAppWeb.Endpoint,\n  http: [ip: {127, 0, 0, 1}, port: 4002],\n  server: false",
      when_loaded: "Compile time (test only)",
      use_for: "Test database, sandbox pool, disable server"
    },
    %{
      id: "prod_exs",
      title: "config/prod.exs",
      description: "Production compile-time config. Only for settings that can be determined at build time.",
      code: "# config/prod.exs\nimport Config\n\nconfig :my_app, MyAppWeb.Endpoint,\n  cache_static_manifest: \"priv/static/cache_manifest.json\"\n\nconfig :logger, level: :info",
      when_loaded: "Compile time (prod only)",
      use_for: "Static manifests, log levels, compile-time optimizations"
    },
    %{
      id: "runtime_exs",
      title: "config/runtime.exs",
      description: "Runtime configuration. Loaded when the application starts, not at compile time. Can read environment variables.",
      code: "# config/runtime.exs\nimport Config\n\nif config_env() == :prod do\n  database_url =\n    System.get_env(\"DATABASE_URL\") ||\n      raise \"DATABASE_URL environment variable is not set\"\n\n  config :my_app, MyApp.Repo,\n    url: database_url,\n    pool_size: String.to_integer(System.get_env(\"POOL_SIZE\") || \"10\")\n\n  secret_key_base =\n    System.get_env(\"SECRET_KEY_BASE\") ||\n      raise \"SECRET_KEY_BASE environment variable is not set\"\n\n  config :my_app, MyAppWeb.Endpoint,\n    http: [port: String.to_integer(System.get_env(\"PORT\") || \"4000\")],\n    secret_key_base: secret_key_base\nend",
      when_loaded: "Application start (runtime)",
      use_for: "Environment variables, secrets, dynamic settings"
    }
  ]

  @access_methods [
    %{
      id: "get_env",
      title: "Application.get_env/3",
      code: "# Read config at runtime\nApplication.get_env(:my_app, :ecto_repos)\n# => [MyApp.Repo]\n\n# With default value\nApplication.get_env(:my_app, :timeout, 5000)\n# => 5000 (if not configured)",
      description: "Read a config value at runtime. Takes app name, key, and optional default."
    },
    %{
      id: "fetch_env",
      title: "Application.fetch_env!/2",
      code: "# Raises if not configured\nApplication.fetch_env!(:my_app, :secret_key_base)\n# => \"abc123...\"\n\n# fetch_env/2 returns {:ok, value} or :error\nApplication.fetch_env(:my_app, :missing)\n# => :error",
      description: "Like get_env but raises if the key is not configured. Use fetch_env/2 for the tagged tuple version."
    },
    %{
      id: "compile_env",
      title: "Application.compile_env/3",
      code: "# Read config at COMPILE time (in module body)\ndefmodule MyModule do\n  @timeout Application.compile_env(:my_app, :timeout, 5000)\n\n  def timeout, do: @timeout\nend",
      description: "Read config at compile time. Used for module attributes. Elixir tracks these and warns if the value changes between compilations."
    },
    %{
      id: "put_env",
      title: "Application.put_env/3",
      code: "# Set config at runtime (useful in tests)\nApplication.put_env(:my_app, :feature_flag, true)\n\nApplication.get_env(:my_app, :feature_flag)\n# => true",
      description: "Set a config value at runtime. Commonly used in tests to override settings."
    }
  ]

  @best_practices [
    %{
      title: "Use runtime.exs for secrets",
      good: "config/runtime.exs reads DATABASE_URL from environment",
      bad: "Hardcoding passwords in config/prod.exs"
    },
    %{
      title: "Use compile_env for module attributes",
      good: "@pool_size Application.compile_env(:my_app, :pool_size, 10)",
      bad: "@pool_size Application.get_env(:my_app, :pool_size, 10)"
    },
    %{
      title: "Namespace your config",
      good: "config :my_app, MyApp.Mailer, adapter: Swoosh.Adapters.SMTP",
      bad: "config :my_app, mailer_adapter: Swoosh.Adapters.SMTP"
    },
    %{
      title: "Provide defaults",
      good: "Application.get_env(:my_app, :timeout, 5000)",
      bad: "Application.get_env(:my_app, :timeout) (may return nil)"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_file, fn -> hd(@config_files) end)
     |> assign_new(:active_method, fn -> hd(@access_methods) end)
     |> assign_new(:show_methods, fn -> false end)
     |> assign_new(:show_best_practices, fn -> false end)
     |> assign_new(:show_timeline, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Application Config</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir uses a layered configuration system. Config files are loaded at <strong>compile time</strong>,
        while <code class="font-mono bg-base-300 px-1 rounded">runtime.exs</code> is loaded when the
        application starts. Understanding the difference is crucial for production deployments.
      </p>

      <!-- Config Files Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Config Files</h3>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for file <- config_files() do %>
              <button
                phx-click="select_file"
                phx-target={@myself}
                phx-value-id={file.id}
                class={"btn btn-sm " <> if(@active_file.id == file.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= file.title %>
              </button>
            <% end %>
          </div>

          <p class="text-sm opacity-70 mb-3"><%= @active_file.description %></p>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-4"><%= @active_file.code %></div>

          <div class="grid grid-cols-2 gap-4 text-sm">
            <div class="bg-base-100 rounded-lg p-3 border border-base-300">
              <span class="font-bold text-xs opacity-60">When loaded:</span>
              <div class={"font-mono mt-1 " <> if(@active_file.when_loaded =~ "runtime", do: "text-warning", else: "text-info")}>
                <%= @active_file.when_loaded %>
              </div>
            </div>
            <div class="bg-base-100 rounded-lg p-3 border border-base-300">
              <span class="font-bold text-xs opacity-60">Use for:</span>
              <div class="mt-1"><%= @active_file.use_for %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Config Loading Timeline -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Config Loading Timeline</h3>
            <button
              phx-click="toggle_timeline"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_timeline, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_timeline do %>
            <div class="space-y-3">
              <!-- Compile time -->
              <div class="bg-info/10 border border-info/30 rounded-lg p-4">
                <div class="font-bold text-info text-sm mb-2">Compile Time</div>
                <div class="flex flex-wrap gap-2">
                  <div class="bg-base-100 rounded px-3 py-1 font-mono text-xs">config.exs</div>
                  <span class="opacity-30 self-center">&rarr;</span>
                  <div class="bg-base-100 rounded px-3 py-1 font-mono text-xs">&lbrace;dev|test|prod&rbrace;.exs</div>
                  <span class="opacity-30 self-center">&rarr;</span>
                  <div class="bg-base-100 rounded px-3 py-1 text-xs">Code compiles with these values baked in</div>
                </div>
                <p class="text-xs opacity-60 mt-2">
                  Values are available via <code class="font-mono bg-base-100 px-1 rounded">Application.compile_env/3</code>
                  and module attributes.
                </p>
              </div>

              <!-- Arrow -->
              <div class="text-center opacity-30">&darr; Application starts &darr;</div>

              <!-- Runtime -->
              <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                <div class="font-bold text-warning text-sm mb-2">Runtime (Application Start)</div>
                <div class="flex flex-wrap gap-2">
                  <div class="bg-base-100 rounded px-3 py-1 font-mono text-xs">runtime.exs</div>
                  <span class="opacity-30 self-center">&rarr;</span>
                  <div class="bg-base-100 rounded px-3 py-1 text-xs">Reads env vars, sets dynamic config</div>
                </div>
                <p class="text-xs opacity-60 mt-2">
                  Values are available via <code class="font-mono bg-base-100 px-1 rounded">Application.get_env/3</code>.
                  Can read <code class="font-mono bg-base-100 px-1 rounded">System.get_env/1</code>.
                </p>
              </div>

              <!-- Arrow -->
              <div class="text-center opacity-30">&darr; Application running &darr;</div>

              <!-- Dynamic -->
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <div class="font-bold text-success text-sm mb-2">Runtime (Dynamic)</div>
                <div class="flex flex-wrap gap-2">
                  <div class="bg-base-100 rounded px-3 py-1 font-mono text-xs">Application.put_env/3</div>
                  <span class="opacity-30 self-center">&rarr;</span>
                  <div class="bg-base-100 rounded px-3 py-1 text-xs">Update config while app is running</div>
                </div>
                <p class="text-xs opacity-60 mt-2">
                  Useful in tests or for feature flags. Changes are not persisted across restarts.
                </p>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Access Methods -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Accessing Config</h3>
            <button
              phx-click="toggle_methods"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_methods, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_methods do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for method <- access_methods() do %>
                <button
                  phx-click="select_method"
                  phx-target={@myself}
                  phx-value-id={method.id}
                  class={"btn btn-sm " <> if(@active_method.id == method.id, do: "btn-accent", else: "btn-outline")}
                >
                  <%= method.title %>
                </button>
              <% end %>
            </div>

            <p class="text-sm opacity-70 mb-3"><%= @active_method.description %></p>
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_method.code %></div>
          <% end %>
        </div>
      </div>

      <!-- Best Practices -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Best Practices</h3>
            <button
              phx-click="toggle_best_practices"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_best_practices, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_best_practices do %>
            <div class="space-y-3">
              <%= for practice <- best_practices() do %>
                <div class="bg-base-100 rounded-lg p-4 border border-base-300">
                  <h4 class="font-bold text-sm mb-2"><%= practice.title %></h4>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-2 text-xs">
                    <div class="bg-success/10 border border-success/30 rounded p-2">
                      <span class="font-bold text-success">Good: </span>
                      <span class="font-mono"><%= practice.good %></span>
                    </div>
                    <div class="bg-error/10 border border-error/30 rounded p-2">
                      <span class="font-bold text-error">Avoid: </span>
                      <span class="font-mono"><%= practice.bad %></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="4"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={"# Try reading application config\nApplication.get_env(:elixir_katas, ElixirKatasWeb.Endpoint)\n|> Keyword.take([:url, :render_errors])"}
              autocomplete="off"
            ><%= @sandbox_code %></textarea>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- sandbox_quick_examples() do %>
              <button
                phx-click="quick_sandbox"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm mt-3 " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs"><%= @sandbox_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>config.exs</strong> and environment files are loaded at <strong>compile time</strong>. Values are baked into the compiled code.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>runtime.exs</strong> is loaded when the application starts. Use it for environment variables and secrets.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">Application.get_env/3</code> with a default value for safe runtime access.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">Application.compile_env/3</code> for module attributes that need config values.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Never hardcode secrets</strong> in config files. Use environment variables via <code class="font-mono bg-base-100 px-1 rounded">System.get_env/1</code> in runtime.exs.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_file", %{"id" => id}, socket) do
    file = Enum.find(config_files(), &(&1.id == id))
    {:noreply, assign(socket, active_file: file)}
  end

  def handle_event("toggle_timeline", _params, socket) do
    {:noreply, assign(socket, show_timeline: !socket.assigns.show_timeline)}
  end

  def handle_event("toggle_methods", _params, socket) do
    {:noreply, assign(socket, show_methods: !socket.assigns.show_methods)}
  end

  def handle_event("select_method", %{"id" => id}, socket) do
    method = Enum.find(access_methods(), &(&1.id == id))
    {:noreply, assign(socket, active_method: method)}
  end

  def handle_event("toggle_best_practices", _params, socket) do
    {:noreply, assign(socket, show_best_practices: !socket.assigns.show_best_practices)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  def handle_event("quick_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp config_files, do: @config_files
  defp access_methods, do: @access_methods
  defp best_practices, do: @best_practices

  defp sandbox_quick_examples do
    [
      {"get all apps", "Application.loaded_applications() |> Enum.map(&elem(&1, 0)) |> Enum.sort() |> Enum.take(10)"},
      {"get_env", "Application.get_env(:logger, :level)"},
      {"put + get", "Application.put_env(:my_test, :flag, true)\nApplication.get_env(:my_test, :flag)"},
      {"all_env", "Application.get_all_env(:logger) |> Keyword.keys()"}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _bindings} = Code.eval_string(code)
      %{ok: true, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, output: "Error: #{Exception.message(e)}"}
    end
  end
end
