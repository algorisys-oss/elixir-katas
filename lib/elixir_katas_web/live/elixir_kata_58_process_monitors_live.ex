defmodule ElixirKatasWeb.ElixirKata58ProcessMonitorsLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "basic_monitor",
      title: "Basic Monitor",
      code: "pid = spawn(fn -> Process.sleep(500) end)\nref = Process.monitor(pid)\n\nreceive do\n  {:DOWN, ^ref, :process, ^pid, reason} ->\n    IO.inspect(reason)\nend",
      result: ":normal",
      explanation: "Process.monitor/1 returns a reference. When the monitored process exits, a :DOWN message is sent to the monitor owner."
    },
    %{
      id: "crash_monitor",
      title: "Monitor a Crash",
      code: "pid = spawn(fn -> raise \"boom!\" end)\nref = Process.monitor(pid)\n\nreceive do\n  {:DOWN, ^ref, :process, ^pid, reason} ->\n    IO.inspect(reason)\nend",
      result: ~s|{%RuntimeError{message: "boom!"}, [...]}|,
      explanation: "When a monitored process crashes, the :DOWN message includes the crash reason. The monitoring process is NOT killed."
    },
    %{
      id: "unidirectional",
      title: "Unidirectional",
      code: "# Monitor is one-way:\n# A monitors B\n# B crashes -> A gets :DOWN message\n# A crashes -> B is NOT affected\n\npid = spawn(fn -> Process.sleep(5000) end)\n_ref = Process.monitor(pid)\n# If WE crash, pid keeps running",
      result: "Monitor is one-way only",
      explanation: "Unlike links, monitors are unidirectional. The monitored process does not even know it is being monitored."
    },
    %{
      id: "demonitor",
      title: "Process.demonitor/1",
      code: "pid = spawn(fn -> Process.sleep(5000) end)\nref = Process.monitor(pid)\n\nProcess.demonitor(ref)\n# No more :DOWN messages\n\nProcess.demonitor(ref, [:flush])\n# Also removes any :DOWN already in mailbox",
      result: "true",
      explanation: "demonitor/1 cancels a monitor. The :flush option also removes any :DOWN message already in the mailbox."
    },
    %{
      id: "down_format",
      title: ":DOWN Message Format",
      code: "# The :DOWN message always has this shape:\n{:DOWN, ref, :process, pid, reason}\n\n# ref    - the monitor reference\n# pid    - the monitored process PID\n# reason - :normal, :killed, or crash info",
      result: "{:DOWN, #Reference<...>, :process, #PID<...>, reason}",
      explanation: "The :DOWN tuple has 5 elements. You can pattern match on ref and pid to know which monitor triggered."
    }
  ]

  @comparison_rows [
    %{aspect: "Direction", link: "Bidirectional", monitor: "Unidirectional"},
    %{aspect: "On crash", link: "Other process crashes too", monitor: "Gets :DOWN message"},
    %{aspect: "Setup", link: "spawn_link/1 or Process.link/1", monitor: "Process.monitor/1"},
    %{aspect: "Teardown", link: "Process.unlink/1", monitor: "Process.demonitor/1"},
    %{aspect: "Multiple?", link: "One link per pair", monitor: "Can have many monitors"},
    %{aspect: "Awareness", link: "Both processes know", monitor: "Monitored process unaware"},
    %{aspect: "Use case", link: "Supervision, co-dependent", monitor: "Observation, health checks"},
    %{aspect: "Normal exit", link: "No crash signal", monitor: "Still gets :DOWN with :normal"}
  ]

  @demo_scenarios [
    %{
      id: "monitor_normal",
      title: "Normal Exit",
      steps: [
        %{label: "A monitors B", a: "alive", b: "alive", arrow: "monitoring", msg: nil},
        %{label: "B exits normally", a: "alive", b: "exited", arrow: "monitoring", msg: nil},
        %{label: "A gets :DOWN", a: "alive", b: "dead", arrow: nil, msg: "{:DOWN, ref, :process, pid, :normal}"}
      ]
    },
    %{
      id: "monitor_crash",
      title: "Crash",
      steps: [
        %{label: "A monitors B", a: "alive", b: "alive", arrow: "monitoring", msg: nil},
        %{label: "B crashes!", a: "alive", b: "crashed", arrow: "monitoring", msg: nil},
        %{label: "A gets :DOWN (with reason)", a: "alive", b: "dead", arrow: nil, msg: "{:DOWN, ref, :process, pid, {error, stacktrace}}"}
      ]
    },
    %{
      id: "monitor_vs_link",
      title: "Monitor vs Link on Crash",
      steps: [
        %{label: "A monitors B, C linked to D", a: "alive", b: "alive", arrow: "monitoring", msg: "C alive, D alive (linked)"},
        %{label: "B and D both crash!", a: "alive", b: "crashed", arrow: "monitoring", msg: "C crashing, D crashed (link propagates)"},
        %{label: "A survives, C dies", a: "alive", b: "dead", arrow: nil, msg: "A gets :DOWN safely. C is dead (killed by link)."}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:active_scenario, fn -> hd(@demo_scenarios) end)
     |> assign_new(:scenario_step, fn -> 0 end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:monitor_log, fn -> [] end)
     |> assign_new(:monitored_procs, fn -> [] end)
     |> assign_new(:next_id, fn -> 1 end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Process Monitors</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Monitors</strong> let you observe a process without being affected by its fate.
        When a monitored process exits (for any reason), the monitor owner receives a
        <code class="font-mono bg-base-300 px-1 rounded">&lbrace;:DOWN, ref, :process, pid, reason&rbrace;</code>
        message instead of crashing.
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

      <!-- Interactive Monitor Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Monitor</h3>
          <p class="text-xs opacity-60 mb-4">
            Spawn monitored processes, then crash or stop them. Watch the :DOWN messages arrive.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <button phx-click="spawn_monitored" phx-target={@myself} class="btn btn-sm btn-primary">
              Spawn &amp; Monitor
            </button>
            <button phx-click="spawn_monitored_crash" phx-target={@myself} class="btn btn-sm btn-warning">
              Spawn &amp; Monitor (will crash)
            </button>
            <button phx-click="clear_monitor_log" phx-target={@myself} class="btn btn-sm btn-ghost">
              Clear All
            </button>
          </div>

          <!-- Monitored Processes -->
          <%= if length(@monitored_procs) > 0 do %>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-2 mb-4">
              <%= for proc <- @monitored_procs do %>
                <div class={"rounded-lg p-3 border text-center " <> monitor_proc_style(proc.status)}>
                  <div class="font-mono text-xs font-bold">Proc #<%= proc.id %></div>
                  <div class={"text-xs mt-1 " <> monitor_status_color(proc.status)}><%= proc.status %></div>
                  <%= if proc.status == "alive" do %>
                    <div class="flex gap-1 mt-2 justify-center">
                      <button
                        phx-click="kill_monitored"
                        phx-target={@myself}
                        phx-value-id={"#{proc.id}"}
                        class="btn btn-xs btn-error"
                      >
                        Crash
                      </button>
                      <button
                        phx-click="stop_monitored"
                        phx-target={@myself}
                        phx-value-id={"#{proc.id}"}
                        class="btn btn-xs btn-ghost"
                      >
                        Stop
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>

          <!-- Monitor Log (:DOWN messages) -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">:DOWN Message Log</div>
            <%= if length(@monitor_log) > 0 do %>
              <div class="space-y-1">
                <%= for {msg, idx} <- Enum.with_index(Enum.reverse(@monitor_log)) do %>
                  <div class="flex items-start gap-2 font-mono text-xs">
                    <span class="badge badge-warning badge-xs mt-0.5"><%= idx + 1 %></span>
                    <span class={"" <> if(String.contains?(msg, ":normal"), do: "text-success", else: "text-error")}><%= msg %></span>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-xs opacity-40 text-center py-2">No :DOWN messages yet. Spawn and crash a process.</div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Step-Through Scenarios -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Visual Scenarios</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for scenario <- demo_scenarios() do %>
              <button
                phx-click="select_scenario"
                phx-target={@myself}
                phx-value-id={scenario.id}
                class={"btn btn-xs " <> if(@active_scenario.id == scenario.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= scenario.title %>
              </button>
            <% end %>
          </div>

          <% current = Enum.at(@active_scenario.steps, @scenario_step, hd(@active_scenario.steps)) %>
          <div class="bg-base-300 rounded-lg p-6 mb-4">
            <div class="flex items-center justify-center gap-8 mb-4">
              <!-- Process A (monitor owner) -->
              <div class={"w-28 h-20 rounded-xl border-2 flex flex-col items-center justify-center " <> scenario_proc_style(current.a)}>
                <div class="font-bold text-xs">A (owner)</div>
                <div class="text-xs mt-1"><%= current.a %></div>
              </div>

              <!-- Arrow -->
              <div class="flex flex-col items-center">
                <%= if current.arrow do %>
                  <div class="text-xs text-accent mb-1"><%= current.arrow %></div>
                  <div class="w-12 h-0.5 bg-accent"></div>
                  <div class="text-accent text-xs">&rarr;</div>
                <% else %>
                  <div class="w-12 h-0.5 bg-base-content/10"></div>
                <% end %>
              </div>

              <!-- Process B (monitored) -->
              <div class={"w-28 h-20 rounded-xl border-2 flex flex-col items-center justify-center " <> scenario_proc_style(current.b)}>
                <div class="font-bold text-xs">B (target)</div>
                <div class="text-xs mt-1"><%= current.b %></div>
              </div>
            </div>

            <div class="text-center">
              <span class="badge badge-lg mb-2"><%= current.label %></span>
              <%= if current.msg do %>
                <div class="font-mono text-xs mt-2 text-warning"><%= current.msg %></div>
              <% end %>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <button phx-click="scenario_back" phx-target={@myself} disabled={@scenario_step <= 0} class="btn btn-sm btn-outline">&larr; Back</button>
            <button phx-click="scenario_forward" phx-target={@myself} disabled={@scenario_step >= length(@active_scenario.steps) - 1} class="btn btn-sm btn-primary">Forward &rarr;</button>
            <span class="text-xs opacity-50 ml-2">Step <%= @scenario_step + 1 %> / <%= length(@active_scenario.steps) %></span>
          </div>
        </div>
      </div>

      <!-- Links vs Monitors -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Links vs Monitors</h3>
            <button phx-click="toggle_comparison" phx-target={@myself} class="btn btn-xs btn-ghost">
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Aspect</th>
                    <th class="text-error">Links</th>
                    <th class="text-accent">Monitors</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- comparison_rows() do %>
                    <tr>
                      <td class="font-bold"><%= row.aspect %></td>
                      <td><%= row.link %></td>
                      <td><%= row.monitor %></td>
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
              <span><strong>Process.monitor/1</strong> is unidirectional: the monitor owner observes but is not affected by crashes.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>When the monitored process exits, a <strong>&lbrace;:DOWN, ref, :process, pid, reason&rbrace;</strong> message is sent.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Monitors report <strong>all exits</strong> including normal ones. Links only propagate abnormal exits.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Process.demonitor(ref, [:flush])</strong> cancels a monitor and clears pending :DOWN messages.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Use <strong>monitors</strong> when you need to know about exits. Use <strong>links</strong> when you need to die together.</span>
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

  def handle_event("spawn_monitored", _params, socket) do
    id = socket.assigns.next_id
    proc = %{id: id, status: "alive", will_crash: false}
    Process.send_after(self(), {:proc_exit, id, "exited", ":normal"}, 5000)
    {:noreply,
     socket
     |> assign(monitored_procs: socket.assigns.monitored_procs ++ [proc])
     |> assign(next_id: id + 1)}
  end

  def handle_event("spawn_monitored_crash", _params, socket) do
    id = socket.assigns.next_id
    proc = %{id: id, status: "alive", will_crash: true}
    Process.send_after(self(), {:proc_exit, id, "crashed", ~s|{:error, "boom!"}|}, 2000)
    {:noreply,
     socket
     |> assign(monitored_procs: socket.assigns.monitored_procs ++ [proc])
     |> assign(next_id: id + 1)}
  end

  def handle_event("kill_monitored", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    procs = Enum.map(socket.assigns.monitored_procs, fn proc ->
      if proc.id == id, do: %{proc | status: "crashed"}, else: proc
    end)
    log_entry = "{:DOWN, #Ref<...>, :process, Proc##{id}, {:error, :killed}}"
    {:noreply,
     socket
     |> assign(monitored_procs: procs)
     |> assign(monitor_log: [log_entry | socket.assigns.monitor_log])}
  end

  def handle_event("stop_monitored", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    procs = Enum.map(socket.assigns.monitored_procs, fn proc ->
      if proc.id == id, do: %{proc | status: "exited"}, else: proc
    end)
    log_entry = "{:DOWN, #Ref<...>, :process, Proc##{id}, :normal}"
    {:noreply,
     socket
     |> assign(monitored_procs: procs)
     |> assign(monitor_log: [log_entry | socket.assigns.monitor_log])}
  end

  def handle_event("clear_monitor_log", _params, socket) do
    {:noreply, assign(socket, monitor_log: [], monitored_procs: [], next_id: 1)}
  end

  def handle_event("select_scenario", %{"id" => id}, socket) do
    scenario = Enum.find(demo_scenarios(), &(&1.id == id))
    {:noreply, assign(socket, active_scenario: scenario, scenario_step: 0)}
  end

  def handle_event("scenario_forward", _params, socket) do
    max = length(socket.assigns.active_scenario.steps) - 1
    {:noreply, assign(socket, scenario_step: min(socket.assigns.scenario_step + 1, max))}
  end

  def handle_event("scenario_back", _params, socket) do
    {:noreply, assign(socket, scenario_step: max(socket.assigns.scenario_step - 1, 0))}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("proc_exited", %{"id" => id_str, "status" => status, "reason" => reason}, socket) do
    id = String.to_integer(id_str)
    procs = Enum.map(socket.assigns.monitored_procs, fn proc ->
      if proc.id == id && proc.status == "alive", do: %{proc | status: status}, else: proc
    end)
    log_entry = "{:DOWN, #Ref<...>, :process, Proc##{id}, #{reason}}"
    {:noreply,
     socket
     |> assign(monitored_procs: procs)
     |> assign(monitor_log: [log_entry | socket.assigns.monitor_log])}
  end

  # Helpers

  defp examples, do: @examples
  defp comparison_rows, do: @comparison_rows
  defp demo_scenarios, do: @demo_scenarios

  defp monitor_proc_style("alive"), do: "border-success/40 bg-success/10"
  defp monitor_proc_style("exited"), do: "border-base-content/20 bg-base-100 opacity-50"
  defp monitor_proc_style("crashed"), do: "border-error/40 bg-error/10"
  defp monitor_proc_style(_), do: "border-base-content/20 bg-base-100"

  defp monitor_status_color("alive"), do: "text-success"
  defp monitor_status_color("exited"), do: "opacity-50"
  defp monitor_status_color("crashed"), do: "text-error font-bold"
  defp monitor_status_color(_), do: "opacity-50"

  defp scenario_proc_style("alive"), do: "border-success bg-success/10"
  defp scenario_proc_style("exited"), do: "border-base-content/20 bg-base-100 opacity-50"
  defp scenario_proc_style("crashed"), do: "border-error bg-error/20"
  defp scenario_proc_style("dead"), do: "border-error/20 bg-base-100 opacity-30"
  defp scenario_proc_style(_), do: "border-base-content/10 bg-base-100"
end
