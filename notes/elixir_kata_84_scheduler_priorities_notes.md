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

---

## What Is Scheduling? (First Principles)

A CPU core can only execute **one thing at a time**. If you have 100 processes but only 4 cores, someone has to decide which 4 processes run right now and when to switch. That "someone" is the **scheduler**.

Think of it like a single cashier at a grocery store with a long line of customers. The scheduling policy decides:
- How long does each customer get at the counter?
- Can a customer be interrupted mid-transaction?
- Do some customers get to skip the line?

### The Two Fundamental Approaches

There are only two ways a running process can lose the CPU:

1. **It gives up voluntarily** (cooperative/non-preemptive)
2. **The scheduler forces it out** (preemptive)

Every scheduling system in computing falls into one of these two categories.

---

## Non-Preemptive (Cooperative) Scheduling — Explained

### How It Works

In cooperative scheduling, a running process keeps the CPU **until it voluntarily yields**. The scheduler cannot interrupt it. The process must explicitly say "I'm done for now, someone else can go."

```
Timeline: ─────────────────────────────────────────>

Process A: ████████████████████████░░░░░░░░░░░░░░░░
Process B: ░░░░░░░░░░░░░░░░░░░░░░░░████████░░░░░░░░
Process C: ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████
                                    ↑        ↑
                                 A yields  B yields
```

**What causes a yield?**
- Calling `await` (JavaScript, Python)
- Performing I/O (reading a file, making an HTTP request)
- Explicitly calling `yield` or `sleep`
- The function finishing naturally

### Real-World Examples of Cooperative Scheduling

**Node.js (Single-threaded event loop):**
```javascript
// This BLOCKS the entire event loop — nothing else runs
function cpuHog() {
  let sum = 0;
  for (let i = 0; i < 10_000_000_000; i++) {
    sum += i;
  }
  return sum;
}

// While cpuHog() runs:
// - HTTP requests queue up unanswered
// - setTimeout callbacks don't fire
// - The entire server appears frozen
cpuHog();
```

**Python asyncio:**
```python
async def cpu_hog():
    # No await anywhere — blocks the event loop!
    total = sum(range(10_000_000_000))
    return total

# Other coroutines are starved until this finishes
await cpu_hog()
```

**Go goroutines (mostly cooperative before Go 1.14):**
```go
// A tight loop with no function calls can starve other goroutines
func cpuHog() {
    for {
        // No function call = no preemption point
        // Other goroutines can't run
    }
}
```

### The Fundamental Problem

If a process does CPU-intensive work without any yield points, **all other processes are blocked**. The programmer must manually insert yield points, which is:
- Error-prone (forget one yield and the system freezes)
- Requires deep understanding of every code path
- Makes third-party libraries dangerous (they might not yield)
- Impossible to guarantee latency bounds

### Where Cooperative Scheduling Works Well

Despite its problems, cooperative scheduling is simpler to implement and works great when:
- Most work is I/O-bound (web servers doing database queries)
- You control all the code and can ensure yield points
- Latency requirements are relaxed
- Single-threaded simplicity is more important than fairness

---

## Preemptive Scheduling — Explained

### How It Works

In preemptive scheduling, the scheduler maintains a **timer or counter**. When a process's budget runs out, the scheduler **forcibly suspends** it (saves its state) and switches to another process. The process has no say in when it gets paused.

```
Timeline: ─────────────────────────────────────────>

Process A: ████░░░░░░░░████░░░░░░░░████░░░░░░░░████
Process B: ░░░░████░░░░░░░░████░░░░░░░░████░░░░░░░░
Process C: ░░░░░░░░████░░░░░░░░████░░░░░░░░████░░░░
            ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑
         scheduler forces context switches every N units
```

Each process gets a **fixed timeslice** — a budget of work it's allowed to do before being swapped out. Once the budget is exhausted, the scheduler saves the process's state and picks the next process from the **run queue**.

### The BEAM's Approach: Reduction-Based Preemption

Most operating systems use **wall-clock time** for preemption (e.g., "each process gets 10ms"). The BEAM is different — it uses **reductions**.

A **reduction** is an abstract unit of work, roughly equivalent to one function call. The BEAM gives each process approximately **4,000 reductions** per timeslice. After ~4,000 function calls, the scheduler pauses the process regardless of what it's doing.

Why reductions instead of time?
- **Deterministic**: The same code always costs the same reductions, regardless of CPU speed
- **No timer overhead**: No need for hardware timer interrupts
- **Fine-grained**: Can preempt mid-computation, not just at I/O points
- **Portable**: Works the same on fast and slow machines

```
Process A budget: 4000 reductions
  Call function_1()  → 3999 remaining
  Call function_2()  → 3998 remaining
  Call function_3()  → 3997 remaining
  ...
  Call function_4000() → 0 remaining
  ⚡ PREEMPTED — scheduler switches to Process B
```

### Why This Matters — A Concrete Example

Imagine a web server handling two requests simultaneously:

**Request 1**: Calculates the 50th Fibonacci number (CPU-intensive)
**Request 2**: Returns "Hello, World!" (trivial)

