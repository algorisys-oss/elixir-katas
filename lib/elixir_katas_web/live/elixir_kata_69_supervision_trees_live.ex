defmodule ElixirKatasWeb.ElixirKata69SupervisionTreesLive do
  use ElixirKatasWeb, :live_component

  @initial_tree %{
    id: "app",
    label: "Application",
    type: :supervisor,
    strategy: :one_for_one,
    status: :running,
    children: [
      %{
        id: "web",
        label: "WebSupervisor",
        type: :supervisor,
        strategy: :one_for_one,
        status: :running,
        children: [
          %{id: "endpoint", label: "Endpoint", type: :worker, status: :running, children: []},
          %{id: "pubsub", label: "PubSub", type: :worker, status: :running, children: []}
        ]
      },
      %{
        id: "data",
        label: "DataSupervisor",
        type: :supervisor,
        strategy: :rest_for_one,
        status: :running,
        children: [
          %{id: "repo", label: "Repo", type: :worker, status: :running, children: []},
          %{id: "cache", label: "Cache", type: :worker, status: :running, children: []}
        ]
      },
      %{
        id: "workers",
        label: "WorkerSupervisor",
        type: :supervisor,
        strategy: :one_for_all,
        status: :running,
        children: [
          %{id: "scheduler", label: "Scheduler", type: :worker, status: :running, children: []},
          %{id: "mailer", label: "Mailer", type: :worker, status: :running, children: []}
        ]
      }
    ]
  }

  @strategy_info [
    %{
      id: "one_for_one",
      label: ":one_for_one",
      description: "If a child crashes, only that child is restarted.",
      effect: "Isolated failure. Other children are unaffected.",
      icon: "1:1"
    },
    %{
      id: "one_for_all",
      label: ":one_for_all",
      description: "If any child crashes, ALL children are terminated and restarted.",
      effect: "Full restart. Use when children depend on each other.",
      icon: "1:*"
    },
    %{
      id: "rest_for_one",
      label: ":rest_for_one",
      description: "If a child crashes, that child and all children started AFTER it are restarted.",
      effect: "Cascade restart. Use when later children depend on earlier ones.",
      icon: "1:>"
    }
  ]

  @design_tips [
    %{
      title: "Isolate Unrelated Services",
      description: "Put unrelated services under separate supervisors so a crash in one doesn't affect the other.",
      good: "WebSupervisor and DataSupervisor under separate branches",
      bad: "Endpoint and Repo as siblings under one supervisor"
    },
    %{
      title: "Match Strategy to Dependencies",
      description: "Choose your strategy based on how children relate to each other.",
      good: ":rest_for_one when Cache depends on Repo (Repo starts first)",
      bad: ":one_for_one when Cache can't work without Repo"
    },
    %{
      title: "Keep Trees Shallow",
      description: "Deep nesting adds complexity. Use 2-3 levels for most applications.",
      good: "Application -> ServiceSupervisor -> Workers",
      bad: "Application -> A -> B -> C -> D -> Worker"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:tree, fn -> @initial_tree end)
     |> assign_new(:selected_node, fn -> nil end)
     |> assign_new(:crash_log, fn -> [] end)
     |> assign_new(:active_strategy, fn -> hd(@strategy_info) end)
     |> assign_new(:show_design_tips, fn -> false end)
     |> assign_new(:show_strategies, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Supervision Trees</h2>
      <p class="text-sm opacity-70 mb-6">
        Supervision trees are hierarchies of supervisors and workers. They provide
        <strong>fault tolerance through isolation</strong> &mdash; crashes are contained within
        subtrees, and supervisors restart failed processes according to their strategy.
      </p>

      <!-- Interactive Tree Visualization -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Supervision Tree</h3>
          <p class="text-xs opacity-60 mb-4">
            Click on a <strong>worker</strong> to simulate a crash. Watch how different
            supervision strategies affect which processes restart.
          </p>

          <!-- Tree Visualization -->
          <div class="bg-base-100 rounded-lg p-4 mb-4 overflow-x-auto">
            <%= render_tree_node(assigns, @tree, 0) %>
          </div>

          <!-- Selected Node Info -->
          <%= if @selected_node do %>
            <div class="alert alert-info text-sm mb-4">
              <div>
                <div class="font-bold"><%= @selected_node %></div>
                <span class="text-xs">Click a worker node to simulate a crash</span>
              </div>
            </div>
          <% end %>

          <!-- Crash Log -->
          <%= if length(@crash_log) > 0 do %>
            <div class="bg-base-300 rounded-lg p-3 max-h-40 overflow-y-auto mb-4">
              <div class="text-xs font-bold opacity-60 mb-2">Crash &amp; Recovery Log</div>
              <%= for entry <- Enum.take(@crash_log, 10) do %>
                <div class={"font-mono text-xs " <> crash_log_color(entry.type)}>
                  <%= entry.message %>
                </div>
              <% end %>
            </div>
          <% end %>

          <div class="flex gap-2">
            <button
              phx-click="reset_tree"
              phx-target={@myself}
              class="btn btn-ghost btn-sm"
            >
              Reset Tree
            </button>
            <button
              phx-click="clear_log"
              phx-target={@myself}
              class="btn btn-ghost btn-sm"
            >
              Clear Log
            </button>
          </div>
        </div>
      </div>

      <!-- Strategy Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Supervision Strategies</h3>
            <button
              phx-click="toggle_strategies"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_strategies, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_strategies do %>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <%= for strategy <- strategy_info() do %>
                <div
                  phx-click="select_strategy"
                  phx-target={@myself}
                  phx-value-id={strategy.id}
                  class={"bg-base-100 rounded-lg p-4 border-2 cursor-pointer transition-all " <>
                    if(@active_strategy.id == strategy.id, do: "border-primary shadow-lg", else: "border-base-300 hover:border-primary/50")}
                >
                  <div class="flex items-center gap-2 mb-2">
                    <span class="font-mono text-xs bg-primary text-primary-content rounded px-2 py-0.5">
                      <%= strategy.icon %>
                    </span>
                    <span class="font-mono font-bold text-sm"><%= strategy.label %></span>
                  </div>
                  <p class="text-xs opacity-70 mb-2"><%= strategy.description %></p>
                  <div class="text-xs bg-base-300 rounded p-2">
                    <span class="font-bold">Effect: </span><%= strategy.effect %>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Visual Strategy Comparison -->
            <div class="mt-4 bg-base-100 rounded-lg p-4">
              <h4 class="text-sm font-bold mb-3">When child B crashes:</h4>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4 font-mono text-xs">
                <div>
                  <div class="font-bold text-primary mb-2">:one_for_one</div>
                  <div class="space-y-1">
                    <div class="text-success">A - running</div>
                    <div class="text-error">B - restarted</div>
                    <div class="text-success">C - running</div>
                  </div>
                </div>
                <div>
                  <div class="font-bold text-primary mb-2">:one_for_all</div>
                  <div class="space-y-1">
                    <div class="text-warning">A - restarted</div>
                    <div class="text-error">B - restarted</div>
                    <div class="text-warning">C - restarted</div>
                  </div>
                </div>
                <div>
                  <div class="font-bold text-primary mb-2">:rest_for_one</div>
                  <div class="space-y-1">
                    <div class="text-success">A - running</div>
                    <div class="text-error">B - restarted</div>
                    <div class="text-warning">C - restarted</div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Design Tips -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Design Tips</h3>
            <button
              phx-click="toggle_design_tips"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_design_tips, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_design_tips do %>
            <div class="space-y-4">
              <%= for tip <- design_tips() do %>
                <div class="bg-base-100 rounded-lg p-4 border border-base-300">
                  <h4 class="font-bold text-sm mb-2"><%= tip.title %></h4>
                  <p class="text-xs opacity-70 mb-3"><%= tip.description %></p>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-2 text-xs">
                    <div class="bg-success/10 border border-success/30 rounded p-2">
                      <span class="font-bold text-success">Good: </span><%= tip.good %>
                    </div>
                    <div class="bg-error/10 border border-error/30 rounded p-2">
                      <span class="font-bold text-error">Avoid: </span><%= tip.bad %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="4"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={"# Try supervision tree related code\nchildren = [{Task, fn -> :work end}]\nSupervisor.start_link(children, strategy: :one_for_one)"}
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
              <span><strong>Supervision trees</strong> are nested hierarchies of supervisors and workers providing fault tolerance through isolation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>The <strong>strategy</strong> determines which siblings restart when one crashes: <code class="font-mono bg-base-100 px-1 rounded">:one_for_one</code>, <code class="font-mono bg-base-100 px-1 rounded">:one_for_all</code>, or <code class="font-mono bg-base-100 px-1 rounded">:rest_for_one</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Nested supervisors</strong> isolate failure domains &mdash; a crash in one subtree does not affect another.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Design your tree to match your application's <strong>dependency graph</strong> &mdash; group related processes under the same supervisor.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Every OTP application has a <strong>root supervisor</strong> started in <code class="font-mono bg-base-100 px-1 rounded">application.ex</code>.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Tree rendering helper
  defp render_tree_node(assigns, node, depth) do
    assigns = assign(assigns, node: node, depth: depth)

    ~H"""
    <div class={"ml-#{min(@depth * 6, 24)}"}>
      <div class="flex items-center gap-2 mb-2">
        <!-- Connector line -->
        <%= if @depth > 0 do %>
          <div class="w-4 border-t-2 border-base-300"></div>
        <% end %>

        <!-- Node -->
        <div
          phx-click={if(@node.type == :worker, do: "crash_worker")}
          phx-target={@myself}
          phx-value-id={@node.id}
          class={"inline-flex items-center gap-2 rounded-lg px-3 py-2 border-2 transition-all " <>
            node_class(@node)}
        >
          <!-- Type icon -->
          <span class={"w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold " <>
            if(@node.type == :supervisor, do: "bg-primary text-primary-content", else: "bg-accent text-accent-content")}>
            <%= if @node.type == :supervisor, do: "S", else: "W" %>
          </span>
          <div>
            <div class="font-mono text-sm font-bold"><%= @node.label %></div>
            <div class="text-xs opacity-50">
              <%= if @node.type == :supervisor do %>
                strategy: <%= @node.strategy %>
              <% else %>
                <span class={if(@node.status == :crashed, do: "text-error", else: "text-success")}>
                  <%= @node.status %>
                </span>
                <span class="ml-1 opacity-40">(click to crash)</span>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Children -->
      <%= if length(@node.children) > 0 do %>
        <div class="border-l-2 border-base-300 ml-3 pl-1">
          <%= for child <- @node.children do %>
            <%= render_tree_node(assigns, child, @depth + 1) %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Event Handlers

  def handle_event("crash_worker", %{"id" => id}, socket) do
    tree = socket.assigns.tree

    # Find the worker's parent supervisor to determine strategy
    {parent, _worker} = find_parent_and_node(tree, id)

    if parent do
      strategy = parent.strategy
      {new_tree, log_entries} = simulate_crash(tree, parent.id, id, strategy)

      {:noreply,
       socket
       |> assign(tree: new_tree)
       |> assign(selected_node: id)
       |> assign(crash_log: log_entries ++ socket.assigns.crash_log)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("reset_tree", _params, socket) do
    {:noreply, assign(socket, tree: @initial_tree, crash_log: [], selected_node: nil)}
  end

  def handle_event("clear_log", _params, socket) do
    {:noreply, assign(socket, crash_log: [])}
  end

  def handle_event("toggle_strategies", _params, socket) do
    {:noreply, assign(socket, show_strategies: !socket.assigns.show_strategies)}
  end

  def handle_event("select_strategy", %{"id" => id}, socket) do
    strategy = Enum.find(strategy_info(), &(&1.id == id))
    {:noreply, assign(socket, active_strategy: strategy)}
  end

  def handle_event("toggle_design_tips", _params, socket) do
    {:noreply, assign(socket, show_design_tips: !socket.assigns.show_design_tips)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp strategy_info, do: @strategy_info
  defp design_tips, do: @design_tips

  defp node_class(node) do
    cond do
      node.status == :crashed -> "border-error bg-error/10"
      node.status == :restarting -> "border-warning bg-warning/10"
      node.type == :supervisor -> "border-primary bg-primary/5"
      true -> "border-base-300 bg-base-100 cursor-pointer hover:border-accent"
    end
  end

  defp crash_log_color(:crash), do: "text-error"
  defp crash_log_color(:restart), do: "text-warning"
  defp crash_log_color(:info), do: "text-info"
  defp crash_log_color(_), do: ""

  defp find_parent_and_node(tree, target_id) do
    find_parent_and_node_recursive(nil, tree, target_id)
  end

  defp find_parent_and_node_recursive(_parent, %{id: id} = node, target_id) when id == target_id do
    {nil, node}
  end

  defp find_parent_and_node_recursive(_parent, %{children: children} = node, target_id) do
    direct_child = Enum.find(children, &(&1.id == target_id))

    if direct_child do
      {node, direct_child}
    else
      Enum.reduce_while(children, {nil, nil}, fn child, _acc ->
        case find_parent_and_node_recursive(node, child, target_id) do
          {nil, nil} -> {:cont, {nil, nil}}
          result -> {:halt, result}
        end
      end)
    end
  end

  defp simulate_crash(tree, parent_id, crashed_id, strategy) do
    timestamp = Time.to_string(Time.utc_now())
    crash_entry = %{type: :crash, message: "[#{timestamp}] CRASH: #{crashed_id} terminated unexpectedly"}

    {updated_tree, restart_entries} =
      case strategy do
        :one_for_one ->
          new_tree = update_node_status(tree, crashed_id, :running)
          entries = [
            %{type: :restart, message: "[#{timestamp}] :one_for_one -> restarting #{crashed_id} only"}
          ]
          {new_tree, entries}

        :one_for_all ->
          # Restart all children of the parent
          parent = find_node(tree, parent_id)
          child_ids = Enum.map(parent.children, & &1.id)
          new_tree = Enum.reduce(child_ids, tree, fn id, acc -> update_node_status(acc, id, :running) end)
          entries = [
            %{type: :restart, message: "[#{timestamp}] :one_for_all -> restarting ALL siblings: #{Enum.join(child_ids, ", ")}"}
          ]
          {new_tree, entries}

        :rest_for_one ->
          parent = find_node(tree, parent_id)
          crashed_idx = Enum.find_index(parent.children, &(&1.id == crashed_id))
          rest_ids = parent.children |> Enum.drop(crashed_idx) |> Enum.map(& &1.id)
          new_tree = Enum.reduce(rest_ids, tree, fn id, acc -> update_node_status(acc, id, :running) end)
          entries = [
            %{type: :restart, message: "[#{timestamp}] :rest_for_one -> restarting #{crashed_id} and subsequent: #{Enum.join(rest_ids, ", ")}"}
          ]
          {new_tree, entries}

        _ ->
          {tree, []}
      end

    {updated_tree, [crash_entry | restart_entries]}
  end

  defp find_node(%{id: id} = node, target_id) when id == target_id, do: node
  defp find_node(%{children: children}, target_id) do
    Enum.find_value(children, fn child -> find_node(child, target_id) end)
  end

  defp update_node_status(%{id: id} = node, target_id, new_status) when id == target_id do
    %{node | status: new_status}
  end
  defp update_node_status(%{children: children} = node, target_id, new_status) do
    %{node | children: Enum.map(children, &update_node_status(&1, target_id, new_status))}
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
