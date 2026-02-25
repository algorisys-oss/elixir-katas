# Kata 60: Trapping Exits

## The Concept

`Process.flag(:trap_exit, true)` converts exit signals from linked processes into regular `{:EXIT, pid, reason}` messages. This allows a process to survive linked process crashes and take corrective action.

```elixir
Process.flag(:trap_exit, true)

spawn_link(fn -> raise "boom!" end)

receive do
  {:EXIT, pid, reason} ->
    IO.puts("Child #{inspect(pid)} died: #{inspect(reason)}")
    # We're still alive!
end
```

## EXIT Message Format

```elixir
{:EXIT, pid, reason}
```

| Field | Description |
|-------|-------------|
| `pid` | The PID of the linked process that exited |
| `reason` | Why it exited: `:normal`, `:shutdown`, `{error, stacktrace}`, etc. |

## Without vs With Trapping

**Without trap_exit** (default):
```elixir
spawn_link(fn -> raise "boom" end)
# Exit signal propagates -> parent crashes too!
```

**With trap_exit**:
```elixir
Process.flag(:trap_exit, true)
spawn_link(fn -> raise "boom" end)

receive do
  {:EXIT, _pid, _reason} ->
    IO.puts("Handled gracefully!")
end
# Parent survives
```

## The Supervisor Pattern

This is the core of how OTP Supervisors work:

```elixir
defmodule MySupervisor do
  def start(child_fn) do
    spawn(fn ->
      Process.flag(:trap_exit, true)
      pid = spawn_link(child_fn)
      supervise(pid, child_fn)
    end)
  end

  defp supervise(pid, child_fn) do
    receive do
      {:EXIT, ^pid, :normal} ->
        :ok  # Normal exit, don't restart
      {:EXIT, ^pid, :shutdown} ->
        :ok  # Graceful shutdown, don't restart
      {:EXIT, ^pid, _reason} ->
        # Crash! Restart the child
        new_pid = spawn_link(child_fn)
        supervise(new_pid, child_fn)
    end
  end
end
```

## Signal Types

| Signal | Without trap_exit | With trap_exit |
|--------|-------------------|---------------|
| `:normal` | Ignored | `{:EXIT, pid, :normal}` |
| `:shutdown` | Process dies | `{:EXIT, pid, :shutdown}` |
| `{:shutdown, term}` | Process dies | `{:EXIT, pid, {:shutdown, term}}` |
| `{error, stacktrace}` | Process dies | `{:EXIT, pid, {error, stacktrace}}` |
| `:kill` | Process dies (untrappable!) | Process dies (untrappable!) |

## The :kill Signal

`:kill` is special — it **cannot** be trapped:

```elixir
Process.flag(:trap_exit, true)
pid = spawn_link(fn -> Process.sleep(:infinity) end)

Process.exit(pid, :kill)
# The killed process exits with reason :killed (not :kill)

receive do
  {:EXIT, ^pid, :killed} ->
    IO.puts("Was killed")  # Reason becomes :killed
end
```

When a process receives `:kill`, it dies immediately. But linked processes receive `:killed` (which CAN be trapped).

## Process.exit/2

You can send exit signals manually:

```elixir
# Send an exit signal to another process
Process.exit(pid, :some_reason)

# Kill yourself
Process.exit(self(), :kill)
```

## Normal Exits When Trapping

Without trapping, normal exits from linked processes are ignored. With trapping, you see ALL exits:

```elixir
Process.flag(:trap_exit, true)
spawn_link(fn -> :ok end)  # Normal exit

receive do
  {:EXIT, _pid, :normal} ->
    # You see this with trap_exit!
    IO.puts("Child exited normally")
end
```

## Practical Guidelines

1. **Use OTP Supervisor** instead of hand-rolling trap_exit in production
2. **Trap exits** only in processes that need to manage other processes
3. **Handle all exit reasons**: normal, shutdown, crashes, killed
4. **Limit restart frequency**: OTP Supervisors implement max_restarts to prevent crash loops
5. **Cleanup**: Use trap_exit for cleanup logic when a process needs to release resources

## Common Pitfalls

1. **Forgetting to handle :normal exits**: With trap_exit, ALL exits become messages
2. **Trapping in every process**: Only supervisor-like processes should trap exits
3. **Not handling :kill properly**: :kill cannot be trapped — design for it
4. **Infinite restart loops**: A child that immediately crashes will restart forever without rate limiting
5. **Confusing :kill and :killed**: You send `:kill`, the linked process receives `:killed`
