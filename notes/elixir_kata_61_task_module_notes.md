# Kata 61: Task Module

## The Concept

The `Task` module provides a convenient abstraction for running concurrent work. It handles spawning, linking, monitoring, and collecting results so you don't have to manage raw processes.

```elixir
task = Task.async(fn -> expensive_computation() end)
# ... do other work ...
result = Task.await(task)
```

## Task.async/1 and Task.await/1

`Task.async/1` spawns a linked, monitored process:

```elixir
task = Task.async(fn ->
  Process.sleep(1000)
  42
end)

result = Task.await(task)  # blocks until result ready
# => 42
```

- `async` returns a `%Task{}` struct (not a PID)
- `await` blocks until the task completes or times out
- Default timeout is 5000ms (5 seconds)
- The task is **linked** to the caller — if the task crashes, the caller crashes too

## Custom Timeout

```elixir
Task.await(task, 10_000)  # Wait up to 10 seconds
Task.await(task, :infinity)  # Wait forever
```

If the timeout is exceeded, `Task.await/2` raises an exit error and kills the task.

## Parallel Execution

The main benefit — running multiple operations concurrently:

```elixir
# Sequential: 3 seconds total
result1 = fetch_user(1)     # 1 second
result2 = fetch_user(2)     # 1 second
result3 = fetch_user(3)     # 1 second

# Parallel: ~1 second total
t1 = Task.async(fn -> fetch_user(1) end)
t2 = Task.async(fn -> fetch_user(2) end)
t3 = Task.async(fn -> fetch_user(3) end)

results = [Task.await(t1), Task.await(t2), Task.await(t3)]
```

## Task.await_many/2

Wait for multiple tasks at once:

```elixir
tasks = Enum.map(user_ids, fn id ->
  Task.async(fn -> fetch_user(id) end)
end)

users = Task.await_many(tasks, 5000)
```

## Task.async_stream/3

Process a collection concurrently with controlled parallelism:

```elixir
urls
|> Task.async_stream(&fetch_url/1, max_concurrency: 10, timeout: 30_000)
|> Enum.map(fn {:ok, result} -> result end)
```

Options:
- `max_concurrency` — Maximum simultaneous tasks (default: `System.schedulers_online()`)
- `timeout` — Per-task timeout in milliseconds
- `ordered` — Whether results maintain input order (default: `true`)
- `on_timeout` — `:exit` (default) or `:kill_task`

## Task.yield/2

A non-crashing alternative to `await`:

```elixir
task = Task.async(fn -> slow_computation() end)

case Task.yield(task, 2000) do
  {:ok, result} ->
    result
  nil ->
    # Not done yet — decide what to do
    Task.shutdown(task)
    :timed_out
  {:exit, reason} ->
    {:error, reason}
end
```

`yield` returns `nil` on timeout instead of raising. You can then:
- Wait more with another `yield`
- Give up with `Task.shutdown/1`

## Task.Supervisor

For fault-tolerant tasks that should not crash the caller:

```elixir
# In your supervision tree:
{Task.Supervisor, name: MyApp.TaskSupervisor}

# Fire and forget (no link):
Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
  send_email(user)
end)

# Async without link:
task = Task.Supervisor.async_nolink(MyApp.TaskSupervisor, fn ->
  risky_operation()
end)
```

## Common Patterns

**Parallel API calls:**
```elixir
[user, posts, comments] =
  Task.await_many([
    Task.async(fn -> get_user(id) end),
    Task.async(fn -> get_posts(id) end),
    Task.async(fn -> get_comments(id) end)
  ])
```

**Batch processing with backpressure:**
```elixir
large_list
|> Task.async_stream(&process_item/1, max_concurrency: 20)
|> Stream.filter(fn {:ok, _} -> true; _ -> false end)
|> Enum.to_list()
```

## Common Pitfalls

1. **Forgetting to await**: A Task.async that is never awaited will crash the caller when it completes (due to the link)
2. **Too many concurrent tasks**: Without max_concurrency, you might overwhelm external services
3. **Task in GenServer**: Use `Task.Supervisor.async_nolink` in GenServers to avoid link issues
4. **Timeout too short**: Default 5s may not be enough for network calls
5. **Not handling errors**: Task.async_stream returns `{:exit, reason}` for failed tasks — handle them
