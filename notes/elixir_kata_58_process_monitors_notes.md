# Kata 58: Process Monitors

## The Concept

A **monitor** is a unidirectional observation mechanism. When a monitored process exits (for any reason), the monitor owner receives a `:DOWN` message instead of being killed.

```elixir
pid = spawn(fn -> Process.sleep(500) end)
ref = Process.monitor(pid)

receive do
  {:DOWN, ^ref, :process, ^pid, reason} ->
    IO.inspect(reason)  # => :normal
end
```

## Process.monitor/1

`Process.monitor/1` returns a unique reference:

```elixir
ref = Process.monitor(pid)
# => #Reference<0.123.456.789>
```

- The monitored process does **not know** it is being monitored
- The monitoring process receives a `:DOWN` message when the target exits
- You can monitor the same process multiple times (each gets a unique ref)

## :DOWN Message Format

```elixir
{:DOWN, ref, :process, pid, reason}
```

| Field | Description |
|-------|-------------|
| `ref` | The monitor reference from `Process.monitor/1` |
| `:process` | Always the atom `:process` |
| `pid` | The PID of the process that exited |
| `reason` | `:normal`, `:killed`, `{error, stacktrace}`, etc. |

## Unidirectional

Unlike links, monitors are one-way:

```elixir
# A monitors B:
# B exits -> A gets {:DOWN, ...} message
# A exits -> B is NOT affected at all

ref = Process.monitor(target_pid)
# target_pid has no idea it's being monitored
```

## Process.demonitor/1

Cancel a monitor:

```elixir
ref = Process.monitor(pid)

# Cancel and flush any pending :DOWN message
Process.demonitor(ref, [:flush])
```

Options:
- `[]` — Just cancel the monitor
- `[:flush]` — Cancel AND remove any `:DOWN` message already in mailbox
- `[:info]` — Return `false` if the monitor was already canceled

## Links vs Monitors

| Aspect | Links | Monitors |
|--------|-------|----------|
| Direction | Bidirectional | Unidirectional |
| On crash | Other process crashes | Gets `:DOWN` message |
| Setup | `spawn_link/1` | `Process.monitor/1` |
| Teardown | `Process.unlink/1` | `Process.demonitor/1` |
| Multiple? | One link per pair | Many monitors allowed |
| Awareness | Both know | Target unaware |
| Normal exit | No signal (silent) | Gets `:DOWN` with `:normal` |
| Use case | Supervision, co-dependent | Observation, health checks |

## Monitoring Already-Dead Processes

If the process is already dead when you call `Process.monitor/1`, you get an immediate `:DOWN` message:

```elixir
pid = spawn(fn -> :ok end)  # Already exited
Process.sleep(100)

ref = Process.monitor(pid)
receive do
  {:DOWN, ^ref, :process, ^pid, :noproc} ->
    IO.puts("Process was already dead")
end
```

## Practical Uses

1. **Health checks**: Monitor worker processes and log when they die
2. **Cleanup**: Release resources when a dependent process exits
3. **Request tracking**: Monitor the caller in a request-reply protocol
4. **GenServer calls**: `GenServer.call/3` uses monitors internally to detect server death

## Common Pitfalls

1. **Forgetting to handle :DOWN**: Unhandled `:DOWN` messages accumulate in the mailbox
2. **Not using :flush with demonitor**: A `:DOWN` message may have been sent before you canceled
3. **Confusing with links**: Monitors never crash the monitoring process
4. **Multiple monitors**: Calling `Process.monitor/1` twice creates two separate monitors — you get two `:DOWN` messages
