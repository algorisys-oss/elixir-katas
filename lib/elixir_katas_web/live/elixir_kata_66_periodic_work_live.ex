defmodule ElixirKatasWeb.ElixirKata66PeriodicWorkLive do
  use ElixirKatasWeb, :live_component

  @timer_patterns [
    %{
      id: "send_after",
      title: "Process.send_after/3",
      description: "Sends a message to a process after a delay. The most common pattern for periodic work in GenServer.",
      code: "defmodule Poller do\n  use GenServer\n\n  def init(interval) do\n    schedule_poll(interval)\n    {:ok, %{interval: interval, count: 0}}\n  end\n\n  def handle_info(:poll, state) do\n    # Do the work\n    new_state = %{state | count: state.count + 1}\n    # Schedule next poll\n    schedule_poll(state.interval)\n    {:noreply, new_state}\n  end\n\n  defp schedule_poll(interval) do\n    Process.send_after(self(), :poll, interval)\n  end\nend",
      key_point: "Self-scheduling: each handle_info schedules the next tick. This creates a reliable recurring pattern."
    },
    %{
      id: "timer_send_interval",
      title: ":timer.send_interval/2",
      description: "Erlang's timer that sends a message at a fixed interval. Simpler but less flexible.",
      code: "def init(interval) do\n  :timer.send_interval(interval, :tick)\n  {:ok, %{count: 0}}\nend\n\ndef handle_info(:tick, state) do\n  {:noreply, %{state | count: state.count + 1}}\nend",
      key_point: "Fires at fixed intervals regardless of processing time. Can cause message buildup if work takes longer than the interval."
    },
    %{
      id: "handle_continue",
      title: "handle_continue/2",
      description: "Not a timer, but useful for deferred initialization that should happen after init returns.",
      code: "def init(args) do\n  {:ok, %{data: nil}, {:continue, :load_data}}\nend\n\ndef handle_continue(:load_data, state) do\n  data = load_expensive_data()\n  {:noreply, %{state | data: data}}\nend",
      key_point: "handle_continue runs immediately after init, but doesn't block the caller of start_link."
    }
  ]

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <h2 class="text-2xl font-bold mb-2">Periodic Work</h2>
        <p class="text-sm opacity-70 mb-6">
          GenServers often need to perform work at regular intervals: polling an API, sending heartbeats,
          cleaning up stale data, or refreshing caches. The key pattern uses
          <code>Process.send_after/3</code> with self-scheduling in <code>handle_info/2</code>.
        </p>

        <!-- Section Tabs -->
        <div class="tabs tabs-boxed mb-6 bg-base-200">
          <button
            :for={tab <- [{"patterns", "Timer Patterns"}, {"heartbeat", "Heartbeat Demo"}, {"poll", "Polling Demo"}, {"countdown", "Countdown"}]}
            phx-click="set_section"
            phx-target={@myself}
            phx-value-section={elem(tab, 0)}
            class={"tab " <> if(@active_section == elem(tab, 0), do: "tab-active", else: "")}
          >
            {elem(tab, 1)}
          </button>
        </div>

        <!-- Timer Patterns -->
        <div :if={@active_section == "patterns"} class="space-y-4">
          <div class="space-y-3">
            <div
              :for={pat <- timer_patterns()}
              class={"card border-2 cursor-pointer transition-all hover:shadow-md " <>
                if(@selected_pattern == pat.id, do: "border-primary shadow-md", else: "border-base-300")}
              phx-click="select_pattern"
              phx-target={@myself}
              phx-value-id={pat.id}
            >
              <div class="card-body p-4">
                <h3 class="card-title text-sm font-mono">{pat.title}</h3>
                <p class="text-xs opacity-60">{pat.description}</p>

                <div :if={@selected_pattern == pat.id} class="mt-3 space-y-3">
                  <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">
                    {pat.code}
                  </div>
                  <div class="alert text-xs">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    <span>{pat.key_point}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- send_after vs send_interval -->
          <div class="card bg-base-200 shadow-md mt-4">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">send_after vs send_interval</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-green-500/10 border border-green-500/30 rounded-lg p-4">
                  <h4 class="font-bold text-green-500 text-sm mb-2">Process.send_after (recommended)</h4>
                  <div class="text-xs space-y-1">
                    <p>Schedules ONE message after a delay.</p>
                    <p>Self-scheduling: each handler schedules the next.</p>
                    <p>Interval = delay AFTER work completes.</p>
                    <p>No message buildup if work is slow.</p>
                    <p>Easy to change interval dynamically.</p>
                    <p>Easy to cancel (returns a timer ref).</p>
                  </div>
                </div>
                <div class="bg-amber-500/10 border border-amber-500/30 rounded-lg p-4">
                  <h4 class="font-bold text-amber-500 text-sm mb-2">:timer.send_interval</h4>
                  <div class="text-xs space-y-1">
                    <p>Sends a message every N ms forever.</p>
                    <p>Fixed interval from start time.</p>
                    <p>Interval = wall clock time between sends.</p>
                    <p>Messages pile up if work takes longer.</p>
                    <p>Cannot change interval without canceling.</p>
                    <p>Must cancel with :timer.cancel/1.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Heartbeat Demo -->
        <div :if={@active_section == "heartbeat"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">Heartbeat Server</h3>
                <div class="flex items-center gap-2">
                  <div class={"w-3 h-3 rounded-full " <> if(@heartbeat_running, do: "bg-success animate-pulse", else: "bg-base-300")}></div>
                  <span class="text-xs opacity-60">{if @heartbeat_running, do: "Running", else: "Stopped"}</span>
                </div>
              </div>

              <p class="text-xs opacity-60 mb-4">
                A heartbeat server sends a periodic signal. This pattern is used for health checks,
                keep-alive connections, and monitoring.
              </p>

              <div class="flex items-center gap-3 mb-4">
                <label class="text-xs font-bold">Interval:</label>
                <input
                  type="range"
                  min="200"
                  max="3000"
                  step="100"
                  value={@heartbeat_interval}
                  phx-change="set_heartbeat_interval"
                  phx-target={@myself}
                  name="interval"
                  class="range range-sm range-primary flex-1"
                />
                <span class="badge badge-sm font-mono">{@heartbeat_interval}ms</span>
              </div>

              <div class="flex items-center gap-3 mb-4">
                <span class="text-2xl font-bold text-primary font-mono">{@heartbeat_count}</span>
                <span class="text-xs opacity-60">beats</span>
              </div>

              <div class="flex gap-2 mb-4">
                <button
                  :if={!@heartbeat_running}
                  phx-click="heartbeat_start"
                  phx-target={@myself}
                  class="btn btn-sm btn-success"
                >
                  Start
                </button>
                <button
                  :if={@heartbeat_running}
                  phx-click="heartbeat_stop"
                  phx-target={@myself}
                  class="btn btn-sm btn-error"
                >
                  Stop
                </button>
                <button
                  phx-click="heartbeat_reset"
                  phx-target={@myself}
                  class="btn btn-sm btn-ghost"
                >
                  Reset
                </button>
              </div>

              <!-- Heartbeat Log -->
              <div class="bg-base-300 rounded-lg p-3 max-h-40 overflow-y-auto">
                <div :if={@heartbeat_log == []} class="text-xs opacity-50 text-center">
                  Start the heartbeat to see the log.
                </div>
                <div :for={entry <- Enum.take(@heartbeat_log, 15)} class="text-xs font-mono opacity-70">
                  {entry}
                </div>
              </div>
            </div>
          </div>

          <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><span class="opacity-50"># This heartbeat is powered by:</span>{heartbeat_code()}</div>
        </div>

        <!-- Polling Demo -->
        <div :if={@active_section == "poll"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">API Poller Simulation</h3>
                <div class="flex items-center gap-2">
                  <div class={"w-3 h-3 rounded-full " <> if(@poll_running, do: "bg-success animate-pulse", else: "bg-base-300")}></div>
                  <span class="text-xs opacity-60">{if @poll_running, do: "Polling", else: "Idle"}</span>
                </div>
              </div>

              <p class="text-xs opacity-60 mb-4">
                A common use case: periodically poll an external API and update local state.
                Each poll fetches "simulated" data and stores it.
              </p>

              <div class="flex gap-2 mb-4">
                <button
                  :if={!@poll_running}
                  phx-click="poll_start"
                  phx-target={@myself}
                  class="btn btn-sm btn-success"
                >
                  Start Polling (every 2s)
                </button>
                <button
                  :if={@poll_running}
                  phx-click="poll_stop"
                  phx-target={@myself}
                  class="btn btn-sm btn-error"
                >
                  Stop Polling
                </button>
              </div>

              <!-- Current Data -->
              <div :if={@poll_data} class="bg-base-300 rounded-lg p-3 mb-4">
                <div class="text-xs font-bold opacity-60 mb-1">Latest Poll Result (poll #{@poll_count})</div>
                <div class="font-mono text-sm">{inspect(@poll_data)}</div>
              </div>

              <!-- History -->
              <div :if={@poll_history != []} class="space-y-1">
                <div class="text-xs font-bold opacity-60 mb-1">Poll History</div>
                <div
                  :for={entry <- Enum.take(@poll_history, 8)}
                  class="text-xs font-mono bg-base-300 rounded px-2 py-1"
                >
                  {entry}
                </div>
              </div>
            </div>
          </div>

          <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">
            <span class="opacity-50"># Polling pattern:</span>
            {polling_code()}</div>
        </div>

        <!-- Countdown Demo -->
        <div :if={@active_section == "countdown"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Countdown Timer</h3>
              <p class="text-xs opacity-60 mb-4">
                A practical example: a countdown that ticks every second and stops at zero.
                Demonstrates conditional scheduling (stop when done).
              </p>

              <div class="text-center mb-4">
                <div class={"text-6xl font-bold font-mono " <>
                  cond do
                    is_nil(@countdown_value) -> "opacity-30"
                    @countdown_value == 0 -> "text-success"
                    @countdown_value <= 3 -> "text-error animate-pulse"
                    true -> "text-primary"
                  end}>
                  {if is_nil(@countdown_value), do: @countdown_target, else: @countdown_value}
                </div>
                <div :if={@countdown_value == 0} class="text-sm text-success font-bold mt-2">
                  Done!
                </div>
              </div>

              <div class="flex items-center gap-3 mb-4">
                <label class="text-xs font-bold">Start from:</label>
                <input
                  type="range"
                  min="3"
                  max="30"
                  value={@countdown_target}
                  phx-change="set_countdown_target"
                  phx-target={@myself}
                  name="target"
                  class="range range-sm range-primary flex-1"
                  disabled={!is_nil(@countdown_value) && @countdown_value > 0}
                />
                <span class="badge badge-sm font-mono">{@countdown_target}s</span>
              </div>

              <div class="flex gap-2">
                <button
                  phx-click="countdown_start"
                  phx-target={@myself}
                  disabled={!is_nil(@countdown_value) && @countdown_value > 0}
                  class="btn btn-sm btn-primary"
                >
                  Start Countdown
                </button>
                <button
                  phx-click="countdown_reset"
                  phx-target={@myself}
                  class="btn btn-sm btn-ghost"
                >
                  Reset
                </button>
              </div>
            </div>
          </div>

          <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">
            <span class="opacity-50"># Conditional scheduling:</span>
            {conditional_scheduling_code()}</div>
        </div>

        <!-- Key Concepts -->
        <div class="card bg-base-200 shadow-md mt-6">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-3">Key Concepts</h3>
            <div class="space-y-3 text-sm">
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">1</span>
                <span>
                  <strong>Self-scheduling pattern:</strong> Call <code>Process.send_after(self(), msg, delay)</code>
                  in <code>handle_info</code> to schedule the next tick after each one completes.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">2</span>
                <span>
                  <strong>Prefer send_after over send_interval:</strong> Self-scheduling with
                  <code>send_after</code> naturally handles slow work without message buildup.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">3</span>
                <span>
                  <strong>Cancellation:</strong> <code>Process.send_after/3</code> returns a timer
                  reference. Use <code>Process.cancel_timer(ref)</code> to cancel.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">4</span>
                <span>
                  <strong>Conditional scheduling:</strong> Only schedule the next tick if needed.
                  Pattern match in <code>handle_info</code> to stop when a condition is met.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
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
       |> assign_new(:active_section, fn -> "patterns" end)
       |> assign_new(:selected_pattern, fn -> nil end)
       |> assign_new(:heartbeat_running, fn -> false end)
       |> assign_new(:heartbeat_count, fn -> 0 end)
       |> assign_new(:heartbeat_interval, fn -> 1000 end)
       |> assign_new(:heartbeat_log, fn -> [] end)
       |> assign_new(:poll_running, fn -> false end)
       |> assign_new(:poll_data, fn -> nil end)
       |> assign_new(:poll_count, fn -> 0 end)
       |> assign_new(:poll_history, fn -> [] end)
       |> assign_new(:countdown_value, fn -> nil end)
       |> assign_new(:countdown_target, fn -> 10 end)}
    end
  end

  def handle_event("set_section", %{"section" => section}, socket) do
    {:noreply, assign(socket, active_section: section)}
  end

  def handle_event("select_pattern", %{"id" => id}, socket) do
    selected = if socket.assigns.selected_pattern == id, do: nil, else: id
    {:noreply, assign(socket, selected_pattern: selected)}
  end

  # Heartbeat events
  def handle_event("heartbeat_start", _params, socket) do
    Process.send_after(self(), :heartbeat_tick, socket.assigns.heartbeat_interval)
    {:noreply, assign(socket, heartbeat_running: true)}
  end

  def handle_event("heartbeat_stop", _params, socket) do
    {:noreply, assign(socket, heartbeat_running: false)}
  end

  def handle_event("heartbeat_reset", _params, socket) do
    {:noreply, assign(socket, heartbeat_running: false, heartbeat_count: 0, heartbeat_log: [])}
  end

  def handle_event("set_heartbeat_interval", %{"interval" => interval_str}, socket) do
    {:noreply, assign(socket, heartbeat_interval: String.to_integer(interval_str))}
  end

  # Polling events
  def handle_event("poll_start", _params, socket) do
    Process.send_after(self(), :poll_tick, 2000)
    {:noreply, assign(socket, poll_running: true)}
  end

  def handle_event("poll_stop", _params, socket) do
    {:noreply, assign(socket, poll_running: false)}
  end

  # Countdown events
  def handle_event("set_countdown_target", %{"target" => target_str}, socket) do
    {:noreply, assign(socket, countdown_target: String.to_integer(target_str))}
  end

  def handle_event("countdown_start", _params, socket) do
    Process.send_after(self(), :countdown_tick, 1000)
    {:noreply, assign(socket, countdown_value: socket.assigns.countdown_target)}
  end

  def handle_event("countdown_reset", _params, socket) do
    {:noreply, assign(socket, countdown_value: nil)}
  end

  # Handle timer messages
  def handle_info(:heartbeat_tick, socket) do
    if socket.assigns.heartbeat_running do
      count = socket.assigns.heartbeat_count + 1
      timestamp = Calendar.strftime(DateTime.utc_now(), "%H:%M:%S")
      log_entry = "[#{timestamp}] heartbeat ##{count} (interval: #{socket.assigns.heartbeat_interval}ms)"

      Process.send_after(self(), :heartbeat_tick, socket.assigns.heartbeat_interval)

      {:noreply,
       socket
       |> assign(heartbeat_count: count)
       |> assign(heartbeat_log: [log_entry | Enum.take(socket.assigns.heartbeat_log, 14)])}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:poll_tick, socket) do
    if socket.assigns.poll_running do
      count = socket.assigns.poll_count + 1
      data = simulate_api_response(count)
      timestamp = Calendar.strftime(DateTime.utc_now(), "%H:%M:%S")
      history_entry = "[#{timestamp}] Poll ##{count}: #{inspect(data)}"

      Process.send_after(self(), :poll_tick, 2000)

      {:noreply,
       socket
       |> assign(poll_count: count, poll_data: data)
       |> assign(poll_history: [history_entry | Enum.take(socket.assigns.poll_history, 7)])}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:countdown_tick, socket) do
    current = socket.assigns.countdown_value

    cond do
      is_nil(current) ->
        {:noreply, socket}

      current <= 1 ->
        {:noreply, assign(socket, countdown_value: 0)}

      true ->
        Process.send_after(self(), :countdown_tick, 1000)
        {:noreply, assign(socket, countdown_value: current - 1)}
    end
  end

  defp timer_patterns, do: @timer_patterns

  defp heartbeat_code do
    """
    def handle_info(:heartbeat, state) do
      IO.puts("heartbeat \#{state.count}")
      Process.send_after(self(), :heartbeat, state.interval)
      {:noreply, %{state | count: state.count + 1}}
    end\
    """
  end

  defp polling_code do
    String.trim("""
    def init(opts) do
      schedule_poll(opts.interval)
      {:ok, %{interval: opts.interval, data: nil}}
    end

    def handle_info(:poll, state) do
      data = fetch_from_api()
      schedule_poll(state.interval)
      {:noreply, %{state | data: data}}
    end

    defp schedule_poll(interval) do
      Process.send_after(self(), :poll, interval)
    end
    """)
  end

  defp conditional_scheduling_code do
    String.trim("""
    def handle_info(:tick, %{remaining: 0} = state) do
      # Don't schedule another tick - we're done!
      {:noreply, state}
    end

    def handle_info(:tick, state) do
      Process.send_after(self(), :tick, 1_000)
      {:noreply, %{state | remaining: state.remaining - 1}}
    end
    """)
  end

  defp simulate_api_response(count) do
    temps = [18.5, 21.3, 19.8, 22.1, 20.5, 23.7, 17.9, 24.2]
    statuses = ["healthy", "healthy", "healthy", "degraded", "healthy"]

    %{
      temperature: Enum.at(temps, rem(count, length(temps))),
      status: Enum.at(statuses, rem(count, length(statuses))),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
