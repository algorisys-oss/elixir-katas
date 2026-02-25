defmodule ElixirKatasWeb.ElixirKata61TaskModuleLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "async_await",
      title: "Task.async/await",
      code: "task = Task.async(fn ->\n  Process.sleep(1000)  # simulate work\n  42\nend)\n\n# Do other work here...\n\nresult = Task.await(task)\n# => 42",
      result: "42",
      explanation: "Task.async/1 spawns a linked process. Task.await/1 blocks until the result is ready. The task runs concurrently with the caller."
    },
    %{
      id: "parallel",
      title: "Parallel Execution",
      code: "t1 = Task.async(fn -> fetch_user(1) end)\nt2 = Task.async(fn -> fetch_user(2) end)\nt3 = Task.async(fn -> fetch_user(3) end)\n\n# All three run concurrently!\nresults = [Task.await(t1), Task.await(t2), Task.await(t3)]",
      result: "3 requests in parallel, not sequential!",
      explanation: "Multiple tasks run concurrently. If each takes 1 second, total time is ~1 second (not 3). This is the main benefit of Task."
    },
    %{
      id: "async_stream",
      title: "Task.async_stream/3",
      code: "urls = [\"a.com\", \"b.com\", \"c.com\", \"d.com\"]\n\nresults =\n  urls\n  |> Task.async_stream(fn url ->\n    fetch(url)\n  end, max_concurrency: 2)\n  |> Enum.map(fn {:ok, result} -> result end)",
      result: "Controlled concurrent processing",
      explanation: "Task.async_stream processes a collection concurrently with controlled parallelism. max_concurrency limits how many run at once."
    },
    %{
      id: "timeout",
      title: "Timeout Handling",
      code: "task = Task.async(fn ->\n  Process.sleep(10_000)  # takes 10 seconds\n  :done\nend)\n\nTask.await(task, 2000)  # timeout after 2 seconds\n# ** (exit) exited in: Task.await(...)\n#    ** (EXIT) time is up",
      result: "** (exit) time is up",
      explanation: "Task.await/2 accepts a timeout (default 5000ms). If the task takes too long, await raises an exit. The task process is also killed."
    },
    %{
      id: "yield",
      title: "Task.yield/2",
      code: "task = Task.async(fn ->\n  Process.sleep(2000)\n  :done\nend)\n\ncase Task.yield(task, 1000) do\n  {:ok, result} -> {:got, result}\n  nil ->\n    # Not ready yet, can try again\n    Task.shutdown(task)\n    :timed_out\nend",
      result: ":timed_out (non-crashing alternative)",
      explanation: "Task.yield/2 is like await but returns nil instead of crashing on timeout. You can then decide to wait more or shut down the task."
    }
  ]

  @timing_demos [
    %{
      id: "sequential",
      label: "Sequential",
      description: "Each task runs after the previous one finishes.",
      tasks: [
        %{name: "Task A", duration: 1000},
        %{name: "Task B", duration: 1500},
        %{name: "Task C", duration: 800}
      ],
      parallel: false
    },
    %{
      id: "parallel",
      label: "Parallel",
      description: "All tasks run at the same time.",
      tasks: [
        %{name: "Task A", duration: 1000},
        %{name: "Task B", duration: 1500},
        %{name: "Task C", duration: 800}
      ],
      parallel: true
    },
    %{
      id: "stream_2",
      label: "Stream (max: 2)",
      description: "At most 2 tasks run concurrently.",
      tasks: [
        %{name: "Task A", duration: 1000},
        %{name: "Task B", duration: 1500},
        %{name: "Task C", duration: 800},
        %{name: "Task D", duration: 1200}
      ],
      parallel: :stream_2
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:active_timing, fn -> hd(@timing_demos) end)
     |> assign_new(:timing_running, fn -> false end)
     |> assign_new(:timing_results, fn -> [] end)
     |> assign_new(:timing_total, fn -> nil end)
     |> assign_new(:show_patterns, fn -> false end)
     |> assign_new(:sim_tasks, fn -> [] end)
     |> assign_new(:sim_next_id, fn -> 1 end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Task Module</h2>
      <p class="text-sm opacity-70 mb-6">
        The <code class="font-mono bg-base-300 px-1 rounded">Task</code> module provides a convenient
        abstraction for running concurrent work. It handles spawning, linking, monitoring, and
        collecting results so you do not have to manage processes manually.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for ex <- examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={ex.id}
            class={"btn btn-sm " <> if(@active_example.id == ex.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= ex.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Example -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_example.title %></h3>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_example.code %></div>
          <div class="bg-success/10 border border-success/30 rounded-lg p-3 mb-3">
            <div class="text-xs font-bold opacity-60 mb-1">Result</div>
            <div class="font-mono text-sm text-success font-bold"><%= @active_example.result %></div>
          </div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3">
            <div class="text-xs font-bold opacity-60 mb-1">How it works</div>
            <div class="text-sm"><%= @active_example.explanation %></div>
          </div>
        </div>
      </div>

      <!-- Timing Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Sequential vs Parallel Timing</h3>
          <p class="text-xs opacity-60 mb-4">
            Compare execution time: sequential (one at a time) vs parallel (Task.async) vs stream (Task.async_stream with max_concurrency).
          </p>

          <!-- Timing Mode Selector -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for demo <- timing_demos() do %>
              <button
                phx-click="select_timing"
                phx-target={@myself}
                phx-value-id={demo.id}
                class={"btn btn-xs " <> if(@active_timing.id == demo.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= demo.label %>
              </button>
            <% end %>
          </div>

          <p class="text-xs opacity-60 mb-3"><%= @active_timing.description %></p>

          <!-- Task Bars -->
          <div class="bg-base-300 rounded-lg p-4 mb-4">
            <div class="space-y-2">
              <%= for task <- @active_timing.tasks do %>
                <div class="flex items-center gap-3">
                  <span class="font-mono text-xs w-16"><%= task.name %></span>
                  <div class="flex-1 bg-base-100 rounded-full h-6 overflow-hidden">
                    <div
                      class="bg-primary h-full rounded-full flex items-center justify-end pr-2 transition-all"
                      style={"width: #{task_bar_width(task.duration, @active_timing)}%"}
                    >
                      <span class="text-xs text-primary-content font-mono"><%= task.duration %>ms</span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Timeline -->
            <div class="mt-4 pt-4 border-t border-base-content/10">
              <div class="flex items-center gap-3">
                <span class="font-mono text-xs w-16 font-bold">Total:</span>
                <div class="flex-1 bg-base-100 rounded-full h-6 overflow-hidden">
                  <div
                    class="bg-accent h-full rounded-full flex items-center justify-end pr-2"
                    style={"width: #{total_bar_width(@active_timing)}%"}
                  >
                    <span class="text-xs text-accent-content font-mono"><%= compute_total(@active_timing) %>ms</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Comparison Summary -->
          <div class="grid grid-cols-3 gap-2">
            <%= for demo <- timing_demos() do %>
              <div class={"rounded-lg p-3 text-center border " <> if(@active_timing.id == demo.id, do: "border-primary bg-primary/10", else: "border-base-content/10 bg-base-100")}>
                <div class="text-xs font-bold"><%= demo.label %></div>
                <div class="font-mono text-lg font-bold mt-1"><%= compute_total(demo) %>ms</div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Interactive Task Launcher -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Task Launcher</h3>
          <p class="text-xs opacity-60 mb-4">
            Launch simulated async tasks. Each takes a random amount of time to complete.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <button phx-click="launch_task" phx-target={@myself} phx-value-duration="fast" class="btn btn-sm btn-success">
              Launch Fast Task (0.5-1s)
            </button>
            <button phx-click="launch_task" phx-target={@myself} phx-value-duration="medium" class="btn btn-sm btn-warning">
              Launch Medium Task (1-2s)
            </button>
            <button phx-click="launch_task" phx-target={@myself} phx-value-duration="slow" class="btn btn-sm btn-error">
              Launch Slow Task (2-4s)
            </button>
            <button phx-click="clear_tasks" phx-target={@myself} class="btn btn-sm btn-ghost">
              Clear
            </button>
          </div>

          <%= if length(@sim_tasks) > 0 do %>
            <div class="space-y-2">
              <%= for task <- Enum.reverse(@sim_tasks) do %>
                <div class={"flex items-center gap-3 rounded-lg p-2 border " <> task_status_style(task.status)}>
                  <span class={"badge badge-sm " <> task_badge(task.status)}>
                    <%= task.status %>
                  </span>
                  <span class="font-mono text-xs">Task #<%= task.id %></span>
                  <span class="text-xs opacity-50">(<%= task.speed %>: <%= task.duration %>ms)</span>
                  <%= if task.status == "completed" do %>
                    <span class="text-xs text-success font-mono ml-auto">Result: <%= task.result %></span>
                  <% end %>
                  <%= if task.status == "running" do %>
                    <span class="loading loading-spinner loading-xs ml-auto"></span>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Common Patterns -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Common Task Patterns</h3>
            <button phx-click="toggle_patterns" phx-target={@myself} class="btn btn-xs btn-ghost">
              <%= if @show_patterns, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_patterns do %>
            <div class="space-y-4">
              <div class="bg-base-300 rounded-lg p-4">
                <h4 class="font-bold text-sm mb-2">Parallel API Calls</h4>
                <div class="font-mono text-xs whitespace-pre-wrap">{parallel_api_code()}</div>
              </div>

              <div class="bg-base-300 rounded-lg p-4">
                <h4 class="font-bold text-sm mb-2">Controlled Concurrency</h4>
                <div class="font-mono text-xs whitespace-pre-wrap">{controlled_concurrency_code()}</div>
              </div>

              <div class="bg-base-300 rounded-lg p-4">
                <h4 class="font-bold text-sm mb-2">Fire-and-Forget with Supervisor</h4>
                <div class="font-mono text-xs whitespace-pre-wrap">{fire_and_forget_code()}</div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>Task.async/1</strong> spawns a linked, monitored process. <strong>Task.await/1</strong> collects the result (default 5s timeout).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Task.async_stream/3</strong> processes collections concurrently with <code class="font-mono bg-base-100 px-1 rounded">max_concurrency</code> control.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Task.yield/2</strong> is a non-crashing alternative to await. Returns <code class="font-mono bg-base-100 px-1 rounded">nil</code> on timeout.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Tasks are <strong>linked</strong> to the caller. Use <strong>Task.Supervisor</strong> for fault-tolerant fire-and-forget work.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Parallel tasks turn <strong>O(n) sequential time into O(1) parallel time</strong> (bounded by the slowest task).</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(examples(), &(&1.id == id))
    {:noreply, assign(socket, active_example: example)}
  end

  def handle_event("select_timing", %{"id" => id}, socket) do
    demo = Enum.find(timing_demos(), &(&1.id == id))
    {:noreply, assign(socket, active_timing: demo)}
  end

  def handle_event("launch_task", %{"duration" => speed}, socket) do
    id = socket.assigns.sim_next_id
    {duration, result} = task_params(speed)
    task = %{id: id, status: "running", speed: speed, duration: duration, result: result}

    Process.send_after(self(), {:task_complete, id}, duration)

    {:noreply,
     socket
     |> assign(sim_tasks: [task | socket.assigns.sim_tasks])
     |> assign(sim_next_id: id + 1)}
  end

  def handle_event("clear_tasks", _params, socket) do
    {:noreply, assign(socket, sim_tasks: [], sim_next_id: 1)}
  end

  def handle_event("toggle_patterns", _params, socket) do
    {:noreply, assign(socket, show_patterns: !socket.assigns.show_patterns)}
  end

  def handle_event("task_completed", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    tasks = Enum.map(socket.assigns.sim_tasks, fn task ->
      if task.id == id, do: %{task | status: "completed"}, else: task
    end)
    {:noreply, assign(socket, sim_tasks: tasks)}
  end

  # Helpers

  defp examples, do: @examples
  defp timing_demos, do: @timing_demos

  defp controlled_concurrency_code do
    String.trim("""
    urls
    |> Task.async_stream(&fetch_url/1,
         max_concurrency: 10,
         timeout: 30_000)
    |> Stream.filter(fn
         {:ok, _} -> true
         {:exit, _} -> false
       end)
    |> Enum.map(fn {:ok, result} -> result end)
    """)
  end

  defp fire_and_forget_code do
    String.trim("""
    # In application.ex, add to children:
    {Task.Supervisor, name: MyApp.TaskSupervisor}

    # Then use:
    Task.Supervisor.async_nolink(
      MyApp.TaskSupervisor,
      fn -> send_email(user) end
    )
    """)
  end

  defp parallel_api_code do
    String.trim("""
    tasks = Enum.map(user_ids, fn id ->
      Task.async(fn -> fetch_user(id) end)
    end)

    users = Task.await_many(tasks, 5000)
    """)
  end

  defp task_params("fast") do
    d = Enum.random(500..1000)
    {d, ":ok"}
  end

  defp task_params("medium") do
    d = Enum.random(1000..2000)
    {d, "{:ok, data}"}
  end

  defp task_params("slow") do
    d = Enum.random(2000..4000)
    {d, "{:ok, large_result}"}
  end

  defp task_params(_), do: {1000, ":ok"}

  defp compute_total(demo) do
    durations = Enum.map(demo.tasks, & &1.duration)

    case demo.parallel do
      false -> Enum.sum(durations)
      true -> Enum.max(durations)
      :stream_2 -> compute_stream_total(durations, 2)
    end
  end

  defp compute_stream_total(durations, max_conc) do
    # Simulate stream scheduling: process in batches of max_conc
    durations
    |> Enum.chunk_every(max_conc)
    |> Enum.map(&Enum.max/1)
    |> Enum.sum()
  end

  defp task_bar_width(duration, demo) do
    max_total = compute_total(%{demo | parallel: false})
    round(duration / max_total * 100)
  end

  defp total_bar_width(demo) do
    max_total = compute_total(%{demo | parallel: false})
    total = compute_total(demo)
    round(total / max_total * 100)
  end

  defp task_status_style("running"), do: "border-info/30 bg-info/5"
  defp task_status_style("completed"), do: "border-success/30 bg-success/5"
  defp task_status_style(_), do: "border-base-content/10 bg-base-100"

  defp task_badge("running"), do: "badge-info"
  defp task_badge("completed"), do: "badge-success"
  defp task_badge(_), do: "badge-ghost"
end
