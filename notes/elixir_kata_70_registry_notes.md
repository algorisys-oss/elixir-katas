# Kata 70: Registry

## The Concept

**Registry** is a built-in Elixir module that provides a local, decentralized key-value process store. Instead of tracking processes by PID, you can register them under meaningful names and look them up later.

```elixir
# Start a Registry in your supervision tree
{Registry, keys: :unique, name: MyApp.Registry}
```

## Unique vs Duplicate Keys

### :unique
Each key maps to exactly one process. Duplicate registrations fail.

```elixir
Registry.start_link(keys: :unique, name: MyRegistry)

Registry.register(MyRegistry, "user:alice", %{role: :admin})
# => {:ok, _owner}

Registry.register(MyRegistry, "user:alice", %{role: :user})
# => {:error, {:already_registered, #PID<...>}}
```

### :duplicate
Multiple processes can register under the same key. Useful for pub/sub.

```elixir
Registry.start_link(keys: :duplicate, name: MyPubSub)

# Process A registers for "events"
Registry.register(MyPubSub, "events", [])
# Process B also registers for "events"
Registry.register(MyPubSub, "events", [])

# Dispatch to all registered under "events"
Registry.dispatch(MyPubSub, "events", fn entries ->
  for {pid, _value} <- entries do
    send(pid, {:event, :user_created})
  end
end)
```

## Via Tuples

The most powerful pattern -- use Registry to name GenServers:

```elixir
defmodule UserSession do
  use GenServer

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id, name: via(user_id))
  end

  def get_state(user_id) do
    GenServer.call(via(user_id), :get_state)
  end

  defp via(user_id) do
    {:via, Registry, {MyApp.Registry, "session:#{user_id}"}}
  end

  # GenServer callbacks...
end

# Start sessions
UserSession.start_link("alice")
UserSession.start_link("bob")

# Call by name
UserSession.get_state("alice")
```

## Core API

| Function | Description |
|----------|-------------|
| `Registry.register/3` | Register the calling process under a key |
| `Registry.lookup/2` | Find processes by key |
| `Registry.unregister/2` | Remove a registration |
| `Registry.keys/2` | Get all keys for a process |
| `Registry.dispatch/3` | Send to all processes under a key |
| `Registry.select/2` | Query with match specs |
| `Registry.count/1` | Count all registrations |
| `Registry.count_match/3` | Count matching registrations |

## Automatic Cleanup

When a registered process dies, its entries are **automatically removed** from the Registry. This is because Registry monitors registered processes.

```elixir
{:ok, pid} = Agent.start(fn -> :ok end)
Registry.register(MyRegistry, "temp", nil)

Process.exit(pid, :kill)
# Registry entry is automatically cleaned up
Registry.lookup(MyRegistry, "temp")
# => []
```

## Registry + DynamicSupervisor Pattern

A common pattern combines Registry (for lookup) with DynamicSupervisor (for lifecycle):

```elixir
# In application.ex
children = [
  {Registry, keys: :unique, name: MyApp.Registry},
  {DynamicSupervisor, name: MyApp.WorkerSup}
]

# Start a named worker
def start_worker(id) do
  DynamicSupervisor.start_child(
    MyApp.WorkerSup,
    {MyWorker, id}
  )
end

# Look up worker by name
def find_worker(id) do
  case Registry.lookup(MyApp.Registry, "worker:#{id}") do
    [{pid, _}] -> {:ok, pid}
    [] -> :not_found
  end
end
```

## Partitioned Registry

For high-throughput scenarios, partition the Registry:

```elixir
{Registry,
  keys: :unique,
  name: MyApp.Registry,
  partitions: System.schedulers_online()
}
```

## Common Pitfalls

1. **Registering from wrong process**: `Registry.register/3` registers the *calling* process. You can't register another process.
2. **Forgetting to start Registry**: It must be in your supervision tree before use.
3. **Using :unique when you need :duplicate**: If multiple subscribers need the same key, use `:duplicate`.
4. **Not using via tuples**: Manually tracking PIDs defeats the purpose of Registry.
