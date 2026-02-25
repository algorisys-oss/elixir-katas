# Kata 63: GenServer Basics

## The Concept

GenServer (Generic Server) is the most commonly used OTP behaviour in Elixir. It provides a standard way to build stateful server processes that handle synchronous and asynchronous messages.

Think of a GenServer as a process that:
1. Holds **state** (a value that persists between messages)
2. Responds to **messages** via well-defined callbacks
3. Processes messages **one at a time** (no race conditions)

## The Four Core Callbacks

### init/1

Called when the server starts. Sets up the initial state.

```elixir
@impl true
def init(args) do
  {:ok, initial_state}
end
```

Return values:
- `{:ok, state}` — start successfully with this state
- `{:ok, state, timeout}` — start with a timeout (triggers `handle_info(:timeout, state)`)
- `:ignore` — don't start, but don't raise an error
- `{:stop, reason}` — don't start, signal an error

### handle_call/3

Handles **synchronous** requests. The caller blocks until it receives a reply.

```elixir
@impl true
def handle_call(:get_count, _from, state) do
  {:reply, state.count, state}
end
```

The `from` argument is a tuple `{pid, ref}` identifying who sent the request. You rarely need it directly.

Return values:
- `{:reply, reply, new_state}` — send reply back to caller
- `{:noreply, new_state}` — don't reply now (use `GenServer.reply/2` later)
- `{:stop, reason, reply, new_state}` — reply and stop the server

### handle_cast/2

Handles **asynchronous** requests. Fire-and-forget; the caller doesn't wait.

```elixir
@impl true
def handle_cast(:increment, state) do
  {:noreply, %{state | count: state.count + 1}}
end
```

Return values:
- `{:noreply, new_state}` — continue with updated state
- `{:stop, reason, new_state}` — stop the server

### handle_info/2

Handles **all other messages** — anything not sent via `call` or `cast`.

```elixir
@impl true
def handle_info(:tick, state) do
  # Handle timer ticks, monitor messages, etc.
  {:noreply, state}
end
```

Common sources: `Process.send_after/3`, `send/2`, monitor/link notifications.

## Client API vs Server Callbacks

A well-structured GenServer module has two distinct sections:

```elixir
defmodule Counter do
  use GenServer

  # ============ Client API ============
  # These functions run in the CALLER's process

  def start_link(initial \\ 0) do
    GenServer.start_link(__MODULE__, initial)
  end

  def increment(pid) do
    GenServer.cast(pid, :increment)
  end

  def get_count(pid) do
    GenServer.call(pid, :get_count)
  end

  # ============ Server Callbacks ============
  # These functions run in the GenServer's process

  @impl true
  def init(initial_count) do
    {:ok, %{count: initial_count}}
  end

  @impl true
  def handle_cast(:increment, state) do
    {:noreply, %{state | count: state.count + 1}}
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    {:reply, state.count, state}
  end
end
```

### Why Separate Client and Server?

- **Encapsulation**: Callers don't need to know the message format
- **Testability**: You can test the client API without knowing internal message protocols
- **Documentation**: The public API is clear and self-documenting

## use GenServer

When you write `use GenServer`, Elixir injects default implementations for all callbacks. This means you only need to implement the callbacks you actually use. The defaults:

- `init/1` — must be implemented (no useful default)
- `handle_call/3` — raises if an unexpected call arrives
- `handle_cast/2` — raises if an unexpected cast arrives
- `handle_info/2` — logs a warning for unexpected messages

## @impl true

Always annotate callbacks with `@impl true`:

```elixir
@impl true
def handle_call(:get_count, _from, state) do
  {:reply, state.count, state}
end
```

Benefits:
- Compiler warns if the function doesn't match any behaviour callback
- Catches typos in callback names
- Makes it clear which functions are callbacks vs helpers

## Starting a GenServer

```elixir
# Anonymous (no registered name)
{:ok, pid} = GenServer.start_link(Counter, 0)

# Named process
{:ok, pid} = GenServer.start_link(Counter, 0, name: Counter)
# Now you can use the name instead of pid:
Counter.get_count(Counter)

# Under a Supervisor (most common in production)
children = [
  {Counter, 0}
]
Supervisor.start_link(children, strategy: :one_for_one)
```

## Message Processing Order

GenServer processes messages from its mailbox **one at a time**, in order:

1. A message arrives in the process mailbox
2. GenServer picks the next message
3. The appropriate callback runs
4. The callback returns new state
5. GenServer loops back to step 2

This sequential processing means you never have concurrent access to state — no mutexes or locks needed.

## Common Pitfalls

1. **Blocking in init/1**: Heavy work in `init` blocks the caller of `start_link`. Use `handle_continue/2` for deferred initialization.
2. **Forgetting @impl true**: Without it, typos in callback names silently become unused functions.
3. **Huge state**: GenServer state lives in process memory. Very large state can cause GC pressure.
4. **Deadlock with call**: If process A calls process B and B calls A back, both block forever.
5. **Not handling unexpected messages**: Implement a catch-all `handle_info/2` to avoid filling the mailbox.
