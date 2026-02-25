# Kata 66: Periodic Work

## The Concept

GenServers frequently need to perform recurring tasks: polling external APIs, sending heartbeats, cleaning up stale data, refreshing caches, or running scheduled jobs. The standard Elixir pattern uses `Process.send_after/3` combined with self-scheduling in `handle_info/2`.

## The Self-Scheduling Pattern

The most common and recommended approach:

```elixir
defmodule Poller do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, 5_000)
    # Schedule the first tick
    schedule_poll(interval)
    {:ok, %{interval: interval, data: nil, count: 0}}
  end

  @impl true
  def handle_info(:poll, state) do
    # 1. Do the work
    data = fetch_latest_data()

    # 2. Schedule the NEXT tick
    schedule_poll(state.interval)

    # 3. Update state
    {:noreply, %{state | data: data, count: state.count + 1}}
  end

  defp schedule_poll(interval) do
    Process.send_after(self(), :poll, interval)
  end
end
```

### Why This Pattern Works

1. **No message buildup**: The next tick is scheduled AFTER the current work completes. If work takes 3 seconds with a 5-second interval, ticks happen every 8 seconds, not every 5.
2. **Easy to cancel**: Stop scheduling the next tick to stop the loop.
3. **Dynamic intervals**: Change the interval in state and the next tick uses it.
4. **Crash-safe**: If the process restarts, `init/1` starts the schedule fresh.

## Process.send_after/3

```elixir
# Send :poll to self() after 5000ms
ref = Process.send_after(self(), :poll, 5_000)

# Cancel a pending timer
remaining_ms = Process.cancel_timer(ref)
# Returns false if already fired, or milliseconds remaining
```

The returned reference can be stored in state for cancellation:

```elixir
def init(_) do
  ref = Process.send_after(self(), :work, 1_000)
  {:ok, %{timer_ref: ref}}
end

def handle_info(:work, state) do
  do_work()
  ref = Process.send_after(self(), :work, 1_000)
  {:noreply, %{state | timer_ref: ref}}
end

def handle_cast(:stop_timer, state) do
  Process.cancel_timer(state.timer_ref)
  {:noreply, %{state | timer_ref: nil}}
end
```

## :timer.send_interval/2 (Alternative)

Erlang's `:timer` module offers a simpler but less flexible approach:

```elixir
def init(_) do
  {:ok, timer_ref} = :timer.send_interval(5_000, :tick)
  {:ok, %{timer: timer_ref, count: 0}}
end

def handle_info(:tick, state) do
  {:noreply, %{state | count: state.count + 1}}
end
```

### send_after vs send_interval

| Aspect | Process.send_after | :timer.send_interval |
|--------|-------------------|---------------------|
| Scheduling | Manual (self-scheduling) | Automatic |
| Work duration | Interval = gap after work | Interval = wall clock time |
| Message buildup | Impossible | Yes, if work > interval |
| Dynamic interval | Easy (change in state) | Must cancel and recreate |
| Cancellation | `Process.cancel_timer/1` | `:timer.cancel/1` |
| Recommendation | **Preferred** | Only for simple cases |

## handle_continue/2

Not a timer, but related: deferred initialization.

```elixir
def init(args) do
  # Return {:continue, term} to trigger handle_continue
  {:ok, %{data: nil}, {:continue, :load_data}}
end

@impl true
def handle_continue(:load_data, state) do
  # This runs immediately after init, but doesn't block start_link
  data = expensive_load()
  {:noreply, %{state | data: data}}
end
```

Use `handle_continue` when `init` needs to do expensive work without blocking the supervisor.

## Practical Patterns

### Heartbeat / Keep-Alive

```elixir
def init(_) do
  schedule_heartbeat()
  {:ok, %{last_heartbeat: nil}}
end

def handle_info(:heartbeat, state) do
  send_heartbeat_to_remote()
  schedule_heartbeat()
  {:noreply, %{state | last_heartbeat: DateTime.utc_now()}}
end

defp schedule_heartbeat, do: Process.send_after(self(), :heartbeat, 30_000)
```

### Cache Refresh

```elixir
def handle_info(:refresh_cache, state) do
  new_data = fetch_from_database()
  schedule_refresh()
  {:noreply, %{state | cache: new_data, refreshed_at: DateTime.utc_now()}}
end

defp schedule_refresh, do: Process.send_after(self(), :refresh_cache, 60_000)
```

### Conditional Scheduling (Countdown)

```elixir
def handle_info(:tick, %{remaining: 0} = state) do
  # Stop! Don't schedule another tick
  notify_complete()
  {:noreply, state}
end

def handle_info(:tick, state) do
  Process.send_after(self(), :tick, 1_000)
  {:noreply, %{state | remaining: state.remaining - 1}}
end
```

### Dynamic Interval

```elixir
def handle_info(:poll, state) do
  result = do_work()

  # Back off if there's an error
  interval = case result do
    :ok -> state.base_interval
    :error -> state.base_interval * 2
  end

  Process.send_after(self(), :poll, interval)
  {:noreply, %{state | last_result: result}}
end
```

## Common Pitfalls

1. **Forgetting to schedule in init**: The timer loop only starts if you make the first `send_after` call. Usually done in `init/1`.
2. **Message buildup with send_interval**: If your work takes longer than the interval, messages pile up in the mailbox.
3. **Not canceling on stop**: If the GenServer stops, pending `send_after` messages arrive at a dead PID (harmless but wasteful).
4. **Scheduling before work**: If you schedule the next tick before doing work, and the work crashes, the timer is already set. Usually schedule AFTER the work.
5. **Using :timer in tests**: `:timer.send_interval` makes tests slow. Use `Process.send_after` so tests can send the message directly.
