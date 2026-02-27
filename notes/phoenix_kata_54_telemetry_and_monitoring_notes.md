# Kata 54: Telemetry & Monitoring

## What is Telemetry?

Telemetry is the standard observability library for the BEAM ecosystem. Libraries emit **structured events** (named lists of atoms) with measurements and metadata. Your application attaches **handlers** to process those events -- logging, metrics aggregation, alerting, etc.

```elixir
# Event name: a list of atoms
[:phoenix, :router_dispatch, :stop]

# Measurements: numeric values to track
%{duration: 45_000_000}  # nanoseconds

# Metadata: context about the event
%{conn: conn, route: "/users/:id"}
```

---

## Telemetry Events

Libraries emit events automatically:

```elixir
# Phoenix HTTP events:
[:phoenix, :endpoint, :start]
[:phoenix, :endpoint, :stop]
[:phoenix, :router_dispatch, :start]
[:phoenix, :router_dispatch, :stop]
[:phoenix, :router_dispatch, :exception]

# Phoenix LiveView events:
[:phoenix, :live_view, :mount, :start]
[:phoenix, :live_view, :mount, :stop]
[:phoenix, :live_view, :handle_event, :start]
[:phoenix, :live_view, :handle_event, :stop]
[:phoenix, :live_view, :handle_event, :exception]

# Ecto events (prefix matches your app name):
[:my_app, :repo, :query]

# BEAM VM events (via :telemetry_poller):
[:vm, :memory]
[:vm, :total_run_queue_lengths]
[:vm, :system_counts]
```

---

## Attaching Handlers

```elixir
# Attach a single handler:
:telemetry.attach(
  "log-slow-queries",                    # unique handler ID
  [:my_app, :repo, :query],             # event name
  &MyApp.Telemetry.handle_slow_query/4, # callback function
  %{threshold_ms: 100}                  # handler config
)

# Attach to multiple events at once:
:telemetry.attach_many(
  "my-handler",
  [
    [:phoenix, :router_dispatch, :stop],
    [:phoenix, :router_dispatch, :exception],
    [:my_app, :repo, :query]
  ],
  &MyApp.Telemetry.handle_event/4,
  %{}
)

# Handler callback signature:
def handle_event(event_name, measurements, metadata, config) do
  # event_name:   [:my_app, :repo, :query]
  # measurements: %{total_time: 45_000_000, ...}
  # metadata:     %{query: "SELECT ...", repo: MyApp.Repo}
  # config:       %{threshold_ms: 100}
  :ok
end
```

---

## Emitting Custom Events

```elixir
# :telemetry.execute/3 -- emit a single event:
:telemetry.execute(
  [:my_app, :orders, :placed],    # event name
  %{amount_cents: 2999},           # measurements (numeric)
  %{order_id: 42, user_id: 7}    # metadata (any term)
)

# :telemetry.span/3 -- emit start + stop + exception:
:telemetry.span(
  [:my_app, :payment, :process],
  %{payment_id: payment.id},
  fn ->
    result = PaymentGateway.charge(payment)
    {result, %{gateway: "stripe"}}
  end
)
# Emits: [:my_app, :payment, :process, :start]
#        [:my_app, :payment, :process, :stop]   (with duration)
# On error: [:my_app, :payment, :process, :exception]
```

---

## Telemetry.Metrics

`Telemetry.Metrics` defines **what** to measure. Reporters (Prometheus, StatsD, LiveDashboard) decide **how** to report it.

```elixir
import Telemetry.Metrics

# counter -- how many times something happened:
counter("phoenix.router_dispatch.stop.duration")

# sum -- running total of a measurement:
sum("my_app.orders.placed.amount_cents")

# last_value -- most recent measurement (gauge):
last_value("vm.memory.total", unit: {:byte, :megabyte})

# summary -- percentile stats (p50, p95, p99):
summary("phoenix.router_dispatch.stop.duration",
  unit: {:native, :millisecond})

# distribution -- histogram with buckets:
distribution("phoenix.router_dispatch.stop.duration",
  unit: {:native, :millisecond},
  buckets: [10, 50, 100, 250, 500, 1000])
```

### Metric Types

| Type | Description | Example |
|------|-------------|---------|
| `counter` | How many times | Request count |
| `sum` | Total of measurement | Total revenue |
| `last_value` | Most recent value | Current memory |
| `summary` | Stats (mean, percentiles) | Request latency |
| `distribution` | Histogram buckets | Latency distribution |

---

## The Telemetry Supervisor

Phoenix generates `lib/my_app/telemetry.ex`:

```elixir
defmodule MyApp.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      # Periodic measurements (polls system stats):
      {:telemetry_poller,
        measurements: periodic_measurements(),
        period: 10_000}  # every 10 seconds

      # Add a reporter for production:
      # {TelemetryMetricsPrometheus, metrics: metrics()}
      # {TelemetryMetricsStatsd, metrics: metrics()}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # HTTP:
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond}),

      # LiveView:
      summary("phoenix.live_view.mount.stop.duration",
        unit: {:native, :millisecond}),

      # Ecto:
      summary("my_app.repo.query.total_time",
        unit: {:native, :millisecond}),
      counter("my_app.repo.query.count"),

      # VM:
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),

      # Custom:
      counter("my_app.orders.placed.count"),
      summary("my_app.orders.placed.amount_cents")
    ]
  end

  defp periodic_measurements do
    [{MyApp.Telemetry, :dispatch_vm_stats, []}]
  end

  def dispatch_vm_stats do
    :telemetry.execute([:vm, :memory], :erlang.memory(), %{})
    :telemetry.execute(
      [:vm, :total_run_queue_lengths],
      %{total: :erlang.statistics(:total_run_queue_lengths)},
      %{}
    )
  end
end
```

