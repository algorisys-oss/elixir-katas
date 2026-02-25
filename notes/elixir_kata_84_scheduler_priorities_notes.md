# Kata 84: BEAM Scheduler & Process Priorities

## The Concept

The BEAM VM uses **preemptive scheduling** — the scheduler forcibly pauses processes after a fixed budget, even if they haven't finished. This is fundamentally different from cooperative scheduling (Node.js, Python, Go goroutines) where a process must voluntarily yield.

```elixir
# This long-running process CANNOT starve others
spawn(fn ->
  Enum.reduce(1..100_000_000, 0, &(&1 + &2))
end)

# This process gets fair CPU time despite the above
spawn(fn ->
  IO.puts("I run just fine!")
end)
```

## Preemptive vs Non-Preemptive Scheduling

### Preemptive (BEAM)

The scheduler interrupts a process after a fixed number of **reductions** (~4000 per timeslice). A reduction is roughly one function call or BIF (built-in function) invocation.

```
Process A:  ████░░░░████░░░░████░░░░
Process B:  ░░░░████░░░░████░░░░████
             ↑       ↑       ↑
          scheduler switches context
```

**Key properties:**
- No process can monopolize the CPU
- Guaranteed fairness — every process gets a turn
- No need to write "yield" or "await" in your code
- A tight CPU loop cannot freeze the system

### Non-Preemptive / Cooperative (Node.js, Python asyncio, Go)

The process runs until it explicitly yields (await, sleep, I/O).

```
Process A:  ████████████████░░░░░░░░
Process B:  ░░░░░░░░░░░░░░░░████████
                             ↑
                      A yields voluntarily
```

**Problems with cooperative scheduling:**
- A CPU-bound task blocks the event loop
- One bad actor starves all others
- Must manually insert yield points

### Why the BEAM Approach Matters

Real-time systems (chat, telephony, web servers) need **latency guarantees**. Preemptive scheduling ensures no single request can block others, even under heavy load. This is why WhatsApp, Discord, and telecom switches use Erlang/Elixir.

## Reductions — The Scheduling Currency

Every function call costs approximately 1 reduction. The scheduler gives each process ~4000 reductions before switching.

```elixir
# Check reductions consumed by a process
{:reductions, count} = Process.info(self(), :reductions)
# => {:reductions, 12345}
```

What counts as a reduction:
- Function calls (local, remote, BIF)
- Sending/receiving messages
- GC cycles
- Pattern matching (complex patterns cost more)

```elixir
# Measure reductions for a piece of work
before = Process.info(self(), :reductions) |> elem(1)
Enum.sum(1..10_000)
after_val = Process.info(self(), :reductions) |> elem(1)
after_val - before
# => ~30_000 reductions for summing 10k numbers
```

## Schedulers and Cores

The BEAM runs one **scheduler thread** per CPU core by default:

```elixir
System.schedulers_online()
# => 8  (on an 8-core machine)

:erlang.system_info(:schedulers)
# => 8  (total schedulers)

:erlang.system_info(:dirty_cpu_schedulers)
# => 8  (for CPU-bound NIFs)

:erlang.system_info(:dirty_io_schedulers)
# => 10 (for blocking I/O NIFs)
```

Each scheduler maintains its own **run queue**. Processes are distributed across schedulers with work-stealing when queues become unbalanced.

## Process Priorities

Elixir provides four priority levels:

```elixir
Process.flag(:priority, :normal)  # default
Process.flag(:priority, :low)
Process.flag(:priority, :high)
Process.flag(:priority, :max)     # RESERVED — never use in app code
```

### How Priorities Affect Scheduling

Priority does NOT mean "more CPU time per turn." Each process still gets the same ~4000 reductions per timeslice. Priority controls **how often** a process is picked from the run queue:

| Priority | Behavior |
|----------|----------|
| `:max` | Always picked first. **Reserved for BEAM internals only.** |
| `:high` | Picked before `:normal` and `:low` processes |
| `:normal` | Default. Fair round-robin with other `:normal` processes |
| `:low` | Only runs when no `:normal` or `:high` processes are runnable |

