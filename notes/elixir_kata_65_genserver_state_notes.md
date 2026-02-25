# Kata 65: GenServer State

## The Concept

A GenServer's state is the value returned by `init/1` and threaded through every callback. It can be any Elixir term — an integer, a map, a struct, or even a tuple. Choosing the right state shape and knowing how to find and inspect processes are key skills.

## State Patterns

### Map State (Most Common)

```elixir
def init(opts) do
  {:ok, %{
    count: 0,
    users: [],
    config: opts,
    started_at: DateTime.utc_now()
  }}
end

def handle_call(:get_count, _from, state) do
  {:reply, state.count, state}
end

def handle_cast({:add_user, user}, state) do
  {:noreply, %{state | users: [user | state.users]}}
end
```

Maps are the go-to choice. They're flexible, support pattern matching in function heads, and make it easy to add new fields.

### Struct State (Production Best Practice)

```elixir
defmodule UserCache do
  use GenServer

  defstruct [:name, users: %{}, hit_count: 0, miss_count: 0]

  def init(name) do
    {:ok, %__MODULE__{name: name}}
  end

  def handle_call({:lookup, id}, _from, %__MODULE__{} = state) do
    case Map.fetch(state.users, id) do
      {:ok, user} ->
        {:reply, {:ok, user}, %{state | hit_count: state.hit_count + 1}}
      :error ->
        {:reply, :not_found, %{state | miss_count: state.miss_count + 1}}
    end
  end
end
```

Structs enforce that only declared keys exist. Typos in key names cause compile-time errors, not runtime bugs.

### Simple Value State

```elixir
# State is just an integer
def init(count), do: {:ok, count}
def handle_call(:get, _from, count), do: {:reply, count, count}
def handle_cast(:inc, count), do: {:noreply, count + 1}
```

Good for single-purpose servers. However, as requirements grow, you'll likely need to refactor to a map or struct.

## Named Processes

Instead of passing PIDs around, you can register a GenServer with a name.

### Atom Names (Singletons)

```elixir
# Start with a name
GenServer.start_link(Counter, 0, name: Counter)

# Call using the name instead of PID
GenServer.call(Counter, :get_count)
```

Atom names are simple but limited to one instance per name per node. Good for application-wide singletons like a config server or cache.

### Via Tuples with Registry (Dynamic)

For many named instances (e.g., one server per user, per room, per game):

```elixir
# 1. Start a Registry in your supervision tree
children = [
  {Registry, keys: :unique, name: MyApp.Registry},
  # ... other children
]

# 2. Register on start
def start_link(user_id) do
  GenServer.start_link(__MODULE__, user_id,
    name: {:via, Registry, {MyApp.Registry, user_id}})
end

# 3. Look up by key
def get_data(user_id) do
  GenServer.call({:via, Registry, {MyApp.Registry, user_id}}, :get)
end
```

### Registry Features

- **Unique keys**: Only one process per key (use `keys: :unique`)
- **Duplicate keys**: Multiple processes per key for pub/sub (use `keys: :duplicate`)
- **Metadata**: Attach metadata to registrations
- **Lookup**: `Registry.lookup/2` returns `[{pid, value}]`

```elixir
# List all registered processes
Registry.select(MyApp.Registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
```

## Complex State Management

### Nested Updates

```elixir
# Updating nested state with put_in/update_in
state = %{users: %{"alice" => %{score: 10}}}

# Update Alice's score
new_state = update_in(state, [:users, "alice", :score], &(&1 + 5))
# => %{users: %{"alice" => %{score: 15}}}
```

### State Boundaries

Keep state minimal. If data is shared or persistent, consider:

- **ETS** for shared read-heavy data
- **Database** for persistent data
- **Agent** for simple state without complex message handling

```elixir
# State should contain only what the GenServer NEEDS for message processing
# BAD: Storing entire database tables in state
# GOOD: Storing cache, counters, connection info, config
```

## State Inspection

### Development Tools

```elixir
# Get raw state (debugging only!)
:sys.get_state(pid)

# Get detailed status
:sys.get_status(pid)

# Process info
Process.info(pid, :message_queue_len)
Process.info(pid, :memory)
Process.info(pid, :current_function)
```

### Production-Safe Inspection

```elixir
# Always expose state through the GenServer API
def handle_call(:get_stats, _from, state) do
  stats = %{
    user_count: map_size(state.users),
    uptime: DateTime.diff(DateTime.utc_now(), state.started_at),
    mailbox: Process.info(self(), :message_queue_len) |> elem(1)
  }
  {:reply, stats, state}
end
```

### Observer

In IEx, start Observer for a visual tool:

```elixir
:observer.start()
```

Observer shows all processes, their state, message queues, and supervision trees.

## Common Pitfalls

1. **Huge state**: GenServer state lives in process heap memory. Large state (millions of items) causes GC pauses. Use ETS for large datasets.
2. **Leaking state**: Forgetting to clean up entries (e.g., removing disconnected users) causes memory leaks.
3. **Name collisions**: Two processes with the same atom name causes a crash. Use Registry for dynamic naming.
4. **Not using structs**: Plain maps with typos in keys silently return `nil`. Structs catch this at compile time.
5. **Exposing raw state**: Using `:sys.get_state/1` in production bypasses the message queue and can block the process.
