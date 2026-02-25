defmodule ElixirKatasWeb.ElixirKata59ProcessStateLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "basic_loop",
      title: "Basic Receive Loop",
      code: "defmodule Counter do\n  def start do\n    spawn(fn -> loop(0) end)\n  end\n\n  defp loop(count) do\n    receive do\n      :increment ->\n        loop(count + 1)\n      {:get, caller} ->\n        send(caller, {:count, count})\n        loop(count)\n    end\n  end\nend",
      result: "A process that maintains state!",
      explanation: "The loop/1 function receives a message, processes it, then calls itself recursively with the new state. This is how processes maintain state between messages."
    },
    %{
      id: "state_evolution",
      title: "State Evolution",
      code: "pid = Counter.start()  # state: 0\nsend(pid, :increment)  # state: 1\nsend(pid, :increment)  # state: 2\nsend(pid, :increment)  # state: 3\n\nsend(pid, {:get, self()})\nreceive do\n  {:count, n} -> n  # => 3\nend",
      result: "3",
      explanation: "Each :increment message causes the loop to recurse with count + 1. The {:get, caller} message sends the current state back without modifying it."
    },
    %{
      id: "multiple_actions",
      title: "Multiple Actions",
      code: "defmodule KVStore do\n  def start, do: spawn(fn -> loop(%{}) end)\n\n  defp loop(map) do\n    receive do\n      {:put, key, value} ->\n        loop(Map.put(map, key, value))\n      {:get, key, caller} ->\n        send(caller, {:ok, Map.get(map, key)})\n        loop(map)\n      {:delete, key} ->\n        loop(Map.delete(map, key))\n    end\n  end\nend",
      result: "A simple key-value store process",
      explanation: "The state is a map. Different message patterns trigger different operations on the state. This is essentially a hand-rolled GenServer."
    },
    %{
      id: "stop",
      title: "Stopping the Loop",
      code: "defp loop(state) do\n  receive do\n    :stop ->\n      :ok  # Don't recurse = process exits\n    msg ->\n      new_state = handle(msg, state)\n      loop(new_state)\n  end\nend",
      result: "Process exits when loop stops recursing",
      explanation: "A process exits when its function returns. To stop the loop, simply don't call loop/1 again. The :stop message causes the function to return :ok."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:counter_value, fn -> 0 end)
     |> assign_new(:counter_history, fn -> [%{action: "start", state: 0}] end)
     |> assign_new(:kv_store, fn -> %{} end)
     |> assign_new(:kv_key, fn -> "" end)
     |> assign_new(:kv_value, fn -> "" end)
     |> assign_new(:kv_history, fn -> [%{action: "start", state: "%{}"}] end)
     |> assign_new(:show_genserver_hint, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Process State Loop</h2>
      <p class="text-sm opacity-70 mb-6">
        A process can maintain <strong>state</strong> by using a recursive receive loop. The state is
        passed as a parameter to each recursive call. This is the fundamental pattern behind
        <code class="font-mono bg-base-300 px-1 rounded">GenServer</code> - you are building one from scratch.
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

      <!-- Interactive Counter Process -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Counter Process</h3>
          <p class="text-xs opacity-60 mb-4">
            This simulates a counter process with a recursive receive loop.
            Each action sends a message and the loop recurses with new state.
          </p>

          <!-- Counter Display -->
          <div class="flex items-center justify-center gap-6 mb-4">
            <button phx-click="counter_decrement" phx-target={@myself} class="btn btn-circle btn-lg btn-outline">-</button>
            <div class="text-center">
              <div class="text-5xl font-bold font-mono"><%= @counter_value %></div>
              <div class="text-xs opacity-50 mt-1">counter state</div>
            </div>
            <button phx-click="counter_increment" phx-target={@myself} class="btn btn-circle btn-lg btn-primary">+</button>
          </div>

          <div class="flex justify-center gap-2 mb-4">
            <button phx-click="counter_double" phx-target={@myself} class="btn btn-sm btn-secondary">Double</button>
            <button phx-click="counter_reset" phx-target={@myself} class="btn btn-sm btn-ghost">Reset</button>
          </div>

          <!-- State Evolution -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">State Evolution (message log)</div>
            <div class="space-y-1 max-h-40 overflow-y-auto">
              <%= for {entry, idx} <- Enum.with_index(Enum.reverse(@counter_history)) do %>
                <div class="flex items-center gap-2 font-mono text-xs">
                  <span class="badge badge-primary badge-xs"><%= idx + 1 %></span>
                  <span class="opacity-50">recv</span>
                  <span class="text-accent"><%= entry.action %></span>
                  <span class="opacity-30">&rarr;</span>
                  <span class="text-info">loop(<%= entry.state %>)</span>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Code representation -->
          <div class="bg-base-300 rounded-lg p-3 mt-3 font-mono text-xs whitespace-pre-wrap">{counter_loop_code(@counter_value)}</div>
        </div>
      </div>

      <!-- Interactive KV Store -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Key-Value Store Process</h3>
          <p class="text-xs opacity-60 mb-4">
            A more complex process state: a map that supports put, get, and delete operations.
          </p>

          <form phx-submit="kv_put" phx-target={@myself} class="flex flex-wrap gap-2 mb-4 items-end">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Key</span></label>
              <input type="text" name="key" value={@kv_key} placeholder="name" class="input input-bordered input-sm font-mono w-32" autocomplete="off" />
            </div>
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Value</span></label>
              <input type="text" name="value" value={@kv_value} placeholder="Alice" class="input input-bordered input-sm font-mono w-32" autocomplete="off" />
            </div>
            <button type="submit" class="btn btn-sm btn-primary">Put</button>
          </form>

          <!-- Current State -->
          <div class="bg-base-300 rounded-lg p-4 mb-4">
            <div class="text-xs font-bold opacity-60 mb-2">Process State (map)</div>
            <%= if map_size(@kv_store) > 0 do %>
              <div class="flex flex-wrap gap-2">
                <%= for {k, v} <- @kv_store do %>
                  <div class="bg-base-100 rounded-lg px-3 py-1.5 flex items-center gap-2 border border-base-content/10">
                    <span class="font-mono text-xs text-accent"><%= k %></span>
                    <span class="opacity-30">=&gt;</span>
                    <span class="font-mono text-xs text-info"><%= v %></span>
                    <button
                      phx-click="kv_delete"
                      phx-target={@myself}
                      phx-value-key={k}
                      class="btn btn-xs btn-ghost text-error ml-1"
                    >x</button>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="font-mono text-xs opacity-40">%&lbrace;&rbrace; (empty map)</div>
            <% end %>
          </div>

          <!-- KV History -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">Message Log</div>
            <div class="space-y-1 max-h-32 overflow-y-auto">
              <%= for {entry, idx} <- Enum.with_index(Enum.reverse(@kv_history)) do %>
                <div class="flex items-center gap-2 font-mono text-xs">
                  <span class="badge badge-secondary badge-xs"><%= idx + 1 %></span>
                  <span class="text-accent"><%= entry.action %></span>
                  <span class="opacity-30">&rarr;</span>
                  <span class="text-info">loop(<%= entry.state %>)</span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- GenServer Connection -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">From DIY Loop to GenServer</h3>
            <button phx-click="toggle_genserver_hint" phx-target={@myself} class="btn btn-xs btn-ghost">
              <%= if @show_genserver_hint, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_genserver_hint do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                <h4 class="font-bold text-sm text-warning mb-2">DIY Process Loop</h4>
                <div class="font-mono text-xs whitespace-pre-wrap">{diy_counter_code()}</div>
              </div>

              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <h4 class="font-bold text-sm text-success mb-2">GenServer Equivalent</h4>
                <div class="font-mono text-xs whitespace-pre-wrap">{genserver_counter_code()}</div>
              </div>
            </div>

            <div class="alert alert-info text-sm mt-4">
              <span>GenServer abstracts the receive loop, state management, and message protocol. What you built here IS what GenServer does under the hood.</span>
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
              <span>Processes maintain <strong>state</strong> by passing it as a parameter to a recursive receive loop.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Each iteration: <strong>receive message &rarr; compute new state &rarr; recurse with new state</strong>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>The state is <strong>immutable within each iteration</strong>. New state is a new value passed to the next call.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>To <strong>stop</strong> a process loop, simply do not recurse (let the function return).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>This pattern is exactly what <strong>GenServer</strong> abstracts. Understanding it helps you master OTP.</span>
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

  def handle_event("counter_increment", _params, socket) do
    new_val = socket.assigns.counter_value + 1
    entry = %{action: ":increment", state: new_val}
    {:noreply,
     socket
     |> assign(counter_value: new_val)
     |> assign(counter_history: [entry | socket.assigns.counter_history])}
  end

  def handle_event("counter_decrement", _params, socket) do
    new_val = max(socket.assigns.counter_value - 1, 0)
    entry = %{action: ":decrement", state: new_val}
    {:noreply,
     socket
     |> assign(counter_value: new_val)
     |> assign(counter_history: [entry | socket.assigns.counter_history])}
  end

  def handle_event("counter_double", _params, socket) do
    new_val = socket.assigns.counter_value * 2
    entry = %{action: ":double", state: new_val}
    {:noreply,
     socket
     |> assign(counter_value: new_val)
     |> assign(counter_history: [entry | socket.assigns.counter_history])}
  end

  def handle_event("counter_reset", _params, socket) do
    entry = %{action: ":reset", state: 0}
    {:noreply,
     socket
     |> assign(counter_value: 0)
     |> assign(counter_history: [entry | socket.assigns.counter_history])}
  end

  def handle_event("kv_put", %{"key" => key, "value" => value}, socket) do
    key = String.trim(key)
    value = String.trim(value)
    if key == "" do
      {:noreply, socket}
    else
      new_store = Map.put(socket.assigns.kv_store, key, value)
      entry = %{action: "{:put, \"#{key}\", \"#{value}\"}", state: inspect(new_store)}
      {:noreply,
       socket
       |> assign(kv_store: new_store)
       |> assign(kv_key: "")
       |> assign(kv_value: "")
       |> assign(kv_history: [entry | socket.assigns.kv_history])}
    end
  end

  def handle_event("kv_delete", %{"key" => key}, socket) do
    new_store = Map.delete(socket.assigns.kv_store, key)
    entry = %{action: "{:delete, \"#{key}\"}", state: inspect(new_store)}
    {:noreply,
     socket
     |> assign(kv_store: new_store)
     |> assign(kv_history: [entry | socket.assigns.kv_history])}
  end

  def handle_event("toggle_genserver_hint", _params, socket) do
    {:noreply, assign(socket, show_genserver_hint: !socket.assigns.show_genserver_hint)}
  end

  # Helpers

  defp examples, do: @examples

  defp diy_counter_code do
    String.trim("""
    defmodule Counter do
      def start do
        spawn(fn -> loop(0) end)
      end

      defp loop(state) do
        receive do
          {:increment, caller} ->
            new = state + 1
            send(caller, {:ok, new})
            loop(new)
        end
      end
    end
    """)
  end

  defp genserver_counter_code do
    String.trim("""
    defmodule Counter do
      use GenServer

      def start_link(init) do
        GenServer.start_link(__MODULE__, init)
      end

      def init(state), do: {:ok, state}

      def handle_call(:increment, _from, state) do
        new = state + 1
        {:reply, new, new}
      end
    end
    """)
  end

  defp counter_loop_code(value) do
    "defp loop(#{value}) do\n" <>
    "  receive do\n" <>
    "    :increment  \u2192 loop(#{value + 1})\n" <>
    "    :decrement  \u2192 loop(#{max(value - 1, 0)})\n" <>
    "    :double     \u2192 loop(#{value * 2})\n" <>
    "    :reset      \u2192 loop(0)\n" <>
    "    {:get, caller} \u2192 send(caller, {:count, #{value}}); loop(#{value})\n" <>
    "  end\n" <>
    "end"
  end
end
