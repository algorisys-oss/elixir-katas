# Kata 55: Spawn & Processes

## The Concept

Everything in Elixir runs inside a **process**. These are not OS-level processes or threads — they are BEAM (Erlang VM) processes, which are extremely lightweight (~2KB initial memory). You can run millions of them concurrently.

```elixir
pid = spawn(fn -> IO.puts("Hello from a new process!") end)
# => #PID<0.123.0>
```

## spawn/1

`spawn/1` creates a new process that executes the given function:

```elixir
pid = spawn(fn ->
  IO.puts("I am process #{inspect(self())}")
end)

IO.puts("Parent is #{inspect(self())}")
# Parent continues immediately — does NOT wait for child
```

Key points:
- Returns the child's PID immediately
- The parent does not wait for the child to finish
- The child runs the function and exits when done

## self/0

Every process can ask for its own PID:

```elixir
my_pid = self()
# => #PID<0.100.0>
```

PIDs are used to send messages and identify processes.

## Process Isolation

Processes share **no memory**. Each process has its own heap and stack:

```elixir
x = 42
spawn(fn ->
  # This is a COPY of x, not a reference
  IO.puts(x)  # prints 42
  # Modifying "x" here has zero effect on the parent
end)
IO.puts(x)  # still 42
```

This isolation means:
- No shared mutable state
- No locks or mutexes needed
- A crash in one process does not corrupt another's memory

## Process Lifecycle

1. **Created** — `spawn/1` called, memory allocated
2. **Running** — Executing the function body
3. **Waiting** — Blocked in `receive`, waiting for messages
4. **Exited** — Function returned or process crashed

A process exits when its function completes. There is no way to externally "stop" a process (without links/monitors/exit signals).

## Process.info/1

Inspect a running process:

```elixir
info = Process.info(self())
# [
#   memory: 2688,
#   message_queue_len: 0,
#   status: :running,
#   heap_size: 233,
#   stack_size: 27,
#   reductions: 1234,
#   ...
# ]
```

## Lightweight Nature

BEAM processes are incredibly cheap:

```elixir
# Spawn 100,000 processes
pids = for _ <- 1..100_000 do
  spawn(fn -> receive do :stop -> :ok end end)
end
length(pids)  # => 100_000
```

Each process starts at ~2KB. OS threads are typically 1-8MB each.

## Common Pitfalls

1. **No return value**: `spawn/1` returns a PID, not the result of the function. Use message passing to get results back.
2. **Fire and forget**: A spawned process is independent. If you need to wait for it, use `Task` or message passing.
3. **Process leak**: Processes stuck in `receive` without a sender will live forever. Always ensure processes can exit.
4. **Not for parallelism of data**: For parallel data processing, use `Task.async_stream/3` or `Flow`, not raw `spawn/1`.