**With cooperative scheduling (Node.js):**
```
Request 1 arrives  → starts computing Fibonacci...
Request 2 arrives  → WAITS (event loop blocked)
                   → WAITS
                   → WAITS (user sees spinner for seconds)
Request 1 finishes → "Fibonacci result: 12586269025"
Request 2 starts   → "Hello, World!" (finally, after seconds of delay)
```
Request 2's user waited seconds for a response that should take microseconds.

**With preemptive scheduling (BEAM):**
```
Request 1 arrives → starts computing Fibonacci...
                  → runs for 4000 reductions → PAUSED
Request 2 starts  → "Hello, World!" (responds in microseconds)
Request 1 resumes → runs for 4000 more reductions → PAUSED
Request 2 done    ✓
Request 1 resumes → eventually finishes: "Fibonacci result: 12586269025"
```
Request 2 is answered almost immediately, even though Request 1 is doing heavy work.

### Preemptive Scheduling in Operating Systems vs BEAM

Your operating system (Linux, macOS, Windows) also uses preemptive scheduling for OS processes and threads. The BEAM goes further by implementing its **own** preemptive scheduler inside the VM for its lightweight processes:

| Aspect | OS Scheduler | BEAM Scheduler |
|--------|-------------|----------------|
| What it schedules | OS threads/processes | BEAM processes |
| Timeslice unit | Wall-clock time (~10ms) | Reductions (~4000) |
| Context switch cost | Expensive (kernel mode, TLB flush) | Very cheap (just swap pointers) |
| Memory per unit | 1-8 MB per thread | ~2 KB per process |
| Number of units | Hundreds to low thousands | Millions |
| Who controls it | Kernel | BEAM VM (userspace) |

This is why Elixir can run millions of concurrent processes efficiently — the BEAM scheduler is purpose-built for massive concurrency with guaranteed fairness.

---

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

### How Context Switching Works

When a process exhausts its reductions:

1. **Save state**: The scheduler saves the process's registers, instruction pointer, and stack pointer
2. **Move to run queue**: The process is placed at the back of its priority queue
3. **Pick next**: The scheduler picks the next runnable process from the queue
4. **Restore state**: The new process's saved state is loaded
5. **Resume**: The new process continues from exactly where it was paused

This entire operation takes **nanoseconds** because BEAM processes are so lightweight. Compare this to OS thread context switches which take microseconds and involve kernel transitions.

---

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

### Run Queues and Work Stealing

Each scheduler maintains its own **run queue** — a list of processes waiting to be executed.

```
Scheduler 1:  [P1, P5, P9]     → runs P1 next
Scheduler 2:  [P2, P6, P10]    → runs P2 next
Scheduler 3:  [P3, P7]         → runs P3 next
Scheduler 4:  []                → idle! steals from Scheduler 1
```

When a scheduler's queue is empty, it **steals** processes from other schedulers' queues. This ensures all CPU cores stay busy without manual load balancing.

### Why One Scheduler Per Core?

