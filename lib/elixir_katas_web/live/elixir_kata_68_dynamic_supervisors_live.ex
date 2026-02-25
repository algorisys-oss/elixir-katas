defmodule ElixirKatasWeb.ElixirKata68DynamicSupervisorsLive do
  use ElixirKatasWeb, :live_component

  @worker_types [
    %{id: "counter", label: "Counter", icon: "#", description: "Counts up every tick"},
    %{id: "timer", label: "Timer", icon: "T", description: "Tracks elapsed seconds"},
    %{id: "echo", label: "Echo", icon: "E", description: "Echoes last message sent"}
  ]

  @concepts [
    %{
      id: "start_child",
      title: "DynamicSupervisor.start_child/2",
      code: "DynamicSupervisor.start_child(\n  MyApp.WorkerSupervisor,\n  {MyWorker, arg}\n)",
      explanation: "Starts a new child process under the dynamic supervisor at runtime. Unlike a regular Supervisor, you don't define children upfront."
    },
    %{
      id: "terminate_child",
      title: "DynamicSupervisor.terminate_child/2",
      code: "DynamicSupervisor.terminate_child(\n  MyApp.WorkerSupervisor,\n  pid\n)",
      explanation: "Terminates a specific child process. The supervisor stops tracking it. Unlike regular supervisors, you target by PID."
    },
    %{
      id: "which_children",
      title: "DynamicSupervisor.which_children/1",
      code: "DynamicSupervisor.which_children(\n  MyApp.WorkerSupervisor\n)\n# => [{:undefined, #PID<0.123.0>, :worker, [MyWorker]}, ...]",
      explanation: "Lists all currently running children. Returns a list of tuples with id, pid, type, and modules."
    },
    %{
      id: "count_children",
      title: "DynamicSupervisor.count_children/1",
      code: "DynamicSupervisor.count_children(\n  MyApp.WorkerSupervisor\n)\n# => %{active: 3, specs: 3, supervisors: 0, workers: 3}",
      explanation: "Returns a map with counts of active children, specs, supervisors, and workers."
    }
  ]

  @strategies [
    %{
      id: "one_for_one",
      label: ":one_for_one",
      description: "If a child crashes, only that child is restarted. Other children are unaffected. This is the only strategy DynamicSupervisor supports.",
      is_default: true
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:workers, fn -> [] end)
     |> assign_new(:next_id, fn -> 1 end)
     |> assign_new(:selected_type, fn -> "counter" end)
     |> assign_new(:log, fn -> [] end)
     |> assign_new(:active_concept, fn -> hd(@concepts) end)
     |> assign_new(:show_strategies, fn -> false end)
     |> assign_new(:show_code_example, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Dynamic Supervisors</h2>
      <p class="text-sm opacity-70 mb-6">
        A <code class="font-mono bg-base-300 px-1 rounded">DynamicSupervisor</code> starts with no children
        and lets you add or remove them at runtime. Perfect for on-demand worker processes like
        user sessions, game rooms, or background jobs.
      </p>

      <!-- API Concepts -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Core API</h3>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for concept <- concepts() do %>
              <button
                phx-click="select_concept"
                phx-target={@myself}
                phx-value-id={concept.id}
                class={"btn btn-sm " <> if(@active_concept.id == concept.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= concept.title %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_concept.code %></div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
            <%= @active_concept.explanation %>
          </div>
        </div>
      </div>

      <!-- Interactive Worker Manager -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Simulated Dynamic Supervisor</h3>
          <p class="text-xs opacity-60 mb-4">
            Add and remove worker processes dynamically. Each worker simulates a child process
            managed by a DynamicSupervisor.
          </p>

          <!-- Worker Type Selection & Add Button -->
          <div class="flex items-center gap-3 mb-4">
            <span class="text-xs opacity-50">Worker type:</span>
            <div class="flex gap-2">
              <%= for wt <- worker_types() do %>
                <button
                  phx-click="select_worker_type"
                  phx-target={@myself}
                  phx-value-type={wt.id}
                  class={"btn btn-sm " <> if(@selected_type == wt.id, do: "btn-accent", else: "btn-ghost")}
                  title={wt.description}
                >
                  <span class="font-mono mr-1"><%= wt.icon %></span>
                  <%= wt.label %>
                </button>
              <% end %>
            </div>
            <button
              phx-click="start_child"
              phx-target={@myself}
              class="btn btn-primary btn-sm"
            >
              + start_child
            </button>
          </div>

          <!-- Worker Count Summary -->
          <div class="flex items-center gap-4 mb-4 bg-base-300 rounded-lg p-3">
            <div class="text-sm">
              <span class="opacity-50">active:</span>
              <span class="font-mono font-bold text-success"><%= length(@workers) %></span>
            </div>
            <div class="text-sm">
              <span class="opacity-50">workers:</span>
              <span class="font-mono font-bold"><%= length(@workers) %></span>
            </div>
            <div class="text-sm">
              <span class="opacity-50">supervisors:</span>
              <span class="font-mono font-bold">0</span>
            </div>
            <%= if length(@workers) > 0 do %>
              <button
                phx-click="terminate_all"
                phx-target={@myself}
                class="btn btn-ghost btn-xs text-error ml-auto"
              >
                Terminate All
              </button>
            <% end %>
          </div>

          <!-- Worker List -->
          <%= if length(@workers) > 0 do %>
            <div class="space-y-2 mb-4">
              <%= for worker <- @workers do %>
                <div class="flex items-center justify-between bg-base-100 rounded-lg p-3 border border-base-300">
                  <div class="flex items-center gap-3">
                    <div class={"w-8 h-8 rounded-full flex items-center justify-center font-mono text-sm font-bold " <> worker_color(worker.type)}>
                      <%= worker.icon %>
                    </div>
                    <div>
                      <div class="font-mono text-sm">
                        <span class="opacity-50">#PID&lt;0.<%= worker.id %>.0&gt;</span>
                        <span class="ml-2 font-bold"><%= worker.label %></span>
                      </div>
                      <div class="text-xs opacity-50"><%= worker.description %></div>
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="badge badge-success badge-sm">running</span>
                    <button
                      phx-click="terminate_child"
                      phx-target={@myself}
                      phx-value-id={worker.id}
                      class="btn btn-ghost btn-xs text-error"
                    >
                      terminate
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="text-center py-8 opacity-40 text-sm">
              No children started. Click <strong>start_child</strong> to add workers.
            </div>
          <% end %>

          <!-- Event Log -->
          <%= if length(@log) > 0 do %>
            <div class="bg-base-300 rounded-lg p-3 max-h-40 overflow-y-auto">
              <div class="text-xs font-bold opacity-60 mb-2">Event Log</div>
              <%= for entry <- Enum.take(@log, 10) do %>
                <div class={"font-mono text-xs " <> if(entry.type == :start, do: "text-success", else: "text-error")}>
                  <%= entry.message %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Generated Code -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Equivalent Elixir Code</h3>
            <button
              phx-click="toggle_code_example"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_code_example, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_code_example do %>
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= generated_code(@workers) %></div>
          <% end %>
        </div>
      </div>

      <!-- Strategy -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Supervision Strategy</h3>
            <button
              phx-click="toggle_strategies"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_strategies, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_strategies do %>
            <%= for strategy <- strategies() do %>
              <div class="bg-base-100 rounded-lg p-4 border border-base-300">
                <div class="flex items-center gap-2 mb-2">
                  <span class="font-mono font-bold text-primary"><%= strategy.label %></span>
                  <%= if strategy.is_default do %>
                    <span class="badge badge-primary badge-xs">only option</span>
                  <% end %>
                </div>
                <p class="text-sm opacity-70"><%= strategy.description %></p>
              </div>
            <% end %>

            <div class="alert alert-info text-sm mt-4">
              <div>
                <strong>Key difference from Supervisor:</strong> Regular Supervisors support
                <code class="font-mono bg-base-100 px-1 rounded">:one_for_one</code>,
                <code class="font-mono bg-base-100 px-1 rounded">:one_for_all</code>, and
                <code class="font-mono bg-base-100 px-1 rounded">:rest_for_one</code>.
                DynamicSupervisor only supports <code class="font-mono bg-base-100 px-1 rounded">:one_for_one</code>
                because children are independent and added dynamically.
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <p class="text-xs opacity-60 mb-4">
            Experiment with DynamicSupervisor-related expressions.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="4"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={"# DynamicSupervisor is started in your application.ex\n# Try evaluating expressions here:\n%{active: 3, specs: 3, supervisors: 0, workers: 3}"}
              autocomplete="off"
            ><%= @sandbox_code %></textarea>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
          </form>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm mt-3 " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono"><%= @sandbox_result.output %></div>
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
              <span><strong>DynamicSupervisor</strong> starts empty and children are added at runtime with <code class="font-mono bg-base-100 px-1 rounded">start_child/2</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Children are terminated individually with <code class="font-mono bg-base-100 px-1 rounded">terminate_child/2</code> using the child's PID.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Only the <code class="font-mono bg-base-100 px-1 rounded">:one_for_one</code> strategy is supported &mdash; each child is independent.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Use cases:</strong> user sessions, game rooms, file processors, background jobs &mdash; anything where workers come and go.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">which_children/1</code> and <code class="font-mono bg-base-100 px-1 rounded">count_children/1</code> to inspect the supervisor state.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_concept", %{"id" => id}, socket) do
    concept = Enum.find(concepts(), &(&1.id == id))
    {:noreply, assign(socket, active_concept: concept)}
  end

  def handle_event("select_worker_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, selected_type: type)}
  end

  def handle_event("start_child", _params, socket) do
    wt = Enum.find(worker_types(), &(&1.id == socket.assigns.selected_type))
    id = socket.assigns.next_id

    worker = %{
      id: id,
      type: wt.id,
      label: "#{wt.label}_#{id}",
      icon: wt.icon,
      description: wt.description
    }

    log_entry = %{
      type: :start,
      message: "[#{Time.to_string(Time.utc_now())}] start_child => {:ok, #PID<0.#{id}.0>} (#{wt.label})"
    }

    {:noreply,
     socket
     |> assign(workers: socket.assigns.workers ++ [worker])
     |> assign(next_id: id + 1)
     |> assign(log: [log_entry | socket.assigns.log])}
  end

  def handle_event("terminate_child", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    worker = Enum.find(socket.assigns.workers, &(&1.id == id))

    log_entry = %{
      type: :stop,
      message: "[#{Time.to_string(Time.utc_now())}] terminate_child(#PID<0.#{id}.0>) => :ok (#{worker.label})"
    }

    {:noreply,
     socket
     |> assign(workers: Enum.reject(socket.assigns.workers, &(&1.id == id)))
     |> assign(log: [log_entry | socket.assigns.log])}
  end

  def handle_event("terminate_all", _params, socket) do
    log_entry = %{
      type: :stop,
      message: "[#{Time.to_string(Time.utc_now())}] terminated all #{length(socket.assigns.workers)} children"
    }

    {:noreply,
     socket
     |> assign(workers: [])
     |> assign(log: [log_entry | socket.assigns.log])}
  end

  def handle_event("toggle_code_example", _params, socket) do
    {:noreply, assign(socket, show_code_example: !socket.assigns.show_code_example)}
  end

  def handle_event("toggle_strategies", _params, socket) do
    {:noreply, assign(socket, show_strategies: !socket.assigns.show_strategies)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp concepts, do: @concepts
  defp worker_types, do: @worker_types
  defp strategies, do: @strategies

  defp worker_color("counter"), do: "bg-info text-info-content"
  defp worker_color("timer"), do: "bg-warning text-warning-content"
  defp worker_color("echo"), do: "bg-accent text-accent-content"
  defp worker_color(_), do: "bg-base-300"

  defp generated_code(workers) do
    start_lines =
      workers
      |> Enum.map(fn w ->
        "DynamicSupervisor.start_child(MySupervisor, {#{String.capitalize(w.type)}Worker, name: :#{w.label}})"
      end)
      |> Enum.join("\n")

    """
    # In application.ex, add to children list:
    {DynamicSupervisor, name: MySupervisor, strategy: :one_for_one}

    # Then at runtime:
    #{if start_lines == "", do: "# No children started yet", else: start_lines}

    # Inspect:
    DynamicSupervisor.count_children(MySupervisor)
    # => %{active: #{length(workers)}, specs: #{length(workers)}, supervisors: 0, workers: #{length(workers)}}
    """
  end

  defp evaluate_code(code) do
    try do
      {result, _bindings} = Code.eval_string(code)
      %{ok: true, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, output: "Error: #{Exception.message(e)}"}
    end
  end
end
