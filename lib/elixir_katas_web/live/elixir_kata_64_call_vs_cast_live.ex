defmodule ElixirKatasWeb.ElixirKata64CallVsCastLive do
  use ElixirKatasWeb, :live_component

  @comparisons [
    %{
      aspect: "Mechanism",
      call_val: "Synchronous - caller blocks until reply",
      cast_val: "Asynchronous - fire and forget"
    },
    %{
      aspect: "Return Value",
      call_val: "Returns the reply from the server",
      cast_val: "Returns :ok immediately"
    },
    %{
      aspect: "Callback",
      call_val: "handle_call/3 (msg, from, state)",
      cast_val: "handle_cast/2 (msg, state)"
    },
    %{
      aspect: "Reply",
      call_val: "&lbrace;:reply, reply, new_state&rbrace;",
      cast_val: "&lbrace;:noreply, new_state&rbrace;"
    },
    %{
      aspect: "Timeout",
      call_val: "Default 5s, configurable with 3rd arg",
      cast_val: "No timeout (no waiting)"
    },
    %{
      aspect: "Error Handling",
      call_val: "Caller gets crash/timeout errors",
      cast_val: "Caller unaware of server errors"
    },
    %{
      aspect: "Back-Pressure",
      call_val: "Natural - caller waits before sending more",
      cast_val: "None - can flood the mailbox"
    }
  ]

  @scenarios [
    %{
      id: "read",
      title: "Reading a value",
      recommendation: "call",
      reason: "You need the value back. Cast can't return data.",
      code_call: "GenServer.call(pid, :get_balance)\n# => 150.00",
      code_cast: "GenServer.cast(pid, :get_balance)\n# => :ok  (but where's the balance?)"
    },
    %{
      id: "write",
      title: "Updating state (caller doesn't need confirmation)",
      recommendation: "cast",
      reason: "If you don't need confirmation, cast avoids blocking. Good for logging, metrics, etc.",
      code_call: "GenServer.call(pid, {:log, msg})\n# Blocks until log is written (slow)",
      code_cast: "GenServer.cast(pid, {:log, msg})\n# Returns immediately, log happens async"
    },
    %{
      id: "validation",
      title: "Operation that might fail",
      recommendation: "call",
      reason: "The caller needs to know if it succeeded or failed to handle the error.",
      code_call: "case GenServer.call(pid, {:withdraw, 200}) do\n  {:ok, balance} -> \"New balance: \#{balance}\"\n  {:error, :insufficient} -> \"Not enough funds\"\nend",
      code_cast: "GenServer.cast(pid, {:withdraw, 200})\n# Hope it works? No feedback!"
    },
    %{
      id: "broadcast",
      title: "Notifying multiple processes",
      recommendation: "cast",
      reason: "Waiting for replies from many processes would be very slow. Cast all at once.",
      code_call: "# Slow: wait for each one\nEnum.each(pids, &GenServer.call(&1, {:notify, event}))",
      code_cast: "# Fast: fire and forget to all\nEnum.each(pids, &GenServer.cast(&1, {:notify, event}))"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_section, fn -> "compare" end)
     |> assign_new(:selected_scenario, fn -> nil end)
     |> assign_new(:sim_mode, fn -> nil end)
     |> assign_new(:sim_log, fn -> [] end)
     |> assign_new(:sim_state, fn -> 0 end)
     |> assign_new(:sim_blocked, fn -> false end)
     |> assign_new(:sim_reply, fn -> nil end)
     |> assign_new(:timeout_demo_state, fn -> "idle" end)
     |> assign_new(:timeout_value, fn -> "5000" end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <h2 class="text-2xl font-bold mb-2">Call vs Cast</h2>
        <p class="text-sm opacity-70 mb-6">
          GenServer provides two ways to send messages: <code>call</code> (synchronous, waits for reply)
          and <code>cast</code> (asynchronous, fire-and-forget). Choosing the right one matters for
          performance, reliability, and correctness.
        </p>

        <!-- Section Tabs -->
        <div class="tabs tabs-boxed mb-6 bg-base-200">
          <button
            :for={tab <- [{"compare", "Comparison"}, {"scenarios", "When to Use"}, {"simulate", "Simulate"}, {"timeout", "Timeout"}]}
            phx-click="set_section"
            phx-target={@myself}
            phx-value-section={elem(tab, 0)}
            class={"tab " <> if(@active_section == elem(tab, 0), do: "tab-active", else: "")}
          >
            {elem(tab, 1)}
          </button>
        </div>

        <!-- Comparison Table -->
        <div :if={@active_section == "compare"} class="space-y-4">
          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th class="w-1/5">Aspect</th>
                  <th class="w-2/5">
                    <span class="text-green-500 font-mono">GenServer.call/2</span>
                  </th>
                  <th class="w-2/5">
                    <span class="text-purple-500 font-mono">GenServer.cast/2</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr :for={row <- comparisons()}>
                  <td class="font-bold text-sm">{row.aspect}</td>
                  <td class="text-sm bg-green-500/5">{row.call_val}</td>
                  <td class="text-sm bg-purple-500/5">{row.cast_val}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Visual Diagram -->
          <div class="card bg-base-200 shadow-md mt-4">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Message Flow</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Call Flow -->
                <div class="bg-green-500/10 border border-green-500/30 rounded-lg p-4">
                  <h4 class="font-bold text-green-500 text-sm mb-3">call (synchronous)</h4>
                  <div class="space-y-2 font-mono text-xs">
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-info">Caller</span>
                      <span>GenServer.call(pid, :get)</span>
                    </div>
                    <div class="text-center opacity-50">--- blocks ---</div>
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-success">Server</span>
                      <span>handle_call(:get, from, state)</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-success">Server</span>
                      <span>&lbrace;:reply, value, state&rbrace;</span>
                    </div>
                    <div class="text-center opacity-50">--- unblocks ---</div>
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-info">Caller</span>
                      <span>receives value</span>
                    </div>
                  </div>
                </div>

                <!-- Cast Flow -->
                <div class="bg-purple-500/10 border border-purple-500/30 rounded-lg p-4">
                  <h4 class="font-bold text-purple-500 text-sm mb-3">cast (asynchronous)</h4>
                  <div class="space-y-2 font-mono text-xs">
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-info">Caller</span>
                      <span>GenServer.cast(pid, :inc)</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-info">Caller</span>
                      <span>gets :ok immediately</span>
                    </div>
                    <div class="text-center opacity-50">--- continues ---</div>
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-secondary">Server</span>
                      <span>handle_cast(:inc, state)</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="badge badge-sm badge-secondary">Server</span>
                      <span>&lbrace;:noreply, new_state&rbrace;</span>
                    </div>
                    <div class="text-center opacity-50">(caller already moved on)</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Scenarios Section -->
        <div :if={@active_section == "scenarios"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            Click a scenario to see the recommended approach and why.
          </p>

          <div class="space-y-3">
            <div
              :for={scenario <- scenarios()}
              class={"card border-2 cursor-pointer transition-all hover:shadow-md " <>
                if(@selected_scenario == scenario.id, do: "border-primary shadow-md", else: "border-base-300")}
              phx-click="select_scenario"
              phx-target={@myself}
              phx-value-id={scenario.id}
            >
              <div class="card-body p-4">
                <div class="flex items-center justify-between mb-2">
                  <h3 class="card-title text-sm">{scenario.title}</h3>
                  <span class={"badge badge-sm " <>
                    if(scenario.recommendation == "call", do: "badge-success", else: "badge-secondary")}>
                    {scenario.recommendation}
                  </span>
                </div>

                <div :if={@selected_scenario == scenario.id} class="space-y-3 mt-2">
                  <p class="text-sm opacity-70">{scenario.reason}</p>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div class="bg-green-500/10 rounded-lg p-3">
                      <div class="text-xs font-bold text-green-500 mb-1">Using call:</div>
                      <div class="font-mono text-xs whitespace-pre-wrap">{scenario.code_call}</div>
                    </div>
                    <div class="bg-purple-500/10 rounded-lg p-3">
                      <div class="text-xs font-bold text-purple-500 mb-1">Using cast:</div>
                      <div class="font-mono text-xs whitespace-pre-wrap">{scenario.code_cast}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Simulate Section -->
        <div :if={@active_section == "simulate"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            See the difference in behavior. Watch how call blocks until a reply,
            while cast returns immediately.
          </p>

          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">Server State</h3>
                <span class="badge badge-primary font-mono">count: {@sim_state}</span>
              </div>

              <div class="flex flex-wrap gap-2 mb-4">
                <button
                  phx-click="sim_call_get"
                  phx-target={@myself}
                  disabled={@sim_blocked}
                  class="btn btn-sm btn-success"
                >
                  call(:get_count)
                </button>
                <button
                  phx-click="sim_call_inc"
                  phx-target={@myself}
                  disabled={@sim_blocked}
                  class="btn btn-sm btn-success btn-outline"
                >
                  call(:increment)
                </button>
                <button
                  phx-click="sim_cast_inc"
                  phx-target={@myself}
                  disabled={@sim_blocked}
                  class="btn btn-sm btn-secondary"
                >
                  cast(:increment)
                </button>
                <button
                  phx-click="sim_cast_dec"
                  phx-target={@myself}
                  disabled={@sim_blocked}
                  class="btn btn-sm btn-secondary btn-outline"
                >
                  cast(:decrement)
                </button>
                <button
                  phx-click="sim_clear"
                  phx-target={@myself}
                  class="btn btn-sm btn-ghost"
                >
                  Clear
                </button>
              </div>

              <!-- Reply display -->
              <div :if={@sim_reply} class="alert alert-success text-sm mb-4">
                <span class="font-mono">Reply received: {@sim_reply}</span>
              </div>

              <!-- Log -->
              <div class="space-y-2">
                <div :if={@sim_log == []} class="text-sm opacity-50 text-center py-4">
                  Send some messages to see the flow.
                </div>
                <div
                  :for={entry <- @sim_log}
                  class={"rounded-lg p-3 border-l-4 text-sm font-mono " <> entry.border}
                >
                  <div class="flex items-center gap-2">
                    <span class={"badge badge-xs " <> entry.badge}>{entry.type}</span>
                    <span class="text-xs">{entry.message}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Timeout Section -->
        <div :if={@active_section == "timeout"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">GenServer.call Timeout</h3>
              <p class="text-sm opacity-70 mb-4">
                <code>GenServer.call/3</code> has a default timeout of 5 seconds (5000ms).
                If the server doesn't reply in time, the caller crashes with an <code>exit</code>.
              </p>

              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4 whitespace-pre-wrap">{timeout_examples_code()}</div>

              <h4 class="text-sm font-bold mb-2">Timeout Behavior Demo</h4>
              <p class="text-xs opacity-60 mb-3">
                Imagine a server that takes 3 seconds to respond. See what happens with different timeout values.
              </p>

              <div class="flex flex-wrap gap-2 mb-4">
                <button
                  phx-click="timeout_sim"
                  phx-target={@myself}
                  phx-value-timeout="1000"
                  class={"btn btn-sm " <> if(@timeout_value == "1000", do: "btn-error", else: "btn-outline")}
                >
                  timeout: 1s
                </button>
                <button
                  phx-click="timeout_sim"
                  phx-target={@myself}
                  phx-value-timeout="5000"
                  class={"btn btn-sm " <> if(@timeout_value == "5000", do: "btn-warning", else: "btn-outline")}
                >
                  timeout: 5s (default)
                </button>
                <button
                  phx-click="timeout_sim"
                  phx-target={@myself}
                  phx-value-timeout="10000"
                  class={"btn btn-sm " <> if(@timeout_value == "10000", do: "btn-success", else: "btn-outline")}
                >
                  timeout: 10s
                </button>
              </div>

              <div class={"alert text-sm " <>
                case @timeout_demo_state do
                  "idle" -> ""
                  "waiting" -> "alert-info"
                  "success" -> "alert-success"
                  "timeout" -> "alert-error"
                  _ -> ""
                end}>
                <span :if={@timeout_demo_state == "idle"} class="opacity-50">
                  Click a timeout button to simulate the call.
                </span>
                <span :if={@timeout_demo_state == "waiting"}>
                  Caller blocked... waiting for server reply (server takes 3s)
                </span>
                <span :if={@timeout_demo_state == "success"}>
                  Server replied in time. Caller received the response.
                </span>
                <span :if={@timeout_demo_state == "timeout"}>
                  ** (exit) exited in: GenServer.call(pid, :slow_op, {@timeout_value})
                  ** (EXIT) time out
                </span>
              </div>

              <div class="mt-4 bg-base-300 rounded-lg p-3">
                <h4 class="text-xs font-bold opacity-60 mb-2">Handling Timeouts Gracefully</h4>
                <div class="font-mono text-sm whitespace-pre-wrap">{timeout_catch_code()}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Key Concepts -->
        <div class="card bg-base-200 shadow-md mt-6">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-3">Rules of Thumb</h3>
            <div class="space-y-3 text-sm">
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-success badge-sm mt-0.5">call</span>
                <span>Use <strong>call</strong> when you need a reply, need confirmation, or want back-pressure.</span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-secondary badge-sm mt-0.5">cast</span>
                <span>Use <strong>cast</strong> for notifications, logging, metrics, or when the caller truly doesn't care about the result.</span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-warning badge-sm mt-0.5">tip</span>
                <span><strong>When in doubt, use call.</strong> It's safer because you get error feedback and natural back-pressure. Only switch to cast when you have a reason.</span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-error badge-sm mt-0.5">danger</span>
                <span><strong>Cast can flood mailboxes.</strong> Without back-pressure, a fast producer can overwhelm a slow GenServer. The mailbox grows unbounded, consuming memory.</span>
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

  def handle_event("select_scenario", %{"id" => id}, socket) do
    selected = if socket.assigns.selected_scenario == id, do: nil, else: id
    {:noreply, assign(socket, selected_scenario: selected)}
  end

  def handle_event("sim_call_get", _params, socket) do
    entry_send = %{
      type: "call",
      message: "Caller -> Server: GenServer.call(pid, :get_count)",
      border: "border-green-500",
      badge: "badge-success"
    }

    entry_reply = %{
      type: "reply",
      message: "Server -> Caller: {:reply, #{socket.assigns.sim_state}, state}",
      border: "border-green-500",
      badge: "badge-info"
    }

    {:noreply,
     socket
     |> assign(sim_reply: inspect(socket.assigns.sim_state))
     |> assign(sim_log: [entry_reply, entry_send | socket.assigns.sim_log])}
  end

  def handle_event("sim_call_inc", _params, socket) do
    new_state = socket.assigns.sim_state + 1

    entry_send = %{
      type: "call",
      message: "Caller -> Server: GenServer.call(pid, :increment)",
      border: "border-green-500",
      badge: "badge-success"
    }

    entry_reply = %{
      type: "reply",
      message: "Server -> Caller: {:reply, :ok, %{count: #{new_state}}}",
      border: "border-green-500",
      badge: "badge-info"
    }

    {:noreply,
     socket
     |> assign(sim_state: new_state)
     |> assign(sim_reply: ":ok")
     |> assign(sim_log: [entry_reply, entry_send | socket.assigns.sim_log])}
  end

  def handle_event("sim_cast_inc", _params, socket) do
    new_state = socket.assigns.sim_state + 1

    entry_send = %{
      type: "cast",
      message: "Caller -> Server: GenServer.cast(pid, :increment)",
      border: "border-purple-500",
      badge: "badge-secondary"
    }

    entry_ack = %{
      type: "cast",
      message: "Caller gets :ok immediately (doesn't wait)",
      border: "border-purple-500",
      badge: "badge-ghost"
    }

    entry_handle = %{
      type: "server",
      message: "Server processes: handle_cast(:increment, state) -> {:noreply, %{count: #{new_state}}}",
      border: "border-purple-500",
      badge: "badge-secondary"
    }

    {:noreply,
     socket
     |> assign(sim_state: new_state)
     |> assign(sim_reply: nil)
     |> assign(sim_log: [entry_handle, entry_ack, entry_send | socket.assigns.sim_log])}
  end

  def handle_event("sim_cast_dec", _params, socket) do
    new_state = socket.assigns.sim_state - 1

    entry_send = %{
      type: "cast",
      message: "Caller -> Server: GenServer.cast(pid, :decrement)",
      border: "border-purple-500",
      badge: "badge-secondary"
    }

    entry_handle = %{
      type: "server",
      message: "Server processes: handle_cast(:decrement, state) -> {:noreply, %{count: #{new_state}}}",
      border: "border-purple-500",
      badge: "badge-secondary"
    }

    {:noreply,
     socket
     |> assign(sim_state: new_state)
     |> assign(sim_reply: nil)
     |> assign(sim_log: [entry_handle, entry_send | socket.assigns.sim_log])}
  end

  def handle_event("sim_clear", _params, socket) do
    {:noreply, assign(socket, sim_state: 0, sim_log: [], sim_reply: nil)}
  end

  def handle_event("timeout_sim", %{"timeout" => timeout_str}, socket) do
    timeout = String.to_integer(timeout_str)
    server_time = 3000

    result = if timeout >= server_time, do: "success", else: "timeout"

    {:noreply,
     socket
     |> assign(timeout_value: timeout_str)
     |> assign(timeout_demo_state: result)}
  end

  defp comparisons, do: @comparisons
  defp scenarios, do: @scenarios

  defp timeout_catch_code do
    String.trim("""
    try do
      GenServer.call(pid, :slow_op, 2_000)
    catch
      :exit, {:timeout, _} ->
        {:error, :timeout}
    end
    """)
  end

  defp timeout_examples_code do
    String.trim("""
    GenServer.call(pid, :slow_operation)
    # Default: waits up to 5000ms

    GenServer.call(pid, :slow_operation, 10_000)
    # Custom: waits up to 10 seconds

    GenServer.call(pid, :operation, :infinity)
    # Waits forever (use with caution!)
    """)
  end
end