```elixir
# A high-priority process
spawn(fn ->
  Process.flag(:priority, :high)
  # This process will be scheduled more frequently
  do_critical_work()
end)

# Check current priority
Process.info(self(), :priority)
# => {:priority, :normal}
```

### When Priorities Are Useful

1. **Supervisor processes** — Some OTP internals use `:high` so supervision tree management isn't delayed
2. **Heartbeat/health checks** — Ensuring monitoring processes respond under load
3. **System processes** — The BEAM uses `:max` for its internal code server, distribution controller, etc.

### When NOT to Use Priorities

Almost always. Here's why:

1. **Starvation risk**: `:high` priority processes that are always runnable will starve `:normal` ones
2. **False sense of control**: Priority doesn't guarantee latency — a process still waits in the run queue
3. **Breaks fairness**: The BEAM's strength is fair scheduling. Priorities undermine that.
4. **Better alternatives exist**:
   - Need faster response? Reduce the work in the process, not bump priority
   - Need guaranteed resources? Use dedicated schedulers or a separate node
   - Need to handle load? Use backpressure (GenStage, Broadway) instead

```elixir
# DON'T do this — it won't help and may hurt
Process.flag(:priority, :high)
do_slow_database_query()  # I/O bound — priority is irrelevant here

# DO this instead — design for concurrency
# Use Task.async_stream with bounded concurrency
Task.async_stream(items, &process_item/1, max_concurrency: 10)
```

### The :max Priority — Danger Zone

`:max` is reserved for internal BEAM processes. If you set a user process to `:max`:

- It runs before ALL other processes including system ones
- Can block garbage collection, code loading, and distribution
- Can make the node unresponsive
- **Never use `:max` in application code**

## Dirty Schedulers

Normal schedulers cannot run code that blocks for a long time (C NIFs, disk I/O). The BEAM provides **dirty schedulers** for this:

```elixir
# Normal schedulers: preemptive, reduction-counted
# Dirty CPU schedulers: for CPU-bound NIFs (one per core)
# Dirty IO schedulers: for blocking I/O NIFs (10 by default, configurable)
```

A NIF that takes >1ms should be flagged as dirty so it doesn't block a normal scheduler:

```c
// In C NIF code:
ERL_NIF_DIRTY_JOB_CPU_BOUND  // for CPU-intensive work
ERL_NIF_DIRTY_JOB_IO_BOUND   // for blocking I/O
```

From Elixir, you don't interact with dirty schedulers directly — they're transparent. But knowing they exist explains why NIFs and ports don't block your processes.

## Observing the Scheduler

```elixir
# See scheduler utilization (requires :runtime_tools)
:scheduler.utilization(1000)
# Returns per-scheduler utilization over 1 second

# In :observer
:observer.start()
# Shows scheduler threads, load charts, and per-process reductions

# Process-level info
Process.info(pid, [:reductions, :priority, :message_queue_len, :status])
```

## Summary

| Aspect | BEAM | Node.js | Go |
|--------|------|---------|-----|
| Scheduling | Preemptive | Cooperative | Cooperative (goroutines) |
| Unit | Reductions (~4000) | Until yield/await | Until channel/syscall |
| Fairness | Guaranteed | Not guaranteed | Mostly fair |
| CPU hog impact | None — gets preempted | Blocks event loop | Can starve others |
| Priority levels | 4 (low/normal/high/max) | N/A | N/A (GOMAXPROCS only) |

## Common Pitfalls

1. **Using `:max` priority**: Reserved for BEAM internals. Will cause system instability.
2. **Using `:high` for performance**: Priority doesn't make code faster. Fix the algorithm instead.
3. **Long-running NIFs on normal schedulers**: Use dirty schedulers for any NIF >1ms.
4. **Assuming priority = latency**: A `:high` process still waits if the scheduler is in the middle of another process's timeslice.
5. **Forgetting the BEAM is already fair**: The default scheduling is excellent. Only override it with strong justification.
