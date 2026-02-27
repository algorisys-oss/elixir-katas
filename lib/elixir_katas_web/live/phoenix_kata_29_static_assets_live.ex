defmodule ElixirKatasWeb.PhoenixKata29StaticAssetsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Project asset structure:
    # assets/js/app.js       → Main JS entry point
    # assets/css/app.css     → Main CSS (Tailwind directives)
    # priv/static/assets/    → Built output (don't edit!)
    # priv/static/images/    → Static images

    # 1. Endpoint — serves static files:
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      plug Plug.Static,
        at: "/",
        from: :my_app,
        gzip: false,
        only: MyAppWeb.static_paths()
    end

    # 2. Static paths — which directories to serve:
    def static_paths do
      ~w(assets fonts images favicon.ico robots.txt)
    end

    # 3. In root layout — reference assets with ~p:
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    <script defer phx-track-static src={~p"/assets/app.js"}></script>
    <img src={~p"/images/logo.png"} alt="Logo" />

    # 4. Cache busting:
    # Dev:  ~p"/assets/app.css" → "/assets/app.css"
    # Prod: ~p"/assets/app.css" → "/assets/app-ABC123.css"

    # 5. Dev config — watchers auto-rebuild on changes:
    config :my_app, MyAppWeb.Endpoint,
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]},
        tailwind: {Tailwind, :install_and_run, [:my_app, ~w(--watch)]}
      ]

    # 6. Production build:
    # $ mix assets.deploy
    # → esbuild (bundle + minify JS)
    # → tailwind (compile + purge CSS)
    # → phx.digest (fingerprint files + cache manifest)
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "structure")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Static Assets</h2>
      <p class="text-gray-600 dark:text-gray-300">
        esbuild for JavaScript, Tailwind for CSS, cache busting for production.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "usage", "deploy", "code"]}
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
            <button :for={topic <- ["structure", "pipeline", "config"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {String.capitalize(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>
        </div>
      <% end %>

      <!-- Usage in templates -->
      <%= if @active_tab == "usage" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            How to reference static assets in templates with cache busting.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">CSS & JS</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{css_js_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Images & Files</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{images_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 md:col-span-2">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Cache Busting</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{cache_busting_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Deployment -->
      <%= if @active_tab == "deploy" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Building and deploying assets for production.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{deploy_code()}</div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Build Steps</p>
            <div class="space-y-2 text-sm text-gray-600 dark:text-gray-300">
              <p><strong>1. esbuild</strong> — Bundles and minifies JavaScript</p>
              <p><strong>2. tailwind</strong> — Compiles and purges unused CSS</p>
              <p><strong>3. phx.digest</strong> — Fingerprints files and creates cache manifest</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Asset Configuration</h4>
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
  defp tab_label("usage"), do: "Usage"
  defp tab_label("deploy"), do: "Deployment"
  defp tab_label("code"), do: "Source Code"

  defp overview_code("structure") do
    """
    # Project asset structure:
    my_app/
      assets/
        js/
          app.js          # Main JS entry point
        css/
          app.css         # Main CSS (Tailwind directives)
        vendor/           # Third-party JS (not on npm)
        tailwind.config.js

      priv/static/
        assets/           # Built output (don't edit!)
          app.js          # Bundled JS
          app.css         # Compiled CSS
        images/           # Static images
          logo.png
        favicon.ico
        robots.txt\
    """
    |> String.trim()
  end

  defp overview_code("pipeline") do
    """
    # Asset pipeline flow:

    # Development:
    assets/js/app.js  → esbuild (watch) → priv/static/assets/app.js
    assets/css/app.css → tailwind (watch) → priv/static/assets/app.css

    # Production:
    assets/js/app.js  → esbuild (minify) → priv/static/assets/app.js
    assets/css/app.css → tailwind (minify) → priv/static/assets/app.css
                       → phx.digest       → priv/static/assets/app-ABC123.js
                                           → priv/static/assets/app-DEF456.css
                                           → priv/static/cache_manifest.json\
    """
    |> String.trim()
  end

  defp overview_code("config") do
    """
    # config/config.exs:
    config :esbuild,
      version: "0.17.11",
      my_app: [
        args: ~w(js/app.js --bundle --target=es2017
                 --outdir=../priv/static/assets
                 --external:/fonts/* --external:/images/*),
        cd: Path.expand("../assets", __DIR__),
        env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
      ]

    config :tailwind,
      version: "3.4.0",
      my_app: [
        args: ~w(
          --config=tailwind.config.js
          --input=css/app.css
          --output=../priv/static/assets/app.css
        ),
        cd: Path.expand("../assets", __DIR__)
      ]\
    """
    |> String.trim()
  end

  defp css_js_code do
    """
    <%# In root.html.heex: %>
    <link phx-track-static
          rel="stylesheet"
          href={~p"/assets/app.css"} />

    <script defer phx-track-static
            src={~p"/assets/app.js"}>
    </script>

    <%# phx-track-static: tells Phoenix
        to track for change detection %>\
    """
    |> String.trim()
  end

  defp images_code do
    """
    <%# Images in priv/static/images/: %>
    <img src={~p"/images/logo.png"} alt="Logo" />
    <img src={~p"/images/hero.jpg"} alt="Hero" />

    <%# Favicon: %>
    <link rel="icon" href={~p"/favicon.ico"} />

    <%# In CSS: %>
    <%# background: url('/images/bg.png'); %>\
    """
    |> String.trim()
  end

  defp cache_busting_code do
    """
    # In development:
    ~p"/assets/app.css"  → "/assets/app.css"

    # In production (after mix phx.digest):
    ~p"/assets/app.css"  → "/assets/app-ABC123.css"

    # The cache manifest maps original → digested:
    # priv/static/cache_manifest.json:
    # {
    #   "assets/app.css": "assets/app-ABC123.css",
    #   "assets/app.js": "assets/app-DEF456.js"
    # }

    # Browsers cache aggressively → new deploy = new hash = fresh load\
    """
    |> String.trim()
  end

  defp deploy_code do
    """
    # Build assets for production:
    $ mix assets.deploy

    # This runs three steps:
    # 1. esbuild — bundle + minify JS
    $ esbuild --bundle --minify --outdir=priv/static/assets

    # 2. tailwind — compile + purge unused CSS
    $ tailwind --minify --output=priv/static/assets/app.css

    # 3. phx.digest — fingerprint + manifest
    $ mix phx.digest
    # Creates: app-ABC123.css, app-DEF456.js
    # Creates: cache_manifest.json

    # In a release:
    $ mix phx.digest.clean  # Remove old digested files\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # 1. Endpoint — serves static files:
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      plug Plug.Static,
        at: "/",
        from: :my_app,
        gzip: false,
        only: MyAppWeb.static_paths()
      # ...
    end

    # 2. Static paths:
    def static_paths do
      ~w(assets fonts images favicon.ico robots.txt)
    end

    # 3. Dev config — watchers:
    config :my_app, MyAppWeb.Endpoint,
      watchers: [
        esbuild: {Esbuild, :install_and_run,
          [:my_app, ~w(--sourcemap=inline --watch)]},
        tailwind: {Tailwind, :install_and_run,
          [:my_app, ~w(--watch)]}
      ]

    # 4. Prod config — cache manifest:
    config :my_app, MyAppWeb.Endpoint,
      cache_static_manifest: "priv/static/cache_manifest.json"

    # 5. Root layout — reference assets:
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    <script defer phx-track-static src={~p"/assets/app.js"}></script>

    # 6. Deploy script:
    # mix assets.deploy
    # → esbuild (minify JS)
    # → tailwind (minify CSS)
    # → phx.digest (fingerprint files)\
    """
    |> String.trim()
  end
end
