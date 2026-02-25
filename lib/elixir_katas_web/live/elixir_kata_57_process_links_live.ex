defmodule ElixirKatasWeb.ElixirKata57ProcessLinksLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "spawn_link",
      title: "spawn_link/1",
      code: "pid = spawn_link(fn ->\n  Process.sleep(1000)\n  IO.puts(\"child done\")\nend)\nIO.inspect(pid)",
      result: "#PID<0.123.0>",
      explanation: "spawn_link/1 creates a process AND a bidirectional link. If either process crashes, the other is killed too."
    },
    %{
      id: "crash_propagation",
      title: "Crash Propagation",
      code: "spawn_link(fn ->\n  raise \"boom!\"\nend)\n\n# Parent also crashes!\n# ** (EXIT from #PID<0.100.0>)\n#    ** (RuntimeError) boom!",
      result: "Both processes crash!",
      explanation: "When the child raises an error, the exit signal propagates through the link and kills the parent too. This is crash propagation."
    },
    %{
      id: "spawn_vs_link",
      title: "spawn vs spawn_link",
      code: "# spawn: child crash does NOT affect parent\nspawn(fn -> raise \"boom\" end)\nIO.puts(\"parent still alive\")\n\n# spawn_link: child crash KILLS parent\nspawn_link(fn -> raise \"boom\" end)\n# parent never reaches here",
      result: "spawn: parent survives | spawn_link: parent dies",
      explanation: "spawn/1 creates an isolated process. spawn_link/1 creates a linked process. Links make failures visible."
    },
    %{
      id: "process_link",
      title: "Process.link/1",
      code: "pid = spawn(fn ->\n  receive do\n    :crash -> raise \"boom!\"\n  end\nend)\n\nProcess.link(pid)  # link AFTER spawn\nsend(pid, :crash)\n# Now parent crashes too",
      result: "Link established after spawn",
      explanation: "Process.link/1 creates a link to an existing process. It is bidirectional - either side crashing kills the other."
    },
    %{
      id: "normal_exit",
      title: "Normal Exit",
      code: "pid = spawn_link(fn ->\n  :ok  # exits normally\nend)\n\n# Normal exit does NOT crash parent\nIO.puts(\"parent fine\")",
      result: "parent fine",
      explanation: "A linked process exiting normally (reason :normal) does NOT crash the other side. Only abnormal exits propagate."
    }
  ]

  @demo_scenarios [
    %{
      id: "isolated",
      title: "Isolated (spawn)",
      description: "Processes are independent. Child crash does not affect parent.",
      steps: [
        %{label: "Parent running", parent: "alive", child: nil, link: false},
        %{label: "Child spawned (no link)", parent: "alive", child: "alive", link: false},
        %{label: "Child crashes!", parent: "alive", child: "crashed", link: false},
        %{label: "Parent continues", parent: "alive", child: "dead", link: false}
      ]
    },
    %{
      id: "linked_child_crash",
      title: "Linked - Child Crashes",
      description: "Link propagates the crash signal from child to parent.",
      steps: [
        %{label: "Parent running", parent: "alive", child: nil, link: false},
        %{label: "Child spawned + linked", parent: "alive", child: "alive", link: true},
        %{label: "Child crashes!", parent: "alive", child: "crashed", link: true},
        %{label: "Exit signal propagates", parent: "crashing", child: "dead", link: true},
        %{label: "Parent also dies!", parent: "dead", child: "dead", link: false}
      ]
    },
    %{
      id: "linked_parent_crash",
      title: "Linked - Parent Crashes",
      description: "Links are bidirectional - parent crash kills child too.",
      steps: [
        %{label: "Both running, linked", parent: "alive", child: "alive", link: true},
        %{label: "Parent crashes!", parent: "crashed", child: "alive", link: true},
        %{label: "Exit signal propagates", parent: "dead", child: "crashing", link: true},
        %{label: "Child also dies!", parent: "dead", child: "dead", link: false}
      ]
    },
    %{
      id: "linked_normal",
      title: "Linked - Normal Exit",
      description: "Normal exits do not propagate. Only abnormal exits kill the linked process.",
      steps: [
        %{label: "Both running, linked", parent: "alive", child: "alive", link: true},
        %{label: "Child exits normally", parent: "alive", child: "exited", link: true},
        %{label: "Parent unaffected", parent: "alive", child: "dead", link: false}
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
     |> assign_new(:show_comparison, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Process Links</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Links</strong> connect two processes bidirectionally. When a linked process exits abnormally,
        the exit signal propagates to the other side, killing it too. This is the foundation of
        Erlang/Elixir's "let it crash" philosophy.
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

      <!-- Interactive Link Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Visual: Link Behavior</h3>
          <p class="text-xs opacity-60 mb-4">
            Step through different scenarios to see how links affect crash propagation.
          </p>

          <!-- Scenario Selector -->
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

          <!-- Process Visualization -->
          <% current_step = Enum.at(@active_scenario.steps, @scenario_step, hd(@active_scenario.steps)) %>
          <div class="bg-base-300 rounded-lg p-6 mb-4">
            <div class="flex items-center justify-center gap-8">
              <!-- Parent Process -->
              <div class={"w-32 h-24 rounded-xl border-2 flex flex-col items-center justify-center transition-all " <> proc_visual_style(current_step.parent)}>
                <div class="font-bold text-sm">Parent</div>
                <div class={"text-xs mt-1 " <> proc_status_text_color(current_step.parent)}>
                  <%= current_step.parent || "not started" %>
                </div>
              </div>

              <!-- Link Line -->
              <div class="flex flex-col items-center gap-1">
                <%= if current_step.link do %>
                  <div class="w-16 h-0.5 bg-warning"></div>
                  <span class="text-xs text-warning">linked</span>
                <% else %>
                  <div class="w-16 h-0.5 bg-base-content/10"></div>
                  <span class="text-xs opacity-30">no link</span>
                <% end %>
              </div>

              <!-- Child Process -->
              <div class={"w-32 h-24 rounded-xl border-2 flex flex-col items-center justify-center transition-all " <> proc_visual_style(current_step.child)}>
                <div class="font-bold text-sm">Child</div>
                <div class={"text-xs mt-1 " <> proc_status_text_color(current_step.child)}>
                  <%= current_step.child || "not spawned" %>
                </div>
              </div>
            </div>

            <!-- Step Label -->
            <div class="text-center mt-4">
              <span class="badge badge-lg"><%= current_step.label %></span>
            </div>
          </div>

          <!-- Step Controls -->
          <div class="flex items-center gap-2">
            <button
              phx-click="scenario_back"
              phx-target={@myself}
              disabled={@scenario_step <= 0}
              class="btn btn-sm btn-outline"
            >
              &larr; Back
            </button>
            <button
              phx-click="scenario_forward"
              phx-target={@myself}
              disabled={@scenario_step >= length(@active_scenario.steps) - 1}
              class="btn btn-sm btn-primary"
            >
              Forward &rarr;
            </button>
            <span class="text-xs opacity-50 ml-2">
              Step <%= @scenario_step + 1 %> of <%= length(@active_scenario.steps) %>
            </span>
          </div>
        </div>
      </div>

      <!-- spawn vs spawn_link comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">spawn vs spawn_link Comparison</h3>
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
                    <th class="text-info">spawn/1</th>
                    <th class="text-warning">spawn_link/1</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-bold">Connection</td>
                    <td>None (isolated)</td>
                    <td>Bidirectional link</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Child crashes</td>
                    <td class="text-success">Parent unaffected</td>
                    <td class="text-error">Parent also crashes</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Parent crashes</td>
                    <td class="text-success">Child unaffected</td>
                    <td class="text-error">Child also crashes</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Normal exit</td>
                    <td>No notification</td>
                    <td>No crash (normal is safe)</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Use case</td>
                    <td>Fire-and-forget tasks</td>
                    <td>Dependent processes, supervision</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Philosophy</td>
                    <td>Ignore failures</td>
                    <td>"Let it crash" together</td>
                  </tr>
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
              <span><strong>spawn_link/1</strong> creates a process with a bidirectional link to the caller.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Links are bidirectional</strong>: if either process exits abnormally, the other is killed.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Normal exits</strong> (reason <code class="font-mono bg-base-100 px-1 rounded">:normal</code>) do NOT propagate through links.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Process.link/1</strong> and <strong>Process.unlink/1</strong> can add/remove links after spawn.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Links are the foundation of <strong>supervision trees</strong>: supervisors use links + trap_exit to detect child failures.</span>
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
    new_step = min(socket.assigns.scenario_step + 1, max)
    {:noreply, assign(socket, scenario_step: new_step)}
  end

  def handle_event("scenario_back", _params, socket) do
    new_step = max(socket.assigns.scenario_step - 1, 0)
    {:noreply, assign(socket, scenario_step: new_step)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  # Helpers

  defp examples, do: @examples
  defp demo_scenarios, do: @demo_scenarios

  defp proc_visual_style(nil), do: "border-base-content/10 bg-base-100 opacity-30"
  defp proc_visual_style("alive"), do: "border-success bg-success/10"
  defp proc_visual_style("crashed"), do: "border-error bg-error/20 animate-pulse"
  defp proc_visual_style("crashing"), do: "border-error bg-error/10 animate-pulse"
  defp proc_visual_style("dead"), do: "border-error/30 bg-error/5 opacity-40"
  defp proc_visual_style("exited"), do: "border-base-content/20 bg-base-100 opacity-50"
  defp proc_visual_style(_), do: "border-base-content/10 bg-base-100"

  defp proc_status_text_color(nil), do: "opacity-40"
  defp proc_status_text_color("alive"), do: "text-success"
  defp proc_status_text_color("crashed"), do: "text-error font-bold"
  defp proc_status_text_color("crashing"), do: "text-error"
  defp proc_status_text_color("dead"), do: "text-error opacity-50"
  defp proc_status_text_color("exited"), do: "opacity-50"
  defp proc_status_text_color(_), do: "opacity-40"
end
