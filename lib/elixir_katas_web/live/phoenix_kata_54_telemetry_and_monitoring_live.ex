defmodule ElixirKatasWeb.PhoenixKata54TelemetryAndMonitoringLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Telemetry & Monitoring

    # 1. Telemetry module (lib/my_app/telemetry.ex)
    defmodule MyApp.Telemetry do
      use Supervisor
      import Telemetry.Metrics

      def start_link(arg) do
        Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
      end

      def init(_arg) do
        children = [
          {:telemetry_poller,
           measurements: [{MyApp.Telemetry, :measure_memory, []}],
           period: 30_000}
        ]
        Supervisor.init(children, strategy: :one_for_one)
      end

      def measure_memory do
        :telemetry.execute([:vm, :memory], :erlang.memory(), %{})
      end

      def metrics do
        [
          # HTTP requests
          counter("phoenix.router_dispatch.stop.duration", tags: [:route]),
          summary("phoenix.router_dispatch.stop.duration",
            tags: [:route], unit: {:native, :millisecond}),

          # LiveView
          summary("phoenix.live_view.mount.stop.duration",
            unit: {:native, :millisecond}),

          # Ecto queries
          summary("my_app.repo.query.total_time",
            unit: {:native, :millisecond}),
          counter("my_app.repo.query.count"),

          # Business events
          counter("my_app.orders.placed.count"),

          # VM
          last_value("vm.memory.total", unit: {:byte, :megabyte}),
          last_value("vm.total_run_queue_lengths.total")
        ]
      end
    end

    # 2. Emitting custom events
    :telemetry.execute(
      [:my_app, :order, :placed],
      %{amount_cents: 2999},
      %{order_id: 42, user_id: 7}
    )

    # 3. Using :telemetry.span for start/stop events
    :telemetry.span([:my_app, :payment, :process], %{}, fn ->
      result = PaymentGateway.charge(payment)
      {result, %{status: elem(result, 0)}}
    end)
    # Emits: [:my_app, :payment, :process, :start]
    #        [:my_app, :payment, :process, :stop]  (with duration)
    #        [:my_app, :payment, :process, :exception]  (on error)

    # 4. Attaching handlers
    :telemetry.attach("my-handler",
      [:phoenix, :router_dispatch, :start],
      &MyApp.Telemetry.handle_event/4, %{})

    def handle_event(event, measurements, metadata, config) do
      # event:        [:phoenix, :router_dispatch, :start]
      # measurements: %{system_time: ...}
      # metadata:     %{conn: ..., route: ...}
    end

    # 5. LiveDashboard
    import Phoenix.LiveDashboard.Router
    scope "/" do
      pipe_through [:browser, :require_admin]
      live_dashboard "/dashboard",
        metrics: MyApp.Telemetry,
        ecto_repos: [MyApp.Repo]
    end

    # 6. Health check controller
    defmodule MyAppWeb.HealthController do
      use MyAppWeb, :controller

      def index(conn, _params), do: json(conn, %{status: "ok"})

      def ready(conn, _params) do
        case MyApp.Repo.query("SELECT 1") do
          {:ok, _} -> json(conn, %{status: "ready", db: "connected"})
          _ -> conn |> put_status(503) |> json(%{status: "not_ready"})
        end
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "events")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Telemetry &amp; Monitoring</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Telemetry events, LiveDashboard, metrics, and health checks — observability for Phoenix applications.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "metrics", "dashboard", "health", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-violet-50 dark:bg-violet-900/30 text-violet-700 dark:text-violet-400 border-b-2 border-violet-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["events", "execute", "span"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-violet-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Telemetry</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Structured events emitted by libraries. Handlers process them.</p>
            </div>
            <div class="p-4 rounded-lg bg-violet-50 dark:bg-violet-900/20 border border-violet-200 dark:border-violet-800">
              <p class="text-sm font-semibold text-violet-700 dark:text-violet-300 mb-1">Metrics</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Aggregate telemetry into counters, gauges, histograms.</p>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">LiveDashboard</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Real-time metrics, process inspection, request logging.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Metrics -->
      <%= if @active_tab == "metrics" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>Telemetry.Metrics</code> defines what you measure. Reporters send those measurements to monitoring systems.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{metrics_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Metric Types</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>counter</strong>: how many times something happened</li>
                <li><strong>sum</strong>: total of a measurement</li>
                <li><strong>last_value</strong>: most recent measurement</li>
                <li><strong>summary</strong>: stats (percentiles) of a measurement</li>
                <li><strong>distribution</strong>: histogram of a measurement</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Built-in Phoenix Events</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{phoenix_events_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- LiveDashboard -->
      <%= if @active_tab == "dashboard" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix LiveDashboard provides real-time observability with zero configuration required.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{dashboard_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Dashboard Features</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>Real-time system metrics (CPU, memory, IO)</li>
                <li>All Erlang processes + memory usage</li>
                <li>ETS tables</li>
                <li>Application tree</li>
                <li>Request logging (configurable)</li>
                <li>Custom pages via plugins</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-2">Security Warning</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">
                LiveDashboard exposes internal state. In production, restrict access via authentication or IP allowlist. Never expose it publicly.
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Health Checks -->
      <%= if @active_tab == "health" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Health check endpoints for load balancers and container orchestrators.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{health_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Health Check Types</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>Liveness</strong>: is the process alive? (simple 200)</li>
                <li><strong>Readiness</strong>: can it serve traffic? (DB connected?)</li>
                <li><strong>Startup</strong>: has initial load completed?</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">External Services</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{external_services_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Telemetry Setup</h4>
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

  defp tab_label("overview"), do: "Telemetry Overview"
  defp tab_label("metrics"), do: "Metrics"
  defp tab_label("dashboard"), do: "LiveDashboard"
  defp tab_label("health"), do: "Health Checks"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("events"), do: "Events"
  defp topic_label("execute"), do: ":execute"
  defp topic_label("span"), do: "Spans"

  defp overview_code("events") do
    """
    # Telemetry events are named lists of atoms:
    # [:my_app, :repo, :query]
    # [:phoenix, :router_dispatch, :start]
    # [:my_app, :orders, :placed]

    # Libraries emit events automatically:
    # Phoenix: [:phoenix, :router_dispatch, :start/:stop/:exception]
    # Ecto:    [:my_app, :repo, :query]
    # Oban:    [:oban, :job, :start/:stop/:exception]

    # Attach a handler to listen for events:
    :telemetry.attach(
      "my-handler",                          # unique handler ID
      [:phoenix, :router_dispatch, :start],  # event name
      &MyApp.Telemetry.handle_event/4,       # callback
      %{}                                    # config
    )

    # Handler signature:
    def handle_event(event, measurements, metadata, config) do
      # event:        [:phoenix, :router_dispatch, :start]
      # measurements: %{system_time: ...}
      # metadata:     %{conn: ..., route: ...}
      # config:       %{}  (your config from attach)
      :ok
    end\
    """
    |> String.trim()
  end

  defp overview_code("execute") do
    """
    # :telemetry.execute/3 - emit an event:
    :telemetry.execute(
      [:my_app, :order, :placed],   # event name
      %{amount_cents: 2999},         # measurements
      %{order_id: 42, user_id: 7}   # metadata
    )

    # Emit from business logic:
    defmodule MyApp.Orders do
      def place_order(user, items) do
        start = System.monotonic_time()

        {:ok, order} = create_order(user, items)

        :telemetry.execute(
          [:my_app, :orders, :placed],
          %{
            duration: System.monotonic_time() - start,
            amount: order.total_cents
          },
          %{
            user_id: user.id,
            order_id: order.id,
            item_count: length(items)
          }
        )

        {:ok, order}
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("span") do
    """
    # :telemetry.span/3 - emit start + stop events:
    result = :telemetry.span(
      [:my_app, :payment, :process],  # base event name
      %{payment_id: payment.id},       # metadata
      fn ->
        # Your code here:
        result = PaymentGateway.charge(payment)
        # Return {result, extra_metadata}:
        {result, %{status: elem(result, 0)}}
      end
    )

    # This emits TWO events automatically:
    # [:my_app, :payment, :process, :start]  at beginning
    # [:my_app, :payment, :process, :stop]   at end (with duration)
    # [:my_app, :payment, :process, :exception] on error
    #
    # Measurements on stop:
    # %{duration: N}  (in native time units)\
    """
    |> String.trim()
  end

  defp metrics_code do
    """
    # lib/my_app/telemetry.ex (generated by Phoenix):
    defmodule MyApp.Telemetry do
      use Supervisor
      import Telemetry.Metrics

      def start_link(arg) do
        Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
      end

      def init(_arg) do
        children = [
          # Periodic measurements (system stats):
          {:telemetry_poller,
            measurements: periodic_measurements(),
            period: 10_000},

          # Metrics reporter (Prometheus, StatsD, etc.):
          # {TelemetryMetricsPrometheus, metrics: metrics()}
          # {TelemetryMetricsStatsd, metrics: metrics()}
        ]
        Supervisor.init(children, strategy: :one_for_one)
      end

      def metrics do
        [
          # Phoenix request metrics:
          summary("phoenix.endpoint.start.system_time"),
          summary("phoenix.router_dispatch.stop.duration",
            unit: {:native, :millisecond}),

          # LiveView metrics:
          summary("phoenix.live_view.mount.stop.duration",
            unit: {:native, :millisecond}),

          # Ecto query metrics:
          summary("my_app.repo.query.total_time",
            unit: {:native, :millisecond}),
          counter("my_app.repo.query.count"),

          # VM metrics:
          summary("vm.memory.total", unit: {:byte, :kilobyte}),
          summary("vm.total_run_queue_lengths.total"),

          # Custom business metrics:
          counter("my_app.orders.placed.count"),
          summary("my_app.orders.placed.amount_cents")
        ]
      end

      defp periodic_measurements do
        [{MyApp.Telemetry, :dispatch_vm_stats, []}]
      end
    end\
    """
    |> String.trim()
  end

  defp phoenix_events_code do
    """
    # Events emitted by Phoenix/Ecto automatically:

    # HTTP requests:
    [:phoenix, :endpoint, :start]
    [:phoenix, :endpoint, :stop]
    [:phoenix, :router_dispatch, :start]
    [:phoenix, :router_dispatch, :stop]
    [:phoenix, :router_dispatch, :exception]

    # LiveView:
    [:phoenix, :live_view, :mount, :start]
    [:phoenix, :live_view, :mount, :stop]
    [:phoenix, :live_view, :handle_event, :start]
    [:phoenix, :live_view, :handle_event, :stop]

    # Ecto (prefix is your app name):
    [:my_app, :repo, :query]  # all queries

    # BEAM VM (via :telemetry_poller):
    [:vm, :memory]
    [:vm, :total_run_queue_lengths]
    [:vm, :system_counts]\
    """
    |> String.trim()
  end

  defp dashboard_code do
    """
    # Add LiveDashboard to router.ex:
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      # Dev: no auth needed:
      live_dashboard "/dashboard",
        metrics: MyApp.Telemetry

      # Production: require auth:
      pipe_through :require_admin
      live_dashboard "/dashboard",
        metrics: MyApp.Telemetry,
        ecto_repos: [MyApp.Repo],
        ecto_psql_extras_options: [lang: :en]
    end

    # Visit http://localhost:4000/dashboard

    # Dependencies in mix.exs:
    {:phoenix_live_dashboard, "~> 0.8"},
    {:telemetry_metrics, "~> 1.0"},
    {:telemetry_poller, "~> 1.0"}\
    """
    |> String.trim()
  end

  defp health_code do
    """
    # Simple health check controller:
    defmodule MyAppWeb.HealthController do
      use MyAppWeb, :controller

      # GET /health (liveness - just 200):
      def index(conn, _params) do
        json(conn, %{status: "ok"})
      end

      # GET /health/ready (readiness - check DB):
      def ready(conn, _params) do
        case check_db() do
          :ok ->
            json(conn, %{
              status: "ready", db: "connected"
            })

          {:error, reason} ->
            conn
            |> put_status(503)
            |> json(%{
              status: "not_ready", db: reason
            })
        end
      end

      defp check_db do
        MyApp.Repo.query("SELECT 1")
        :ok
      rescue
        e -> {:error, Exception.message(e)}
      end
    end

    # In router.ex (before auth plugs):
    scope "/" do
      get "/health", HealthController, :index
      get "/health/ready", HealthController, :ready
    end

    # Docker HEALTHCHECK:
    # HEALTHCHECK --interval=30s --timeout=10s \\
    #   CMD wget -qO- http://localhost:4000/health || exit 1\
    """
    |> String.trim()
  end

  defp external_services_code do
    """
    # Check external deps in readiness probe:
    def ready(conn, _params) do
      checks = %{
        database: check_db(),
        redis: check_redis(),
        storage: check_s3()
      }

      all_ok = Enum.all?(checks,
        fn {_, v} -> v == :ok end)

      if all_ok do
        json(conn, %{
          status: "ready", checks: checks
        })
      else
        conn
        |> put_status(503)
        |> json(%{
          status: "degraded", checks: checks
        })
      end
    end

    defp check_db do
      case MyApp.Repo.query("SELECT 1") do
        {:ok, _} -> :ok
        _ -> :error
      end
    rescue
      _ -> :error
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete telemetry setup:

    # 1. lib/my_app/telemetry.ex:
    defmodule MyApp.Telemetry do
      use Supervisor
      import Telemetry.Metrics

      def start_link(arg) do
        Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
      end

      def init(_arg) do
        children = [
          {:telemetry_poller,
           measurements: [
             {MyApp.Telemetry, :measure_memory, []}
           ],
           period: 30_000}
        ]
        Supervisor.init(children, strategy: :one_for_one)
      end

      def measure_memory do
        :telemetry.execute([:vm, :memory],
          :erlang.memory(), %{})
      end

      def metrics do
        [
          # Requests:
          counter("phoenix.router_dispatch.stop.duration",
            tags: [:route]),
          summary("phoenix.router_dispatch.stop.duration",
            tags: [:route],
            unit: {:native, :millisecond}),

          # LiveView:
          counter("phoenix.live_view.mount.stop.duration"),
          summary(
            "phoenix.live_view.handle_event.stop.duration",
            unit: {:native, :millisecond}),

          # Database:
          summary("my_app.repo.query.total_time",
            unit: {:native, :millisecond}),
          counter("my_app.repo.query.count"),

          # Business events:
          counter("my_app.orders.placed.count"),

          # System:
          last_value("vm.memory.total",
            unit: {:byte, :megabyte}),
          last_value("vm.total_run_queue_lengths.total")
        ]
      end
    end

    # 2. Emit custom events in contexts:
    defmodule MyApp.Orders do
      def place_order(user, params) do
        :telemetry.span(
          [:my_app, :orders, :placed],
          %{user_id: user.id},
          fn ->
            {:ok, order} = do_place_order(user, params)
            {{:ok, order}, %{
              order_id: order.id,
              amount: order.total_cents
            }}
          end
        )
      end
    end

    # 3. Application supervisor includes Telemetry:
    children = [
      MyApp.Repo,
      MyApp.Telemetry,   # <-- telemetry supervisor
      MyAppWeb.Endpoint
    ]\
    """
    |> String.trim()
  end
end
