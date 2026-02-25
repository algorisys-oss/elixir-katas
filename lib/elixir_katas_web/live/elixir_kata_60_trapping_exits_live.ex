defmodule ElixirKatasWeb.ElixirKata60TrappingExitsLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "trap_exit",
      title: "Process.flag(:trap_exit, true)",
      code: "Process.flag(:trap_exit, true)\n\npid = spawn_link(fn -> raise \"boom!\" end)\n\nreceive do\n  {:EXIT, ^pid, reason} ->\n    IO.inspect(reason)\nend\n# Process stays alive!",
      result: "{%RuntimeError{message: \"boom!\"}, [...]}",
      explanation: "With trap_exit enabled, exit signals from linked processes become regular messages in the format {:EXIT, pid, reason}. The trapping process survives."
    },
    %{
      id: "exit_message_format",
      title: "EXIT Message Format",
      code: "# The EXIT message shape:\n{:EXIT, pid, reason}\n\n# pid    - the process that exited\n# reason - :normal, :kill, or error tuple\n\n# Normal exit:\n{:EXIT, pid, :normal}\n\n# Crash exit:\n{:EXIT, pid, {%RuntimeError{}, stacktrace}}",
      result: "{:EXIT, #PID<0.123.0>, reason}",
      explanation: "EXIT messages have a consistent 3-element tuple format. The reason tells you exactly how the linked process exited."
    },
    %{
      id: "supervisor_pattern",
      title: "Supervisor-like Behavior",
      code: "defmodule MySupervisor do\n  def start(child_fn) do\n    spawn(fn ->\n      Process.flag(:trap_exit, true)\n      pid = spawn_link(child_fn)\n      supervise(pid, child_fn)\n    end)\n  end\n\n  defp supervise(pid, child_fn) do\n    receive do\n      {:EXIT, ^pid, :normal} ->\n        :ok  # Child exited normally\n      {:EXIT, ^pid, _reason} ->\n        new_pid = spawn_link(child_fn)\n        supervise(new_pid, child_fn)\n    end\n  end\nend",
      result: "Automatic restart on crash!",
      explanation: "This is the core supervisor pattern: trap exits, watch for child crashes, restart them. OTP Supervisor does this (and much more) for you."
    },
    %{
      id: "normal_exit_trap",
      title: "Normal Exits When Trapping",
      code: "Process.flag(:trap_exit, true)\npid = spawn_link(fn -> :ok end)\n\nreceive do\n  {:EXIT, ^pid, :normal} ->\n    IO.puts(\"Child exited normally\")\nend",
      result: "Child exited normally",
      explanation: "When trapping exits, you receive ALL exit signals, including normal ones. Without trapping, :normal exits are silently ignored."
    },
    %{
      id: "kill_signal",
      title: "The Unstoppable :kill",
      code: "Process.flag(:trap_exit, true)\npid = spawn_link(fn -> Process.sleep(:infinity) end)\n\nProcess.exit(pid, :kill)\n\nreceive do\n  {:EXIT, ^pid, :killed} ->\n    IO.puts(\"killed!\")\nend",
      result: "killed!",
      explanation: "Process.exit(pid, :kill) sends an untrappable exit signal. Even processes trapping exits cannot survive :kill. Note the trapped reason becomes :killed."
    }
  ]

  @demo_scenarios [
    %{
      id: "no_trap",
      title: "Without Trapping",
      description: "Default behavior: linked child crash kills parent.",
      steps: [
        %{label: "Parent and child running (linked)", parent: "alive", child: "alive", trapped: false, message: nil},
        %{label: "Child crashes!", parent: "alive", child: "crashed", trapped: false, message: nil},
        %{label: "Exit signal sent via link", parent: "alive", child: "dead", trapped: false, message: "EXIT signal propagating..."},
        %{label: "Parent dies too!", parent: "dead", child: "dead", trapped: false, message: "Both dead. No recovery."}
      ]
    },
    %{
      id: "with_trap",
      title: "With Trapping",
      description: "Trapping converts exit signals to messages. Parent survives.",
      steps: [
        %{label: "Parent traps exits, child linked", parent: "trapping", child: "alive", trapped: true, message: nil},
        %{label: "Child crashes!", parent: "trapping", child: "crashed", trapped: true, message: nil},
        %{label: "Exit signal converted to message", parent: "trapping", child: "dead", trapped: true, message: "{:EXIT, child_pid, reason}"},
        %{label: "Parent receives and handles it", parent: "trapping", child: "dead", trapped: true, message: "Parent alive! Can restart child."}
      ]
    },
    %{
      id: "restart",
      title: "Trap + Restart",
      description: "Full supervisor pattern: trap exit, detect crash, restart child.",
      steps: [
        %{label: "Supervisor trapping, child running", parent: "trapping", child: "alive", trapped: true, message: nil},
        %{label: "Child crashes!", parent: "trapping", child: "crashed", trapped: true, message: nil},
        %{label: "Supervisor gets EXIT message", parent: "trapping", child: "dead", trapped: true, message: "{:EXIT, old_pid, reason}"},
        %{label: "Supervisor spawns new child", parent: "trapping", child: "restarting", trapped: true, message: "spawn_link(child_fn)"},
        %{label: "New child running!", parent: "trapping", child: "alive", trapped: true, message: "Recovered! New PID assigned."}
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
     |> assign_new(:trap_enabled, fn -> false end)
     |> assign_new(:sim_children, fn -> [] end)
     |> assign_new(:sim_exit_log, fn -> [] end)
     |> assign_new(:sim_parent_status, fn -> "alive" end)
     |> assign_new(:sim_next_id, fn -> 1 end)
     |> assign_new(:show_comparison, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Trapping Exits</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">Process.flag(:trap_exit, true)</code> converts
        exit signals from linked processes into regular
        <code class="font-mono bg-base-300 px-1 rounded">&lbrace;:EXIT, pid, reason&rbrace;</code> messages.
        This lets a process survive linked process crashes and is the foundation of supervision.
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

      <!-- Visual Scenarios -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Visual: Trap Exit Behavior</h3>

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

          <p class="text-xs opacity-60 mb-4"><%= @active_scenario.description %></p>

          <% current = Enum.at(@active_scenario.steps, @scenario_step, hd(@active_scenario.steps)) %>
          <div class="bg-base-300 rounded-lg p-6 mb-4">
            <div class="flex items-center justify-center gap-8 mb-4">
              <!-- Parent Process -->
              <div class={"w-36 h-24 rounded-xl border-2 flex flex-col items-center justify-center transition-all " <> parent_style(current.parent)}>
                <div class="font-bold text-sm">Parent</div>
                <%= if current.trapped do %>
                  <div class="badge badge-warning badge-xs mt-1">trap_exit</div>
                <% end %>
                <div class="text-xs mt-1"><%= current.parent %></div>
              </div>

              <!-- Link -->
              <div class="flex flex-col items-center gap-1">
                <div class="w-16 h-0.5 bg-warning"></div>
                <span class="text-xs text-warning">linked</span>
              </div>

              <!-- Child Process -->
              <div class={"w-36 h-24 rounded-xl border-2 flex flex-col items-center justify-center transition-all " <> child_visual_style(current.child)}>
                <div class="font-bold text-sm">Child</div>
                <div class="text-xs mt-1"><%= current.child %></div>
              </div>
            </div>

            <!-- Step Info -->
            <div class="text-center">
              <span class="badge badge-lg mb-2"><%= current.label %></span>
              <%= if current.message do %>
                <div class="font-mono text-xs mt-2 text-warning"><%= current.message %></div>
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

      <!-- Interactive Supervisor Simulator -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Mini Supervisor Simulator</h3>
          <p class="text-xs opacity-60 mb-4">
            Toggle trap_exit, spawn linked children, and crash them. See how trapping changes everything.
          </p>

          <!-- Trap Toggle -->
          <div class="flex items-center gap-4 mb-4">
            <label class="label cursor-pointer gap-2">
              <span class="label-text text-sm font-bold">Process.flag(:trap_exit, </span>
              <input
                type="checkbox"
                class="toggle toggle-warning toggle-sm"
                checked={@trap_enabled}
                phx-click="toggle_trap"
                phx-target={@myself}
              />
              <span class={"label-text text-sm font-mono font-bold " <> if(@trap_enabled, do: "text-warning", else: "opacity-50")}>
                <%= @trap_enabled %>)
              </span>
            </label>
          </div>

          <!-- Parent Status -->
          <div class={"rounded-lg p-3 mb-4 border-2 " <> sim_parent_style(@sim_parent_status)}>
            <div class="flex items-center justify-between">
              <div>
                <span class="font-bold text-sm">Supervisor Process</span>
                <span class={"badge badge-sm ml-2 " <> sim_parent_badge(@sim_parent_status)}><%= @sim_parent_status %></span>
                <%= if @trap_enabled do %>
                  <span class="badge badge-warning badge-xs ml-1">trapping</span>
                <% end %>
              </div>
              <%= if @sim_parent_status == "dead" do %>
                <button phx-click="sim_restart_parent" phx-target={@myself} class="btn btn-xs btn-primary">Restart Parent</button>
              <% end %>
            </div>
          </div>

          <!-- Child Controls -->
          <%= if @sim_parent_status != "dead" do %>
            <div class="flex gap-2 mb-4">
              <button phx-click="sim_spawn_child" phx-target={@myself} class="btn btn-sm btn-primary">
                spawn_link(child)
              </button>
            </div>
          <% end %>

          <!-- Children -->
          <%= if length(@sim_children) > 0 do %>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-2 mb-4">
              <%= for child <- @sim_children do %>
                <div class={"rounded-lg p-3 border text-center " <> sim_child_style(child.status)}>
                  <div class="font-mono text-xs font-bold">Child #<%= child.id %></div>
                  <div class="text-xs mt-1"><%= child.status %></div>
                  <%= if child.status == "alive" do %>
                    <button
                      phx-click="sim_crash_child"
                      phx-target={@myself}
                      phx-value-id={"#{child.id}"}
                      class="btn btn-xs btn-error mt-2"
                    >
                      Crash!
                    </button>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>

          <!-- EXIT Log -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">EXIT Signal Log</div>
            <%= if length(@sim_exit_log) > 0 do %>
              <div class="space-y-1">
                <%= for {entry, idx} <- Enum.with_index(Enum.reverse(@sim_exit_log)) do %>
                  <div class={"font-mono text-xs " <> if(entry.survived, do: "text-success", else: "text-error")}>
                    <span class="badge badge-xs mr-1"><%= idx + 1 %></span>
                    <%= entry.message %>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-xs opacity-40 text-center py-2">No exit signals yet.</div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Signal Types -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Exit Signal Types</h3>
            <button phx-click="toggle_comparison" phx-target={@myself} class="btn btn-xs btn-ghost">
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Signal</th>
                    <th>Without trap_exit</th>
                    <th>With trap_exit</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-mono font-bold">:normal</td>
                    <td class="text-success">Ignored (no effect)</td>
                    <td class="text-warning">&lbrace;:EXIT, pid, :normal&rbrace; message</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold">:shutdown</td>
                    <td class="text-error">Linked process dies</td>
                    <td class="text-warning">&lbrace;:EXIT, pid, :shutdown&rbrace; message</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold">&lbrace;:error, reason&rbrace;</td>
                    <td class="text-error">Linked process dies</td>
                    <td class="text-warning">&lbrace;:EXIT, pid, &lbrace;:error, reason&rbrace;&rbrace; message</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold">:kill</td>
                    <td class="text-error">Linked process dies (unstoppable)</td>
                    <td class="text-error">ALSO dies! :kill cannot be trapped</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="alert alert-warning text-xs mt-3">
              <span><strong>:kill</strong> is the only signal that cannot be trapped. It always kills the target process. The linked processes receive <strong>:killed</strong> (not :kill) which CAN be trapped.</span>
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
              <span><strong>Process.flag(:trap_exit, true)</strong> converts exit signals from linked processes into &lbrace;:EXIT, pid, reason&rbrace; messages.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>A trapping process <strong>survives</strong> linked process crashes and can take corrective action (like restarting).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>This is the core <strong>supervisor pattern</strong>: trap exits + spawn_link + restart on crash.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>:kill</strong> is the only exit signal that cannot be trapped. Use it as a last resort.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>In practice, use <strong>OTP Supervisor</strong> instead of hand-rolling trap_exit. But understanding the mechanism helps debug OTP issues.</span>
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

  def handle_event("toggle_trap", _params, socket) do
    {:noreply, assign(socket, trap_enabled: !socket.assigns.trap_enabled)}
  end

  def handle_event("sim_spawn_child", _params, socket) do
    id = socket.assigns.sim_next_id
    child = %{id: id, status: "alive"}
    {:noreply,
     socket
     |> assign(sim_children: socket.assigns.sim_children ++ [child])
     |> assign(sim_next_id: id + 1)}
  end

  def handle_event("sim_crash_child", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    children = Enum.map(socket.assigns.sim_children, fn child ->
      if child.id == id, do: %{child | status: "crashed"}, else: child
    end)

    if socket.assigns.trap_enabled do
      entry = %{
        message: "{:EXIT, Child##{id}, {:error, \"crash!\"}} -> handled, parent alive",
        survived: true
      }
      {:noreply,
       socket
       |> assign(sim_children: children)
       |> assign(sim_exit_log: [entry | socket.assigns.sim_exit_log])}
    else
      entry = %{
        message: "EXIT signal from Child##{id} -> parent KILLED (no trap_exit)",
        survived: false
      }
      all_dead = Enum.map(children, fn c -> %{c | status: "dead"} end)
      {:noreply,
       socket
       |> assign(sim_children: all_dead)
       |> assign(sim_parent_status: "dead")
       |> assign(sim_exit_log: [entry | socket.assigns.sim_exit_log])}
    end
  end

  def handle_event("sim_restart_parent", _params, socket) do
    {:noreply,
     socket
     |> assign(sim_parent_status: "alive")
     |> assign(sim_children: [])
     |> assign(sim_next_id: 1)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  # Helpers

  defp examples, do: @examples
  defp demo_scenarios, do: @demo_scenarios

  defp parent_style("alive"), do: "border-success bg-success/10"
  defp parent_style("trapping"), do: "border-warning bg-warning/10"
  defp parent_style("dead"), do: "border-error bg-error/10 opacity-40"
  defp parent_style(_), do: "border-base-content/10 bg-base-100"

  defp child_visual_style("alive"), do: "border-success bg-success/10"
  defp child_visual_style("crashed"), do: "border-error bg-error/20 animate-pulse"
  defp child_visual_style("dead"), do: "border-error/20 bg-base-100 opacity-30"
  defp child_visual_style("restarting"), do: "border-info bg-info/20 animate-pulse"
  defp child_visual_style(_), do: "border-base-content/10 bg-base-100"

  defp sim_parent_style("alive"), do: "border-success/40 bg-success/5"
  defp sim_parent_style("dead"), do: "border-error/40 bg-error/10"
  defp sim_parent_style(_), do: "border-base-content/20 bg-base-100"

  defp sim_parent_badge("alive"), do: "badge-success"
  defp sim_parent_badge("dead"), do: "badge-error"
  defp sim_parent_badge(_), do: "badge-ghost"

  defp sim_child_style("alive"), do: "border-success/40 bg-success/10"
  defp sim_child_style("crashed"), do: "border-error/40 bg-error/10"
  defp sim_child_style("dead"), do: "border-base-content/20 bg-base-100 opacity-40"
  defp sim_child_style(_), do: "border-base-content/20 bg-base-100"
end
