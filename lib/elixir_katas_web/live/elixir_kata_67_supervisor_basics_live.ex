defmodule ElixirKatasWeb.ElixirKata67SupervisorBasicsLive do
  use ElixirKatasWeb, :live_component

  @strategies [
    %{
      id: "one_for_one",
      name: ":one_for_one",
      description: "If a child process crashes, only that process is restarted. Other children are unaffected.",
      when_to_use: "Children are independent. Crashing one doesn't affect the others.",
      example: "Web request handlers, independent worker pools, per-user GenServers.",
      color: "text-blue-500",
      bg: "bg-blue-500/10",
      border: "border-blue-500/30"
    },
    %{
      id: "one_for_all",
      name: ":one_for_all",
      description: "If any child crashes, ALL children are terminated and restarted together.",
      when_to_use: "Children are tightly coupled. If one fails, the others' state is invalid.",
      example: "Database connection + connection pool, tightly coupled producer/consumer pairs.",
      color: "text-red-500",
      bg: "bg-red-500/10",
      border: "border-red-500/30"
    },
    %{
      id: "rest_for_one",
      name: ":rest_for_one",
      description: "If a child crashes, that child and all children started AFTER it are terminated and restarted.",
      when_to_use: "Children have ordered dependencies. Later children depend on earlier ones.",
      example: "Config server -> Cache -> API client (cache depends on config, API depends on cache).",
      color: "text-amber-500",
      bg: "bg-amber-500/10",
      border: "border-amber-500/30"
    }
  ]

  defp initial_children do
    [
      %{id: "A", name: "Worker A", status: :running, order: 1},
      %{id: "B", name: "Worker B", status: :running, order: 2},
      %{id: "C", name: "Worker C", status: :running, order: 3},
      %{id: "D", name: "Worker D", status: :running, order: 4}
    ]
  end

  # Forward info_msg from the host LiveView
  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:__initialized__] do
      {:ok, assign(socket, assigns)}
    else
      socket = assign(socket, assigns)
      socket = assign(socket, :__initialized__, true)

      {:ok,
       socket
       |> assign_new(:active_section, fn -> "strategies" end)
       |> assign_new(:selected_strategy, fn -> "one_for_one" end)
       |> assign_new(:sim_strategy, fn -> "one_for_one" end)
       |> assign_new(:sim_children, fn -> initial_children() end)
       |> assign_new(:sim_log, fn -> [] end)
       |> assign_new(:sim_restarts, fn -> 0 end)
       |> assign_new(:show_child_spec, fn -> false end)
       |> assign_new(:show_max_restarts, fn -> false end)
       |> assign_new(:max_restarts, fn -> 3 end)
       |> assign_new(:max_seconds, fn -> 5 end)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <h2 class="text-2xl font-bold mb-2">Supervisor Basics</h2>
        <p class="text-sm opacity-70 mb-6">
          Supervisors monitor child processes and restart them when they crash. This is the foundation
          of Elixir's "let it crash" philosophy: instead of defensive error handling everywhere,
          let processes crash and have supervisors restart them in a known good state.
        </p>

        <!-- Section Tabs -->
        <div class="tabs tabs-boxed mb-6 bg-base-200">
          <button
            :for={tab <- [{"strategies", "Restart Strategies"}, {"simulate", "Simulate Crashes"}, {"childspec", "Child Spec"}, {"limits", "Restart Limits"}]}
            phx-click="set_section"
            phx-target={@myself}
            phx-value-section={elem(tab, 0)}
            class={"tab " <> if(@active_section == elem(tab, 0), do: "tab-active", else: "")}
          >
            {elem(tab, 1)}
          </button>
        </div>

        <!-- Restart Strategies -->
        <div :if={@active_section == "strategies"} class="space-y-4">
          <div class="space-y-3">
            <div
              :for={strat <- strategies()}
              class={"card border-2 cursor-pointer transition-all hover:shadow-md " <>
                if(@selected_strategy == strat.id, do: "#{strat.border} shadow-md", else: "border-base-300")}
              phx-click="select_strategy"
              phx-target={@myself}
              phx-value-id={strat.id}
            >
              <div class="card-body p-4">
                <div class="flex items-center justify-between mb-2">
                  <h3 class={"card-title text-sm font-mono #{strat.color}"}>{strat.name}</h3>
                </div>
                <p class="text-sm">{strat.description}</p>

                <div :if={@selected_strategy == strat.id} class="mt-3 space-y-3">
                  <div class={"rounded-lg p-3 #{strat.bg}"}>
                    <span class="text-xs font-bold opacity-60">WHEN TO USE: </span>
                    <span class="text-sm">{strat.when_to_use}</span>
                  </div>
                  <div class="text-xs opacity-60">
                    <span class="font-bold">Examples: </span>{strat.example}
                  </div>

                  <!-- Visual diagram for each strategy -->
                  <div class="bg-base-300 rounded-lg p-4">
                    <div class="text-xs font-bold opacity-60 mb-3">When Worker B crashes:</div>
                    <div class="flex gap-2 items-end">
                      <div
                        :for={w <- ["A", "B", "C", "D"]}
                        class={"flex-1 rounded-lg p-2 text-center text-xs font-bold transition-all " <>
                          cond do
                            w == "B" -> "bg-error/20 border-2 border-error text-error line-through"
                            strat.id == "one_for_one" -> "bg-success/20 border-2 border-success text-success"
                            strat.id == "one_for_all" -> "bg-error/20 border-2 border-error text-error"
                            strat.id == "rest_for_one" and w > "B" -> "bg-error/20 border-2 border-error text-error"
                            true -> "bg-success/20 border-2 border-success text-success"
                          end}
                      >
                        {w}
                        <div class="text-[10px] font-normal mt-1">
                          {cond do
                            w == "B" -> "crashed"
                            strat.id == "one_for_one" -> "unaffected"
                            strat.id == "one_for_all" -> "restarted"
                            strat.id == "rest_for_one" and w > "B" -> "restarted"
                            true -> "unaffected"
                          end}
                        </div>
                      </div>
                    </div>
                    <div class="text-center text-xs opacity-50 mt-2">
                      Then all affected processes restart in order.
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Simulate Crashes -->
        <div :if={@active_section == "simulate"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">Supervision Tree Simulator</h3>
                <span class="badge badge-primary font-mono">{@sim_strategy}</span>
              </div>

              <!-- Strategy Picker -->
              <div class="flex gap-2 mb-4">
                <button
                  :for={strat <- ["one_for_one", "one_for_all", "rest_for_one"]}
                  phx-click="sim_set_strategy"
                  phx-target={@myself}
                  phx-value-strategy={strat}
                  class={"btn btn-xs " <> if(@sim_strategy == strat, do: "btn-primary", else: "btn-outline")}
                >
                  {strat}
                </button>
              </div>

              <!-- Children Display -->
              <div class="grid grid-cols-4 gap-3 mb-4">
                <div
                  :for={child <- @sim_children}
                  class={"rounded-lg p-3 text-center border-2 transition-all " <>
                    case child.status do
                      :running -> "border-success bg-success/10"
                      :crashed -> "border-error bg-error/10 animate-pulse"
                      :restarting -> "border-warning bg-warning/10 animate-pulse"
                    end}
                >
                  <div class={"text-lg font-bold " <>
                    case child.status do
                      :running -> "text-success"
                      :crashed -> "text-error"
                      :restarting -> "text-warning"
                    end}>
                    {child.id}
                  </div>
                  <div class="text-xs opacity-60">{child.name}</div>
                  <div class={"text-xs font-mono mt-1 " <>
                    case child.status do
                      :running -> "text-success"
                      :crashed -> "text-error"
                      :restarting -> "text-warning"
                    end}>
                    {child.status}
                  </div>
                  <button
                    :if={child.status == :running}
                    phx-click="sim_crash"
                    phx-target={@myself}
                    phx-value-id={child.id}
                    class="btn btn-xs btn-error mt-2"
                  >
                    Crash!
                  </button>
                </div>
              </div>

              <div class="flex items-center justify-between">
                <span class="text-xs opacity-60">
                  Total restarts: <span class="font-bold">{@sim_restarts}</span>
                </span>
                <button
                  phx-click="sim_reset"
                  phx-target={@myself}
                  class="btn btn-xs btn-ghost"
                >
                  Reset All
                </button>
              </div>
            </div>
          </div>

          <!-- Log -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Supervisor Log</h3>
              <div :if={@sim_log == []} class="text-sm opacity-50 text-center py-4">
                Click "Crash!" on a worker to see the supervisor in action.
              </div>
              <div class="space-y-1">
                <div
                  :for={entry <- Enum.take(@sim_log, 12)}
                  class={"rounded px-3 py-2 text-xs font-mono border-l-4 " <> entry.border}
                >
                  {entry.message}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Child Spec -->
        <div :if={@active_section == "childspec"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Child Specification</h3>
              <p class="text-xs opacity-60 mb-4">
                A child spec tells the supervisor how to start, stop, and restart a child process.
                Every supervised process needs one.
              </p>

              <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-4">{child_spec_code()}</div>

              <h4 class="text-sm font-bold mb-2">Restart Values</h4>
              <div class="overflow-x-auto mb-4">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Value</th>
                      <th>Restart when...</th>
                      <th>Use for</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td class="font-mono text-success">:permanent</td>
                      <td>Always restarted (default)</td>
                      <td>Long-running servers that should always be up</td>
                    </tr>
                    <tr>
                      <td class="font-mono text-warning">:transient</td>
                      <td>Only if it crashes (abnormal exit)</td>
                      <td>Tasks that should complete but can retry on error</td>
                    </tr>
                    <tr>
                      <td class="font-mono text-error">:temporary</td>
                      <td>Never restarted</td>
                      <td>One-off tasks, fire-and-forget work</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <h4 class="text-sm font-bold mb-2">Shorthand with use GenServer</h4>
              <p class="text-xs opacity-60 mb-3">
                When you <code>use GenServer</code>, a default <code>child_spec/1</code> is generated automatically.
                You can override it:
              </p>

              <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap mb-4">{raw(use_genserver_code())}</div>

              <h4 class="text-sm font-bold mb-2">Starting a Supervisor</h4>
              <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">{raw(start_supervisor_code())}</div>
            </div>
          </div>
        </div>

        <!-- Restart Limits -->
        <div :if={@active_section == "limits"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">max_restarts and max_seconds</h3>
              <p class="text-xs opacity-60 mb-4">
                Supervisors have built-in circuit breakers. If a child crashes too many times
                in a time window, the supervisor itself shuts down (and its parent supervisor handles that).
              </p>

              <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap mb-4">{raw(max_restarts_code())}</div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div class="bg-base-300 rounded-lg p-4">
                  <h4 class="text-sm font-bold mb-2">max_restarts (default: 3)</h4>
                  <p class="text-xs opacity-60">
                    Maximum number of restarts allowed within the time window.
                    If exceeded, the supervisor terminates all children and exits.
                  </p>
                </div>
                <div class="bg-base-300 rounded-lg p-4">
                  <h4 class="text-sm font-bold mb-2">max_seconds (default: 5)</h4>
                  <p class="text-xs opacity-60">
                    The time window in seconds. Restarts older than this are not counted.
                    This is a rolling window, not a fixed one.
                  </p>
                </div>
              </div>

              <!-- Interactive Demo -->
              <h4 class="text-sm font-bold mb-2">Visualize the Circuit Breaker</h4>
              <div class="flex items-center gap-4 mb-3">
                <div class="form-control">
                  <label class="label py-0"><span class="label-text text-xs">max_restarts</span></label>
                  <input
                    type="number"
                    min="1"
                    max="10"
                    value={@max_restarts}
                    phx-change="set_max_restarts"
                    phx-target={@myself}
                    name="value"
                    class="input input-bordered input-sm w-20 font-mono"
                  />
                </div>
                <div class="form-control">
                  <label class="label py-0"><span class="label-text text-xs">max_seconds</span></label>
                  <input
                    type="number"
                    min="1"
                    max="30"
                    value={@max_seconds}
                    phx-change="set_max_seconds"
                    phx-target={@myself}
                    name="value"
                    class="input input-bordered input-sm w-20 font-mono"
                  />
                </div>
              </div>

              <div class="bg-base-300 rounded-lg p-4">
                <div class="text-sm mb-2">
                  With <span class="font-mono font-bold text-primary">max_restarts: {@max_restarts}</span> and
                  <span class="font-mono font-bold text-primary">max_seconds: {@max_seconds}</span>:
                </div>
                <div class="text-xs space-y-1 opacity-70">
                  <p>If a child crashes <strong>{@max_restarts + 1} times</strong> within <strong>{@max_seconds} seconds</strong>, the supervisor shuts down.</p>
                  <p>This means up to <strong>{@max_restarts} restarts</strong> are tolerated in any {@max_seconds}-second window.</p>
                  <p>Sustained crash rate above <strong>{Float.round(@max_restarts / @max_seconds, 2)} crashes/sec</strong> will trigger shutdown.</p>
                </div>
              </div>

              <div class="alert alert-info mt-4">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                <div>
                  <h4 class="font-bold text-sm">Why limit restarts?</h4>
                  <p class="text-xs">
                    If a child keeps crashing (e.g., bad config, missing dependency), restarting forever wastes
                    resources and hides the problem. The supervisor "gives up" and escalates to its parent supervisor,
                    which can try a broader recovery strategy. This is the supervision tree in action.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Key Concepts -->
        <div class="card bg-base-200 shadow-md mt-6">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-3">Key Concepts</h3>
            <div class="space-y-3 text-sm">
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">1</span>
                <span>
                  <strong>Let it crash:</strong> Don't try to handle every error. Let the process crash
                  and the supervisor restart it in a clean state.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">2</span>
                <span>
                  <strong>Choose the right strategy:</strong> <code>:one_for_one</code> for independent children,
                  <code>:one_for_all</code> for tightly coupled, <code>:rest_for_one</code> for ordered dependencies.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">3</span>
                <span>
                  <strong>Child order matters:</strong> Children start in list order and stop in reverse order.
                  Put dependencies first.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">4</span>
                <span>
                  <strong>Restart limits are circuit breakers:</strong> <code>max_restarts</code> and
                  <code>max_seconds</code> prevent infinite restart loops. The default (3 in 5 seconds) works
                  for most cases.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">5</span>
                <span>
                  <strong>Supervision trees:</strong> Supervisors can supervise other supervisors,
                  forming a tree. Failures propagate up, and each level can choose its recovery strategy.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("set_section", %{"section" => section}, socket) do
    {:noreply, assign(socket, active_section: section)}
  end

  def handle_event("select_strategy", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_strategy: id)}
  end

  def handle_event("sim_set_strategy", %{"strategy" => strategy}, socket) do
    {:noreply,
     socket
     |> assign(sim_strategy: strategy)
     |> assign(sim_children: initial_children())
     |> assign(sim_log: [])
     |> assign(sim_restarts: 0)}
  end

  def handle_event("sim_crash", %{"id" => crashed_id}, socket) do
    strategy = socket.assigns.sim_strategy
    children = socket.assigns.sim_children

    # Determine which children are affected
    {affected_ids, log_entries} = apply_strategy(strategy, crashed_id, children)

    # Mark affected as crashed
    crashed_children =
      Enum.map(children, fn child ->
        if child.id in affected_ids do
          %{child | status: :crashed}
        else
          child
        end
      end)

    # Then mark as restarting (simulates restart)
    restarted_children =
      Enum.map(crashed_children, fn child ->
        if child.id in affected_ids do
          %{child | status: :restarting}
        else
          child
        end
      end)

    restart_count = length(affected_ids)

    # Schedule the "restarted" state
    Process.send_after(self(), {:sim_restart_complete, affected_ids}, 800)

    {:noreply,
     socket
     |> assign(sim_children: restarted_children)
     |> assign(sim_restarts: socket.assigns.sim_restarts + restart_count)
     |> assign(sim_log: log_entries ++ socket.assigns.sim_log)}
  end

  def handle_event("sim_reset", _params, socket) do
    {:noreply,
     socket
     |> assign(sim_children: initial_children())
     |> assign(sim_log: [])
     |> assign(sim_restarts: 0)}
  end

  def handle_event("set_max_restarts", %{"value" => val}, socket) do
    {:noreply, assign(socket, max_restarts: String.to_integer(val))}
  end

  def handle_event("set_max_seconds", %{"value" => val}, socket) do
    {:noreply, assign(socket, max_seconds: String.to_integer(val))}
  end

  def handle_info({:sim_restart_complete, affected_ids}, socket) do
    updated_children =
      Enum.map(socket.assigns.sim_children, fn child ->
        if child.id in affected_ids do
          %{child | status: :running}
        else
          child
        end
      end)

    {:noreply, assign(socket, sim_children: updated_children)}
  end

  defp apply_strategy("one_for_one", crashed_id, _children) do
    log = [
      %{message: "Worker #{crashed_id} crashed!", border: "border-error"},
      %{message: "[one_for_one] Restarting only Worker #{crashed_id}", border: "border-blue-500"},
      %{message: "Worker #{crashed_id} restarted successfully", border: "border-success"}
    ]

    {[crashed_id], log}
  end

  defp apply_strategy("one_for_all", crashed_id, children) do
    all_ids = Enum.map(children, & &1.id)

    log = [
      %{message: "Worker #{crashed_id} crashed!", border: "border-error"},
      %{message: "[one_for_all] Terminating ALL workers: #{Enum.join(all_ids, ", ")}", border: "border-red-500"},
      %{message: "Restarting all workers in order: #{Enum.join(all_ids, " -> ")}", border: "border-success"}
    ]

    {all_ids, log}
  end

  defp apply_strategy("rest_for_one", crashed_id, children) do
    crashed_order =
      children
      |> Enum.find(&(&1.id == crashed_id))
      |> Map.get(:order)

    affected =
      children
      |> Enum.filter(&(&1.order >= crashed_order))
      |> Enum.map(& &1.id)

    log = [
      %{message: "Worker #{crashed_id} crashed!", border: "border-error"},
      %{message: "[rest_for_one] Terminating #{crashed_id} and all after it: #{Enum.join(affected, ", ")}", border: "border-amber-500"},
      %{message: "Restarting in order: #{Enum.join(affected, " -> ")}", border: "border-success"}
    ]

    {affected, log}
  end

  defp strategies, do: @strategies

  defp use_genserver_code do
    """
    <span class="opacity-50"># Default child_spec from use GenServer:</span>
    defmodule MyWorker do
      use GenServer

      # This is auto-generated:
      # def child_spec(arg) do
      #   %{
      #     id: __MODULE__,
      #     start: {__MODULE__, :start_link, [arg]}
      #   }
      # end
    end

    <span class="opacity-50"># Override restart strategy:</span>
    defmodule MyWorker do
      use GenServer, restart: :transient
    end\
    """
  end

  defp start_supervisor_code do
    """
    children = [
      {Counter, 0},             <span class="opacity-50"># calls Counter.child_spec(0)</span>
      {Cache, name: :my_cache},  <span class="opacity-50"># calls Cache.child_spec(name: :my_cache)</span>
      {Poller, interval: 5000}   <span class="opacity-50"># calls Poller.child_spec(interval: 5000)</span>
    ]

    Supervisor.start_link(children, strategy: :one_for_one)\
    """
  end

  defp max_restarts_code do
    """
    Supervisor.start_link(children,
      strategy: :one_for_one,
      max_restarts: 3,     <span class="opacity-50"># max 3 restarts...</span>
      max_seconds: 5       <span class="opacity-50"># ...within 5 seconds</span>
    )\
    """
  end

  defp child_spec_code do
    String.trim("""
    %{
      id: MyWorker,              # unique identifier
      start: {MyWorker, :start_link, [arg]},  # MFA tuple
      restart: :permanent,       # :permanent | :temporary | :transient
      shutdown: 5000,            # ms to wait before force kill
      type: :worker              # :worker | :supervisor
    }
    """)
  end
end
