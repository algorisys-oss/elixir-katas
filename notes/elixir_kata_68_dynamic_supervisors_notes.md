# Kata 68: Dynamic Supervisors

## The Concept

A **DynamicSupervisor** is a supervisor that starts with no children and allows you to add or remove child processes at runtime. Unlike a regular `Supervisor` where children are defined upfront, a `DynamicSupervisor` is designed for on-demand process management.

```elixir
# Start a DynamicSupervisor in your application supervision tree
children = [
  {DynamicSupervisor, name: MyApp.WorkerSupervisor, strategy: :one_for_one}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

## Starting Children Dynamically

Use `DynamicSupervisor.start_child/2` to add a worker at runtime:

```elixir
# Start a child process
{:ok, pid} = DynamicSupervisor.start_child(
  MyApp.WorkerSupervisor,
  {MyWorker, [id: 1, name: "worker_1"]}
)

# The child spec can also be a map
{:ok, pid} = DynamicSupervisor.start_child(
  MyApp.WorkerSupervisor,
  %{
    id: MyWorker,
    start: {MyWorker, :start_link, [arg]},
    restart: :transient
  }
)
```

## Terminating Children

Remove a specific child by its PID:

```elixir
:ok = DynamicSupervisor.terminate_child(MyApp.WorkerSupervisor, pid)
```

## Inspecting the Supervisor

```elixir
# List all children
DynamicSupervisor.which_children(MyApp.WorkerSupervisor)
# => [{:undefined, #PID<0.123.0>, :worker, [MyWorker]}, ...]

# Count children
DynamicSupervisor.count_children(MyApp.WorkerSupervisor)
# => %{active: 3, specs: 3, supervisors: 0, workers: 3}
```

## Strategy

DynamicSupervisor only supports `:one_for_one`. Each child is independent -- if one crashes, only that child is restarted. This makes sense because children are added independently at runtime.

## Defining the Worker Module

```elixir
defmodule MyWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:ok, %{id: opts[:id], data: nil}}
  end
end
```

## Common Use Cases

| Use Case | Why DynamicSupervisor? |
|----------|----------------------|
| User sessions | Users connect and disconnect dynamically |
| Game rooms | Rooms are created and destroyed on demand |
| File processors | Each file gets its own worker |
| WebSocket handlers | One process per connection |
| Background jobs | Jobs are enqueued and completed |

## DynamicSupervisor vs Supervisor

| Feature | Supervisor | DynamicSupervisor |
|---------|-----------|-------------------|
| Children defined at | Compile time | Runtime |
| Strategies | :one_for_one, :one_for_all, :rest_for_one | :one_for_one only |
| Adding children | Not typical | `start_child/2` |
| Removing children | Not typical | `terminate_child/2` |
| Use case | Fixed set of services | On-demand workers |

## Options

```elixir
DynamicSupervisor.start_link(
  name: MyApp.WorkerSupervisor,
  strategy: :one_for_one,
  max_children: 100,        # Limit number of children
  max_restarts: 3,          # Max restarts in time window
  max_seconds: 5            # Time window for max_restarts
)
```

## Common Pitfalls

1. **Forgetting to track PIDs**: Store the PID returned by `start_child/2` so you can terminate later.
2. **Not handling `{:error, ...}`**: `start_child/2` can fail -- always pattern match on the result.
3. **Unbounded children**: Use `max_children` to prevent resource exhaustion.
4. **Using the wrong supervisor type**: If children are known upfront, use a regular `Supervisor` instead.
