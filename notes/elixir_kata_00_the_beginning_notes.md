# Kata 00: The Beginning — Elixir's Technical Foundations

This kata is **theory-first**. Before writing a single line of Elixir, understand *why* the language exists and *what problems* it solves. Every design choice in Elixir traces back to one question: **how do you build software that runs forever and handles millions of things at once?**

---

## Part 1: The Hardware Reality

### What Is a CPU Core?

A CPU core is a single processing unit that executes instructions **one at a time**, in sequence. Modern CPUs have multiple cores (4, 8, 16, or more), but each core is still fundamentally sequential.

```
Single core:     [instruction] → [instruction] → [instruction] → ...

4-core CPU:      Core 1: [instruction] → [instruction] → ...
                 Core 2: [instruction] → [instruction] → ...
                 Core 3: [instruction] → [instruction] → ...
                 Core 4: [instruction] → [instruction] → ...
```

**Key insight**: If you write a single-threaded program, it uses **one core**. The other 3, 7, or 15 cores sit idle. To use all cores, you need concurrency.

### Clock Speed Hit a Wall

CPUs stopped getting significantly faster around 2005 (~3-4 GHz). Instead, manufacturers started adding more cores. This means:

```
2000: 1 core at 1 GHz     → write fast single-threaded code
2005: 1 core at 3.8 GHz   → still single-threaded, just faster
2010: 4 cores at 3 GHz    → need concurrent code to use all 4
2020: 8 cores at 4 GHz    → single-threaded code wastes 87.5% of CPU
2024: 16 cores at 5 GHz   → single-threaded code wastes 93.75% of CPU
```

**The industry shifted from "faster cores" to "more cores."** Languages designed for single-threaded execution (Ruby, Python, early JavaScript) suddenly had a problem. Elixir was designed from the ground up for multi-core.

### Memory Hierarchy — Why Sharing Is Expensive

```
CPU Register:    ~0.3 ns    (fastest, tiny, per-core)
L1 Cache:        ~1 ns      (small, per-core)
L2 Cache:        ~3 ns      (medium, per-core)
L3 Cache:        ~10 ns     (large, shared across cores)
RAM:             ~100 ns    (huge, shared across everything)
```

When two cores share data through RAM, they must synchronize through the **L3 cache or RAM** — 30-300x slower than local access. This is why **shared memory concurrency** (threads + locks) is fundamentally slow and error-prone.

Elixir avoids this entirely: processes share **nothing**. Each process has its own memory. Communication happens through **message passing**, which the BEAM optimizes internally.

---

## Part 2: Concurrency vs Parallelism

These are different concepts that beginners often confuse.

### Concurrency: Managing Multiple Things

Concurrency is about **structure** — organizing your program to handle multiple tasks that may or may not run simultaneously.

```
One barista, two orders (CONCURRENT, not parallel):
  Make coffee A: [grind]→[brew]→[pour]
  Make coffee B:              [grind]→[brew]→[pour]

  Timeline:  [grind A][brew A][grind B][pour A][brew B][pour B]
                              ↑
                    switch while A brews (waiting)
```

The barista handles two orders by switching between them during wait times. Only one thing happens at any instant.

### Parallelism: Doing Multiple Things Simultaneously

Parallelism is about **execution** — actually performing multiple tasks at the same time using multiple cores.

```
Two baristas, two orders (PARALLEL):
  Barista 1: [grind A]→[brew A]→[pour A]
  Barista 2: [grind B]→[brew B]→[pour B]

  Both happen simultaneously.
```

### Elixir Does Both

Elixir gives you concurrency (millions of processes structured independently) **and** parallelism (processes run on all available CPU cores simultaneously):

```elixir
# Concurrency: structure your program as independent processes
pid1 = spawn(fn -> handle_user_request("Alice") end)
pid2 = spawn(fn -> handle_user_request("Bob") end)
pid3 = spawn(fn -> handle_user_request("Charlie") end)

# Parallelism: the BEAM automatically runs these on different cores
# On a 4-core machine, up to 4 processes execute simultaneously
```

---

## Part 3: Multitasking — The Operating System Way

Before understanding Elixir's model, you need to understand how operating systems handle concurrency.

### Multitasking (OS Processes)

Your OS runs many programs at once: a browser, a text editor, a music player. Each is an **OS process** with its own isolated memory space.

```
OS Process 1 (Browser):     [own memory: 500MB]  [own file handles]
OS Process 2 (Editor):      [own memory: 100MB]  [own file handles]
OS Process 3 (Music):       [own memory: 50MB]   [own file handles]
```

**Advantages:**
- Complete isolation — one crash doesn't affect others
- Security — processes can't read each other's memory

