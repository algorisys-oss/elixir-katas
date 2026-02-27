defmodule ElixirKatasWeb.PhoenixKata53MixReleasesLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Mix Releases — Building & Deploying Phoenix

    # --- Build steps ---
    export MIX_ENV=prod
    mix deps.get --only prod
    mix compile
    mix assets.deploy    # bundle JS, minify CSS, digest fingerprints
    mix release          # => _build/prod/rel/my_app/

    # --- Release config (mix.exs) ---
    def project do
      [
        app: :my_app,
        version: "0.1.0",
        releases: [
          my_app: [
            include_executables_for: [:unix],
            steps: [:assemble, :tar]
          ]
        ]
      ]
    end

    # --- Release commands ---
    # bin/my_app start       # start in foreground
    # bin/my_app start_iex   # start with IEx shell
    # bin/my_app daemon      # start as background daemon
    # bin/my_app stop        # stop the app
    # bin/my_app remote      # connect IEx to running app
    # bin/my_app eval "MyApp.Release.migrate()"

    # --- Custom release module (migrations) ---
    defmodule MyApp.Release do
      @app :my_app

      def migrate do
        load_app()
        for repo <- repos() do
          {:ok, _, _} = Ecto.Migrator.with_repo(repo,
            &Ecto.Migrator.run(&1, :up, all: true))
        end
      end

      def rollback(repo, version) do
        load_app()
        {:ok, _, _} = Ecto.Migrator.with_repo(repo,
          &Ecto.Migrator.run(&1, :down, to: version))
      end

      defp repos, do: Application.fetch_env!(@app, :ecto_repos)
      defp load_app, do: Application.load(@app)
    end

    # --- Dockerfile (multi-stage build) ---
    # Stage 1: Build
    FROM elixir:1.16-alpine AS build
    RUN apk add --no-cache build-base git nodejs npm
    WORKDIR /app
    ENV MIX_ENV=prod
    RUN mix local.hex --force && mix local.rebar --force
    COPY mix.exs mix.lock ./
    RUN mix deps.get --only prod && mix deps.compile
    COPY . .
    RUN mix assets.deploy && mix release

    # Stage 2: Runtime (much smaller!)
    FROM alpine:3.19 AS app
    RUN apk add --no-cache libstdc++ openssl ncurses-libs
    WORKDIR /app
    COPY --from=build /app/_build/prod/rel/my_app ./
    CMD ["bin/my_app", "start"]

    # --- Running with Docker ---
    # docker build -t my_app:latest .
    # docker run -d -p 4000:4000 \\
    #   -e DATABASE_URL="postgres://..." \\
    #   -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \\
    #   my_app:latest
    # docker exec my_app bin/my_app eval "MyApp.Release.migrate()"
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "release")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Mix Releases</h2>
      <p class="text-gray-600 dark:text-gray-300">
        mix release, self-contained builds, and Dockerfile — packaging your Phoenix app for production deployment.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "building", "docker", "commands", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-cyan-50 dark:bg-cyan-900/30 text-cyan-700 dark:text-cyan-400 border-b-2 border-cyan-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["release", "why", "assets"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-cyan-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Self-Contained</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Includes Erlang runtime — no Elixir/Mix on production server needed.</p>
            </div>
            <div class="p-4 rounded-lg bg-cyan-50 dark:bg-cyan-900/20 border border-cyan-200 dark:border-cyan-800">
              <p class="text-sm font-semibold text-cyan-700 dark:text-cyan-300 mb-1">Fast Startup</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Pre-compiled bytecode — starts in milliseconds.</p>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">Hot Upgrades</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Supports hot code upgrades without downtime (advanced).</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Building -->
      <%= if @active_tab == "building" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Building a release requires compiling assets first, then running mix release.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{building_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Release Config (mix.exs)</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{mix_release_config_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Release Structure</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{release_structure_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Docker -->
      <%= if @active_tab == "docker" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix generates a Dockerfile with multi-stage builds for efficient, secure images.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{docker_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Multi-Stage Benefits</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>Build stage: has mix, npm, compilers</li>
                <li>Final stage: just the release binary</li>
                <li>Much smaller final image (~50MB vs ~1GB)</li>
                <li>No build tools exposed in production</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Build &amp; Run</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{docker_run_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Release Commands -->
      <%= if @active_tab == "commands" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The release binary provides commands for starting, stopping, and managing the application.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{commands_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-2">Custom Release Commands</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{custom_commands_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Running Migrations</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{migrations_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Generated Dockerfile (Phoenix default)</h4>
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
  defp tab_label("building"), do: "Building"
  defp tab_label("docker"), do: "Dockerfile"
  defp tab_label("commands"), do: "Release Commands"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("release"), do: "What is a Release?"
  defp topic_label("why"), do: "Why Releases?"
  defp topic_label("assets"), do: "Asset Pipeline"

  defp overview_code("release") do
    """
    # A Mix Release packages your app as a self-contained binary:
    # - Includes the Erlang runtime (BEAM VM)
    # - Includes all compiled BEAM bytecode
    # - Includes all dependencies
    # - Does NOT include mix or Elixir source code
    #
    # The production server only needs:
    # - Linux (matching glibc version)
    # - The release tarball
    # - Environment variables
    #
    # Compare to:
    # - Heroku: requires buildpack (git push -> compile)
    # - Docker: container with OS + app (can use releases)
    # - Fly.io: uses Dockerfile (recommended approach)\
    """
    |> String.trim()
  end

  defp overview_code("why") do
    """
    # Why use releases instead of mix phx.server?

    # Development (mix phx.server):
    # - Hot reloading
    # - Mix available
    # - Source maps
    # - Logger colors

    # Production (mix release):
    # + No mix/Elixir needed on server
    # + Smaller attack surface (no compiler)
    # + Fast startup
    # + Can run as a daemon
    # + systemd service support
    # + Multiple named release variants
    # + Hot code upgrades
    # - No interactive shell by default (use eval)
    # - Must recompile for changes\
    """
    |> String.trim()
  end

  defp overview_code("assets") do
    """
    # Before building a release, compile assets:
    # JavaScript (esbuild):
    mix assets.deploy
    # => bundles JS, minifies CSS, digest fingerprints

    # This runs:
    # 1. mix assets.build   (esbuild compile)
    # 2. mix phx.digest     (add cache-busting hashes)

    # Output goes to priv/static/:
    # priv/static/assets/app-abc123.js
    # priv/static/assets/app-abc123.css
    # priv/static/cache_manifest.json

    # mix phx.digest creates a manifest so Phoenix knows
    # which fingerprinted file to serve for each asset name.
    # This enables long-term browser caching (max-age=1year).\
    """
    |> String.trim()
  end

  defp building_code do
    """
    # Local build steps (for testing):
    export MIX_ENV=prod

    # 1. Get dependencies:
    mix deps.get --only prod

    # 2. Compile:
    mix compile

    # 3. Compile assets:
    mix assets.deploy

    # 4. Build the release:
    mix release

    # Output: _build/prod/rel/my_app/
    # Run it:
    _build/prod/rel/my_app/bin/my_app start

    # Named release (if multiple defined):
    mix release my_app\
    """
    |> String.trim()
  end

  defp mix_release_config_code do
    """
    # mix.exs — configure releases:
    def project do
      [
        app: :my_app,
        version: "0.1.0",
        # ...
        releases: [
          my_app: [
            include_executables_for: [:unix],
            steps: [:assemble, :tar]  # create tarball
          ]
        ]
      ]
    end\
    """
    |> String.trim()
  end

  defp release_structure_code do
    """
    # _build/prod/rel/my_app/
    # ├── bin/
    # │   ├── my_app          # main executable
    # │   └── server          # convenience script
    # ├── erts-14.0/          # Erlang runtime
    # ├── lib/
    # │   ├── my_app-0.1.0/   # your app's beam files
    # │   ├── phoenix-1.7.x/  # Phoenix beams
    # │   └── ...             # all dependencies
    # ├── releases/
    # │   └── 0.1.0/
    # │       ├── start.boot
    # │       ├── sys.config
    # │       ├── vm.args
    # │       └── runtime.exs
    # └── tmp/\
    """
    |> String.trim()
  end

  defp docker_code do
    """
    # Dockerfile (multi-stage build):
    # Stage 1: Build
    FROM elixir:1.16-alpine AS build

    RUN apk add --no-cache build-base git nodejs npm

    WORKDIR /app
    ENV MIX_ENV=prod

    # Install hex + rebar:
    RUN mix local.hex --force && mix local.rebar --force

    # Install Elixir deps:
    COPY mix.exs mix.lock ./
    RUN mix deps.get --only prod
    RUN mix deps.compile

    # Copy source and compile assets:
    COPY . .
    RUN mix assets.deploy

    # Build release:
    RUN mix release

    # Stage 2: Runtime (much smaller!)
    FROM alpine:3.19 AS app

    RUN apk add --no-cache libstdc++ openssl ncurses-libs

    WORKDIR /app

    # Copy release from build stage:
    COPY --from=build /app/_build/prod/rel/my_app ./

    ENV HOME=/app
    CMD ["bin/my_app", "start"]\
    """
    |> String.trim()
  end

  defp docker_run_code do
    """
    # Build the Docker image:
    docker build -t my_app:latest .

    # Run with env vars:
    docker run -d \\
      -p 4000:4000 \\
      -e DATABASE_URL="postgres://..." \\
      -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \\
      -e PHX_HOST="example.com" \\
      --name my_app \\
      my_app:latest

    # Run migrations inside the container:
    docker exec my_app \\
      bin/my_app eval "MyApp.Release.migrate()"

    # Or use a separate one-off container:
    docker run --rm \\
      -e DATABASE_URL="postgres://..." \\
      my_app:latest \\
      bin/my_app eval "MyApp.Release.migrate()"\
    """
    |> String.trim()
  end

  defp commands_code do
    """
    # Release commands:
    bin/my_app start         # start in foreground
    bin/my_app start_iex     # start with IEx shell
    bin/my_app daemon        # start as background daemon
    bin/my_app stop          # stop the app
    bin/my_app restart       # restart
    bin/my_app remote        # connect IEx to running app
    bin/my_app pid           # print OS PID
    bin/my_app version       # print version

    # Run a one-off Elixir expression:
    bin/my_app eval "IO.puts(:hello)"

    # Run a function (migrations!):
    bin/my_app eval "MyApp.Release.migrate()"

    # Connect to running node:
    bin/my_app remote
    # => iex(my_app@hostname)>
    # Now you can call any function in the running system!\
    """
    |> String.trim()
  end

  defp custom_commands_code do
    """
    # lib/my_app/release.ex — custom commands:
    defmodule MyApp.Release do
      @app :my_app

      def migrate do
        load_app()
        for repo <- repos() do
          {:ok, _, _} = Ecto.Migrator.with_repo(
            repo,
            &Ecto.Migrator.run(&1, :up, all: true)
          )
        end
      end

      def rollback(repo, version) do
        load_app()
        {:ok, _, _} = Ecto.Migrator.with_repo(
          repo,
          &Ecto.Migrator.run(&1, :down, to: version)
        )
      end

      defp repos, do:
        Application.fetch_env!(@app, :ecto_repos)

      defp load_app do
        Application.load(@app)
      end
    end\
    """
    |> String.trim()
  end

  defp migrations_code do
    """
    # Run migrations in production (release):

    # Option 1: As a release command:
    bin/my_app eval "MyApp.Release.migrate()"

    # Option 2: In entrypoint.sh (Docker):
    #!/bin/bash
    set -e
    bin/my_app eval "MyApp.Release.migrate()"
    exec bin/my_app start

    # Option 3: Fly.io release command:
    # fly.toml:
    [deploy]
      release_command = "bin/my_app eval \\
        'MyApp.Release.migrate()'"

    # Fly runs this before deploying new instances.\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete Dockerfile generated by Phoenix:
    # (mix phx.new generates this automatically)

    ARG ELIXIR_VERSION=1.16.0
    ARG OTP_VERSION=26.2.1
    ARG DEBIAN_VERSION=bullseye-20231009-slim
    ARG BUILDER_IMAGE="hexpm/elixir:\\
      \${ELIXIR_VERSION}-erlang-\${OTP_VERSION}-\\
      debian-\${DEBIAN_VERSION}"
    ARG RUNNER_IMAGE="debian:\${DEBIAN_VERSION}"

    FROM \${BUILDER_IMAGE} as builder

    RUN apt-get update -y && \\
        apt-get install -y build-essential git && \\
        apt-get clean && rm -f /var/lib/apt/lists/*_*

    WORKDIR /app
    RUN mix local.hex --force && \\
        mix local.rebar --force

    ENV MIX_ENV="prod"

    COPY mix.exs mix.lock ./
    RUN mix deps.get --only \$MIX_ENV
    RUN mkdir config
    COPY config/config.exs config/\${MIX_ENV}.exs config/
    RUN mix deps.compile

    COPY priv priv
    COPY lib lib
    COPY assets assets

    RUN mix assets.deploy
    RUN mix compile

    COPY config/runtime.exs config/
    RUN mix release

    # ---- Runner stage ----
    FROM \${RUNNER_IMAGE}

    RUN apt-get update -y && \\
      apt-get install -y libstdc++6 openssl \\
        libncurses5 locales ca-certificates && \\
      apt-get clean && rm -f /var/lib/apt/lists/*_* && \\
      sed -i '/en_US.UTF-8/s/^# //g' \\
        /etc/locale.gen && locale-gen

    ENV LANG en_US.UTF-8
    ENV LANGUAGE en_US:en
    ENV LC_ALL en_US.UTF-8

    WORKDIR "/app"
    RUN chown nobody /app
    ENV MIX_ENV="prod"

    COPY --from=builder --chown=nobody:root \\
      /app/_build/\${MIX_ENV}/rel/my_app ./

    USER nobody

    CMD ["/app/bin/server"]\
    """
    |> String.trim()
  end
end
