# Kata 82: Debugging Tools

## The Concept

Elixir provides a rich toolkit for debugging, from the simple `IO.inspect/2` to the powerful `dbg` macro (Elixir 1.14+), IEx helpers, Logger, and OTP process introspection. Knowing which tool to reach for in different situations is key to efficient debugging.

## IO.inspect/2

The workhorse of Elixir debugging. `IO.inspect/2` prints a value and **returns it unchanged**, making it safe to insert anywhere in a pipeline.

```elixir
# Basic usage
IO.inspect([1, 2, 3])
# Prints: [1, 2, 3]
# Returns: [1, 2, 3]

# In a pipeline (transparent -- doesn't change the value)
[1, 2, 3]
|> Enum.map(& &1 * 2)
|> IO.inspect(label: "after map")
|> Enum.sum()
|> IO.inspect(label: "final sum")

# Output:
# after map: [2, 4, 6]
# final sum: 12
```

### Useful Options

| Option | Description | Example |
|--------|-------------|---------|
| `:label` | Prefix label for output | `IO.inspect(x, label: "here")` |
| `:pretty` | Multi-line formatting | `IO.inspect(x, pretty: true)` |
| `:limit` | Max entries to print | `IO.inspect(x, limit: 5)` |
| `:width` | Max line width | `IO.inspect(x, width: 40)` |
| `:charlists` | How to display charlists | `IO.inspect(x, charlists: :as_lists)` |
| `:structs` | Show struct internals | `IO.inspect(x, structs: false)` |

### Charlist Gotcha

```elixir
IO.inspect([72, 101, 108, 108, 111])
# => ~c"Hello"  (interpreted as charlist!)

IO.inspect([72, 101, 108, 108, 111], charlists: :as_lists)
# => [72, 101, 108, 108, 111]
```

## dbg/2 (Elixir 1.14+)

`dbg` is a macro that shows the source expression, file location, and result. In pipelines, it shows each step.

```elixir
# Simple expression
dbg(1 + 2)
# [my_file.ex:1: (file)]
# 1 + 2 #=> 3

# Pipeline -- shows EACH step
[1, 2, 3, 4, 5]
|> Enum.filter(&rem(&1, 2) == 0)
|> Enum.map(& &1 * 10)
|> dbg()

# [my_file.ex:4: (file)]
# [1, 2, 3, 4, 5] #=> [1, 2, 3, 4, 5]
# |> Enum.filter(&rem(&1, 2) == 0) #=> [2, 4]
# |> Enum.map(& &1 * 10) #=> [20, 40]
```

### dbg vs IO.inspect

| Feature | IO.inspect | dbg |
|---------|-----------|-----|
| Shows source expression | No | Yes |
| Shows file/line | No | Yes |
| Pipeline step-by-step | No | Yes |
| Available since | Always | Elixir 1.14 |
| Works in production | Yes | Yes (but usually removed) |
| Configurable backend | No | Yes (`Macro.dbg/3`) |

## IEx Helpers

IEx provides many built-in helpers for interactive debugging:

### Documentation & Inspection

```elixir
h Enum.map          # View documentation
h Enum.map/2        # Specific arity
i "hello"           # Detailed type info
t Enum              # Type specs
b GenServer         # Behaviour callbacks
exports(Enum)       # All exported functions
```

### History & Evaluation

```elixir
v()                 # Last result
v(3)                # Result from line 3
```

### Compilation

```elixir
recompile()         # Recompile entire project
r MyModule          # Recompile specific module
c "path/to/file.ex" # Compile a file
```

### Debugging

```elixir
break!(MyModule, :my_fun, 2)  # Set breakpoint
break!(MyModule.my_fun/2)     # Alternative syntax
continues()                    # List breakpoints
```

### System Info

```elixir
runtime_info()      # System and runtime information
```

## Logger

Logger provides structured, leveled logging with compile-time filtering.

```elixir
require Logger

Logger.debug("Detailed diagnostic info")
Logger.info("General operational message")
Logger.warning("Something unexpected happened")
Logger.error("Something failed, needs attention")
```

