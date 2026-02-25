defmodule ElixirKatasWeb.ElixirKata63GenserverBasicsLive do
  use ElixirKatasWeb, :live_component

  @callbacks [
    %{
      name: "init/1",
      purpose: "Initialize the server state",
      triggered_by: "GenServer.start_link/3",
      returns: "&lbrace;:ok, state&rbrace; | &lbrace;:ok, state, timeout&rbrace; | :ignore | &lbrace;:stop, reason&rbrace;",
      example: "def init(initial_count) do\n  {:ok, %{count: initial_count}}\nend",
      color: "text-blue-500",
      bg: "bg-blue-500/10",
      border: "border-blue-500/30"
    },
    %{
      name: "handle_call/3",
      purpose: "Handle synchronous requests (client waits for reply)",
      triggered_by: "GenServer.call(pid, message)",
      returns: "&lbrace;:reply, reply, new_state&rbrace; | &lbrace;:noreply, new_state&rbrace; | &lbrace;:stop, reason, reply, new_state&rbrace;",
      example: "def handle_call(:get_count, _from, state) do\n  {:reply, state.count, state}\nend",
      color: "text-green-500",
      bg: "bg-green-500/10",
      border: "border-green-500/30"
    },
    %{
      name: "handle_cast/2",
      purpose: "Handle asynchronous requests (fire-and-forget)",
      triggered_by: "GenServer.cast(pid, message)",
      returns: "&lbrace;:noreply, new_state&rbrace; | &lbrace;:stop, reason, new_state&rbrace;",
      example: "def handle_cast(:increment, state) do\n  {:noreply, %{state | count: state.count + 1}}\nend",
      color: "text-purple-500",
      bg: "bg-purple-500/10",
      border: "border-purple-500/30"
    },
    %{
      name: "handle_info/2",
      purpose: "Handle all other messages (send/2, Process.send_after, etc.)",
      triggered_by: "send(pid, message) or Process.send_after/3",
      returns: "&lbrace;:noreply, new_state&rbrace; | &lbrace;:stop, reason, new_state&rbrace;",
      example: "def handle_info(:tick, state) do\n  {:noreply, %{state | ticks: state.ticks + 1}}\nend",
      color: "text-amber-500",
      bg: "bg-amber-500/10",
      border: "border-amber-500/30"
    }
  ]

  @flow_steps [
    %{
      step: 1,
      label: "Define Module",
      code: "defmodule Counter do\n  use GenServer",
      desc: "use GenServer brings in default implementations of all callbacks. You only override what you need.",
      side: "server"
    },
    %{
      step: 2,
      label: "Client API",
      code: "  # Client API\n  def start_link(initial \\\\ 0) do\n    GenServer.start_link(__MODULE__, initial)\n  end\n\n  def increment(pid) do\n    GenServer.cast(pid, :increment)\n  end\n\n  def get_count(pid) do\n    GenServer.call(pid, :get_count)\n  end",
      desc: "The client API is the public interface. These functions run in the CALLER's process. They send messages to the GenServer process.",
      side: "client"
    },
    %{
      step: 3,
      label: "Server Callbacks",
      code: "  # Server Callbacks\n  @impl true\n  def init(initial_count) do\n    {:ok, %{count: initial_count}}\n  end\n\n  @impl true\n  def handle_cast(:increment, state) do\n    {:noreply, %{state | count: state.count + 1}}\n  end\n\n  @impl true\n  def handle_call(:get_count, _from, state) do\n    {:reply, state.count, state}\n  end\nend",
      desc: "Server callbacks run INSIDE the GenServer process. They receive messages and return updated state.",
      side: "server"
    },
    %{
      step: 4,
      label: "Usage",
      code: "{:ok, pid} = Counter.start_link(0)\nCounter.increment(pid)\nCounter.increment(pid)\nCounter.get_count(pid)  # => 2",
      desc: "The client never touches the state directly. All interaction happens through message passing.",
      side: "client"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:selected_callback, fn -> nil end)
     |> assign_new(:flow_step, fn -> 0 end)
     |> assign_new(:show_full_example, fn -> false end)
     |> assign_new(:counter_value, fn -> 0 end)
     |> assign_new(:message_log, fn -> [] end)
     |> assign_new(:active_section, fn -> "callbacks" end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <h2 class="text-2xl font-bold mb-2">GenServer Basics</h2>
        <p class="text-sm opacity-70 mb-6">
          GenServer is the foundational OTP behaviour for building stateful server processes.
          It abstracts the common client-server pattern into a set of well-defined callbacks.
        </p>

        <!-- Section Tabs -->
        <div class="tabs tabs-boxed mb-6 bg-base-200">
          <button
            :for={tab <- [{"callbacks", "Callbacks"}, {"flow", "Build a GenServer"}, {"simulate", "Simulate"}]}
            phx-click="set_section"
            phx-target={@myself}
            phx-value-section={elem(tab, 0)}
            class={"tab " <> if(@active_section == elem(tab, 0), do: "tab-active", else: "")}
          >
            {elem(tab, 1)}
          </button>
        </div>

        <!-- Callbacks Section -->
        <div :if={@active_section == "callbacks"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            A GenServer has four core callbacks. Click each to explore its role, arguments, and return values.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              :for={cb <- callbacks()}
              class={"card border-2 cursor-pointer transition-all hover:shadow-lg " <>
                if(@selected_callback == cb.name, do: "#{cb.border} shadow-lg", else: "border-base-300")}
              phx-click="select_callback"
              phx-target={@myself}
              phx-value-name={cb.name}
            >
              <div class="card-body p-4">
                <h3 class={"card-title text-base font-mono #{cb.color}"}>{cb.name}</h3>
                <p class="text-sm opacity-70">{cb.purpose}</p>
                <div class="mt-2">
                  <span class="badge badge-sm badge-outline">Triggered by:</span>
                  <code class="text-xs font-mono ml-1">{cb.triggered_by}</code>
                </div>
              </div>
            </div>
          </div>

          <!-- Callback Detail -->
          <div :if={@selected_callback} class="card bg-base-200 shadow-md mt-4">
            <div class="card-body p-4">
              <% cb = Enum.find(callbacks(), &(&1.name == @selected_callback)) %>
              <h3 class={"card-title text-lg font-mono #{cb.color} mb-3"}>{cb.name}</h3>

              <div class="space-y-3">
                <div>
                  <span class="text-xs font-bold opacity-60">PURPOSE</span>
                  <p class="text-sm">{cb.purpose}</p>
                </div>

                <div>
                  <span class="text-xs font-bold opacity-60">RETURN VALUES</span>
                  <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mt-1">
                    {cb.returns}
                  </div>
                </div>

                <div>
                  <span class="text-xs font-bold opacity-60">EXAMPLE</span>
                  <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mt-1 whitespace-pre-wrap">{cb.example}</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Client vs Server -->
          <div class="alert mt-4">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <div>
              <h4 class="font-bold">Client vs Server</h4>
              <p class="text-sm">
                A GenServer module typically has two halves: <strong>Client API</strong> functions
                (like <code>start_link/1</code>, <code>increment/1</code>) that run in the caller's process,
                and <strong>Server Callbacks</strong> (like <code>init/1</code>, <code>handle_call/3</code>)
                that run inside the GenServer process. The client functions use
                <code>GenServer.call/2</code> and <code>GenServer.cast/2</code> to send messages to the server.
              </p>
            </div>
          </div>
        </div>

        <!-- Build a GenServer Section -->
        <div :if={@active_section == "flow"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            Walk through building a simple Counter GenServer step by step.
          </p>

          <div class="space-y-3">
            <div
              :for={{step, idx} <- Enum.with_index(flow_steps())}
              class={"rounded-lg p-4 border-2 cursor-pointer transition-all " <>
                cond do
                  idx == @flow_step -> "border-primary bg-primary/10"
                  idx < @flow_step -> "border-base-300 bg-base-100 opacity-70"
                  true -> "border-base-300 bg-base-100 opacity-40"
                end}
              phx-click="flow_goto"
              phx-target={@myself}
              phx-value-step={idx}
            >
              <div class="flex items-start gap-3">
                <div class={"flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold " <>
                  if(idx <= @flow_step, do: "bg-primary text-primary-content", else: "bg-base-300 text-base-content/50")}>
                  {step.step}
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-1">
                    <span class="font-bold text-sm">{step.label}</span>
                    <span class={"badge badge-xs " <> if(step.side == "client", do: "badge-info", else: "badge-success")}>
                      {step.side}
                    </span>
                  </div>
                  <div :if={idx <= @flow_step} class="bg-base-300 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap mb-2">
                    {step.code}
                  </div>
                  <p :if={idx <= @flow_step} class="text-xs opacity-70">{step.desc}</p>
                </div>
              </div>
            </div>
          </div>

          <div class="flex gap-2 mt-4">
            <button
              phx-click="flow_prev"
              phx-target={@myself}
              disabled={@flow_step <= 0}
              class="btn btn-sm btn-outline"
            >
              Previous
            </button>
            <button
              phx-click="flow_next"
              phx-target={@myself}
              disabled={@flow_step >= length(flow_steps()) - 1}
              class="btn btn-sm btn-primary"
            >
              Next
            </button>
            <button
              phx-click="flow_reset"
              phx-target={@myself}
              class="btn btn-sm btn-ghost"
            >
              Reset
            </button>
          </div>

          <!-- Full Example Toggle -->
          <div class="mt-4">
            <button
              phx-click="toggle_full_example"
              phx-target={@myself}
              class="btn btn-sm btn-outline"
            >
              {if @show_full_example, do: "Hide Full Example", else: "Show Full Example"}
            </button>
            <div :if={@show_full_example} class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mt-3">{full_counter_example()}</div>
          </div>
        </div>

        <!-- Simulate Section -->
        <div :if={@active_section == "simulate"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            Simulate a GenServer's message flow. Each button sends a message and you can see
            the callback that handles it and the resulting state change.
          </p>

          <!-- Current State Display -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">GenServer State</h3>
                <span class="badge badge-primary font-mono">count: {@counter_value}</span>
              </div>

              <div class="flex flex-wrap gap-2">
                <button
                  phx-click="sim_increment"
                  phx-target={@myself}
                  class="btn btn-sm btn-success"
                >
                  cast(:increment)
                </button>
                <button
                  phx-click="sim_decrement"
                  phx-target={@myself}
                  class="btn btn-sm btn-warning"
                >
                  cast(:decrement)
                </button>
                <button
                  phx-click="sim_get_count"
                  phx-target={@myself}
                  class="btn btn-sm btn-info"
                >
                  call(:get_count)
                </button>
                <button
                  phx-click="sim_send_info"
                  phx-target={@myself}
                  class="btn btn-sm btn-accent"
                >
                  send(:ping)
                </button>
                <button
                  phx-click="sim_reset"
                  phx-target={@myself}
                  class="btn btn-sm btn-ghost"
                >
                  Reset
                </button>
              </div>
            </div>
          </div>

          <!-- Message Log -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Message Log</h3>
              <div :if={@message_log == []} class="text-sm opacity-50 text-center py-4">
                Click a button above to see the message flow.
              </div>
              <div class="space-y-2">
                <div
                  :for={entry <- @message_log}
                  class={"rounded-lg p-3 border-l-4 text-sm " <> entry.border}
                >
                  <div class="flex items-center gap-2 mb-1">
                    <span class={"badge badge-sm " <> entry.badge}>{entry.callback}</span>
                    <span class="font-mono text-xs opacity-60">{entry.trigger}</span>
                  </div>
                  <div class="font-mono text-xs">
                    <span class="opacity-50">state: </span>
                    <span>{entry.state_display}</span>
                    <span :if={entry.reply} class="ml-2 text-info">
                      reply: {entry.reply}
                    </span>
                  </div>
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
                  <strong>use GenServer</strong> provides default implementations of all callbacks.
                  You only override the ones you need with <code>@impl true</code>.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">2</span>
                <span>
                  <strong>Client/Server split:</strong> Public API functions run in the caller's process;
                  callbacks run in the GenServer process.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">3</span>
                <span>
                  <strong>Single process:</strong> A GenServer processes one message at a time,
                  so state updates are inherently serialized (no race conditions).
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">4</span>
                <span>
                  <strong>@impl true</strong> annotation tells the compiler this function implements
                  a behaviour callback, catching typos and missing callbacks at compile time.
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

  def handle_event("select_callback", %{"name" => name}, socket) do
    selected = if socket.assigns.selected_callback == name, do: nil, else: name
    {:noreply, assign(socket, selected_callback: selected)}
  end

  def handle_event("flow_goto", %{"step" => step_str}, socket) do
    {:noreply, assign(socket, flow_step: String.to_integer(step_str))}
  end

  def handle_event("flow_next", _params, socket) do
    max_step = length(flow_steps()) - 1
    {:noreply, assign(socket, flow_step: min(socket.assigns.flow_step + 1, max_step))}
  end

  def handle_event("flow_prev", _params, socket) do
    {:noreply, assign(socket, flow_step: max(socket.assigns.flow_step - 1, 0))}
  end

  def handle_event("flow_reset", _params, socket) do
    {:noreply, assign(socket, flow_step: 0)}
  end

  def handle_event("toggle_full_example", _params, socket) do
    {:noreply, assign(socket, show_full_example: !socket.assigns.show_full_example)}
  end

  def handle_event("sim_increment", _params, socket) do
    new_count = socket.assigns.counter_value + 1
    entry = %{
      callback: "handle_cast/2",
      trigger: "GenServer.cast(pid, :increment)",
      state_display: "%{count: #{new_count}}",
      reply: nil,
      border: "border-purple-500",
      badge: "badge-secondary"
    }

    {:noreply,
     socket
     |> assign(counter_value: new_count)
     |> assign(message_log: [entry | socket.assigns.message_log])}
  end

  def handle_event("sim_decrement", _params, socket) do
    new_count = socket.assigns.counter_value - 1
    entry = %{
      callback: "handle_cast/2",
      trigger: "GenServer.cast(pid, :decrement)",
      state_display: "%{count: #{new_count}}",
      reply: nil,
      border: "border-purple-500",
      badge: "badge-warning"
    }

    {:noreply,
     socket
     |> assign(counter_value: new_count)
     |> assign(message_log: [entry | socket.assigns.message_log])}
  end

  def handle_event("sim_get_count", _params, socket) do
    entry = %{
      callback: "handle_call/3",
      trigger: "GenServer.call(pid, :get_count)",
      state_display: "%{count: #{socket.assigns.counter_value}}",
      reply: inspect(socket.assigns.counter_value),
      border: "border-green-500",
      badge: "badge-success"
    }

    {:noreply, assign(socket, message_log: [entry | socket.assigns.message_log])}
  end

  def handle_event("sim_send_info", _params, socket) do
    entry = %{
      callback: "handle_info/2",
      trigger: "send(pid, :ping)",
      state_display: "%{count: #{socket.assigns.counter_value}} (unchanged)",
      reply: nil,
      border: "border-amber-500",
      badge: "badge-accent"
    }

    {:noreply, assign(socket, message_log: [entry | socket.assigns.message_log])}
  end

  def handle_event("sim_reset", _params, socket) do
    {:noreply, assign(socket, counter_value: 0, message_log: [])}
  end

  defp callbacks, do: @callbacks
  defp flow_steps, do: @flow_steps

  defp full_counter_example do
    "defmodule Counter do\n" <>
    "  use GenServer\n" <>
    "\n" <>
    "  # --- Client API ---\n" <>
    "  def start_link(initial \\\\ 0) do\n" <>
    "    GenServer.start_link(__MODULE__, initial)\n" <>
    "  end\n" <>
    "\n" <>
    "  def increment(pid), do: GenServer.cast(pid, :increment)\n" <>
    "  def decrement(pid), do: GenServer.cast(pid, :decrement)\n" <>
    "  def get_count(pid), do: GenServer.call(pid, :get_count)\n" <>
    "\n" <>
    "  # --- Server Callbacks ---\n" <>
    "  @impl true\n" <>
    "  def init(initial_count) do\n" <>
    "    {:ok, %{count: initial_count}}\n" <>
    "  end\n" <>
    "\n" <>
    "  @impl true\n" <>
    "  def handle_cast(:increment, state) do\n" <>
    "    {:noreply, %{state | count: state.count + 1}}\n" <>
    "  end\n" <>
    "\n" <>
    "  def handle_cast(:decrement, state) do\n" <>
    "    {:noreply, %{state | count: state.count - 1}}\n" <>
    "  end\n" <>
    "\n" <>
    "  @impl true\n" <>
    "  def handle_call(:get_count, _from, state) do\n" <>
    "    {:reply, state.count, state}\n" <>
    "  end\n" <>
    "end"
  end
end
