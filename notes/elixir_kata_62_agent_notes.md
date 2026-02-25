# Kata 62: Agent

## The Concept

An **Agent** is a simple process that wraps state. It provides `get`, `update`, and `get_and_update` functions for reading and modifying state without writing a full GenServer.

```elixir
{:ok, agent} = Agent.start_link(fn -> 0 end)

Agent.get(agent, fn state -> state end)       # => 0
Agent.update(agent, fn state -> state + 1 end) # => :ok
Agent.get(agent, fn state -> state end)       # => 1
```

## Agent.start_link/1

Start an Agent process with initial state:

```elixir
# Anonymous agent
{:ok, pid} = Agent.start_link(fn -> %{} end)

# Named agent
{:ok, _} = Agent.start_link(fn -> [], name: :my_cache)

# Now use the name instead of PID
Agent.get(:my_cache, fn state -> state end)
```

The function you pass returns the initial state.

## Agent.get/2

Read state without modifying it:

```elixir
{:ok, agent} = Agent.start_link(fn -> %{name: "Alice", age: 30} end)

Agent.get(agent, fn state -> state.name end)  # => "Alice"
Agent.get(agent, fn state -> state.age end)   # => 30
Agent.get(agent, fn state -> state end)       # => %{name: "Alice", age: 30}
```

The function receives the current state and its return value is sent back to the caller. State is NOT modified.

## Agent.update/2

Replace state with a new value:

```elixir
{:ok, agent} = Agent.start_link(fn -> [] end)

Agent.update(agent, fn state -> ["a" | state] end)  # :ok
Agent.update(agent, fn state -> ["b" | state] end)  # :ok
Agent.get(agent, & &1)  # => ["b", "a"]
```

`update/2` returns `:ok`. The function's return value becomes the new state.

## Agent.get_and_update/2

Atomically read and modify state:

```elixir
{:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)

# Pop the first element
first = Agent.get_and_update(agent, fn [h | t] ->
  {h, t}  # {value_to_return, new_state}
end)
# first => 1
# state is now [2, 3]
```

Return `{return_value, new_state}` — the first element is returned to the caller, the second becomes the new state.

## Agent.stop/1

Terminate the agent:

```elixir
Agent.stop(agent)
# => :ok

Agent.get(agent, & &1)
# ** (exit) process is not alive
```

## Timeout

All Agent functions accept an optional timeout (default 5000ms):

```elixir
Agent.get(agent, fn state -> state end, 10_000)  # 10 second timeout
Agent.update(agent, fn state -> process(state) end, :infinity)
```

## Agent Under the Hood

An Agent is a GenServer in disguise:

```elixir
# Agent.get(agent, fun) is roughly:
GenServer.call(agent, {:get, fun})

# In the GenServer:
def handle_call({:get, fun}, _from, state) do
  {:reply, fun.(state), state}
end
```

## Agent vs GenServer

| Aspect | Agent | GenServer |
|--------|-------|-----------|
| Purpose | Simple state wrapper | Complex stateful server |
| API | get, update, get_and_update | call, cast, info handlers |
| Callbacks | None needed | init, handle_call, handle_cast, handle_info |
| Side effects | State only | Can do I/O, timers, etc. |
| Complexity | Minimal boilerplate | More structure, more power |
| When to use | Shared state (cache, counters) | Business logic, protocols |

## Good Use Cases for Agent

1. **Simple counters**: Hit counters, sequence generators
2. **Caches**: In-memory key-value caches
3. **Configuration**: Runtime configuration shared across processes
4. **Collecting results**: Aggregating data from multiple processes

## When to Use GenServer Instead

1. Need `handle_info` for incoming messages
2. Need periodic timers or scheduled work
3. Need complex request/response protocols
4. Need side effects (I/O, database) in state changes
5. Need to handle process lifecycle events

## Common Pitfalls

1. **Long-running functions**: The function passed to `get`/`update` runs inside the Agent process. If it takes too long, it blocks all other operations on that Agent.
2. **Using Agent for business logic**: Agent is for state, not logic. Put logic in the caller.
3. **Too many Agents**: If you have many independent pieces of state, consider ETS instead.
4. **Bottleneck**: All operations are serialized. High-contention Agents become a bottleneck.
5. **Not supervising**: Always start Agents under a Supervisor in production code.

## Best Practice: Keep Functions Small

```elixir
# Bad — long computation inside the Agent
Agent.get(agent, fn state ->
  Enum.map(state, &expensive_transform/1)
end)

# Good — get state out, compute outside
state = Agent.get(agent, & &1)
Enum.map(state, &expensive_transform/1)
```

The function runs inside the Agent process. While it runs, no other caller can access the Agent.
