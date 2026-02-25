# Kata 56: Send & Receive

## The Concept

Processes communicate exclusively through **message passing**. `send/2` puts a message into a process's mailbox. `receive` pulls messages out using pattern matching.

```elixir
send(self(), :hello)

receive do
  :hello -> "Got it!"
end
# => "Got it!"
```

## send/2

`send/2` is **non-blocking** (fire-and-forget):

```elixir
send(pid, {:data, 42})
# Returns the message itself: {:data, 42}
# Does NOT wait for the receiver to process it
```

- Any Elixir term can be a message: atoms, tuples, maps, lists, etc.
- Messages are copied into the receiver's mailbox (no shared memory)
- Sending to a dead PID silently succeeds (no error)

## receive

`receive` blocks the current process until a matching message arrives:

```elixir
receive do
  {:ok, value} -> IO.puts("Success: #{value}")
  {:error, reason} -> IO.puts("Error: #{reason}")
end
```

- Uses pattern matching like `case`
- The first matching clause wins
- Process is suspended (uses no CPU) while waiting

## Pattern Matching in receive

You can match on any pattern:

```elixir
receive do
  {:greeting, name} when is_binary(name) ->
    "Hello, #{name}!"
  {tag, _value} when tag in [:ok, :error] ->
    "Got a result tuple"
  msg ->
    "Catch-all: #{inspect(msg)}"
end
```

Guards work inside receive clauses too.

## Selective Receive

`receive` scans the **entire** mailbox for the first matching message:

```elixir
send(self(), :b)
send(self(), :a)

receive do
  :a -> "Got :a"  # Matches even though :b was sent first
end
# :b remains in the mailbox
```

Non-matching messages stay in the queue. This is powerful but can cause **mailbox bloat** if messages never match.

## Timeout with after

Prevent infinite blocking with `after`:

```elixir
receive do
  :response -> :ok
after
  5000 -> :timed_out  # 5 seconds
end
```

- `after 0` — check mailbox without blocking
- `after :infinity` — wait forever (same as no `after`)

## Between Processes

The typical pattern for inter-process communication:

```elixir
parent = self()

child = spawn(fn ->
  # Do some work
  result = expensive_computation()
  # Send result back to parent
  send(parent, {:result, result})
end)

# Parent waits for the result
receive do
  {:result, value} -> value
end
```

## Request-Reply Pattern

Include the caller's PID so the server knows where to reply:

```elixir
# Client
send(server_pid, {:request, self(), :get_data})
receive do
  {:response, data} -> data
end

# Server
receive do
  {:request, caller, :get_data} ->
    send(caller, {:response, "here is your data"})
end
```

## Common Pitfalls

1. **Mailbox bloat**: Unmatched messages accumulate. Always have a catch-all clause or ensure all message types are handled.
2. **Deadlock**: Two processes both waiting in `receive` for each other's message.
3. **Missing timeout**: Without `after`, `receive` blocks forever if no message matches.
4. **PID not captured**: Forgetting to pass `self()` means the server cannot reply.
5. **Message ordering**: Messages from the same sender arrive in order, but messages from different senders have no guaranteed ordering relative to each other.