**Disadvantages:**
- Heavy — each process uses 10-100MB+ of memory
- Slow to create — takes milliseconds
- Expensive communication — must go through the OS kernel (pipes, sockets, shared memory)
- Limited count — thousands at most before the OS struggles

### Multithreading (Within One OS Process)

To get concurrency *within* a single program, you use **threads**. Threads share the same memory space but have their own execution stack.

```
One OS Process:
  ┌─────────────────────────────────────────┐
  │  Shared Memory (heap)                    │
  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
  │  │ Thread 1 │ │ Thread 2 │ │ Thread 3 │ │
  │  │ (stack)  │ │ (stack)  │ │ (stack)  │ │
  │  └──────────┘ └──────────┘ └──────────┘ │
  └─────────────────────────────────────────┘
```

**Advantages:**
- Lighter than OS processes (~1-8MB per thread)
- Fast communication (shared memory)
- Can run on multiple cores (true parallelism)

**Disadvantages — and this is critical:**

#### The Shared Memory Problem

When threads share memory, they can **corrupt each other's data**:

```
Thread 1: read balance → 100
Thread 2: read balance → 100        (reads BEFORE Thread 1 writes)
Thread 1: write balance → 100 + 50 = 150
Thread 2: write balance → 100 - 30 = 70   (WRONG! Should be 120)
```

This is a **race condition**. The fix is **locks** (mutexes):

```
Thread 1: LOCK → read balance → 100 → write 150 → UNLOCK
Thread 2: WAIT... WAIT... LOCK → read balance → 150 → write 120 → UNLOCK
```

But locks introduce new problems:

1. **Deadlock**: Thread A holds Lock 1, waits for Lock 2. Thread B holds Lock 2, waits for Lock 1. Both wait forever.
2. **Priority inversion**: A high-priority thread waits for a lock held by a low-priority thread.
3. **Performance bottleneck**: Only one thread can access shared data at a time, defeating the purpose of concurrency.
4. **Complexity**: Getting locks right in large systems is extremely difficult. Most concurrency bugs in Java, C++, and C# are lock-related.

#### Why Elixir Doesn't Use Threads

Elixir (via the BEAM) avoids all of these problems by taking a completely different approach: **no shared memory, ever**. Instead of threads that share a heap, Elixir uses processes that share nothing and communicate by copying messages.

---

## Part 4: The BEAM Way — Processes

### What Is a BEAM Process?

A BEAM process is **not** an OS process or an OS thread. It is a lightweight unit of execution managed entirely by the BEAM virtual machine.

```
Comparison:
  OS Process:    ~10-100 MB memory, milliseconds to create
  OS Thread:     ~1-8 MB memory, microseconds to create
  BEAM Process:  ~2 KB memory, microseconds to create

  A single BEAM VM can run MILLIONS of BEAM processes
  on a handful of OS threads (one per CPU core).
```

### The Actor Model

Elixir processes follow the **Actor Model** (invented by Carl Hewitt, 1973). Each actor:

1. **Has private state** — no other process can read or modify it
2. **Has a mailbox** — receives messages asynchronously
3. **Processes messages one at a time** — sequential within the process
4. **Can create new actors** — spawn new processes
5. **Can send messages** — to any process it knows the PID of

```
┌─────────────┐     message     ┌─────────────┐
│  Process A  │ ──────────────→ │  Process B  │
│  state: 42  │                 │  state: "hi"│
│  mailbox:[] │ ←────────────── │  mailbox:[] │
└─────────────┘     reply       └─────────────┘
```

### Why No Shared Memory?

| Problem | Threads (shared memory) | BEAM Processes (message passing) |
|---------|------------------------|----------------------------------|
| Race conditions | Common, hard to debug | **Impossible** — no shared state |
| Deadlocks | Common with multiple locks | **Impossible** — no locks |
| Data corruption | One thread corrupts another's data | **Impossible** — isolated heaps |
| Debugging | Non-deterministic, hard to reproduce | Deterministic message order per process |
| Scaling | Lock contention limits scaling | Linearly scalable across cores |

The tradeoff: message passing is slightly slower than shared memory for tight loops. But for real-world systems (web servers, chat apps, IoT), the safety and simplicity far outweigh the cost.

### Creating Processes

```elixir
# spawn/1 — create a process from an anonymous function
pid = spawn(fn ->
  IO.puts("Hello from process #{inspect(self())}")
end)
# The parent continues immediately — does NOT wait

# spawn/3 — create a process from a named function
pid = spawn(MyModule, :my_function, [arg1, arg2])
```

### Message Passing

```elixir
# Send a message (non-blocking, always succeeds)
send(pid, {:hello, "world"})

# Receive a message (blocks until a matching message arrives)
receive do
  {:hello, name} -> IO.puts("Got hello from #{name}")
  {:error, reason} -> IO.puts("Error: #{reason}")
after
  5000 -> IO.puts("Timed out after 5 seconds")
end
```

