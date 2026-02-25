defmodule ElixirKatasWeb.ElixirKata82DebuggingLive do
  use ElixirKatasWeb, :live_component

  @inspect_options [
    %{
      id: "label",
      label: ":label",
      description: "Adds a prefix label to the output, making it easy to identify which inspect call produced which output.",
      code: "[1, 2, 3]\n|> Enum.map(& &1 * 2)\n|> IO.inspect(label: \"after map\")\n|> Enum.sum()\n|> IO.inspect(label: \"final sum\")\n\n# Output:\n# after map: [2, 4, 6]\n# final sum: 12"
    },
    %{
      id: "pretty",
      label: ":pretty",
      description: "Enables multi-line, indented formatting for nested data structures.",
      code: "IO.inspect(%{users: [%{name: \"Alice\", roles: [:admin, :user]}, %{name: \"Bob\", roles: [:user]}]}, pretty: true)\n\n# Output:\n# %{\n#   users: [\n#     %{name: \"Alice\", roles: [:admin, :user]},\n#     %{name: \"Bob\", roles: [:user]}\n#   ]\n# }"
    },
    %{
      id: "limit",
      label: ":limit",
      description: "Limits the number of entries printed for lists and other collections. Default is 50.",
      code: "IO.inspect(Enum.to_list(1..100), limit: 5)\n# => [1, 2, 3, 4, 5, ...]\n\nIO.inspect(Enum.to_list(1..100), limit: :infinity)\n# => [1, 2, 3, ..., 100]"
    },
    %{
      id: "width",
      label: ":width",
      description: "Sets the maximum line width for output. Shorter widths cause more line breaks.",
      code: "IO.inspect([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], width: 20)\n# => [1, 2, 3, 4, 5,\n#     6, 7, 8, 9,\n#     10]"
    },
    %{
      id: "charlists",
      label: ":charlists",
      description: "Controls how charlists are printed. Use :as_lists to avoid seeing unexpected string output.",
      code: "IO.inspect([72, 101, 108, 108, 111])\n# => ~c\"Hello\"\n\nIO.inspect([72, 101, 108, 108, 111], charlists: :as_lists)\n# => [72, 101, 108, 108, 111]"
    }
  ]

  @dbg_examples [
    %{
      id: "simple",
      label: "Simple Expression",
      code: "dbg(1 + 2)\n\n# Output:\n# [my_file.ex:1: (file)]\n# 1 + 2 #=> 3",
      explanation: "dbg prints the expression, its location, and the result."
    },
    %{
      id: "pipeline",
      label: "Pipeline",
      code: "[1, 2, 3, 4, 5]\n|> Enum.filter(&rem(&1, 2) == 0)\n|> Enum.map(& &1 * 10)\n|> dbg()\n\n# Output:\n# [my_file.ex:4: (file)]\n# [1, 2, 3, 4, 5] #=> [1, 2, 3, 4, 5]\n# |> Enum.filter(&rem(&1, 2) == 0) #=> [2, 4]\n# |> Enum.map(& &1 * 10) #=> [20, 40]",
      explanation: "When used at the end of a pipeline, dbg shows the result of EACH step."
    },
    %{
      id: "variables",
      label: "Variables",
      code: "x = 10\ny = 20\ndbg(x + y)\n\n# Output:\n# [my_file.ex:3: (file)]\n# x #=> 10\n# y #=> 20\n# x + y #=> 30",
      explanation: "dbg shows the value of each variable used in the expression."
    }
  ]

  @iex_helpers [
    %{name: "h/1", description: "Prints documentation for a module or function", example: "h Enum.map"},
    %{name: "i/1", description: "Prints detailed info about a value (type, modules, etc.)", example: "i \"hello\""},
    %{name: "v/0", description: "Returns the value of the last evaluated expression", example: "v()"},
    %{name: "v/1", description: "Returns the value from a specific history line", example: "v(3)"},
    %{name: "t/1", description: "Prints type specs for a module", example: "t Enum"},
    %{name: "b/1", description: "Prints callbacks for a behaviour", example: "b GenServer"},
    %{name: "recompile/0", description: "Recompiles the current Mix project", example: "recompile()"},
    %{name: "r/1", description: "Recompiles and reloads a specific module", example: "r MyModule"},
    %{name: "c/1", description: "Compiles a file", example: "c \"lib/my_module.ex\""},
    %{name: "break!/2", description: "Sets a breakpoint on a function", example: "break!(MyModule, :my_fun, 2)"},
    %{name: "exports/1", description: "Lists all exports of a module", example: "exports(Enum)"},
    %{name: "open/1", description: "Opens the source of a module in your editor", example: "open Enum"},
    %{name: "pid/3", description: "Creates a PID from three integers", example: "pid(0, 123, 0)"},
    %{name: "ref/1", description: "Creates a reference from a string", example: "ref(\"0.1.2.3\")"},
    %{name: "runtime_info/0", description: "Prints system and runtime information", example: "runtime_info()"}
  ]

  @logger_levels [
    %{
      id: "debug",
      label: ":debug",
      color: "badge-ghost",
      description: "Detailed diagnostic info. Only shown when log level is :debug.",
      code: "require Logger\nLogger.debug(\"Processing user: alice\")\n# 10:30:00.123 [debug] Processing user: alice"
    },
    %{
      id: "info",
      label: ":info",
      color: "badge-info",
      description: "General operational messages. Default level in production.",
      code: "require Logger\nLogger.info(\"User alice logged in\")\n# 10:30:00.123 [info] User alice logged in"
    },
    %{
      id: "warning",
      label: ":warning",
      color: "badge-warning",
      description: "Something unexpected but not an error. System continues operating.",
      code: "require Logger\nLogger.warning(\"Cache miss for key: user:alice\")\n# 10:30:00.123 [warning] Cache miss for key: user:alice"
    },
    %{
      id: "error",
      label: ":error",
      color: "badge-error",
      description: "Something failed. Requires attention.",
      code: "require Logger\nLogger.error(\"Failed to connect to database: timeout\")\n# 10:30:00.123 [error] Failed to connect to database: timeout"
    }
  ]

  @process_debug_examples [
    %{
      id: "process_info",
      label: "Process.info/2",
      code: "pid = self()\nProcess.info(pid, :message_queue_len)\n# => {:message_queue_len, 0}\n\nProcess.info(pid, :status)\n# => {:status, :running}\n\nProcess.info(pid, [:registered_name, :memory, :current_function])\n# => [registered_name: [], memory: 2688,\n#     current_function: {:erl_eval, :do_apply, 7}]",
      explanation: "Process.info/2 returns specific information about a process. Useful keys: :message_queue_len, :status, :memory, :current_function, :dictionary, :links, :monitors."
    },
    %{
      id: "sys_state",
      label: ":sys.get_state/1",
      code: "# For any GenServer, Agent, or :gen_statem process:\n:sys.get_state(MyGenServer)\n# => %{count: 42, users: [\"alice\", \"bob\"]}\n\n# Also works with PIDs:\n:sys.get_state(pid)\n# => current state of the process",
      explanation: ":sys.get_state/1 retrieves the internal state of any OTP-compatible process (GenServer, Agent, etc.) without sending a custom message."
    },
    %{
      id: "sys_status",
      label: ":sys.get_status/1",
      code: ":sys.get_status(MyGenServer)\n# => {:status, #PID<0.123.0>, {:module, :gen_server},\n#     [[\"$ancestors\": [#PID<0.122.0>]],\n#      :running, #PID<0.122.0>, [],\n#      [header: ~c\"Status for generic server ...\",\n#       data: [{~c\"Status\", :running}, ...],\n#       data: [{~c\"State\", %{count: 42}}]]]}",
      explanation: ":sys.get_status/1 returns comprehensive status info including ancestors, current status, and state. More detailed than get_state."
    },
    %{
      id: "sys_trace",
      label: ":sys.trace/2",
      code: "# Turn on tracing for a GenServer:\n:sys.trace(MyGenServer, true)\n\n# Now every message in/out is printed:\n# *DBG* my_server got call get_count from <0.150.0>\n# *DBG* my_server sent 42 to <0.150.0>\n\n# Turn off:\n:sys.trace(MyGenServer, false)",
      explanation: ":sys.trace/2 enables real-time tracing of all messages to/from an OTP process. Very useful for debugging GenServer interactions."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_option, fn -> hd(@inspect_options) end)
     |> assign_new(:active_dbg, fn -> hd(@dbg_examples) end)
     |> assign_new(:show_iex, fn -> false end)
     |> assign_new(:active_logger, fn -> hd(@logger_levels) end)
     |> assign_new(:log_level_filter, fn -> "debug" end)
     |> assign_new(:active_process_debug, fn -> hd(@process_debug_examples) end)
     |> assign_new(:show_process_debug, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Debugging Tools</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir provides a rich set of debugging tools, from simple <code class="font-mono bg-base-300 px-1 rounded">IO.inspect</code>
        to the powerful <code class="font-mono bg-base-300 px-1 rounded">dbg</code> macro, IEx helpers, and
        OTP process introspection with <code class="font-mono bg-base-300 px-1 rounded">:sys</code>.
      </p>

      <!-- IO.inspect Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">IO.inspect Explorer</h3>
          <p class="text-xs opacity-60 mb-3">
            IO.inspect/2 returns the value it inspects, making it pipe-friendly. Click an option to see how it works.
          </p>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for opt <- inspect_options() do %>
              <button
                phx-click="select_option"
                phx-target={@myself}
                phx-value-id={opt.id}
                class={"btn btn-sm " <> if(@active_option.id == opt.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= opt.label %>
              </button>
            <% end %>
          </div>

          <p class="text-sm opacity-70 mb-3"><%= @active_option.description %></p>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_option.code %></div>
        </div>
      </div>

      <!-- dbg Macro -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">dbg Macro (Elixir 1.14+)</h3>
          <p class="text-xs opacity-60 mb-3">
            The <code class="font-mono bg-base-100 px-1 rounded">dbg</code> macro shows the source expression,
            file location, and each step in a pipeline. It returns the value, so it is pipe-friendly like IO.inspect.
          </p>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for ex <- dbg_examples() do %>
              <button
                phx-click="select_dbg"
                phx-target={@myself}
                phx-value-id={ex.id}
                class={"btn btn-sm " <> if(@active_dbg.id == ex.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= ex.label %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_dbg.code %></div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
            <%= @active_dbg.explanation %>
          </div>
        </div>
      </div>

      <!-- IEx Helpers -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">IEx Helpers Reference</h3>
            <button
              phx-click="toggle_iex"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_iex, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_iex do %>
            <div class="overflow-x-auto">
              <table class="table table-xs">
                <thead>
                  <tr>
                    <th class="font-mono">Helper</th>
                    <th>Description</th>
                    <th class="font-mono">Example</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for helper <- iex_helpers() do %>
                    <tr>
                      <td class="font-mono font-bold text-primary"><%= helper.name %></td>
                      <td class="text-xs"><%= helper.description %></td>
                      <td class="font-mono text-xs opacity-60"><%= helper.example %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="alert alert-info text-xs mt-4">
              <div>
                <strong>Tip:</strong> In IEx, type <code class="font-mono bg-base-100 px-1 rounded">h IEx.Helpers</code> to see all available helpers.
                Use <code class="font-mono bg-base-100 px-1 rounded">IEx.configure(inspect: [limit: :infinity])</code> to change default inspect options.
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Logger Levels -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Logger Levels</h3>
          <p class="text-xs opacity-60 mb-3">
            Logger filters messages by level. Messages below the configured level are discarded at compile time.
            Levels from lowest to highest: :debug &lt; :info &lt; :warning &lt; :error.
          </p>

          <!-- Level Filter -->
          <div class="flex items-center gap-2 mb-4">
            <span class="text-xs font-bold opacity-60">Min level:</span>
            <%= for level <- logger_levels() do %>
              <button
                phx-click="set_log_level"
                phx-target={@myself}
                phx-value-id={level.id}
                class={"btn btn-xs " <> if(@log_level_filter == level.id, do: "btn-primary", else: "btn-ghost")}
              >
                <%= level.label %>
              </button>
            <% end %>
          </div>

          <!-- Level Cards -->
          <div class="space-y-3">
            <%= for level <- logger_levels() do %>
              <% visible = level_visible?(level.id, @log_level_filter) %>
              <div class={"bg-base-100 rounded-lg p-3 border-2 transition-all " <>
                if(visible, do: "border-base-300", else: "border-base-300 opacity-30")}>
                <div class="flex items-center gap-2 mb-2">
                  <span class={"badge badge-sm " <> level.color}><%= level.label %></span>
                  <%= if !visible do %>
                    <span class="badge badge-xs badge-ghost">filtered out</span>
                  <% end %>
                </div>
                <p class="text-xs opacity-70 mb-2"><%= level.description %></p>
                <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= level.code %></div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Process Debugging -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Process Debugging</h3>
            <button
              phx-click="toggle_process_debug"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_process_debug, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_process_debug do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for ex <- process_debug_examples() do %>
                <button
                  phx-click="select_process_debug"
                  phx-target={@myself}
                  phx-value-id={ex.id}
                  class={"btn btn-sm " <> if(@active_process_debug.id == ex.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= ex.label %>
                </button>
              <% end %>
            </div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_process_debug.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
              <%= @active_process_debug.explanation %>
            </div>

            <div class="alert alert-warning text-xs mt-4">
              <div>
                <strong>Also useful:</strong> Run <code class="font-mono bg-base-100 px-1 rounded">:observer.start()</code> in IEx to open a
                GUI showing all processes, their memory, message queues, and supervision trees.
              </div>
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
              placeholder={"[1, 2, 3]\n|> Enum.map(& &1 * 2)\n|> IO.inspect(label: \"doubled\")\n|> Enum.sum()"}
              autocomplete="off"
            ><%= @sandbox_code %></textarea>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- sandbox_examples() do %>
              <button
                phx-click="quick_sandbox"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

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
              <span><strong>IO.inspect/2</strong> returns its argument unchanged, making it safe to insert anywhere in a pipeline for quick debugging.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>dbg/2</strong> (Elixir 1.14+) is a macro that prints the source expression and result of each pipeline step, providing richer context than IO.inspect.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>IEx helpers</strong> like <code class="font-mono bg-base-100 px-1 rounded">h/1</code>, <code class="font-mono bg-base-100 px-1 rounded">i/1</code>, <code class="font-mono bg-base-100 px-1 rounded">break!/2</code>, and <code class="font-mono bg-base-100 px-1 rounded">recompile/0</code> make interactive exploration and debugging fast.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Logger</strong> provides leveled logging (:debug, :info, :warning, :error) with compile-time filtering, so debug messages have zero cost in production.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>:sys.get_state/1</strong> and <strong>Process.info/2</strong> let you inspect the internal state of any OTP process without modifying its code.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_option", %{"id" => id}, socket) do
    opt = Enum.find(inspect_options(), &(&1.id == id))
    {:noreply, assign(socket, active_option: opt)}
  end

  def handle_event("select_dbg", %{"id" => id}, socket) do
    ex = Enum.find(dbg_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_dbg: ex)}
  end

  def handle_event("toggle_iex", _params, socket) do
    {:noreply, assign(socket, show_iex: !socket.assigns.show_iex)}
  end

  def handle_event("set_log_level", %{"id" => id}, socket) do
    {:noreply, assign(socket, log_level_filter: id)}
  end

  def handle_event("toggle_process_debug", _params, socket) do
    {:noreply, assign(socket, show_process_debug: !socket.assigns.show_process_debug)}
  end

  def handle_event("select_process_debug", %{"id" => id}, socket) do
    ex = Enum.find(process_debug_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_process_debug: ex)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  def handle_event("quick_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp inspect_options, do: @inspect_options
  defp dbg_examples, do: @dbg_examples
  defp iex_helpers, do: @iex_helpers
  defp logger_levels, do: @logger_levels
  defp process_debug_examples, do: @process_debug_examples

  defp level_visible?(level, min_level) do
    level_order = %{"debug" => 0, "info" => 1, "warning" => 2, "error" => 3}
    Map.get(level_order, level, 0) >= Map.get(level_order, min_level, 0)
  end

  defp sandbox_examples do
    [
      {"IO.inspect in pipe",
       "[1, 2, 3, 4, 5]\n|> Enum.filter(&rem(&1, 2) == 0)\n|> IO.inspect(label: \"evens\")\n|> Enum.sum()"},
      {"inspect options",
       "IO.inspect(%{a: 1, b: [2, 3], c: %{d: 4}}, pretty: true, width: 30)"},
      {"Process.info",
       "self() |> Process.info([:status, :memory, :message_queue_len])"},
      {"charlist display",
       "IO.inspect([65, 66, 67], charlists: :as_lists)"}
    ]
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
