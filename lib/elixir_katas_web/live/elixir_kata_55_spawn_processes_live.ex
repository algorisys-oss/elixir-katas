defmodule ElixirKatasWeb.ElixirKata55SpawnProcessesLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "spawn_basic",
      title: "Basic spawn/1",
      code: "pid = spawn(fn -> IO.puts(\"Hello from process!\") end)\nIO.inspect(pid)\n# => #PID<0.123.0>",
      result: "#PID<0.123.0>",
      explanation: "spawn/1 creates a new process that runs the given function. It returns the PID immediately - the parent does not wait for the child."
    },
    %{
      id: "self",
      title: "self/0 - Current PID",
      code: "my_pid = self()\nIO.inspect(my_pid)\n# => #PID<0.100.0>",
      result: "#PID<0.100.0>",
      explanation: "self() returns the PID of the calling process. Every process has a unique PID."
    },
    %{
      id: "isolation",
      title: "Process Isolation",
      code: "x = 42\nspawn(fn -> x = 99; IO.puts(x) end)\nIO.puts(x)\n# Parent still sees 42\n# Child sees 99",
      result: "Parent: 42, Child: 99",
      explanation: "Processes do NOT share memory. The child gets a copy of x. Modifying it in the child has no effect on the parent."
    },
    %{
      id: "many",
      title: "Spawning Many Processes",
      code: ~s|pids = for i <- 1..5 do\n  spawn(fn ->\n    IO.puts("Process \#{i} running")\n  end)\nend\nlength(pids)  # => 5|,
      result: "5 processes created",
      explanation: "BEAM processes are extremely lightweight (~2KB each). You can easily spawn thousands or millions of them."
    },
    %{
      id: "info",
      title: "Process.info/1",
      code: "pid = self()\ninfo = Process.info(pid)\n# Returns keyword list with:\n# memory, message_queue_len,\n# status, etc.",
      result: "[memory: 2688, message_queue_len: 0, status: :running, ...]",
      explanation: "Process.info/1 returns metadata about a process including memory usage, mailbox size, status, and more."
    }
  ]

  @lifecycle_stages [
    %{id: "created", label: "Created", description: "spawn/1 called, process allocated", color: "info"},
    %{id: "running", label: "Running", description: "Executing the function body", color: "success"},
    %{id: "waiting", label: "Waiting", description: "Blocked in receive, waiting for messages", color: "warning"},
    %{id: "exited", label: "Exited", description: "Function completed or process crashed", color: "error"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:spawned_processes, fn -> [] end)
     |> assign_new(:next_proc_id, fn -> 1 end)
     |> assign_new(:show_lifecycle, fn -> false end)
     |> assign_new(:process_info_target, fn -> nil end)
     |> assign_new(:show_info, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Spawn &amp; Processes</h2>
      <p class="text-sm opacity-70 mb-6">
        Everything in Elixir runs inside <strong>processes</strong>. These are not OS processes -
        they are extremely lightweight BEAM processes (~2KB each). You can spawn millions of them.
        Processes are <strong>isolated</strong> - they share no memory and communicate only via message passing.
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

      <!-- Active Example Card -->
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

      <!-- Interactive Process Spawner -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Process Spawner</h3>
          <p class="text-xs opacity-60 mb-4">
            Spawn processes and watch them appear. Each runs independently and exits when done.
            Observe how the parent process (this LiveView) continues running.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <button phx-click="spawn_one" phx-target={@myself} class="btn btn-sm btn-primary">
              Spawn 1 Process
            </button>
            <button phx-click="spawn_five" phx-target={@myself} class="btn btn-sm btn-secondary">
              Spawn 5 Processes
            </button>
            <button phx-click="spawn_crash" phx-target={@myself} class="btn btn-sm btn-warning">
              Spawn &amp; Crash
            </button>
            <button phx-click="clear_processes" phx-target={@myself} class="btn btn-sm btn-ghost">
              Clear All
            </button>
          </div>

          <!-- Spawned Process Grid -->
          <%= if length(@spawned_processes) > 0 do %>
            <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-2 mb-4">
              <%= for proc <- @spawned_processes do %>
                <div class={"rounded-lg p-3 text-center border " <> proc_style(proc.status)}>
                  <div class="font-mono text-xs font-bold">P#<%= proc.id %></div>
                  <div class="text-xs opacity-70 mt-1">PID: 0.<%= proc.fake_pid %>.0</div>
                  <div class={"badge badge-xs mt-1 " <> proc_badge(proc.status)}>
                    <%= proc.status %>
                  </div>
                  <%= if proc.work do %>
                    <div class="text-xs opacity-50 mt-1"><%= proc.work %></div>
                  <% end %>
                </div>
              <% end %>
            </div>

            <!-- Stats -->
            <div class="flex gap-4 text-sm">
              <div class="badge badge-info gap-1">
                Total: <%= length(@spawned_processes) %>
              </div>
              <div class="badge badge-success gap-1">
                Running: <%= Enum.count(@spawned_processes, &(&1.status == "running")) %>
              </div>
              <div class="badge badge-ghost gap-1">
                Exited: <%= Enum.count(@spawned_processes, &(&1.status == "exited")) %>
              </div>
              <div class="badge badge-error gap-1">
                Crashed: <%= Enum.count(@spawned_processes, &(&1.status == "crashed")) %>
              </div>
            </div>
          <% else %>
            <div class="text-center opacity-40 py-8 text-sm">
              No processes spawned yet. Click a button above to get started.
            </div>
          <% end %>
        </div>
      </div>

      <!-- Process Lifecycle -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Process Lifecycle</h3>
            <button
              phx-click="toggle_lifecycle"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_lifecycle, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_lifecycle do %>
            <div class="flex flex-wrap items-center gap-2 mb-4">
              <%= for {stage, idx} <- Enum.with_index(lifecycle_stages()) do %>
                <div class="flex items-center gap-2">
                  <div class={"rounded-lg px-4 py-2 border border-" <> stage.color <> "/30 bg-" <> stage.color <> "/10"}>
                    <div class={"font-bold text-sm text-" <> stage.color}><%= stage.label %></div>
                    <div class="text-xs opacity-60"><%= stage.description %></div>
                  </div>
                  <%= if idx < length(lifecycle_stages()) - 1 do %>
                    <span class="opacity-30 text-lg">&rarr;</span>
                  <% end %>
                </div>
              <% end %>
            </div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap">{lifecycle_diagram()}</div>
          <% end %>
        </div>
      </div>

      <!-- Process Info Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Process.info - Inspect a Live Process</h3>
            <button
              phx-click="inspect_self"
              phx-target={@myself}
              class="btn btn-xs btn-accent"
            >
              Inspect This LiveView Process
            </button>
          </div>

          <%= if @show_info do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Key</th>
                    <th>Value</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for {key, value, desc} <- @process_info_target do %>
                    <tr>
                      <td class="font-mono text-xs font-bold"><%= key %></td>
                      <td class="font-mono text-xs text-primary"><%= value %></td>
                      <td class="text-xs opacity-70"><%= desc %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
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
              <span><strong>spawn/1</strong> creates a new process and returns its PID immediately. The parent does not wait.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>self/0</strong> returns the PID of the current process. Every process has a unique PID.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Processes are <strong>isolated</strong> - they share no memory. A crash in one process does not affect others (unless linked).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>BEAM processes are <strong>extremely lightweight</strong> (~2KB initial memory). You can run millions concurrently.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>A process <strong>exits</strong> when its function finishes. There is no way to "stop" a process from outside (without links/monitors).</span>
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

  def handle_event("spawn_one", _params, socket) do
    proc = make_process(socket.assigns.next_proc_id, "running", "computing...")
    {:noreply,
     socket
     |> assign(spawned_processes: socket.assigns.spawned_processes ++ [proc])
     |> assign(next_proc_id: socket.assigns.next_proc_id + 1)
     |> then(&schedule_exit(&1, proc.id, "exited", 1500))}
  end

  def handle_event("spawn_five", _params, socket) do
    start_id = socket.assigns.next_proc_id
    procs = for i <- 0..4 do
      work = Enum.random(["sorting...", "fetching...", "parsing...", "encoding...", "hashing..."])
      make_process(start_id + i, "running", work)
    end

    socket =
      socket
      |> assign(spawned_processes: socket.assigns.spawned_processes ++ procs)
      |> assign(next_proc_id: start_id + 5)

    socket = Enum.reduce(procs, socket, fn proc, acc ->
      delay = Enum.random(800..3000)
      schedule_exit(acc, proc.id, "exited", delay)
    end)

    {:noreply, socket}
  end

  def handle_event("spawn_crash", _params, socket) do
    proc = make_process(socket.assigns.next_proc_id, "running", "will crash!")
    {:noreply,
     socket
     |> assign(spawned_processes: socket.assigns.spawned_processes ++ [proc])
     |> assign(next_proc_id: socket.assigns.next_proc_id + 1)
     |> then(&schedule_exit(&1, proc.id, "crashed", 800))}
  end

  def handle_event("clear_processes", _params, socket) do
    {:noreply, assign(socket, spawned_processes: [], next_proc_id: 1)}
  end

  def handle_event("toggle_lifecycle", _params, socket) do
    {:noreply, assign(socket, show_lifecycle: !socket.assigns.show_lifecycle)}
  end

  def handle_event("inspect_self", _params, socket) do
    info = build_process_info()
    {:noreply, assign(socket, process_info_target: info, show_info: true)}
  end

  def handle_event("proc_exited", %{"id" => id_str, "status" => status}, socket) do
    id = String.to_integer(id_str)
    procs = Enum.map(socket.assigns.spawned_processes, fn proc ->
      if proc.id == id, do: %{proc | status: status, work: nil}, else: proc
    end)
    {:noreply, assign(socket, spawned_processes: procs)}
  end

  # Helpers

  defp examples, do: @examples
  defp lifecycle_stages, do: @lifecycle_stages

  defp make_process(id, status, work) do
    %{
      id: id,
      fake_pid: 100 + id,
      status: status,
      work: work
    }
  end

  defp schedule_exit(socket, proc_id, status, delay) do
    Process.send_after(self(), {:proc_exit, proc_id, status}, delay)
    socket
  end

  defp build_process_info do
    pid = self()
    info = Process.info(pid)

    [
      {"current_function", inspect(Keyword.get(info, :current_function)), "Currently executing function"},
      {"memory", "#{Keyword.get(info, :memory)} bytes", "Heap + stack memory used"},
      {"message_queue_len", "#{Keyword.get(info, :message_queue_len)}", "Messages waiting in mailbox"},
      {"reductions", "#{Keyword.get(info, :reductions)}", "Number of reduction steps executed"},
      {"status", "#{Keyword.get(info, :status)}", "Process scheduler status"},
      {"heap_size", "#{Keyword.get(info, :heap_size)} words", "Current heap size"},
      {"stack_size", "#{Keyword.get(info, :stack_size)} words", "Current stack size"},
      {"total_heap_size", "#{Keyword.get(info, :total_heap_size)} words", "Total heap including fragments"}
    ]
  end

  defp lifecycle_diagram do
    """
    spawn/1
      ↓
    [Created] → Process struct allocated (~2KB)
      ↓
    [Running] → Function body executing
      ↓
    [Waiting] → In receive block (optional)
      ↓
    [Exited]  → Function returned or crash
      ↓
    Memory reclaimed by garbage collector\
    """
  end

  defp proc_style("running"), do: "border-success/40 bg-success/10"
  defp proc_style("exited"), do: "border-base-300 bg-base-100 opacity-50"
  defp proc_style("crashed"), do: "border-error/40 bg-error/10"
  defp proc_style(_), do: "border-base-300 bg-base-100"

  defp proc_badge("running"), do: "badge-success"
  defp proc_badge("exited"), do: "badge-ghost"
  defp proc_badge("crashed"), do: "badge-error"
  defp proc_badge(_), do: "badge-ghost"
end