Messages are **copied** into the receiver's mailbox (not shared). This is what guarantees isolation.

### Process Lifecycle

```
spawn/1 called
    ↓
 [CREATED] — ~2KB memory allocated, placed in scheduler run queue
    ↓
 [RUNNING] — executing function body, consuming reductions
    ↓
 [WAITING] — blocked in receive, waiting for a message (optional)
    ↓
 [EXITED]  — function returned OR process crashed
    ↓
 Memory reclaimed by garbage collector
```

A process exits when its function completes. There is no way to externally "stop" a process without links, monitors, or exit signals.

---

## Part 5: Beyond Raw Processes — OTP Abstractions

Raw `spawn` and `send`/`receive` are like assembly language — powerful but low-level. OTP (Open Telecom Platform) provides battle-tested abstractions built on top of processes.

### GenServer — The Workhorse

A GenServer is a process that follows a standard request/response pattern with managed state:

```elixir
# Instead of:
# - Manually writing receive loops
# - Managing state in recursive function arguments
# - Handling edge cases (timeouts, unexpected messages)

# You write:
defmodule Counter do
  use GenServer

  def init(_), do: {:ok, 0}                           # initial state
  def handle_call(:get, _from, count), do: {:reply, count, count}  # sync
  def handle_cast(:increment, count), do: {:noreply, count + 1}   # async
end

{:ok, pid} = GenServer.start_link(Counter, [])
GenServer.cast(pid, :increment)    # fire and forget
GenServer.call(pid, :get)          # => 1
```

**When to use**: Any process that needs to maintain state and respond to requests. This covers 80% of use cases: caches, session stores, connection pools, rate limiters, game state, etc.

### Agent — Simple State Container

An Agent is a simplified GenServer for when you just need to store and retrieve state:

```elixir
{:ok, pid} = Agent.start_link(fn -> 0 end)
Agent.update(pid, fn count -> count + 1 end)
Agent.get(pid, fn count -> count end)  # => 1
```

**When to use**: Simple state that doesn't need complex logic. Think of it as a concurrent variable.

**When NOT to use**: When you need `handle_info` (incoming messages), periodic work, or complex request handling. Use GenServer instead.

### Task — One-Shot Async Work

A Task is a process that runs a single function and returns the result:

```elixir
# Fire and forget
Task.start(fn -> send_welcome_email(user) end)

# Async with result
task = Task.async(fn -> expensive_computation() end)
# ... do other work ...
result = Task.await(task)  # blocks until done, default 5s timeout

# Parallel processing
results =
  ["url1", "url2", "url3"]
  |> Task.async_stream(&fetch_url/1, max_concurrency: 10)
  |> Enum.to_list()
```

**When to use**: One-off async work, parallelizing independent operations, offloading work you don't need to wait for.

**When NOT to use**: Long-running stateful processes (use GenServer), simple state storage (use Agent).

### Supervisor — The Safety Net

A Supervisor monitors child processes and restarts them when they crash:

```elixir
children = [
  {Counter, name: :my_counter},
  {Cache, name: :my_cache},
  {WebSocket, url: "wss://example.com"}
]

# If any child crashes, restart just that child
Supervisor.start_link(children, strategy: :one_for_one)
```

Restart strategies:
- **`:one_for_one`** — restart only the crashed child
- **`:one_for_all`** — restart ALL children if one crashes
- **`:rest_for_one`** — restart the crashed child and all children started after it

This builds **fault-tolerant systems**: instead of trying to handle every possible error, let processes crash and restart them in a known good state.

### The Supervision Tree

Real applications organize supervisors in a tree:

```
Application
└── TopSupervisor
    ├── WebSupervisor
    │   ├── Endpoint (Phoenix web server)
    │   ├── PubSub (real-time messaging)
    │   └── UserSessionSupervisor (dynamic)
    │       ├── UserSession (Alice)
    │       ├── UserSession (Bob)
    │       └── UserSession (Charlie)
    ├── WorkerSupervisor
    │   ├── Cache (ETS-backed)
    │   ├── RateLimiter
    │   └── BackgroundJobRunner
    └── Repo (database connection pool)
```

If `UserSession (Alice)` crashes, only Alice's session restarts. Bob and Charlie are unaffected. If the entire `WebSupervisor` crashes, it restarts with all its children, but `WorkerSupervisor` and `Repo` continue running.

---

## Part 6: Scheduling and Priorities (Overview)

*(Covered in detail in Kata 84)*

### The BEAM Scheduler

The BEAM uses **preemptive scheduling** — it forcibly pauses processes after ~4000 **reductions** (function calls) and switches to the next process. No process can monopolize the CPU.

