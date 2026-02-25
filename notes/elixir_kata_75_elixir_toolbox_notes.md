# Kata 75: The Elixir Toolbox

## The Concept

Knowing which tool to use for a given problem is just as important as knowing how each tool works. This kata provides a decision framework for choosing between Elixir's data structures, process types, and concurrency primitives.

## Data Structure Decision Tree

### Map vs Keyword List vs Struct

```
Do you need key-value pairs?
├── Yes
│   ├── Are keys known at compile time and fixed?
│   │   ├── Yes → Struct
│   │   └── No → Are keys always atoms?
│   │       ├── Yes → Need ordering/duplicates?
│   │       │   ├── Yes → Keyword List
│   │       │   └── No → Map
│   │       └── No → Map
│   └──
└── No
    ├── Fixed-size positional data? → Tuple
    └── Variable-length sequence? → List
```

### Quick Comparison

| Feature | Map | Keyword List | Struct |
|---------|-----|-------------|--------|
| Key types | Any | Atoms only | Atoms (fixed) |
| Duplicate keys | No | Yes | No |
| Ordered | No | Yes | No |
| Default values | No | No | Yes |
| Compile-time validation | No | No | Yes |
| Pattern matching | Partial | Full | Partial |
| Best for | General data | Function options | Typed domain data |

## Process Type Decision Tree

### GenServer vs Agent vs Task vs ETS

```
What kind of work?
├── One-off computation → Task
├── Long-running with state
│   ├── Simple get/update only → Agent
│   ├── Complex logic, message handling → GenServer
│   └── Read-heavy shared cache → ETS
└── Fire-and-forget → spawn or Task.start
```

### Quick Comparison

| Feature | Task | Agent | GenServer | ETS |
|---------|------|-------|-----------|-----|
| Lifetime | Short | Long | Long | Owner-bound |
| State | No | Simple | Complex | Key-value table |
| Concurrent reads | N/A | No (sequential) | No (sequential) | Yes (lock-free) |
| Custom messages | No | No | Yes | N/A |
| Supervision | Task.Supervisor | Supervisor | Supervisor | N/A |
| Use case | Async work | Shared state | Services | Caches |

## Supervisor Decision Tree

```
Are children known at startup?
├── Yes → Supervisor
│   ├── Children independent? → :one_for_one
│   ├── Later children depend on earlier? → :rest_for_one
│   └── All children interdependent? → :one_for_all
└── No → DynamicSupervisor (workers come and go)
```

## Common Scenarios

### Scenario 1: User Session State
**Need**: Track per-user state, users come and go
**Solution**: DynamicSupervisor + Registry + GenServer
```elixir
# DynamicSupervisor starts/stops sessions
# Registry provides lookup by user_id
# GenServer holds the session state
```

### Scenario 2: Application Cache
**Need**: Shared data, read by many processes, updated infrequently
**Solution**: ETS table
```elixir
# ETS provides concurrent reads without bottleneck
# A GenServer can own the table and handle updates
```

### Scenario 3: Background Job Processing
**Need**: Run tasks concurrently, handle failures
**Solution**: Task.Supervisor + Task.async
```elixir
# Task.Supervisor supervises short-lived tasks
# Task.async/await for results
# Task.start for fire-and-forget
```

### Scenario 4: Function Options
**Need**: Pass named options to a function
**Solution**: Keyword List
```elixir
def query(table, opts \\ []) do
  limit = Keyword.get(opts, :limit, 100)
  offset = Keyword.get(opts, :offset, 0)
  # ...
end
```

### Scenario 5: Domain Model
**Need**: Represent a user with known fields
**Solution**: Struct
```elixir
defmodule User do
  defstruct [:id, :name, :email, role: :user, active: true]
end
```

### Scenario 6: Process Naming
**Need**: Find a process by a business identifier
**Solution**: Registry with via tuples
```elixir
{:via, Registry, {MyRegistry, "room:#{room_id}"}}
```

## Anti-Patterns

| Problem | Wrong Tool | Right Tool |
|---------|-----------|------------|
| Shared cache | GenServer (bottleneck) | ETS |
| One-off work | GenServer (overkill) | Task |
| Simple state | GenServer (complex) | Agent |
| Fixed options | Map (no structure) | Struct |
| Dynamic workers | Supervisor (static) | DynamicSupervisor |
| Process naming | Global atom registry | Registry |

## Functions vs Macros

```
Can a function solve this?
├── Yes → Use a function!
└── No
    ├── Need compile-time code generation? → Macro
    ├── Need to transform code structure? → Macro
    └── Need caller's context? → Macro
```

**Rule of thumb**: Always try a function first. Macros add compile-time complexity, are harder to debug, and should only be used when runtime solutions are insufficient.
