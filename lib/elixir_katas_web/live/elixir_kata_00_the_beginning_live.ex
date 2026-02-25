defmodule ElixirKatasWeb.ElixirKata00TheBeginningLive do
  use ElixirKatasWeb, :live_component

  @sections [
    %{
      id: "hardware",
      title: "The Hardware Reality",
      icon: "hero-cpu-chip",
      points: [
        "A CPU core executes one instruction at a time — to use all cores you need concurrency",
        "Clock speeds plateaued around 2005 (~4 GHz). Manufacturers added more cores instead",
        "A 16-core machine wastes 93.75% of its CPU on single-threaded code",
        "Sharing data between cores goes through slow shared caches (30-300x slower than local)"
      ]
    },
    %{
      id: "concurrency",
      title: "Concurrency vs Parallelism",
      icon: "hero-arrows-right-left",
      points: [
        "Concurrency = structure. Managing multiple tasks (one barista, two orders, switching between them)",
        "Parallelism = execution. Actually doing things simultaneously (two baristas, two orders)",
        "Elixir gives you both: millions of concurrent processes running in parallel across all cores",
        "You don't opt into concurrency in Elixir — it's the default way of thinking"
      ]
    },
    %{
      id: "os_models",
      title: "OS Processes vs Threads",
      icon: "hero-server-stack",
      points: [
        "OS processes: heavy (10-100MB), full isolation, slow to create, safe",
        "OS threads: lighter (1-8MB), share memory within a process, prone to race conditions",
        "Threads + shared memory = locks → deadlocks, priority inversion, complexity",
        "Most concurrency bugs in Java/C++/C# are lock-related — the model is fundamentally hard"
      ]
    },
    %{
      id: "beam_processes",
      title: "BEAM Processes",
      icon: "hero-bolt",
      points: [
        "Not OS processes or threads — managed entirely by the BEAM VM (~2KB each)",
        "Share NOTHING — each has its own private heap. No locks, no races, no deadlocks",
        "Communicate by copying messages into each other's mailbox",
        "Can create millions of them. WhatsApp: 2 million connections per server"
      ]
    },
    %{
      id: "otp",
      title: "OTP Abstractions",
      icon: "hero-cube-transparent",
      points: [
        "GenServer: stateful process with sync (call) and async (cast) interface — 80% of use cases",
        "Agent: simplified GenServer for simple get/put state — like a concurrent variable",
        "Task: one-shot async work — fire-and-forget or async/await pattern",
        "Supervisor: monitors children, restarts them on crash — the safety net"
      ]
    },
    %{
      id: "let_it_crash",
      title: "Let It Crash",
      icon: "hero-shield-check",
      points: [
        "Don't defend against every error with try/catch. Let processes crash and restart clean",
        "Supervisors automatically restart crashed processes in a known good state",
        "Crash isolation: one process crashing cannot corrupt another's memory",
        "Clean restarts fix most transient errors (network blips, temporary exhaustion)"
      ]
    },
    %{
      id: "scheduling",
      title: "Scheduling & Priorities",
      icon: "hero-clock",
      points: [
        "Preemptive scheduling: BEAM forcibly pauses processes after ~4000 reductions (function calls)",
        "No process can starve others — unlike Node.js where a CPU hog blocks the event loop",
        "One scheduler thread per CPU core, with work-stealing for load balance",
        "Priorities: :low, :normal (default), :high, :max (never use). Almost never change from :normal"
      ]
    }
  ]

  @comparison [
    %{problem: "Multi-core utilization", traditional: "Manual thread management", elixir: "Automatic — processes on all cores"},
    %{problem: "Shared state bugs", traditional: "Locks, mutexes, semaphores", elixir: "No shared state — message passing"},
    %{problem: "Error handling", traditional: "Defensive try/catch everywhere", elixir: "Let it crash + supervisor restarts"},
    %{problem: "Scaling connections", traditional: "Thread pool with limits", elixir: "Millions of lightweight processes"},
    %{problem: "Fault isolation", traditional: "One crash can cascade", elixir: "One crash = one process only"}
  ]

  @tool_chooser [
    %{question: "Need to maintain state over time?", no: "Task or plain function", yes: "next"},
    %{question: "Is the state simple (get/put)?", yes: "Agent", no: "GenServer"},
    %{question: "Need fault tolerance?", yes: "Wrap in a Supervisor", no: "Consider it anyway — supervisors are cheap"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_section, fn -> "hardware" end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:show_tool_chooser, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">The Beginning — Elixir's Technical Foundations</h2>
      <p class="text-sm opacity-70 mb-6">
        Before writing code, understand <strong>why</strong> Elixir exists and what problems it solves.
        Every design choice traces back to one question: how do you build software that runs forever
        and handles millions of things at once?
      </p>

      <!-- Section Navigator -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for sec <- sections() do %>
          <button
            phx-click="select_section"
            phx-target={@myself}
            phx-value-id={sec.id}
            class={"btn btn-sm " <> if(@active_section == sec.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= sec.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Section Card -->
      <%= for sec <- sections(), sec.id == @active_section do %>
        <div class="card bg-base-200 shadow-md mb-6">
          <div class="card-body p-4">
            <div class="flex items-center gap-2 mb-4">
              <.icon name={sec.icon} class="w-5 h-5 text-primary" />
              <h3 class="card-title text-sm"><%= sec.title %></h3>
            </div>

            <div class="space-y-3">
              <%= for {point, idx} <- Enum.with_index(sec.points) do %>
                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5"><%= idx + 1 %></span>
                  <span class="text-sm"><%= point %></span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Architecture Overview -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">BEAM Architecture at a Glance</h3>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap"><%= architecture_diagram() %></div>
        </div>
      </div>

      <!-- Process Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Process Model Comparison</h3>
          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Aspect</th>
                  <th>OS Process</th>
                  <th>OS Thread</th>
                  <th class="text-primary">BEAM Process</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="font-bold text-xs">Memory</td>
                  <td class="text-xs opacity-70">10-100 MB</td>
                  <td class="text-xs opacity-70">1-8 MB</td>
                  <td class="text-xs text-primary font-bold">~2 KB</td>
                </tr>
                <tr>
                  <td class="font-bold text-xs">Creation time</td>
                  <td class="text-xs opacity-70">Milliseconds</td>
                  <td class="text-xs opacity-70">Microseconds</td>
                  <td class="text-xs text-primary font-bold">Microseconds</td>
                </tr>
                <tr>
                  <td class="font-bold text-xs">Isolation</td>
                  <td class="text-xs opacity-70">Full</td>
                  <td class="text-xs opacity-70">None (shared heap)</td>
                  <td class="text-xs text-primary font-bold">Full (private heap)</td>
                </tr>
                <tr>
                  <td class="font-bold text-xs">Communication</td>
                  <td class="text-xs opacity-70">IPC (slow)</td>
                  <td class="text-xs opacity-70">Shared memory (fast but dangerous)</td>
                  <td class="text-xs text-primary font-bold">Message passing (safe)</td>
                </tr>
                <tr>
                  <td class="font-bold text-xs">Max concurrent</td>
                  <td class="text-xs opacity-70">Thousands</td>
                  <td class="text-xs opacity-70">Thousands</td>
                  <td class="text-xs text-primary font-bold">Millions</td>
                </tr>
                <tr>
                  <td class="font-bold text-xs">Race conditions</td>
                  <td class="text-xs opacity-70">Between processes: No</td>
                  <td class="text-xs opacity-70">Common — needs locks</td>
                  <td class="text-xs text-primary font-bold">Impossible</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Tool Chooser -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Choosing the Right Tool</h3>
            <button phx-click="toggle_tool_chooser" phx-target={@myself} class="btn btn-xs btn-ghost">
              <%= if @show_tool_chooser, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_tool_chooser do %>
            <div class="space-y-2">
              <%= for step <- tool_chooser() do %>
                <div class="flex items-center gap-3 p-3 bg-base-300 rounded-lg text-sm">
                  <span class="font-bold min-w-[200px]"><%= step.question %></span>
                  <div class="flex gap-4">
                    <%= if step[:yes] do %>
                      <span class="badge badge-success badge-sm">Yes → <%= step.yes %></span>
                    <% end %>
                    <%= if step[:no] do %>
                      <span class="badge badge-warning badge-sm">No → <%= step.no %></span>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <div class="bg-info/10 border border-info/30 rounded-lg p-3 mt-3">
                <div class="text-xs">
                  <strong>Quick reference:</strong>
                  <span class="badge badge-sm ml-1">GenServer</span> = stateful process with complex logic
                  <span class="badge badge-sm ml-1">Agent</span> = simple state container
                  <span class="badge badge-sm ml-1">Task</span> = one-shot async work
                  <span class="badge badge-sm ml-1">Supervisor</span> = restarts crashed children
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Why Elixir Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Why Elixir? — Traditional vs BEAM</h3>
            <button phx-click="toggle_comparison" phx-target={@myself} class="btn btn-xs btn-ghost">
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Problem</th>
                    <th>Traditional</th>
                    <th class="text-success">Elixir</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- comparison() do %>
                    <tr>
                      <td class="font-bold text-xs"><%= row.problem %></td>
                      <td class="text-xs opacity-70"><%= row.traditional %></td>
                      <td class="text-xs text-success"><%= row.elixir %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Key Mental Models -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">The 6 Mental Models</h3>
          <p class="text-xs opacity-60 mb-3">Carry these with you through every kata that follows.</p>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>Everything is a process</strong> — each concurrent activity gets its own lightweight process</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Processes share nothing</strong> — private memory, communication only through messages</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Let it crash</strong> — don't defend against every error; crash and restart cleanly</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Supervisors are your safety net</strong> — they watch processes and restart them automatically</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Preemptive fairness</strong> — the BEAM scheduler ensures no process can starve others</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span><strong>Concurrency is the default</strong> — you don't opt in; it's how Elixir thinks</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_section", %{"id" => id}, socket) do
    {:noreply, assign(socket, active_section: id)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("toggle_tool_chooser", _params, socket) do
    {:noreply, assign(socket, show_tool_chooser: !socket.assigns.show_tool_chooser)}
  end

  # Helpers

  defp sections, do: @sections
  defp comparison, do: @comparison
  defp tool_chooser, do: @tool_chooser

  defp architecture_diagram do
    """
    ┌─────────────────────────────────────────────────────────┐
    │                     Your Elixir App                      │
    │                                                          │
    │   Supervisors          GenServers        Tasks/Agents    │
    │   ┌─────────┐         ┌──────────┐      ┌──────────┐   │
    │   │ restart  │─watches─│  state   │      │ one-shot │   │
    │   │ children │         │  + logic │      │   work   │   │
    │   └─────────┘         └──────────┘      └──────────┘   │
    ├──────────────────────────────────────────────────────────┤
    │                      BEAM VM                             │
    │                                                          │
    │  ┌────────────┐ ┌────────────┐ ┌────────────┐          │
    │  │ Scheduler 1│ │ Scheduler 2│ │ Scheduler N│ (1/core) │
    │  │ [P1,P4,P7] │ │ [P2,P5,P8] │ │ [P3,P6,P9] │          │
    │  └────────────┘ └────────────┘ └────────────┘          │
    │                                                          │
    │  Each process: ~2KB | Preemptive | Message passing       │
    │  Millions of processes across a handful of OS threads    │
    ├──────────────────────────────────────────────────────────┤
    │  OS: Linux/macOS/Windows                                 │
    │  Hardware: CPU cores + RAM                               │
    └─────────────────────────────────────────────────────────┘\
    """
  end
end