Add it to your application supervisor:

```elixir
children = [
  MyApp.Repo,
  MyApp.Telemetry,      # telemetry supervisor
  MyAppWeb.Endpoint
]
```

---

## Phoenix.LiveDashboard

LiveDashboard provides a real-time web UI for observability:

```elixir
# In router.ex:
import Phoenix.LiveDashboard.Router

scope "/" do
  pipe_through :browser

  live_dashboard "/dashboard",
    metrics: MyApp.Telemetry
end

# Visit http://localhost:4000/dashboard
```

### Dashboard Features

- **Home**: system info, memory, atoms, ports, processes
- **OS Data**: CPU, memory, disk I/O
- **Metrics**: real-time charts for your `Telemetry.Metrics`
- **Request Logger**: stream live request logs
- **Applications**: supervision tree browser
- **Processes**: inspect any running process
- **ETS**: browse ETS tables
- **Sockets**: active TCP connections

### Dependencies

```elixir
# mix.exs:
{:phoenix_live_dashboard, "~> 0.8"},
{:telemetry_metrics, "~> 1.0"},
{:telemetry_poller, "~> 1.0"}
```

### Production Security

```elixir
# Never expose the dashboard publicly!

# Option 1: Admin-only pipeline:
scope "/" do
  pipe_through [:browser, :require_admin]
  live_dashboard "/dashboard", metrics: MyApp.Telemetry
end

# Option 2: Dev-only (default Phoenix setup):
if Application.compile_env(:my_app, :dev_routes) do
  scope "/dev" do
    pipe_through :browser
    live_dashboard "/dashboard", metrics: MyApp.Telemetry
  end
end
```

---

## Health Checks

Health check endpoints for load balancers and container orchestrators:

```elixir
defmodule MyAppWeb.HealthController do
  use MyAppWeb, :controller

  # GET /health -- liveness probe (is the process alive?):
  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end

  # GET /health/ready -- readiness probe (can it serve traffic?):
  def ready(conn, _params) do
    case check_db() do
      :ok ->
        json(conn, %{status: "ready", db: "connected"})
      {:error, reason} ->
        conn
        |> put_status(503)
        |> json(%{status: "not_ready", db: reason})
    end
  end

  defp check_db do
    MyApp.Repo.query("SELECT 1")
    :ok
  rescue
    e -> {:error, Exception.message(e)}
  end
end
```

### Router Setup

```elixir
# In router (before auth pipelines):
scope "/" do
  get "/health", HealthController, :index
  get "/health/ready", HealthController, :ready
end
```

### Docker / Kubernetes Health Checks

```dockerfile
# Docker HEALTHCHECK:
HEALTHCHECK --interval=30s --timeout=10s \
  CMD wget -qO- http://localhost:4000/health || exit 1
```

```yaml
# Kubernetes:
livenessProbe:
  httpGet:
    path: /health
    port: 4000
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 4000
  initialDelaySeconds: 10
  periodSeconds: 5
```

---

## Checking Multiple External Services

```elixir
def ready(conn, _params) do
  checks = %{
    database: check_db(),
    redis: check_redis(),
    storage: check_s3()
  }

  if Enum.all?(checks, fn {_, v} -> v == :ok end) do
    json(conn, %{status: "ready", checks: checks})
  else
    conn
    |> put_status(503)
    |> json(%{status: "degraded", checks: checks})
  end
end

defp check_db do
  case MyApp.Repo.query("SELECT 1") do
    {:ok, _} -> :ok
    _ -> :error
  end
rescue
  _ -> :error
end
```

---

## Reporters (Sending Metrics Externally)

```elixir
# Prometheus (pull-based):
# mix.exs: {:telemetry_metrics_prometheus, "~> 1.1"}
children = [
  {TelemetryMetricsPrometheus,
    metrics: MyApp.Telemetry.metrics(),
    port: 9568}
]
# Exposes /metrics endpoint for Prometheus to scrape

# StatsD (push-based):
# mix.exs: {:telemetry_metrics_statsd, "~> 0.7"}
children = [
  {TelemetryMetricsStatsd,
    metrics: MyApp.Telemetry.metrics(),
    host: "statsd.example.com",
    port: 8125}
]
```

---

## Emitting Custom Events in Contexts

```elixir
defmodule MyApp.Orders do
  def create_order(user, items) do
    start_time = System.monotonic_time()

    result = do_create_order(user, items)

    case result do
      {:ok, order} ->
        :telemetry.execute(
          [:my_app, :orders, :created],
          %{
            duration: System.monotonic_time() - start_time,
            amount: order.total_cents,
            item_count: length(items)
          },
          %{
            user_id: user.id,
            order_id: order.id,
            status: :success
          }
        )

      {:error, reason} ->
        :telemetry.execute(
          [:my_app, :orders, :failed],
          %{duration: System.monotonic_time() - start_time},
          %{user_id: user.id, reason: reason}
        )
    end

    result
  end
end
```

---

## Key Takeaways

1. **Telemetry events** are lists of atoms -- libraries emit them, you attach handlers
2. **`:telemetry.execute/3`** emits a single event; **`:telemetry.span/3`** emits start/stop/exception
3. **`Telemetry.Metrics`** defines what to measure: counter, sum, last_value, summary, distribution
4. **Phoenix.LiveDashboard** gives you free observability -- processes, memory, metrics, ETS
5. **Secure the dashboard** in production -- require admin auth, never expose publicly
6. **Health checks**: liveness (200 = alive), readiness (200 = can serve traffic, check DB)
7. **telemetry_poller** periodically measures VM stats (memory, run queues, process counts)
8. Use **reporters** (Prometheus, StatsD) to send metrics to external monitoring systems
9. Emit **custom business events** from contexts -- measure what matters to your business
