# Kata 69: Supervision Trees

## The Concept

A **supervision tree** is a hierarchical structure of supervisors and workers. Supervisors monitor their children and restart them according to a **strategy** when they crash. By nesting supervisors, you create **isolated failure domains** -- a crash in one subtree doesn't bring down the whole application.

```elixir
# A typical Phoenix application supervision tree
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,                           # Database
      {Phoenix.PubSub, name: MyApp.PubSub}, # PubSub
      MyAppWeb.Endpoint                     # Web server
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Supervision Strategies

### :one_for_one
If a child crashes, only that child is restarted.

```
Before:  A(ok)  B(crash)  C(ok)
After:   A(ok)  B(new)    C(ok)
```

### :one_for_all
If any child crashes, ALL children are terminated and restarted.

```
Before:  A(ok)  B(crash)  C(ok)
After:   A(new) B(new)    C(new)
```

### :rest_for_one
If a child crashes, that child and all children started AFTER it are restarted.

```
Before:  A(ok)  B(crash)  C(ok)
After:   A(ok)  B(new)    C(new)
```

## Nested Supervisors

Nesting supervisors creates isolation boundaries:

```elixir
children = [
  # Web-related services
  {Supervisor, [
    strategy: :one_for_one,
    children: [
      MyAppWeb.Endpoint,
      {Phoenix.PubSub, name: MyApp.PubSub}
    ]
  ]},
  # Data services
  {Supervisor, [
    strategy: :rest_for_one,
    children: [
      MyApp.Repo,
      MyApp.Cache  # Cache depends on Repo
    ]
  ]},
  # Background workers
  {DynamicSupervisor, name: MyApp.WorkerSup}
]
```

## Designing Supervision Trees

### 1. Group by Failure Domain
Processes that can fail independently should be under `:one_for_one`. Processes with shared state should be under `:one_for_all`.

### 2. Order Matters for :rest_for_one
Children are started in order. If Cache depends on Repo, Repo must come first:

```elixir
children = [
  MyApp.Repo,   # Started first
  MyApp.Cache   # Started second, depends on Repo
]
opts = [strategy: :rest_for_one]
```

### 3. Restart Options

```elixir
# In the child spec:
%{
  id: MyWorker,
  start: {MyWorker, :start_link, [arg]},
  restart: :permanent,    # Always restart (default)
  # restart: :temporary,  # Never restart
  # restart: :transient,  # Restart only on abnormal exit
  shutdown: 5000          # Timeout for graceful shutdown
}
```

### 4. Max Restarts

```elixir
Supervisor.start_link(children,
  strategy: :one_for_one,
  max_restarts: 3,    # Max 3 restarts...
  max_seconds: 5      # ...within 5 seconds
)
```

## Visualizing Your Tree

Use `:observer.start()` in IEx to see the live supervision tree:

```elixir
iex> :observer.start()
# Navigate to the "Applications" tab
```

## Common Patterns

| Pattern | Strategy | Use Case |
|---------|----------|----------|
| Independent workers | `:one_for_one` | Web endpoints, API handlers |
| Coupled processes | `:one_for_all` | Producer + Consumer pairs |
| Ordered dependencies | `:rest_for_one` | Database + Cache + API |
| On-demand workers | `DynamicSupervisor` | User sessions, game rooms |

## Common Pitfalls

1. **Flat tree**: Putting everything under one supervisor means one crash policy for all.
2. **Wrong strategy**: Using `:one_for_one` when children have dependencies leads to inconsistent state.
3. **Too many restarts**: Not setting `max_restarts` can cause restart loops that consume resources.
4. **Deep nesting**: Over-engineering the tree with too many levels adds complexity without benefit.
