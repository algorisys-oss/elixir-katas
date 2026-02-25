defmodule ElixirKatasWeb.ElixirKata84SchedulerPrioritiesLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "preemptive",
      title: "Preemptive Scheduling",
      code: "# This CPU hog CANNOT starve others\nspawn(fn ->\n  Enum.reduce(1..100_000_000, 0, &(&1 + &2))\nend)\n\n# This still runs fine — scheduler preempts the hog\nspawn(fn -> IO.puts(\"I'm not blocked!\") end)",
      result: "\"I'm not blocked!\"  (prints immediately)",
      explanation: "The BEAM scheduler interrupts every process after ~4000 reductions (function calls). No process can monopolize a CPU core, unlike Node.js where a tight loop blocks the event loop."
    },
    %{
      id: "reductions",
      title: "Reductions — Scheduling Currency",
      code: "before = Process.info(self(), :reductions) |> elem(1)\nEnum.sum(1..10_000)\nafter_val = Process.info(self(), :reductions) |> elem(1)\nafter_val - before\n# => ~30_000 reductions",
      result: "~30,000 reductions consumed",
      explanation: "Every function call costs ~1 reduction. The scheduler gives each process ~4000 reductions per timeslice before switching to the next. This is the core mechanism behind preemptive fairness."
    },
    %{
      id: "priorities",
      title: "Process.flag(:priority, level)",
      code: "# Default is :normal\nProcess.info(self(), :priority)\n# => {:priority, :normal}\n\nProcess.flag(:priority, :high)\n# Now scheduled before :normal/:low processes\n\n# Levels: :low, :normal, :high, :max\n# :max is RESERVED for BEAM internals!",
      result: "{:priority, :high}",
      explanation: "Priority controls how OFTEN a process is picked from the run queue, not how much CPU time it gets per turn. :high processes run before :normal ones. :max should never be used in application code."
    },
    %{
      id: "schedulers",
      title: "Schedulers & Cores",
      code: "System.schedulers_online()\n# => 8  (one per CPU core)\n\n:erlang.system_info(:dirty_cpu_schedulers)\n# => 8  (for CPU-bound NIFs)\n\n:erlang.system_info(:dirty_io_schedulers)\n# => 10 (for blocking I/O NIFs)",
      result: "8 normal + 8 dirty CPU + 10 dirty IO schedulers",
      explanation: "The BEAM runs one scheduler thread per core, each with its own run queue. Work-stealing balances load across cores. Dirty schedulers handle long-running C NIFs without blocking normal process scheduling."
    },
    %{
      id: "when_not",
      title: "When NOT to Set Priorities",
      code: "# DON'T — priority doesn't help I/O-bound work\nProcess.flag(:priority, :high)\ndo_slow_database_query()\n\n# DO — design for concurrency instead\nTask.async_stream(items, &process/1,\n  max_concurrency: 10)\n|> Enum.to_list()",
      result: "Use concurrency, not priority",
      explanation: "Priority is almost never the answer. I/O-bound processes spend time waiting, not running — priority only helps when a process is runnable. Use backpressure (GenStage/Broadway) or bounded concurrency instead."
    }
  ]

  @priority_levels [
    %{level: ":max", color: "error", desc: "BEAM internals only. Never use.", runs: "Always first"},
    %{level: ":high", color: "warning", desc: "Runs before :normal and :low", runs: "Before normal"},
    %{level: ":normal", color: "success", desc: "Default. Fair round-robin.", runs: "Default"},
    %{level: ":low", color: "info", desc: "Only when no higher-priority runnable", runs: "Last"}
  ]

  @comparison [
    %{aspect: "Scheduling", beam: "Preemptive", nodejs: "Cooperative", go: "Cooperative"},
    %{aspect: "Unit", beam: "Reductions (~4000)", nodejs: "Until yield/await", go: "Until chan/syscall"},
    %{aspect: "Fairness", beam: "Guaranteed", nodejs: "Not guaranteed", go: "Mostly fair"},
    %{aspect: "CPU hog", beam: "Gets preempted", nodejs: "Blocks event loop", go: "Can starve others"},
    %{aspect: "Priorities", beam: "4 levels", nodejs: "N/A", go: "N/A"}
  ]

  # Forward info_msg from the host LiveView
  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:sim_running, fn -> false end)
     |> assign_new(:sim_tick, fn -> 0 end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:scheduler_info, fn -> nil end)
     |> assign_new(:show_scheduler_info, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">BEAM Scheduler &amp; Process Priorities</h2>
      <p class="text-sm opacity-70 mb-6">
        The BEAM uses <strong>preemptive scheduling</strong> — it forcibly pauses processes after a
        fixed budget of <strong>reductions</strong> (~4000 per timeslice). No process can starve others.
        This is fundamentally different from Node.js, Python, or Go where tasks must cooperatively yield.
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

      <!-- Preemptive vs Cooperative Visualization -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Preemptive vs Cooperative Scheduling</h3>
          <p class="text-xs opacity-60 mb-4">
            Watch how processes are scheduled differently. In preemptive mode, the scheduler
            forces context switches. In cooperative mode, a CPU hog blocks everyone else.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <!-- BEAM (preemptive) -->
            <div class="bg-base-300 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-3">
                <span class="badge badge-success badge-sm">BEAM</span>
                <span class="text-xs font-bold">Preemptive</span>
              </div>
              <div class="space-y-2 font-mono text-xs">
                <div class="flex items-center gap-2">
                  <span class="w-6 opacity-60">P1</span>
                  <div class="flex-1 flex h-5">
                    <%= for i <- 0..11 do %>
                      <div class={"flex-1 " <> if(rem(i, 3) == 0, do: "bg-success/60", else: if(rem(i, 3) == 1, do: "bg-info/60", else: "bg-warning/60")) <> beam_tick_highlight(@sim_tick, i)}></div>
                    <% end %>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <span class="w-6 opacity-60">P2</span>
                  <div class="flex-1 flex h-5">
                    <%= for i <- 0..11 do %>
                      <div class={"flex-1 " <> if(rem(i, 3) == 1, do: "bg-success/60", else: if(rem(i, 3) == 0, do: "bg-info/60", else: "bg-warning/60")) <> beam_tick_highlight(@sim_tick, i)}></div>
                    <% end %>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <span class="w-6 opacity-60">P3</span>
                  <div class="flex-1 flex h-5">
                    <%= for i <- 0..11 do %>
                      <div class={"flex-1 " <> if(rem(i, 3) == 2, do: "bg-success/60", else: if(rem(i, 3) == 0, do: "bg-info/60", else: "bg-warning/60")) <> beam_tick_highlight(@sim_tick, i)}></div>
                    <% end %>
                  </div>
                </div>
              </div>
              <div class="text-xs opacity-50 mt-2">Each process gets fair timeslices (~4000 reductions)</div>
            </div>

            <!-- Node.js (cooperative) -->
            <div class="bg-base-300 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-3">
                <span class="badge badge-error badge-sm">Node.js</span>
                <span class="text-xs font-bold">Cooperative</span>
              </div>
              <div class="space-y-2 font-mono text-xs">
                <div class="flex items-center gap-2">
                  <span class="w-6 opacity-60">P1</span>
                  <div class="flex-1 flex h-5">
                    <%= for i <- 0..11 do %>
                      <div class={"flex-1 " <> if(i < 8, do: "bg-error/60", else: "bg-base-100/30") <> coop_tick_highlight(@sim_tick, i)}></div>
                    <% end %>
                  </div>
                  <span class="text-error text-xs">CPU hog!</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="w-6 opacity-60">P2</span>
                  <div class="flex-1 flex h-5">
                    <%= for i <- 0..11 do %>
                      <div class={"flex-1 " <> if(i >= 8 and i < 10, do: "bg-info/60", else: "bg-base-100/30") <> coop_tick_highlight(@sim_tick, i)}></div>
                    <% end %>
                  </div>
                  <span class="text-warning text-xs">Starved</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="w-6 opacity-60">P3</span>
                  <div class="flex-1 flex h-5">
                    <%= for i <- 0..11 do %>
                      <div class={"flex-1 " <> if(i >= 10, do: "bg-warning/60", else: "bg-base-100/30") <> coop_tick_highlight(@sim_tick, i)}></div>
                    <% end %>
                  </div>
                  <span class="text-warning text-xs">Starved</span>
                </div>
              </div>
              <div class="text-xs opacity-50 mt-2">CPU hog blocks event loop until it yields</div>
            </div>
          </div>

          <div class="flex gap-2">
            <button phx-click="run_sim" phx-target={@myself} class={"btn btn-sm " <> if(@sim_running, do: "btn-disabled", else: "btn-primary")}>
              <%= if @sim_running, do: "Running...", else: "Run Animation" %>
            </button>
            <button phx-click="reset_sim" phx-target={@myself} class="btn btn-sm btn-ghost">Reset</button>
          </div>
        </div>
      </div>

      <!-- Priority Levels -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Priority Levels</h3>
          <p class="text-xs opacity-60 mb-4">
            Priority controls how <strong>often</strong> a process is picked from the run queue,
            not how much CPU it gets per turn. Every process still gets ~4000 reductions per timeslice.
          </p>

          <div class="space-y-2">
            <%= for p <- priority_levels() do %>
              <div class={"flex items-center gap-3 p-3 rounded-lg border border-" <> p.color <> "/30 bg-" <> p.color <> "/10"}>
                <span class={"badge badge-" <> p.color <> " font-mono text-xs min-w-[80px] justify-center"}><%= p.level %></span>
                <div class="flex-1">
                  <div class="text-sm font-bold"><%= p.runs %></div>
                  <div class="text-xs opacity-70"><%= p.desc %></div>
                </div>
                <%= if p.level == ":max" do %>
                  <span class="badge badge-error badge-sm">DANGER</span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Live Scheduler Info -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Live Scheduler Info</h3>
            <button
              phx-click="inspect_schedulers"
              phx-target={@myself}
              class="btn btn-xs btn-accent"
            >
              Inspect This Node
            </button>
          </div>

          <%= if @show_scheduler_info do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Property</th>
                    <th>Value</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for {key, value, desc} <- @scheduler_info do %>
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

      <!-- Cross-Runtime Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">BEAM vs Node.js vs Go</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Aspect</th>
                    <th class="text-success">BEAM</th>
                    <th>Node.js</th>
                    <th>Go</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- comparison() do %>
                    <tr>
                      <td class="font-bold text-xs"><%= row.aspect %></td>
                      <td class="text-xs text-success"><%= row.beam %></td>
                      <td class="text-xs opacity-70"><%= row.nodejs %></td>
                      <td class="text-xs opacity-70"><%= row.go %></td>
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
              <span><strong>Preemptive scheduling</strong> — the BEAM forcibly pauses processes after ~4000 reductions. No process can starve others.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Reductions</strong> are the scheduling currency. Each function call costs ~1 reduction. This is how the scheduler measures work.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Priority controls frequency</strong>, not throughput. A :high process is picked more often but still gets the same timeslice.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Don't use :max priority</strong> — it's reserved for BEAM internals and will cause system instability.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Almost never change priority</strong> — the default scheduling is excellent. Use concurrency and backpressure instead.</span>
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

  def handle_event("run_sim", _params, socket) do
    if socket.assigns.sim_running do
      {:noreply, socket}
    else
      schedule_sim_tick()
      {:noreply, assign(socket, sim_running: true, sim_tick: 0)}
    end
  end

  def handle_event("reset_sim", _params, socket) do
    {:noreply, assign(socket, sim_running: false, sim_tick: 0)}
  end

  def handle_event("inspect_schedulers", _params, socket) do
    info = build_scheduler_info()
    {:noreply, assign(socket, scheduler_info: info, show_scheduler_info: true)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  # Info handler (forwarded from host LiveView via update(%{info_msg: msg}))

  def handle_info(:sim_tick, socket) do
    if socket.assigns.sim_running do
      new_tick = socket.assigns.sim_tick + 1

      if new_tick > 11 do
        {:noreply, assign(socket, sim_running: false, sim_tick: 12)}
      else
        schedule_sim_tick()
        {:noreply, assign(socket, sim_tick: new_tick)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # Helpers

  defp examples, do: @examples
  defp priority_levels, do: @priority_levels
  defp comparison, do: @comparison

  defp schedule_sim_tick do
    Process.send_after(self(), :sim_tick, 200)
  end

  defp build_scheduler_info do
    schedulers = System.schedulers_online()
    dirty_cpu = :erlang.system_info(:dirty_cpu_schedulers)
    dirty_io = :erlang.system_info(:dirty_io_schedulers)
    process_count = :erlang.system_info(:process_count)
    process_limit = :erlang.system_info(:process_limit)
    run_queue = :erlang.statistics(:run_queue)
    {:reductions, {total_reductions, _since_last}} = :erlang.statistics(:reductions)
    otp_release = :erlang.system_info(:otp_release) |> to_string()
    {:priority, my_priority} = Process.info(self(), :priority)

    [
      {"schedulers_online", "#{schedulers}", "Normal scheduler threads (one per core)"},
      {"dirty_cpu_schedulers", "#{dirty_cpu}", "For CPU-bound NIFs"},
      {"dirty_io_schedulers", "#{dirty_io}", "For blocking I/O NIFs"},
      {"process_count", "#{process_count}", "Currently alive processes"},
      {"process_limit", "#{process_limit}", "Maximum allowed processes"},
      {"run_queue_length", "#{run_queue}", "Processes waiting to be scheduled right now"},
      {"total_reductions", "#{total_reductions}", "Total reductions across all processes"},
      {"this_process_priority", "#{my_priority}", "Priority of this LiveView process"},
      {"otp_release", otp_release, "Erlang/OTP version"}
    ]
  end

  defp beam_tick_highlight(sim_tick, i) do
    if sim_tick == i, do: " ring-2 ring-white", else: ""
  end

  defp coop_tick_highlight(sim_tick, i) do
    if sim_tick == i, do: " ring-2 ring-white", else: ""
  end
end
