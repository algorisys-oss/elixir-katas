defmodule ElixirKatasWeb.ElixirKata70RegistryLive do
  use ElixirKatasWeb, :live_component

  @registry_types [
    %{
      id: "unique",
      label: ":unique",
      description: "Each key maps to exactly one process. Attempting to register a duplicate key fails.",
      code: "Registry.start_link(keys: :unique, name: MyRegistry)\n\n{:ok, _} = Registry.register(MyRegistry, \"user:alice\", %{role: :admin})\n{:ok, _} = Registry.register(MyRegistry, \"user:bob\", %{role: :user})\n\n# Lookup returns [{pid, value}]\nRegistry.lookup(MyRegistry, \"user:alice\")\n# => [{#PID<0.123.0>, %{role: :admin}}]",
      use_case: "Named process lookup, service discovery, unique worker identification"
    },
    %{
      id: "duplicate",
      label: ":duplicate",
      description: "Multiple processes can register under the same key. Useful for pub/sub patterns.",
      code: "Registry.start_link(keys: :duplicate, name: MyPubSub)\n\n# Multiple processes register for same event\nRegistry.register(MyPubSub, \"user:created\", [])\nRegistry.register(MyPubSub, \"user:created\", [])\n\n# Dispatch to all registered processes\nRegistry.dispatch(MyPubSub, \"user:created\", fn entries ->\n  for {pid, _value} <- entries do\n    send(pid, {:event, \"user:created\", %{name: \"Alice\"}})\n  end\nend)",
      use_case: "Event broadcasting, pub/sub, topic-based message routing"
    }
  ]

  @naming_patterns [
    %{id: "via", title: "Via Tuples", code: "# Register a GenServer with a name via Registry\ndef start_link(user_id) do\n  GenServer.start_link(\n    __MODULE__,\n    user_id,\n    name: via_tuple(user_id)\n  )\nend\n\ndefp via_tuple(user_id) do\n  {:via, Registry, {MyRegistry, \"user:\" <> user_id}}\nend\n\n# Call by name instead of PID\nGenServer.call(via_tuple(\"alice\"), :get_state)"},
    %{id: "lookup", title: "Registry.lookup/2", code: "# Find a process by key\ncase Registry.lookup(MyRegistry, \"user:alice\") do\n  [{pid, value}] -> {:ok, pid, value}\n  [] -> :not_found\nend"},
    %{id: "select", title: "Registry.select/2", code: "# Query the registry with match specs\nRegistry.select(MyRegistry, [\n  {{:_, :_, %{role: :admin}}, [], [true]}\n])\n# Returns count of matching entries"},
    %{id: "keys", title: "Registry.keys/2", code: "# Get all keys registered by a process\nRegistry.keys(MyRegistry, self())\n# => [\"user:alice\", \"session:abc123\"]"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_type, fn -> hd(@registry_types) end)
     |> assign_new(:entries, fn -> [] end)
     |> assign_new(:next_pid, fn -> 100 end)
     |> assign_new(:register_key, fn -> "" end)
     |> assign_new(:register_value, fn -> "" end)
     |> assign_new(:lookup_key, fn -> "" end)
     |> assign_new(:lookup_result, fn -> nil end)
     |> assign_new(:active_pattern, fn -> hd(@naming_patterns) end)
     |> assign_new(:show_patterns, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Registry</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">Registry</code> is a key-value process store.
        It lets you look up processes by name instead of PID, and supports both
        <strong>unique</strong> and <strong>duplicate</strong> key modes.
      </p>

      <!-- Registry Type Selector -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Registry Types</h3>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for rt <- registry_types() do %>
              <button
                phx-click="select_type"
                phx-target={@myself}
                phx-value-id={rt.id}
                class={"btn btn-sm " <> if(@active_type.id == rt.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= rt.label %>
              </button>
            <% end %>
          </div>

          <p class="text-sm opacity-70 mb-3"><%= @active_type.description %></p>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_type.code %></div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-xs">
            <span class="font-bold">Use case: </span><%= @active_type.use_case %>
          </div>
        </div>
      </div>

      <!-- Interactive Registry Simulation -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Simulated Registry (<%= @active_type.label %>)</h3>

          <!-- Register Form -->
          <form phx-submit="register" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Key</span></label>
              <input
                type="text"
                name="key"
                value={@register_key}
                placeholder="user:alice"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Value</span></label>
              <input
                type="text"
                name="value"
                value={@register_value}
                placeholder="%{role: :admin}"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Register</button>
          </form>

          <!-- Lookup Form -->
          <form phx-submit="lookup" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Lookup Key</span></label>
              <input
                type="text"
                name="key"
                value={@lookup_key}
                placeholder="user:alice"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-accent btn-sm">Lookup</button>
          </form>

          <!-- Lookup Result -->
          <%= if @lookup_result do %>
            <div class={"alert text-sm mb-4 " <> if(@lookup_result.found, do: "alert-success", else: "alert-warning")}>
              <div class="font-mono text-xs">
                <div class="opacity-60">Registry.lookup(MyRegistry, "<%= @lookup_result.key %>")</div>
                <div class="font-bold mt-1"><%= @lookup_result.display %></div>
              </div>
            </div>
          <% end %>

          <!-- Registered Entries -->
          <div class="bg-base-300 rounded-lg p-3 mb-4">
            <div class="text-xs font-bold opacity-60 mb-2">Registered Entries (<%= length(@entries) %>)</div>
            <%= if length(@entries) > 0 do %>
              <div class="space-y-1">
                <%= for entry <- @entries do %>
                  <div class="flex items-center justify-between bg-base-100 rounded p-2">
                    <div class="font-mono text-xs">
                      <span class="text-primary font-bold"><%= entry.key %></span>
                      <span class="opacity-30 mx-2">=&gt;</span>
                      <span class="opacity-50">&lbrace;#PID&lt;0.<%= entry.pid %>.0&gt;, </span>
                      <span class="text-accent"><%= entry.value %></span>
                      <span class="opacity-50">&rbrace;</span>
                    </div>
                    <button
                      phx-click="unregister"
                      phx-target={@myself}
                      phx-value-idx={entry.idx}
                      class="btn btn-ghost btn-xs text-error"
                    >
                      unregister
                    </button>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-xs opacity-40 text-center py-2">No entries registered</div>
            <% end %>
          </div>

          <%= if length(@entries) > 0 do %>
            <button
              phx-click="clear_registry"
              phx-target={@myself}
              class="btn btn-ghost btn-xs"
            >
              Clear All
            </button>
          <% end %>
        </div>
      </div>

      <!-- Naming Patterns -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Naming Patterns</h3>
            <button
              phx-click="toggle_patterns"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_patterns, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_patterns do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for pattern <- naming_patterns() do %>
                <button
                  phx-click="select_pattern"
                  phx-target={@myself}
                  phx-value-id={pattern.id}
                  class={"btn btn-sm " <> if(@active_pattern.id == pattern.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= pattern.title %>
                </button>
              <% end %>
            </div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap">
              <%= @active_pattern.code %>
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
              placeholder={"# Registry is started in your supervision tree\n# Try via tuples:\n{:via, Registry, {MyRegistry, \"user:alice\"}}"}
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
              <span><strong>Registry</strong> maps keys to processes, providing name-based lookup instead of using raw PIDs.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">:unique</code> keys allow one process per key. <code class="font-mono bg-base-100 px-1 rounded">:duplicate</code> keys allow many processes per key (pub/sub).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Via tuples</strong> (<code class="font-mono bg-base-100 px-1 rounded">&lbrace;:via, Registry, &lbrace;Name, key&rbrace;&rbrace;</code>) let GenServers register and be called by name.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>When a registered process dies, its entries are <strong>automatically removed</strong> from the Registry.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Registry is often combined with <code class="font-mono bg-base-100 px-1 rounded">DynamicSupervisor</code> to manage and look up on-demand processes.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_type", %{"id" => id}, socket) do
    rt = Enum.find(registry_types(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_type: rt)
     |> assign(entries: [])
     |> assign(lookup_result: nil)}
  end

  def handle_event("register", %{"key" => key, "value" => value}, socket) do
    key = String.trim(key)
    value = String.trim(value)

    if key == "" do
      {:noreply, socket}
    else
      is_unique = socket.assigns.active_type.id == "unique"
      already_exists = Enum.any?(socket.assigns.entries, &(&1.key == key))

      if is_unique && already_exists do
        {:noreply,
         assign(socket,
           lookup_result: %{
             found: false,
             key: key,
             display: "{:error, {:already_registered, #PID<...>}}"
           }
         )}
      else
        pid = socket.assigns.next_pid
        entry = %{
          key: key,
          value: if(value == "", do: "[]", else: value),
          pid: pid,
          idx: pid
        }

        {:noreply,
         socket
         |> assign(entries: socket.assigns.entries ++ [entry])
         |> assign(next_pid: pid + 1)
         |> assign(register_key: "")
         |> assign(register_value: "")}
      end
    end
  end

  def handle_event("lookup", %{"key" => key}, socket) do
    key = String.trim(key)

    if key == "" do
      {:noreply, socket}
    else
      matches = Enum.filter(socket.assigns.entries, &(&1.key == key))

      result =
        if length(matches) > 0 do
          entries_display =
            matches
            |> Enum.map(fn e -> "{#PID<0.#{e.pid}.0>, #{e.value}}" end)
            |> Enum.join(", ")

          %{found: true, key: key, display: "[#{entries_display}]"}
        else
          %{found: false, key: key, display: "[]"}
        end

      {:noreply, assign(socket, lookup_key: key, lookup_result: result)}
    end
  end

  def handle_event("unregister", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, entries: Enum.reject(socket.assigns.entries, &(&1.idx == idx)))}
  end

  def handle_event("clear_registry", _params, socket) do
    {:noreply, assign(socket, entries: [], lookup_result: nil)}
  end

  def handle_event("toggle_patterns", _params, socket) do
    {:noreply, assign(socket, show_patterns: !socket.assigns.show_patterns)}
  end

  def handle_event("select_pattern", %{"id" => id}, socket) do
    pattern = Enum.find(naming_patterns(), &(&1.id == id))
    {:noreply, assign(socket, active_pattern: pattern)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp registry_types, do: @registry_types
  defp naming_patterns, do: @naming_patterns

  defp evaluate_code(code) do
    try do
      {result, _bindings} = Code.eval_string(code)
      %{ok: true, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, output: "Error: #{Exception.message(e)}"}
    end
  end
end
