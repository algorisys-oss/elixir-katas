defmodule ElixirKatasWeb.ElixirKata62AgentLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "start",
      title: "Agent.start_link/1",
      code: "{:ok, agent} = Agent.start_link(fn -> 0 end)\n\n# Named agent:\n{:ok, _} = Agent.start_link(\n  fn -> [] end,\n  name: :my_list\n)",
      result: "{:ok, #PID<0.123.0>}",
      explanation: "Agent.start_link/1 starts a process that holds state. The function returns the initial state. You can optionally give it a name."
    },
    %{
      id: "get",
      title: "Agent.get/2",
      code: "{:ok, agent} = Agent.start_link(fn -> 42 end)\n\nAgent.get(agent, fn state -> state end)\n# => 42\n\nAgent.get(agent, fn state -> state * 2 end)\n# => 84 (state is still 42)",
      result: "42 (state unchanged by get)",
      explanation: "Agent.get/2 reads state by calling the function with the current state. The state itself is not modified."
    },
    %{
      id: "update",
      title: "Agent.update/2",
      code: "{:ok, agent} = Agent.start_link(fn -> 0 end)\n\nAgent.update(agent, fn state -> state + 1 end)\nAgent.update(agent, fn state -> state + 10 end)\n\nAgent.get(agent, fn state -> state end)\n# => 11",
      result: "11",
      explanation: "Agent.update/2 replaces the state with the return value of the function. It returns :ok."
    },
    %{
      id: "get_and_update",
      title: "Agent.get_and_update/2",
      code: "{:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)\n\n# Pop the first element\nAgent.get_and_update(agent, fn [h | t] ->\n  {h, t}  # {return_value, new_state}\nend)\n# => 1, state is now [2, 3]",
      result: "1 (and state becomes [2, 3])",
      explanation: "get_and_update/2 lets you read and modify state atomically. Return {value_to_return, new_state}."
    },
    %{
      id: "stop",
      title: "Agent.stop/1",
      code: "{:ok, agent} = Agent.start_link(fn -> :data end)\nAgent.stop(agent)\n# Agent process exits normally\n\n# After stop, any call raises:\nAgent.get(agent, & &1)\n# ** (exit) process not alive",
      result: ":ok (agent stopped)",
      explanation: "Agent.stop/1 terminates the agent process. After stopping, any interaction raises an exit error."
    }
  ]

  @agent_vs_genserver [
    %{aspect: "Purpose", agent: "Simple state wrapper", genserver: "Complex stateful server"},
    %{aspect: "API", agent: "get, update, get_and_update", genserver: "call, cast, info handlers"},
    %{aspect: "Callbacks", agent: "None (just functions)", genserver: "init, handle_call, handle_cast, ..."},
    %{aspect: "Side effects", agent: "State only, no side effects", genserver: "Can do I/O, timers, etc."},
    %{aspect: "Complexity", agent: "Minimal boilerplate", genserver: "More structure, more power"},
    %{aspect: "When to use", agent: "Shared mutable state (cache, counters)", genserver: "Business logic, protocols, supervision"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:agent_state, fn -> 0 end)
     |> assign_new(:agent_history, fn -> [%{action: "start_link(fn -> 0 end)", state: "0"}] end)
     |> assign_new(:list_state, fn -> [] end)
     |> assign_new(:list_history, fn -> [%{action: "start_link(fn -> [] end)", state: "[]"}] end)
     |> assign_new(:list_input, fn -> "" end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:show_use_cases, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Agent</h2>
      <p class="text-sm opacity-70 mb-6">
        An <strong>Agent</strong> is a simple process that wraps state. It provides
        <code class="font-mono bg-base-300 px-1 rounded">get</code>,
        <code class="font-mono bg-base-300 px-1 rounded">update</code>, and
        <code class="font-mono bg-base-300 px-1 rounded">get_and_update</code> operations.
        Think of it as a simpler alternative to GenServer when you only need state management.
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

      <!-- Interactive Counter Agent -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Counter Agent</h3>
          <p class="text-xs opacity-60 mb-4">
            Simulate an Agent holding an integer. Each button calls a different Agent function.
          </p>

          <!-- Counter Display -->
          <div class="flex items-center justify-center gap-4 mb-4">
            <div class="text-center">
              <div class="text-5xl font-bold font-mono"><%= @agent_state %></div>
              <div class="text-xs opacity-50 mt-1">Agent state</div>
            </div>
          </div>

          <div class="flex flex-wrap gap-2 justify-center mb-4">
            <button phx-click="agent_increment" phx-target={@myself} class="btn btn-sm btn-primary">
              update(+1)
            </button>
            <button phx-click="agent_decrement" phx-target={@myself} class="btn btn-sm btn-secondary">
              update(-1)
            </button>
            <button phx-click="agent_double" phx-target={@myself} class="btn btn-sm btn-accent">
              update(*2)
            </button>
            <button phx-click="agent_get" phx-target={@myself} class="btn btn-sm btn-info btn-outline">
              get(state)
            </button>
            <button phx-click="agent_get_and_update" phx-target={@myself} class="btn btn-sm btn-warning">
              get_and_update (return old, set 0)
            </button>
            <button phx-click="agent_reset" phx-target={@myself} class="btn btn-sm btn-ghost">
              Reset
            </button>
          </div>

          <!-- History -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">Agent Call Log</div>
            <div class="space-y-1 max-h-40 overflow-y-auto">
              <%= for {entry, idx} <- Enum.with_index(Enum.reverse(@agent_history)) do %>
                <div class="flex items-center gap-2 font-mono text-xs">
                  <span class="badge badge-primary badge-xs"><%= idx + 1 %></span>
                  <span class="text-accent">Agent.<%= entry.action %></span>
                  <span class="opacity-30">&rarr;</span>
                  <span class="text-info">state = <%= entry.state %></span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Interactive List Agent -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive List Agent</h3>
          <p class="text-xs opacity-60 mb-4">
            An Agent holding a list. Demonstrates get, update, and get_and_update with complex state.
          </p>

          <!-- Current State -->
          <div class="bg-base-300 rounded-lg p-4 mb-4">
            <div class="text-xs font-bold opacity-60 mb-2">Agent.get(agent, &amp;&amp;1)</div>
            <div class="font-mono text-sm">
              <%= if length(@list_state) > 0 do %>
                <span class="text-info">[<%= Enum.join(@list_state, ", ") %>]</span>
              <% else %>
                <span class="opacity-40">[] (empty list)</span>
              <% end %>
            </div>
          </div>

          <!-- Add Item -->
          <form phx-submit="list_push" phx-target={@myself} class="flex gap-2 mb-3">
            <input
              type="text"
              name="item"
              value={@list_input}
              placeholder="Item to add..."
              class="input input-bordered input-sm font-mono flex-1"
              autocomplete="off"
            />
            <button type="submit" class="btn btn-sm btn-primary">
              update(fn s -&gt; [item | s] end)
            </button>
          </form>

          <div class="flex flex-wrap gap-2 mb-4">
            <button phx-click="list_pop" phx-target={@myself} class="btn btn-xs btn-warning" disabled={length(@list_state) == 0}>
              get_and_update (pop first)
            </button>
            <button phx-click="list_reverse" phx-target={@myself} class="btn btn-xs btn-accent" disabled={length(@list_state) == 0}>
              update(Enum.reverse)
            </button>
            <button phx-click="list_sort" phx-target={@myself} class="btn btn-xs btn-info" disabled={length(@list_state) == 0}>
              update(Enum.sort)
            </button>
            <button phx-click="list_clear" phx-target={@myself} class="btn btn-xs btn-ghost">
              stop &amp; restart
            </button>
          </div>

          <!-- List History -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">Call Log</div>
            <div class="space-y-1 max-h-32 overflow-y-auto">
              <%= for {entry, idx} <- Enum.with_index(Enum.reverse(@list_history)) do %>
                <div class="flex items-center gap-2 font-mono text-xs">
                  <span class="badge badge-secondary badge-xs"><%= idx + 1 %></span>
                  <span class="text-accent"><%= entry.action %></span>
                  <span class="opacity-30">&rarr;</span>
                  <span class="text-info"><%= entry.state %></span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Agent vs GenServer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Agent vs GenServer</h3>
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
                    <th class="text-info">Agent</th>
                    <th class="text-warning">GenServer</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- agent_vs_genserver() do %>
                    <tr>
                      <td class="font-bold"><%= row.aspect %></td>
                      <td><%= row.agent %></td>
                      <td><%= row.genserver %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="alert alert-info text-sm mt-3">
              <span><strong>Rule of thumb:</strong> Start with Agent. If you need handle_info, timers, complex protocols, or side effects, upgrade to GenServer.</span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- When to Use Agent -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">When to Use Agent</h3>
            <button phx-click="toggle_use_cases" phx-target={@myself} class="btn btn-xs btn-ghost">
              <%= if @show_use_cases, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_use_cases do %>
            <div class="space-y-3">
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <h4 class="font-bold text-success text-sm mb-2">Good Use Cases</h4>
                <ul class="space-y-1 text-sm">
                  <li class="flex items-start gap-2">
                    <span class="text-success mt-0.5">&#x2713;</span>
                    <span>Simple counters and accumulators</span>
                  </li>
                  <li class="flex items-start gap-2">
                    <span class="text-success mt-0.5">&#x2713;</span>
                    <span>Caches and lookup tables</span>
                  </li>
                  <li class="flex items-start gap-2">
                    <span class="text-success mt-0.5">&#x2713;</span>
                    <span>Configuration state shared across processes</span>
                  </li>
                  <li class="flex items-start gap-2">
                    <span class="text-success mt-0.5">&#x2713;</span>
                    <span>Collecting results from multiple processes</span>
                  </li>
                </ul>
              </div>

              <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                <h4 class="font-bold text-error text-sm mb-2">Use GenServer Instead</h4>
                <ul class="space-y-1 text-sm">
                  <li class="flex items-start gap-2">
                    <span class="text-error mt-0.5">&#x2717;</span>
                    <span>Need to handle incoming messages (handle_info)</span>
                  </li>
                  <li class="flex items-start gap-2">
                    <span class="text-error mt-0.5">&#x2717;</span>
                    <span>Need periodic timers or scheduled work</span>
                  </li>
                  <li class="flex items-start gap-2">
                    <span class="text-error mt-0.5">&#x2717;</span>
                    <span>Complex request/response protocols</span>
                  </li>
                  <li class="flex items-start gap-2">
                    <span class="text-error mt-0.5">&#x2717;</span>
                    <span>Need side effects (I/O, database) in state changes</span>
                  </li>
                </ul>
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
              <span><strong>Agent</strong> is a simple state server. Start with <code class="font-mono bg-base-100 px-1 rounded">Agent.start_link(fn -> initial_state end)</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Agent.get/2</strong> reads state (does not modify it). <strong>Agent.update/2</strong> replaces state.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Agent.get_and_update/2</strong> reads and modifies state atomically. Return <code class="font-mono bg-base-100 px-1 rounded">&lbrace;return_value, new_state&rbrace;</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Agent operations are <strong>serialized</strong>: only one operation runs at a time, preventing race conditions.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Agents are simpler than GenServer. Use Agent for <strong>pure state</strong>; upgrade to GenServer when you need more.</span>
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

  # Counter Agent events

  def handle_event("agent_increment", _params, socket) do
    new_state = socket.assigns.agent_state + 1
    entry = %{action: "update(agent, fn s -> s + 1 end)", state: "#{new_state}"}
    {:noreply,
     socket
     |> assign(agent_state: new_state)
     |> assign(agent_history: [entry | socket.assigns.agent_history])}
  end

  def handle_event("agent_decrement", _params, socket) do
    new_state = socket.assigns.agent_state - 1
    entry = %{action: "update(agent, fn s -> s - 1 end)", state: "#{new_state}"}
    {:noreply,
     socket
     |> assign(agent_state: new_state)
     |> assign(agent_history: [entry | socket.assigns.agent_history])}
  end

  def handle_event("agent_double", _params, socket) do
    new_state = socket.assigns.agent_state * 2
    entry = %{action: "update(agent, fn s -> s * 2 end)", state: "#{new_state}"}
    {:noreply,
     socket
     |> assign(agent_state: new_state)
     |> assign(agent_history: [entry | socket.assigns.agent_history])}
  end

  def handle_event("agent_get", _params, socket) do
    entry = %{action: "get(agent, fn s -> s end)", state: "#{socket.assigns.agent_state}"}
    {:noreply, assign(socket, agent_history: [entry | socket.assigns.agent_history])}
  end

  def handle_event("agent_get_and_update", _params, socket) do
    old = socket.assigns.agent_state
    entry = %{action: "get_and_update(agent, fn s -> {s, 0} end) => #{old}", state: "0"}
    {:noreply,
     socket
     |> assign(agent_state: 0)
     |> assign(agent_history: [entry | socket.assigns.agent_history])}
  end

  def handle_event("agent_reset", _params, socket) do
    {:noreply,
     socket
     |> assign(agent_state: 0)
     |> assign(agent_history: [%{action: "stop + start_link(fn -> 0 end)", state: "0"}])}
  end

  # List Agent events

  def handle_event("list_push", %{"item" => item}, socket) do
    item = String.trim(item)
    if item == "" do
      {:noreply, socket}
    else
      new_state = [item | socket.assigns.list_state]
      entry = %{action: "update(fn s -> [\"#{item}\" | s] end)", state: inspect(new_state)}
      {:noreply,
       socket
       |> assign(list_state: new_state)
       |> assign(list_input: "")
       |> assign(list_history: [entry | socket.assigns.list_history])}
    end
  end

  def handle_event("list_pop", _params, socket) do
    case socket.assigns.list_state do
      [] ->
        {:noreply, socket}
      [head | tail] ->
        entry = %{action: "get_and_update(fn [h|t] -> {h, t} end) => \"#{head}\"", state: inspect(tail)}
        {:noreply,
         socket
         |> assign(list_state: tail)
         |> assign(list_history: [entry | socket.assigns.list_history])}
    end
  end

  def handle_event("list_reverse", _params, socket) do
    new_state = Enum.reverse(socket.assigns.list_state)
    entry = %{action: "update(fn s -> Enum.reverse(s) end)", state: inspect(new_state)}
    {:noreply,
     socket
     |> assign(list_state: new_state)
     |> assign(list_history: [entry | socket.assigns.list_history])}
  end

  def handle_event("list_sort", _params, socket) do
    new_state = Enum.sort(socket.assigns.list_state)
    entry = %{action: "update(fn s -> Enum.sort(s) end)", state: inspect(new_state)}
    {:noreply,
     socket
     |> assign(list_state: new_state)
     |> assign(list_history: [entry | socket.assigns.list_history])}
  end

  def handle_event("list_clear", _params, socket) do
    {:noreply,
     socket
     |> assign(list_state: [])
     |> assign(list_history: [%{action: "stop + start_link(fn -> [] end)", state: "[]"}])}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("toggle_use_cases", _params, socket) do
    {:noreply, assign(socket, show_use_cases: !socket.assigns.show_use_cases)}
  end

  # Helpers

  defp examples, do: @examples
  defp agent_vs_genserver, do: @agent_vs_genserver
end
