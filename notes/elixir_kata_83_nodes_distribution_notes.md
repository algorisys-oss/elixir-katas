# Kata 83: Nodes & Distribution

## The Concept

The BEAM VM has built-in support for **transparent distribution**. Processes on different machines can communicate using the same `send` and `receive` primitives as local processes. A cluster of connected BEAM nodes forms a distributed system where processes can be spawned, linked, and monitored across machine boundaries.

```elixir
# On node :alice@host1
Node.connect(:bob@host2)
# => true

# Send a message to a named process on bob
send({:my_server, :bob@host2}, {:hello, "from alice"})

# Execute a function on bob
:rpc.call(:bob@host2, String, :upcase, ["hello"])
# => "HELLO"
```

## Starting Distributed Nodes

### Short Names (--sname)

For nodes on the same machine or local network:

```bash
# Terminal 1
iex --sname alice

# Terminal 2
iex --sname bob
```

```elixir
# In alice's IEx:
Node.self()
# => :alice@hostname

Node.connect(:bob@hostname)
# => true

Node.list()
# => [:bob@hostname]
```

### Full Names (--name)

For nodes across different networks:

```bash
iex --name alice@192.168.1.10
iex --name bob@192.168.1.20
```

**Rule**: You cannot mix `--sname` and `--name` nodes. All nodes in a cluster must use the same naming scheme.

### With Mix Projects

```bash
iex --sname alice -S mix
```

## Cookie Authentication

The **cookie** is a shared secret (an atom) that nodes must match to connect. It is a simple authentication mechanism, NOT encryption.

```bash
# Set via command line
iex --sname alice --cookie my_secret

# Or set in ~/.erlang.cookie (auto-read on startup)
# File must have permissions 400
```

```elixir
# Check current cookie
Node.get_cookie()
# => :my_secret

# Set cookie at runtime (before connecting)
Node.set_cookie(:new_secret)
```

### Security Warning

Distributed Erlang traffic is **unencrypted by default**. The cookie only prevents unauthorized connections. For production systems, use TLS:

```elixir
# In vm.args or runtime config:
# -proto_dist inet_tls
# -ssl_dist_optfile /path/to/ssl.conf
```

## Node Functions

```elixir
Node.self()           # Current node name
Node.alive?()         # Are we a distributed node?
Node.list()           # Connected nodes (excludes self)
Node.list(:known)     # All known nodes (includes previously connected)
Node.connect(node)    # Connect to a node
Node.disconnect(node) # Disconnect from a node
Node.get_cookie()     # Get the distribution cookie
Node.set_cookie(cookie) # Set the distribution cookie
Node.ping(node)       # Check if a node is reachable (:pong or :pang)
Node.monitor(node, flag) # Monitor node up/down events
```

## Remote Communication

### :rpc.call/4 -- Remote Procedure Call

Execute a function on a remote node and wait for the result:

```elixir
:rpc.call(:bob@hostname, String, :upcase, ["hello"])
# => "HELLO"

# With timeout (default is :infinity)
:rpc.call(:bob@hostname, Enum, :sum, [[1, 2, 3]], 5000)
# => 6

# Non-blocking (returns immediately)
:rpc.cast(:bob@hostname, IO, :puts, ["fire and forget"])
# => true
```

### Node.spawn/2 and Node.spawn_link/2

Spawn processes on remote nodes:

```elixir
# Spawn without link
pid = Node.spawn(:bob@hostname, fn ->
  IO.puts("Running on #{Node.self()}")
end)
# => #PID<12345.200.0>

# Spawn with link (crash propagation)
pid = Node.spawn_link(:bob@hostname, fn ->
  Process.sleep(1000)
  raise "boom!"
end)
# Local process will also crash due to the link
```

### Sending Messages to Remote Processes

```elixir
# By registered name
send({:my_server, :bob@hostname}, {:hello, "from alice"})

# By PID (if you have the remote PID)
send(remote_pid, :ping)

# GenServer calls also work across nodes
GenServer.call({:my_server, :bob@hostname}, :get_state)
```

## Global Process Registration

### :global Module

Register a process under a name that is unique across the entire cluster:

```elixir
# Register globally
:global.register_name(:my_service, self())
# => :yes (success) or :no (name taken)

# Look up from any node
pid = :global.whereis_name(:my_service)
# => #PID<12345.200.0> or :undefined

# Unregister
:global.unregister_name(:my_service)

# Use with GenServer via tuples
GenServer.start_link(MyServer, arg,
  name: {:global, :my_service}
)
GenServer.call({:global, :my_service}, :get_state)
```

### :pg Module (Process Groups)

Process groups allow multiple processes (possibly on different nodes) to join a named group:

```elixir
# Start pg (usually in supervision tree)
:pg.start_link()

# Join a group
:pg.join(:workers, self())

# List members
:pg.get_members(:workers)
# => [#PID<0.100.0>, #PID<12345.200.0>]

# Local members only
:pg.get_local_members(:workers)
# => [#PID<0.100.0>]

# Leave a group
:pg.leave(:workers, self())
```

Use cases for :pg:
- Load balancing across a worker pool
- Pub/sub event broadcasting
- Service discovery

## Distributed Topology

### Full Mesh (Default)

By default, Distributed Erlang creates a **full mesh**: every node connects to every other node.

```
    alice
   /     \
  bob --- carol
```

When alice connects to bob, and bob is already connected to carol, alice automatically connects to carol.

### Hidden Nodes

Use `--hidden` to prevent auto-mesh behavior:

```bash
iex --sname monitor --hidden
```

Hidden nodes:
- Don't appear in `Node.list()` on other nodes
- Don't trigger auto-connections
- Useful for monitoring, debugging, or admin tools

## Node Monitoring

```elixir
# Monitor a node for disconnect events
Node.monitor(:bob@hostname, true)

# Receive notifications
receive do
  {:nodedown, :bob@hostname} ->
    IO.puts("bob disconnected!")
end

# Or use :net_kernel.monitor_nodes/1 for all nodes
:net_kernel.monitor_nodes(true)
receive do
  {:nodeup, node} -> IO.puts("#{node} connected")
  {:nodedown, node} -> IO.puts("#{node} disconnected")
end
```

## Common Patterns

### Pattern 1: Distributed GenServer

```elixir
defmodule DistributedWorker do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: {:global, name})
  end

  def get_state(name) do
    GenServer.call({:global, name}, :get_state)
  end
end
```

### Pattern 2: Fan-out to All Nodes

```elixir
def broadcast(message) do
  for node <- [Node.self() | Node.list()] do
    send({:my_server, node}, message)
  end
end
```

### Pattern 3: Cluster Singleton

```elixir
# Use :global to ensure only one instance runs cluster-wide
case :global.register_name(:singleton, self()) do
  :yes -> run_singleton_work()
  :no -> :already_running
end
```

## Common Pitfalls

1. **Mixing --sname and --name**: These are incompatible. All nodes in a cluster must use the same scheme.
2. **Forgetting the cookie**: Nodes with different cookies silently fail to connect. Check with `Node.get_cookie()`.
3. **Assuming encryption**: The cookie is NOT encryption. Use TLS for production traffic.
4. **Network partitions**: The cluster can split into separate groups. Consider using libraries like `libcluster` for production.
5. **Full mesh scaling**: Full mesh doesn't scale well beyond ~50-100 nodes. Consider hidden nodes or alternative topologies.
6. **Blocking :rpc.call**: Default timeout is `:infinity`. Always set explicit timeouts in production.
7. **Global name conflicts**: `:global.register_name` can have race conditions during network partitions. Consider `Horde` for partition-tolerant registries.
