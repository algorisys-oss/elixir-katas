defmodule ElixirKatasWeb.ElixirKata65GenserverStateLive do
  use ElixirKatasWeb, :live_component

  @state_patterns [
    %{
      id: "map",
      title: "Map State",
      description: "The most common pattern. Use a map to hold multiple pieces of related state.",
      code: "def init(_args) do\n  {:ok, %{users: [], count: 0, started_at: DateTime.utc_now()}}\nend\n\ndef handle_call(:get_stats, _from, state) do\n  {:reply, %{count: state.count, started: state.started_at}, state}\nend",
      pros: ["Flexible key-value access", "Easy to add new fields", "Pattern match in callbacks"],
      cons: ["No compile-time guarantees on keys", "Easy to typo a key name"]
    },
    %{
      id: "struct",
      title: "Struct State",
      description: "Define a struct for the state. Provides compile-time key checking and documentation.",
      code: "defmodule MyServer do\n  use GenServer\n\n  defstruct [:name, :count, items: [], status: :idle]\n\n  def init(name) do\n    {:ok, %__MODULE__{name: name, count: 0}}\n  end\n\n  def handle_cast(:increment, %__MODULE__{} = state) do\n    {:noreply, %{state | count: state.count + 1}}\n  end\nend",
      pros: ["Compile-time key validation", "Self-documenting default values", "Pattern match on struct type"],
      cons: ["Slightly more boilerplate", "All keys must be declared upfront"]
    },
    %{
      id: "keyword",
      title: "Keyword List State",
      description: "Rarely used, but sometimes seen for simple ordered configuration.",
      code: "def init(opts) do\n  {:ok, [mode: :normal, retries: 0, max_retries: Keyword.get(opts, :max, 3)]}\nend",
      pros: ["Ordered keys", "Duplicate keys allowed"],
      cons: ["O(n) access", "Less common, may confuse readers"]
    },
    %{
      id: "simple",
      title: "Simple Value State",
      description: "When you only need a single value, the state can be anything: an integer, a list, a tuple.",
      code: "def init(initial) do\n  {:ok, initial}  # state is just an integer\nend\n\ndef handle_call(:get, _from, count) do\n  {:reply, count, count}\nend\n\ndef handle_cast(:increment, count) do\n  {:noreply, count + 1}\nend",
      pros: ["Simplest possible state", "No wrapping overhead"],
      cons: ["Hard to extend later", "Adding a second field requires refactoring"]
    }
  ]

  @naming_examples [
    %{
      method: "No name (anonymous)",
      code: "{:ok, pid} = GenServer.start_link(MyServer, [])\nGenServer.call(pid, :get)",
      note: "Must track PID manually. Multiple instances easy."
    },
    %{
      method: "Atom name",
      code: "GenServer.start_link(MyServer, [], name: MyServer)\nGenServer.call(MyServer, :get)",
      note: "Global name. Only one instance per name. Simplest for singletons."
    },
    %{
      method: "{:global, term}",
      code: "GenServer.start_link(MyServer, [], name: {:global, :my_server})\nGenServer.call({:global, :my_server}, :get)",
      note: "Distributed name across connected nodes."
    },
    %{
      method: "{:via, Registry, {reg, key}}",
      code: "GenServer.start_link(MyServer, [],\n  name: {:via, Registry, {MyRegistry, user_id}})\n\nGenServer.call(\n  {:via, Registry, {MyRegistry, user_id}}, :get)",
      note: "Dynamic naming with Registry. Best for many named instances."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_section, fn -> "patterns" end)
     |> assign_new(:selected_pattern, fn -> nil end)
     |> assign_new(:selected_naming, fn -> nil end)
     |> assign_new(:kv_store, fn -> %{} end)
     |> assign_new(:kv_key, fn -> "" end)
     |> assign_new(:kv_value, fn -> "" end)
     |> assign_new(:kv_get_key, fn -> "" end)
     |> assign_new(:kv_get_result, fn -> nil end)
     |> assign_new(:kv_log, fn -> [] end)
     |> assign_new(:show_state_inspect, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <h2 class="text-2xl font-bold mb-2">GenServer State</h2>
        <p class="text-sm opacity-70 mb-6">
          A GenServer's state can be any Elixir term. Learn patterns for managing complex state,
          naming processes for easy lookup, and inspecting state at runtime.
        </p>

        <!-- Section Tabs -->
        <div class="tabs tabs-boxed mb-6 bg-base-200">
          <button
            :for={tab <- [{"patterns", "State Patterns"}, {"naming", "Named Processes"}, {"kv", "KV Store Demo"}, {"inspect", "State Inspection"}]}
            phx-click="set_section"
            phx-target={@myself}
            phx-value-section={elem(tab, 0)}
            class={"tab " <> if(@active_section == elem(tab, 0), do: "tab-active", else: "")}
          >
            {elem(tab, 1)}
          </button>
        </div>

        <!-- State Patterns -->
        <div :if={@active_section == "patterns"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            GenServer state can be any Elixir term. Here are the most common patterns.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              :for={pat <- state_patterns()}
              class={"card border-2 cursor-pointer transition-all hover:shadow-md " <>
                if(@selected_pattern == pat.id, do: "border-primary shadow-md", else: "border-base-300")}
              phx-click="select_pattern"
              phx-target={@myself}
              phx-value-id={pat.id}
            >
              <div class="card-body p-4">
                <h3 class="card-title text-sm">{pat.title}</h3>
                <p class="text-xs opacity-60">{pat.description}</p>
              </div>
            </div>
          </div>

          <div :if={@selected_pattern} class="card bg-base-200 shadow-md mt-4">
            <div class="card-body p-4">
              <% pat = Enum.find(state_patterns(), &(&1.id == @selected_pattern)) %>
              <h3 class="card-title text-sm mb-3">{pat.title}</h3>

              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap mb-4">
                {pat.code}
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <h4 class="text-xs font-bold text-success mb-2">Pros</h4>
                  <ul class="space-y-1">
                    <li :for={pro <- pat.pros} class="text-xs flex items-start gap-1">
                      <span class="text-success mt-0.5">+</span>
                      <span>{pro}</span>
                    </li>
                  </ul>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-error mb-2">Cons</h4>
                  <ul class="space-y-1">
                    <li :for={con <- pat.cons} class="text-xs flex items-start gap-1">
                      <span class="text-error mt-0.5">-</span>
                      <span>{con}</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Named Processes -->
        <div :if={@active_section == "naming"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            Instead of tracking PIDs, you can register GenServers with a name for easy lookup.
          </p>

          <div class="space-y-3">
            <div
              :for={{naming, idx} <- Enum.with_index(naming_examples())}
              class={"card border-2 cursor-pointer transition-all hover:shadow-md " <>
                if(@selected_naming == idx, do: "border-primary shadow-md", else: "border-base-300")}
              phx-click="select_naming"
              phx-target={@myself}
              phx-value-idx={idx}
            >
              <div class="card-body p-4">
                <div class="flex items-center justify-between mb-2">
                  <h3 class="card-title text-sm font-mono">{naming.method}</h3>
                </div>

                <div :if={@selected_naming == idx} class="space-y-3 mt-2">
                  <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">
                    {naming.code}
                  </div>
                  <div class="alert text-xs">
                    <span>{naming.note}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Registry Explanation -->
          <div class="card bg-base-200 shadow-md mt-4">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Registry for Dynamic Names</h3>
              <p class="text-xs opacity-60 mb-3">
                When you need many named instances (e.g., one GenServer per user), use a Registry:
              </p>
              <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">{registry_example_code()}</div>
            </div>
          </div>
        </div>

        <!-- KV Store Demo -->
        <div :if={@active_section == "kv"} class="space-y-4">
          <p class="text-sm opacity-60 mb-4">
            A key-value store is a classic GenServer example. Try building up state interactively.
          </p>

          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">KV Store State</h3>
                <span class="badge badge-primary font-mono">{map_size(@kv_store)} keys</span>
              </div>

              <!-- Current state display -->
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
                <span class="opacity-50">state = </span>
                {if map_size(@kv_store) == 0, do: "%{}", else: inspect(@kv_store)}
              </div>

              <!-- Put -->
              <form phx-submit="kv_put" phx-target={@myself} class="flex gap-2 items-end mb-3">
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Key</span></label>
                  <input
                    type="text"
                    name="key"
                    value={@kv_key}
                    placeholder="name"
                    class="input input-bordered input-sm font-mono w-full"
                    autocomplete="off"
                  />
                </div>
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Value</span></label>
                  <input
                    type="text"
                    name="value"
                    value={@kv_value}
                    placeholder="Alice"
                    class="input input-bordered input-sm font-mono w-full"
                    autocomplete="off"
                  />
                </div>
                <button type="submit" class="btn btn-sm btn-primary">Put</button>
              </form>

              <!-- Get -->
              <form phx-submit="kv_get" phx-target={@myself} class="flex gap-2 items-end mb-3">
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Lookup Key</span></label>
                  <input
                    type="text"
                    name="key"
                    value={@kv_get_key}
                    placeholder="name"
                    class="input input-bordered input-sm font-mono w-full"
                    autocomplete="off"
                  />
                </div>
                <button type="submit" class="btn btn-sm btn-info">Get</button>
              </form>

              <div :if={@kv_get_result} class={"alert text-sm mb-3 " <> if(@kv_get_result.found, do: "alert-success", else: "alert-warning")}>
                <span class="font-mono">{@kv_get_result.display}</span>
              </div>

              <div class="flex gap-2">
                <button
                  phx-click="kv_clear"
                  phx-target={@myself}
                  class="btn btn-sm btn-ghost"
                >
                  Clear All
                </button>
              </div>
            </div>
          </div>

          <!-- Operation Log -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Operation Log (GenServer Messages)</h3>
              <div :if={@kv_log == []} class="text-sm opacity-50 text-center py-4">
                Perform operations above to see the message flow.
              </div>
              <div class="space-y-1">
                <div
                  :for={entry <- Enum.take(@kv_log, 10)}
                  class={"rounded px-3 py-2 text-xs font-mono border-l-4 " <> entry.border}
                >
                  {entry.message}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- State Inspection -->
        <div :if={@active_section == "inspect"} class="space-y-4">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Inspecting GenServer State</h3>
              <p class="text-xs opacity-60 mb-4">
                Several tools let you peek into a running GenServer's state for debugging.
              </p>

              <div class="space-y-4">
                <div class="bg-base-300 rounded-lg p-4">
                  <h4 class="text-sm font-bold mb-2">:sys.get_state/1</h4>
                  <div class="font-mono text-xs whitespace-pre-wrap mb-2">{sys_get_state_code()}</div>
                  <p class="text-xs opacity-60">
                    Returns the current state directly. <strong>Development/debugging only.</strong>
                    Never use in production code because it bypasses the GenServer's message queue.
                  </p>
                </div>

                <div class="bg-base-300 rounded-lg p-4">
                  <h4 class="text-sm font-bold mb-2">:sys.get_status/1</h4>
                  <div class="font-mono text-xs whitespace-pre-wrap mb-2">{sys_get_status_code()}</div>
                  <p class="text-xs opacity-60">
                    Returns detailed status including module, state, parent, and debug info.
                  </p>
                </div>

                <div class="bg-base-300 rounded-lg p-4">
                  <h4 class="text-sm font-bold mb-2">Dedicated API endpoint</h4>
                  <div class="font-mono text-xs whitespace-pre-wrap mb-2">{dedicated_api_code()}</div>
                  <p class="text-xs opacity-60">
                    The proper way for production code. Exposes state through the normal message-passing API.
                  </p>
                </div>

                <div class="bg-base-300 rounded-lg p-4">
                  <h4 class="text-sm font-bold mb-2">Process.info/2</h4>
                  <div class="font-mono text-xs whitespace-pre-wrap mb-2">{process_info_code()}</div>
                  <p class="text-xs opacity-60">
                    Doesn't show GenServer state, but useful for monitoring process health (mailbox size, memory usage).
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="alert alert-warning mt-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
            <div>
              <h4 class="font-bold text-sm">Warning: :sys functions in production</h4>
              <p class="text-xs">
                <code>:sys.get_state/1</code> sends a synchronous message to the process. If the
                process is busy or has a large state, this can cause timeouts or slow things down.
                Always use dedicated API endpoints for production state access.
              </p>
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
                  <strong>State is immutable.</strong> Each callback receives the current state and
                  returns a new state. The GenServer holds the latest version.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">2</span>
                <span>
                  <strong>Use maps or structs for state.</strong> Maps are flexible; structs add
                  compile-time safety. Avoid simple values unless the server is truly single-purpose.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">3</span>
                <span>
                  <strong>Name processes for easy lookup.</strong> Use atom names for singletons,
                  Registry for dynamic per-entity servers.
                </span>
              </div>
              <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                <span class="badge badge-primary badge-sm mt-0.5">4</span>
                <span>
                  <strong>Expose state through APIs, not :sys.</strong> Production code should
                  access state through <code>handle_call</code>, not debugging tools.
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

  def handle_event("select_pattern", %{"id" => id}, socket) do
    selected = if socket.assigns.selected_pattern == id, do: nil, else: id
    {:noreply, assign(socket, selected_pattern: selected)}
  end

  def handle_event("select_naming", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    selected = if socket.assigns.selected_naming == idx, do: nil, else: idx
    {:noreply, assign(socket, selected_naming: selected)}
  end

  def handle_event("kv_put", %{"key" => key, "value" => value}, socket) do
    key = String.trim(key)
    value = String.trim(value)

    if key == "" do
      {:noreply, socket}
    else
      new_store = Map.put(socket.assigns.kv_store, key, value)
      entry = %{
        message: "cast({:put, \"#{key}\", \"#{value}\"}) -> {:noreply, #{inspect(new_store)}}",
        border: "border-purple-500"
      }

      {:noreply,
       socket
       |> assign(kv_store: new_store, kv_key: "", kv_value: "")
       |> assign(kv_log: [entry | socket.assigns.kv_log])}
    end
  end

  def handle_event("kv_get", %{"key" => key}, socket) do
    key = String.trim(key)

    if key == "" do
      {:noreply, socket}
    else
      case Map.fetch(socket.assigns.kv_store, key) do
        {:ok, val} ->
          entry = %{
            message: "call({:get, \"#{key}\"}) -> {:reply, \"#{val}\", state}",
            border: "border-green-500"
          }

          {:noreply,
           socket
           |> assign(kv_get_key: key, kv_get_result: %{found: true, display: "#{key} => \"#{val}\""})
           |> assign(kv_log: [entry | socket.assigns.kv_log])}

        :error ->
          entry = %{
            message: "call({:get, \"#{key}\"}) -> {:reply, nil, state}",
            border: "border-amber-500"
          }

          {:noreply,
           socket
           |> assign(kv_get_key: key, kv_get_result: %{found: false, display: "#{key} => nil (not found)"})
           |> assign(kv_log: [entry | socket.assigns.kv_log])}
      end
    end
  end

  def handle_event("kv_clear", _params, socket) do
    entry = %{
      message: "cast(:clear) -> {:noreply, %{}}",
      border: "border-red-500"
    }

    {:noreply,
     socket
     |> assign(kv_store: %{}, kv_get_result: nil)
     |> assign(kv_log: [entry | socket.assigns.kv_log])}
  end

  defp state_patterns, do: @state_patterns
  defp naming_examples, do: @naming_examples

  defp sys_get_state_code do
    String.trim("""
    iex> :sys.get_state(pid)
    %{count: 42, users: ["Alice", "Bob"]}
    """)
  end

  defp sys_get_status_code do
    String.trim(~s"""
    iex> :sys.get_status(pid)
    {:status, #PID<0.123.0>, {:module, MyServer},
     [["$initial_call": ..., "$ancestors": ...],
      :running, #PID<0.120.0>, [],
      [header: ..., data: ..., data: ...]]}
    """)
  end

  defp dedicated_api_code do
    String.trim("""
    # Add to your GenServer:
    def handle_call(:get_state, _from, state) do
      {:reply, state, state}
    end

    # Client API:
    def get_state(pid), do: GenServer.call(pid, :get_state)
    """)
  end

  defp process_info_code do
    String.trim("""
    iex> Process.info(pid, :message_queue_len)
    {:message_queue_len, 0}

    iex> Process.info(pid, :memory)
    {:memory, 2688}
    """)
  end

  defp registry_example_code do
    "# In your application supervision tree:\n" <>
    "children = [\n" <>
    "  {Registry, keys: :unique, name: MyApp.Registry}\n" <>
    "]\n" <>
    "\n" <>
    "# Starting a per-user server:\n" <>
    "def start_link(user_id) do\n" <>
    "  GenServer.start_link(__MODULE__, user_id,\n" <>
    "    name: {:via, Registry, {MyApp.Registry, user_id}})\n" <>
    "end\n" <>
    "\n" <>
    "# Looking up by user_id:\n" <>
    "GenServer.call(\n" <>
    "  {:via, Registry, {MyApp.Registry, user_id}},\n" <>
    "  :get_data\n" <>
    ")"
  end
end
