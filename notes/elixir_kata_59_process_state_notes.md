# Kata 59: Process State Loop

## The Concept

A process maintains **state** by using a recursive receive loop. The state is passed as a parameter to each recursive call. This is the fundamental pattern behind `GenServer`.

```elixir
defmodule Counter do
  def start, do: spawn(fn -> loop(0) end)

  defp loop(count) do
    receive do
      :increment -> loop(count + 1)
      {:get, caller} ->
        send(caller, {:count, count})
        loop(count)
    end
  end
end
```

## The Receive Loop Pattern

The pattern has three parts:

1. **Initial state**: Passed to the first call to `loop/1`
2. **Receive and process**: Pattern match on messages, compute new state
3. **Recurse**: Call `loop/1` with the new state (tail call optimized)

```elixir
defp loop(state) do
  receive do
    msg ->
      new_state = process(msg, state)
      loop(new_state)  # Tail call — constant stack
  end
end
```

Because the recursive call is the last operation, the BEAM optimizes it into a loop with constant stack usage.

## State Evolution

Each message transforms the state:

```elixir
pid = Counter.start()    # state: 0
send(pid, :increment)    # state: 1
send(pid, :increment)    # state: 2
send(pid, :increment)    # state: 3

send(pid, {:get, self()})
receive do
  {:count, n} -> n       # => 3
end
```

The state is immutable within each iteration. "Mutation" is really creating a new value for the next iteration.

## Building a Key-Value Store

Any Elixir data structure can be the state:

```elixir
defmodule KVStore do
  def start, do: spawn(fn -> loop(%{}) end)

  defp loop(map) do
    receive do
      {:put, key, value} ->
        loop(Map.put(map, key, value))
      {:get, key, caller} ->
        send(caller, {:ok, Map.get(map, key)})
        loop(map)
      {:delete, key} ->
        loop(Map.delete(map, key))
      :stop ->
        :ok  # Don't recurse — process exits
    end
  end
end
```

## Stopping the Loop

A process exits when its function returns. To stop:

```elixir
defp loop(state) do
  receive do
    :stop ->
      :ok  # Return without recursing — process exits
    msg ->
      loop(handle(msg, state))
  end
end
```

## Client API

Good practice: wrap send/receive in public functions:

```elixir
defmodule Counter do
  def start, do: spawn(fn -> loop(0) end)

  # Client API
  def increment(pid), do: send(pid, :increment)
  def get(pid) do
    send(pid, {:get, self()})
    receive do
      {:count, n} -> n
    after
      5000 -> {:error, :timeout}
    end
  end

  # Server (private)
  defp loop(count) do
    receive do
      :increment -> loop(count + 1)
      {:get, caller} ->
        send(caller, {:count, count})
        loop(count)
    end
  end
end

pid = Counter.start()
Counter.increment(pid)
Counter.increment(pid)
Counter.get(pid)  # => 2
```

## Connection to GenServer

This DIY pattern is exactly what GenServer abstracts:

| DIY Loop | GenServer |
|----------|-----------|
| `spawn(fn -> loop(state) end)` | `GenServer.start_link/3` |
| `loop(state)` | `init/1` callback |
| `receive + send reply` | `handle_call/3` |
| `receive (no reply)` | `handle_cast/2` |
| Custom messages | `handle_info/2` |
| Client send/receive | `GenServer.call/2` |

## Common Pitfalls

1. **Forgetting to recurse**: If you forget `loop(new_state)` in a clause, the process exits
2. **Not handling all message types**: Unmatched messages stay in the mailbox forever
3. **Blocking operations in loop**: Long computations block message processing for all other messages
4. **Missing timeout**: A process stuck in receive with no messages wastes a process slot
5. **Race conditions in client API**: Multiple callers can interleave — but the server processes one message at a time (serialized)