Each scheduler is an OS thread pinned to a CPU core. This means:
- No contention between schedulers (each has its own queue)
- Full utilization of all cores
- No over-subscription (you don't have 100 OS threads fighting for 8 cores)
- The BEAM manages concurrency in userspace, which is much cheaper than OS scheduling

---

## Process Priorities

Elixir provides four priority levels:

```elixir
Process.flag(:priority, :normal)  # default
Process.flag(:priority, :low)
Process.flag(:priority, :high)
Process.flag(:priority, :max)     # RESERVED — never use in app code
```

### How Priorities Affect Scheduling

Priority does NOT mean "more CPU time per turn." Each process still gets the same ~4000 reductions per timeslice. Priority controls **how often** a process is picked from the run queue.

The scheduler maintains **separate queues** per priority level:

```
Max queue:    [system_code_server]           ← checked first
High queue:   [supervisor_1, health_check]   ← checked second
Normal queue: [web_req_1, web_req_2, ...]    ← checked third
Low queue:    [log_cleanup, metrics_flush]   ← checked last
```

The scheduler always picks from the highest non-empty queue first. This means:

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

### Starvation Explained

**Starvation** happens when a process never gets to run because higher-priority processes always take its place:

```
High queue:   [P1, P2, P3]    ← always has runnable processes
Normal queue: [P4, P5]        ← NEVER gets picked!
Low queue:    [P6]             ← NEVER gets picked!

P4, P5, P6 are STARVED — they wait forever.
```

The BEAM does have some safeguards (it occasionally lets lower-priority processes run), but heavy use of `:high` priority can still cause significant starvation.

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

---

## Dirty Schedulers

Normal schedulers cannot run code that blocks for a long time (C NIFs, disk I/O). The BEAM provides **dirty schedulers** for this:

```elixir
# Normal schedulers: preemptive, reduction-counted
# Dirty CPU schedulers: for CPU-bound NIFs (one per core)
# Dirty IO schedulers: for blocking I/O NIFs (10 by default, configurable)
```

### Why Dirty Schedulers Exist

Normal schedulers count reductions to enforce preemption. But **C code (NIFs)** doesn't go through the BEAM's reduction counter — the BEAM can't preempt C code. If a NIF runs for 100ms on a normal scheduler, that scheduler is **blocked** and all processes in its queue are stalled.

Dirty schedulers solve this by running long NIFs on **separate OS threads** that don't block normal scheduling:

```
Normal schedulers (preemptive, handle Elixir code):
  Scheduler 1: [P1, P2, P3] → runs Elixir code, preempts every ~4000 reductions
  Scheduler 2: [P4, P5, P6] → runs Elixir code, preempts every ~4000 reductions

Dirty CPU schedulers (for CPU-bound NIFs):
  Dirty CPU 1: [heavy_crypto_nif] → runs until done, doesn't block normal schedulers
  Dirty CPU 2: [image_resize_nif] → runs until done

Dirty IO schedulers (for blocking I/O NIFs):
  Dirty IO 1: [disk_read_nif] → blocks on I/O, doesn't block anything else
  Dirty IO 2: [network_call_nif]
```

A NIF that takes >1ms should be flagged as dirty so it doesn't block a normal scheduler:

```c
// In C NIF code:
ERL_NIF_DIRTY_JOB_CPU_BOUND  // for CPU-intensive work
ERL_NIF_DIRTY_JOB_IO_BOUND   // for blocking I/O
```

From Elixir, you don't interact with dirty schedulers directly — they're transparent. But knowing they exist explains why NIFs and ports don't block your processes.

---

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

---

## Summary: The Big Picture

```
┌─────────────────────────────────────────────────────────┐
│                    BEAM VM                               │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │Scheduler │  │Scheduler │  │Scheduler │  (1 per core) │
│  │    1     │  │    2     │  │    3     │              │
│  ├──────────┤  ├──────────┤  ├──────────┤              │
│  │Max:  []  │  │Max:  []  │  │Max:  []  │              │
│  │High: [P1]│  │High: []  │  │High: []  │              │
│  │Norm: [P2,│  │Norm: [P5,│  │Norm: [P8]│              │
│  │  P3, P4] │  │  P6, P7] │  │          │              │
│  │Low:  [P9]│  │Low:  []  │  │Low: [P10]│              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                                                          │
│  Each process gets ~4000 reductions per turn.            │
│  Scheduler picks from highest non-empty queue.           │
│  Work-stealing when a scheduler's queues are empty.      │
│                                                          │
│  ┌──────────────┐  ┌──────────────────┐                 │
│  │Dirty CPU (8) │  │Dirty IO (10)     │                 │
│  │for C NIFs    │  │for blocking NIFs │                 │
│  └──────────────┘  └──────────────────┘                 │
└─────────────────────────────────────────────────────────┘
```

### Cross-Runtime Comparison

| Aspect | BEAM | Node.js | Go | Java (threads) |
|--------|------|---------|-----|----------------|
| Scheduling | Preemptive | Cooperative | Cooperative* | Preemptive (OS) |
| Unit | Reductions (~4000) | Until yield/await | Until channel/syscall | Time-based (~10ms) |
| Fairness | Guaranteed | Not guaranteed | Mostly fair | Guaranteed |
| CPU hog impact | None — gets preempted | Blocks event loop | Can starve others | None — gets preempted |
| Context switch cost | Nanoseconds | N/A (single-threaded) | Microseconds | Microseconds |
| Memory per unit | ~2 KB | N/A | ~8 KB (goroutine) | 1-8 MB (thread) |
| Max concurrent | Millions | 1 (event loop) | Hundreds of thousands | Thousands |
| Priority levels | 4 (low/normal/high/max) | N/A | N/A (GOMAXPROCS only) | 10 levels |

*Go added non-cooperative preemption in Go 1.14, but it's coarser than BEAM's approach.

---

## Common Pitfalls

1. **Using `:max` priority**: Reserved for BEAM internals. Will cause system instability.
2. **Using `:high` for performance**: Priority doesn't make code faster. Fix the algorithm instead.
3. **Long-running NIFs on normal schedulers**: Use dirty schedulers for any NIF >1ms.
4. **Assuming priority = latency**: A `:high` process still waits if the scheduler is in the middle of another process's timeslice.
5. **Forgetting the BEAM is already fair**: The default scheduling is excellent. Only override it with strong justification.
6. **Thinking "preemptive" means "faster"**: Preemptive scheduling guarantees fairness, not speed. Each process gets the same total CPU time — it's just distributed more evenly.

## Key Takeaways for Freshers

1. **Cooperative = polite**: Processes take turns voluntarily. Simple but fragile — one bad process ruins it for everyone.
2. **Preemptive = enforced**: The scheduler is the referee. It forces fairness even if a process doesn't cooperate.
3. **The BEAM is unique**: It combines preemptive scheduling with extremely lightweight processes. This is why Elixir excels at building systems that need to handle millions of concurrent connections reliably.
4. **Don't touch priorities**: The default `:normal` priority is right for 99.9% of use cases. If you think you need `:high`, you probably need a better algorithm instead.
5. **Reductions are the secret sauce**: By counting function calls instead of wall-clock time, the BEAM achieves fine-grained, deterministic preemption that's impossible with timer-based approaches.