```
Scheduler run queue:  [P1, P2, P3, P4, P5]

P1 runs for 4000 reductions → PAUSED, moved to back
P2 runs for 4000 reductions → PAUSED, moved to back
P3 runs for 4000 reductions → PAUSED, moved to back
...
```

One scheduler thread per CPU core. Work-stealing balances load across cores.

### Process Priorities

```elixir
Process.flag(:priority, :low)     # runs when nothing else is waiting
Process.flag(:priority, :normal)  # default — fair round-robin
Process.flag(:priority, :high)    # runs before :normal and :low
Process.flag(:priority, :max)     # RESERVED for BEAM internals — NEVER use
```

**Rule of thumb**: Don't change priorities. The default is right 99.9% of the time.

---

## Part 7: The "Let It Crash" Philosophy

Traditional programming teaches defensive coding:

```java
// Java: try to handle EVERY possible error
try {
    connection = database.connect();
    try {
        result = connection.query(sql);
        try {
            parsed = JSON.parse(result);
            return parsed;
        } catch (ParseException e) {
            log.error("Parse failed", e);
            return defaultValue;
        }
    } catch (QueryException e) {
        log.error("Query failed", e);
        return defaultValue;
    } finally {
        connection.close();
    }
} catch (ConnectionException e) {
    log.error("Connection failed", e);
    return defaultValue;
}
```

Elixir takes a different approach: **let it crash**.

```elixir
# Elixir: just do the work. If it fails, the supervisor restarts us.
def handle_call(:fetch_data, _from, state) do
  result = Database.query!(state.conn, sql)  # raises on failure
  parsed = Jason.decode!(result)              # raises on failure
  {:reply, parsed, state}
end
# If ANYTHING fails, this process crashes and the supervisor
# restarts it in a clean state. No error handling needed here.
```

This works because:
1. Processes are isolated — a crash doesn't corrupt other processes
2. Supervisors automatically restart crashed processes
3. Clean restarts often fix transient errors (network blips, temporary resource exhaustion)
4. Code is simpler and more focused on the happy path

This doesn't mean "never handle errors." It means: handle errors you can meaningfully recover from. For everything else, crash and restart.

---

## Part 8: Choosing the Right Tool

```
Do you need to maintain state over time?
├── NO: Is it one-shot async work?
│   ├── YES → Task (Task.async, Task.start, Task.async_stream)
│   └── NO  → Regular function call (no process needed)
└── YES: Is the state simple (get/put only)?
    ├── YES → Agent
    └── NO:  Do you need handle_info, timers, or complex logic?
        ├── YES → GenServer
        └── NO  → Agent (keep it simple)

Do you need fault tolerance?
├── YES → Wrap in a Supervisor
└── NO  → Maybe still wrap it. Supervisors are cheap insurance.

Do you need to scale across cores?
├── YES → Processes are automatically distributed across cores
└── (This is the default. You get it for free.)
```

---

## Part 9: Why Elixir? — Putting It All Together

| Problem | Traditional Approach | Elixir's Approach |
|---------|---------------------|-------------------|
| Multi-core utilization | Manual thread management | Automatic — processes on all cores |
| Shared state bugs | Locks, mutexes, semaphores | No shared state — message passing |
| Error handling | Defensive try/catch everywhere | Let it crash + supervisor restarts |
| Scaling connections | Thread pool with limits | Millions of lightweight processes |
| Hot code upgrades | Restart the entire server | Replace code while running |
| Fault isolation | One crash can take down the system | One crash only affects one process |

### Who Uses Elixir and Why?

- **WhatsApp**: 2 million concurrent connections per server (Erlang)
- **Discord**: Handles millions of concurrent users, real-time messaging
- **Pinterest**: Replaced Java notification system — 10x fewer servers
- **Bleacher Report**: Went from 150 servers to 5 after rewriting in Elixir
- **Telecom switches**: Erlang runs telephone networks with 99.9999999% uptime (nine nines)

All of these need: massive concurrency, fault tolerance, and low latency. These are exactly what the BEAM was built for.

---

## Summary: The Key Mental Models

1. **Everything is a process** — Each concurrent activity gets its own lightweight process
2. **Processes share nothing** — Private memory, communication only through messages
3. **Let it crash** — Don't defend against every error; crash and restart cleanly
4. **Supervisors are your safety net** — They watch processes and restart them automatically
5. **Preemptive fairness** — The BEAM scheduler ensures no process can starve others
6. **Concurrency is the default** — You don't opt into concurrency; it's how Elixir thinks

With these foundations, you're ready to start coding. The remaining katas will teach you the syntax, patterns, and tools — but this mental model is what makes Elixir code fundamentally different from code in other languages.
