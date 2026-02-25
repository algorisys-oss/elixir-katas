# Kata 67: Supervisor Basics

## The Concept

Supervisors are the backbone of fault-tolerant Elixir applications. A supervisor is a process whose sole job is to monitor child processes and restart them when they crash. This is the foundation of the "let it crash" philosophy: instead of writing defensive error-handling code, let processes crash and rely on supervisors to recover.

## Starting a Supervisor

```elixir
children = [
  {Counter, 0},
  {Cache, name: :my_cache},
  {Poller, interval: 5000}
]

{:ok, sup_pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Each item in the children list is passed to the module's `child_spec/1` function to produce a full child specification.

## Restart Strategies

The strategy determines what happens when a child crashes.

### :one_for_one

Only the crashed child is restarted. Other children continue running.

```elixir
Supervisor.start_link(children, strategy: :one_for_one)
```

```
Before crash:  [A: running] [B: running] [C: running] [D: running]
B crashes:     [A: running] [B: crashed ] [C: running] [D: running]
After restart: [A: running] [B: running] [C: running] [D: running]
```

**Use when**: Children are independent. One crashing doesn't affect the others. This is the most common strategy.

### :one_for_all

If any child crashes, ALL children are terminated and restarted.

```elixir
Supervisor.start_link(children, strategy: :one_for_all)
```

```
Before crash:  [A: running] [B: running] [C: running] [D: running]
B crashes:     [A: stopped] [B: crashed ] [C: stopped] [D: stopped]
After restart: [A: running] [B: running] [C: running] [D: running]
```

**Use when**: Children are tightly coupled. If one fails, the others' state is invalid or inconsistent. Example: a database connection and its connection pool.

### :rest_for_one

If a child crashes, that child and all children started **after** it are terminated and restarted. Children started before it are unaffected.

```elixir
Supervisor.start_link(children, strategy: :rest_for_one)
```

```
Before crash:  [A: running] [B: running] [C: running] [D: running]
B crashes:     [A: running] [B: crashed ] [C: stopped] [D: stopped]
After restart: [A: running] [B: running] [C: running] [D: running]
```

**Use when**: Children have ordered dependencies. Later children depend on earlier ones. Example: Config server -> Cache (depends on config) -> API client (depends on cache).

## Child Specification

A child spec is a map that tells the supervisor everything about a child process:

```elixir
%{
  id: MyWorker,                              # unique identifier
  start: {MyWorker, :start_link, [arg]},     # {Module, Function, Args}
  restart: :permanent,                        # when to restart
  shutdown: 5000,                             # graceful shutdown timeout (ms)
  type: :worker                               # :worker or :supervisor
}
```

### Automatic child_spec

When you `use GenServer`, a `child_spec/1` function is automatically defined:

```elixir
defmodule MyWorker do
  use GenServer  # auto-generates child_spec/1

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end
end

# These are equivalent:
Supervisor.start_link([{MyWorker, arg}], ...)
Supervisor.start_link([MyWorker.child_spec(arg)], ...)
```

### Customizing child_spec

```elixir
# Override restart strategy
defmodule MyWorker do
  use GenServer, restart: :transient
end

# Or override child_spec/1 directly
def child_spec(arg) do
  %{
    id: __MODULE__,
    start: {__MODULE__, :start_link, [arg]},
    restart: :transient,
    shutdown: 10_000
  }
end
```

### Restart Values

| Value | Restart when... | Use for |
|-------|----------------|---------|
| `:permanent` | Always (default) | Long-running servers, anything that should always be up |
| `:transient` | Only on abnormal exit (crash) | Tasks that should complete; normal exit is fine |
| `:temporary` | Never | One-off tasks, fire-and-forget |

"Normal exit" means the process exits with reason `:normal` or `:shutdown`. "Abnormal exit" is any other reason.

## max_restarts and max_seconds

Supervisors have built-in circuit breakers to prevent infinite restart loops:

```elixir
Supervisor.start_link(children,
  strategy: :one_for_one,
  max_restarts: 3,    # default: 3
  max_seconds: 5      # default: 5
)
```

If a child crashes more than `max_restarts` times within `max_seconds` seconds, the **supervisor itself terminates**. This escalates the failure to the supervisor's parent.

### Why Limit Restarts?

If a child keeps crashing (bad config, missing dependency, corrupted state), restarting it forever:
- Wastes CPU cycles
- Fills logs with crash reports
- Hides the real problem

By terminating, the supervisor signals to its parent that something is fundamentally wrong, allowing a broader recovery strategy.

## Supervision Trees

Supervisors can supervise other supervisors, forming a tree:

```
Application Supervisor
├── Web Supervisor
│   ├── Endpoint
│   └── PubSub
├── Worker Supervisor
│   ├── Cache
│   ├── Mailer
│   └── Scheduler
└── Repo (Ecto)
```

Each level in the tree can have its own strategy and restart limits. Failures bubble up the tree until a supervisor can handle them.

### Application Supervisor

Every OTP application has a top-level supervisor defined in `application.ex`:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Child Start Order

Children start in the order listed and stop in reverse order:

```elixir
children = [
  Database,    # starts 1st, stops last
  Cache,       # starts 2nd, stops 2nd
  WebServer    # starts 3rd, stops first
]
```

This matters for `:rest_for_one` — put dependencies first so they start before their dependents.

## Common Pitfalls

1. **Wrong strategy**: Using `:one_for_one` when children depend on each other. A restarted child may try to use a stale reference to another child.
2. **Forgetting start_link**: The `start` function in child_spec must return `{:ok, pid}`. If your GenServer doesn't implement `start_link`, the supervisor can't start it.
3. **Duplicate ids**: Two children with the same `id` causes a startup error. Use unique ids if supervising multiple instances of the same module.
4. **Ignoring max_restarts**: The default (3 in 5 seconds) may be too aggressive or too lenient for your use case. Tune based on expected failure patterns.
5. **Not using supervisors at all**: Running GenServers without supervision means a single crash permanently loses that server. Always supervise production processes.
