# Kata 57: Process Links

## The Concept

A **link** is a bidirectional connection between two processes. When a linked process exits abnormally, it sends an exit signal to the other side, killing it too. This is the foundation of the "let it crash" philosophy.

```elixir
pid = spawn_link(fn -> raise "boom!" end)
# Parent also crashes because they are linked!
```

## spawn_link/1

`spawn_link/1` creates a process AND a bidirectional link in a single atomic operation:

```elixir
pid = spawn_link(fn ->
  Process.sleep(1000)
  IO.puts("child done")
end)
```

If the child crashes, the parent crashes too. If the parent crashes, the child crashes too.

## spawn vs spawn_link

```elixir
# spawn: isolated, fire-and-forget
spawn(fn -> raise "boom" end)
IO.puts("parent still alive")  # This executes

# spawn_link: connected, crash propagation
spawn_link(fn -> raise "boom" end)
IO.puts("never reached")  # Parent is dead
```

| Aspect | spawn/1 | spawn_link/1 |
|--------|---------|-------------|
| Connection | None | Bidirectional link |
| Child crashes | Parent unaffected | Parent also crashes |
| Parent crashes | Child unaffected | Child also crashes |
| Normal exit | No notification | No crash propagation |
| Use case | Fire-and-forget | Dependent processes |

## Process.link/1 and Process.unlink/1

You can add or remove links after spawn:

```elixir
pid = spawn(fn -> Process.sleep(:infinity) end)

Process.link(pid)    # Now linked
Process.unlink(pid)  # Link removed
```

`spawn_link/1` is preferred because it is atomic — there is no window where the child could crash before the link is established.

## Bidirectional

Links work both ways:

```elixir
# Parent -> Child
parent = self()
child = spawn_link(fn -> Process.sleep(:infinity) end)
Process.exit(parent, :kill)  # Child also dies

# Child -> Parent
child = spawn_link(fn -> raise "crash" end)
# Parent also dies when child crashes
```

## Normal Exits

A process exiting with reason `:normal` does NOT propagate through links:

```elixir
spawn_link(fn -> :ok end)  # Exits normally
# Parent is fine — :normal exits are silent
```

Only **abnormal** exits (crashes, `:kill`, `:shutdown`, custom reasons) propagate.

## Exit Reasons

| Reason | Propagates? | Meaning |
|--------|-------------|---------|
| `:normal` | No | Function returned successfully |
| `:shutdown` | Yes | Graceful shutdown requested |
| `{:shutdown, term}` | Yes | Shutdown with info |
| `:kill` | Yes (untrappable) | Forced kill |
| Any other term | Yes | Crash or error |

## Why Links Matter

Links are the building block for:
1. **Supervision trees** — Supervisors link to children and restart them on crash
2. **Failure propagation** — Ensures dependent processes fail together
3. **Cleanup** — When a coordinator dies, all its workers die too

## Common Pitfalls

1. **Race condition with separate spawn + link**: Use `spawn_link/1` not `spawn/1` + `Process.link/1`
2. **Unexpected cascading crashes**: A deep chain of linked processes all crash together
3. **Forgetting links are bidirectional**: Killing a child kills the parent too
4. **Not using trap_exit**: If you need to handle crashes gracefully, use `Process.flag(:trap_exit, true)` (see Kata 60)
