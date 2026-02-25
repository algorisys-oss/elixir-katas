# Kata 64: Call vs Cast

## The Concept

GenServer has two primary ways to send messages to a server process:

- **`GenServer.call/2,3`** — synchronous. The caller blocks until it receives a reply.
- **`GenServer.cast/2`** — asynchronous. The caller sends the message and immediately continues.

Choosing between them affects correctness, performance, and error handling.

## GenServer.call/2,3 (Synchronous)

```elixir
# Client side
result = GenServer.call(pid, :get_count)
# Blocks here until server replies

# Server side
@impl true
def handle_call(:get_count, _from, state) do
  {:reply, state.count, state}
end
```

### How It Works

1. Caller sends a message to the server's mailbox
2. Caller **blocks**, waiting for a reply
3. Server picks up the message, runs `handle_call/3`
4. Server returns `{:reply, reply_value, new_state}`
5. Caller receives `reply_value` and continues

### The `from` Argument

```elixir
def handle_call(:request, from, state) do
  # from is {pid, ref} — identifies the caller
  # Usually you just use {:reply, ...} and ignore from
  {:reply, :ok, state}
end
```

You can use `from` with `GenServer.reply/2` for deferred replies:

```elixir
def handle_call(:slow_request, from, state) do
  # Don't reply now — spawn a task to reply later
  Task.start(fn ->
    result = do_slow_work()
    GenServer.reply(from, result)
  end)
  {:noreply, state}
end
```

## GenServer.cast/2 (Asynchronous)

```elixir
# Client side
:ok = GenServer.cast(pid, :increment)
# Returns :ok immediately, doesn't wait

# Server side
@impl true
def handle_cast(:increment, state) do
  {:noreply, %{state | count: state.count + 1}}
end
```

### How It Works

1. Caller sends a message to the server's mailbox
2. Caller gets `:ok` back **immediately**
3. Server eventually picks up the message, runs `handle_cast/2`
4. Server returns `{:noreply, new_state}`

The caller has no way to know if the server processed the message, or if it even received it.

## Timeout Handling

`GenServer.call/3` accepts an optional timeout (default: 5000ms):

```elixir
# Default 5 second timeout
GenServer.call(pid, :request)

# Custom timeout
GenServer.call(pid, :request, 10_000)  # 10 seconds

# Infinite timeout (dangerous!)
GenServer.call(pid, :request, :infinity)
```

### When Timeout Fires

If the server doesn't reply within the timeout, the caller process **crashes** with:

```
** (exit) exited in: GenServer.call(#PID<0.123.0>, :request, 5000)
    ** (EXIT) time out
```

### Handling Timeouts Gracefully

```elixir
try do
  GenServer.call(pid, :slow_operation, 2_000)
catch
  :exit, {:timeout, _} ->
    {:error, :timeout}
end
```

## When to Use Call vs Cast

### Use Call When:

1. **You need the return value** — reading state, getting computation results
2. **You need confirmation** — knowing the operation succeeded
3. **You want back-pressure** — the caller naturally slows down when the server is busy
4. **You need error propagation** — if the server crashes, the caller knows

### Use Cast When:

1. **Fire-and-forget is acceptable** — logging, metrics, notifications
2. **Broadcasting to many processes** — waiting for each reply would be too slow
3. **The caller truly doesn't care** about the outcome
4. **Performance is critical** and you've measured that call is a bottleneck

### The Golden Rule

> **When in doubt, use `call`.** It's safer and easier to reason about. Only switch to `cast` when you have a specific reason.

## Back-Pressure: The Hidden Benefit of Call

With `call`, a fast producer naturally slows down because it waits for each reply before sending the next message. This prevents mailbox overflow.

With `cast`, there's no such mechanism:

```elixir
# This can crash the server with out-of-memory!
Enum.each(1..1_000_000, fn i ->
  GenServer.cast(pid, {:process, i})
end)
# All million messages land in the mailbox at once
```

## Common Patterns

### Read with Call, Write with Cast

```elixir
# Read operations: always call (you need the data back)
def get_user(pid, id), do: GenServer.call(pid, {:get_user, id})

# Write operations: cast if confirmation isn't needed
def log_event(pid, event), do: GenServer.cast(pid, {:log, event})

# Write operations: call if confirmation is needed
def create_user(pid, attrs), do: GenServer.call(pid, {:create_user, attrs})
```

### Call for Validation, Cast for Side Effects

```elixir
# Validate first with call
case GenServer.call(pid, {:validate, data}) do
  :ok ->
    # Then fire-and-forget the side effect
    GenServer.cast(pid, {:persist, data})
  {:error, reason} ->
    handle_error(reason)
end
```

## Common Pitfalls

1. **Using cast for reads**: Cast returns `:ok`, not the server's state. You can't read data with cast.
2. **Ignoring timeouts**: The default 5-second timeout may be too short for slow operations.
3. **Using `:infinity` timeout**: Can cause the caller to hang forever if the server is stuck.
4. **Cast flooding**: Sending millions of casts without any flow control can exhaust memory.
5. **Deadlock with call**: Process A calls B, B calls A — both block forever.