### Log Levels (lowest to highest)

```
:debug < :info < :warning < :error
```

Messages below the configured level are discarded **at compile time**, meaning zero runtime cost.

### Configuration

```elixir
# In config/config.exs
config :logger, level: :info

# At runtime
Logger.configure(level: :debug)
```

### Metadata

```elixir
Logger.metadata(user_id: "alice", request_id: "abc123")
Logger.info("Processing request")
# 10:30:00.123 request_id=abc123 user_id=alice [info] Processing request
```

### Best Practices

- Use `:debug` for development-only diagnostics
- Use `:info` for normal operational messages
- Use `:warning` for unexpected but non-fatal situations
- Use `:error` for failures requiring attention
- Use metadata for structured context (user IDs, request IDs)
- Set level to `:info` or `:warning` in production

## Process Debugging

### Process.info/2

```elixir
pid = self()

# Single key
Process.info(pid, :message_queue_len)
# => {:message_queue_len, 0}

# Multiple keys
Process.info(pid, [:status, :memory, :current_function, :message_queue_len])
# => [status: :running, memory: 2688,
#     current_function: {:erl_eval, :do_apply, 7},
#     message_queue_len: 0]
```

Useful keys: `:message_queue_len`, `:status`, `:memory`, `:current_function`, `:dictionary`, `:links`, `:monitors`, `:registered_name`, `:heap_size`, `:stack_size`, `:reductions`.

### :sys Module (for OTP Processes)

```elixir
# Get internal state of a GenServer/Agent
:sys.get_state(MyGenServer)
# => %{count: 42, users: ["alice", "bob"]}

# Get comprehensive status
:sys.get_status(MyGenServer)
# => {:status, #PID<0.123.0>, {:module, :gen_server}, [...]}

# Enable message tracing
:sys.trace(MyGenServer, true)
# *DBG* my_server got call get_count from <0.150.0>
# *DBG* my_server sent 42 to <0.150.0>

# Disable tracing
:sys.trace(MyGenServer, false)
```

### :observer

```elixir
# Start the GUI observer (in IEx)
:observer.start()
```

Observer provides:
- System overview (CPU, memory, IO)
- Process list with sorting by memory, reductions, message queue
- Process details (state, links, monitors)
- Supervision tree visualization
- ETS table browser
- Application tree view

## Debugging Patterns

### Pattern 1: Pipeline Debugging

```elixir
data
|> step_one()
|> IO.inspect(label: "after step 1")
|> step_two()
|> IO.inspect(label: "after step 2")
|> step_three()
```

### Pattern 2: Conditional Inspect

```elixir
# Only inspect when a condition is met
value
|> then(fn v ->
  if some_condition?, do: IO.inspect(v, label: "debug")
  v
end)
```

### Pattern 3: Tap for Side Effects

```elixir
# Elixir 1.12+
value
|> tap(&IO.inspect(&1, label: "peeking"))
|> next_step()
```

### Pattern 4: Process Mailbox Check

```elixir
# Check if a process has a growing mailbox (potential bottleneck)
{:message_queue_len, len} = Process.info(pid, :message_queue_len)
if len > 1000, do: Logger.warning("Mailbox growing: #{len} messages")
```

### Pattern 5: GenServer State Inspection

```elixir
# In IEx, inspect any named GenServer:
:sys.get_state(MyApp.Cache)
:sys.get_status(MyApp.Worker)
:sys.trace(MyApp.Worker, true)  # Watch all messages
```

## Common Pitfalls

1. **Leaving IO.inspect in production code**: Use Logger instead for production logging. IO.inspect is for development debugging only.
2. **Not using labels**: Without labels, multiple IO.inspect calls produce confusing output. Always use the `:label` option.
3. **Forgetting IO.inspect returns its argument**: This is a feature, not a bug. It means you can insert it anywhere without changing behavior.
4. **Using puts instead of inspect**: `IO.puts` converts to string, losing structure. `IO.inspect` preserves the Elixir data representation.
5. **Ignoring :observer**: The observer GUI is incredibly powerful for understanding system behavior, process trees, and memory usage. Use it!
