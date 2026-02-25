defmodule ElixirKatasWeb.ElixirKata71EtsTablesLive do
  use ElixirKatasWeb, :live_component

  @table_types [
    %{
      id: "set",
      label: ":set",
      description: "One value per key. Inserting a duplicate key overwrites the previous value.",
      behavior: "Key uniqueness enforced. Last write wins.",
      default: true
    },
    %{
      id: "ordered_set",
      label: ":ordered_set",
      description: "Like :set, but entries are ordered by key. Iteration returns entries in key order.",
      behavior: "Key uniqueness enforced. Ordered by key."
    },
    %{
      id: "bag",
      label: ":bag",
      description: "Multiple entries per key allowed, but no exact duplicate tuples (same key AND value).",
      behavior: "Same key OK, but exact duplicate tuples are rejected."
    },
    %{
      id: "duplicate_bag",
      label: ":duplicate_bag",
      description: "Multiple entries per key allowed, including exact duplicate tuples.",
      behavior: "Everything goes. Full duplicates are allowed."
    }
  ]

  @api_examples [
    %{
      id: "new",
      title: ":ets.new/2",
      code: "table = :ets.new(:my_cache, [:set, :public, :named_table])\n# => :my_cache",
      explanation: "Creates a new ETS table. Options include the table type (:set, :ordered_set, :bag, :duplicate_bag) and access level (:public, :protected, :private)."
    },
    %{
      id: "insert",
      title: ":ets.insert/2",
      code: ":ets.insert(:my_cache, {\"user:alice\", %{name: \"Alice\", age: 30}})\n:ets.insert(:my_cache, {\"user:bob\", %{name: \"Bob\", age: 25}})\n# => true",
      explanation: "Inserts one or more tuples into the table. The first element of each tuple is the key."
    },
    %{
      id: "lookup",
      title: ":ets.lookup/2",
      code: ":ets.lookup(:my_cache, \"user:alice\")\n# => [{\"user:alice\", %{name: \"Alice\", age: 30}}]",
      explanation: "Returns a list of matching entries. For :set and :ordered_set, returns at most one entry. For :bag and :duplicate_bag, may return multiple."
    },
    %{
      id: "delete",
      title: ":ets.delete/2",
      code: ":ets.delete(:my_cache, \"user:alice\")\n# => true\n\n# Delete entire table:\n:ets.delete(:my_cache)\n# => true",
      explanation: "Deletes all entries matching the key, or deletes the entire table."
    },
    %{
      id: "match",
      title: ":ets.match/2",
      code: "# Match pattern: :_ is wildcard, :'$1' captures\n:ets.match(:my_cache, {:_, %{name: :'$1', age: :'$2'}})\n# => [[\"Alice\", 30], [\"Bob\", 25]]",
      explanation: "Pattern matching on ETS entries. Use :_ for wildcards and :'$N' for captures."
    },
    %{
      id: "tab2list",
      title: ":ets.tab2list/1",
      code: ":ets.tab2list(:my_cache)\n# => [{\"user:alice\", %{...}}, {\"user:bob\", %{...}}]",
      explanation: "Returns all entries in the table as a list. Useful for debugging but expensive for large tables."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_table_type, fn -> hd(@table_types) end)
     |> assign_new(:table_entries, fn -> [] end)
     |> assign_new(:insert_key, fn -> "" end)
     |> assign_new(:insert_value, fn -> "" end)
     |> assign_new(:lookup_key, fn -> "" end)
     |> assign_new(:lookup_result, fn -> nil end)
     |> assign_new(:active_api, fn -> hd(@api_examples) end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">ETS Tables</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>ETS (Erlang Term Storage)</strong> provides in-memory key-value tables with concurrent
        read access. ETS tables live outside the process heap, making them ideal for shared
        caches and lookup tables.
      </p>

      <!-- API Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">ETS API</h3>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for api <- api_examples() do %>
              <button
                phx-click="select_api"
                phx-target={@myself}
                phx-value-id={api.id}
                class={"btn btn-sm " <> if(@active_api.id == api.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= api.title %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_api.code %></div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
            <%= @active_api.explanation %>
          </div>
        </div>
      </div>

      <!-- Table Type Selector -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Table Types</h3>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-2 mb-4">
            <%= for tt <- table_types() do %>
              <button
                phx-click="select_table_type"
                phx-target={@myself}
                phx-value-id={tt.id}
                class={"btn btn-sm h-auto py-2 flex-col " <> if(@active_table_type.id == tt.id, do: "btn-primary", else: "btn-outline")}
              >
                <span class="font-mono"><%= tt.label %></span>
                <%= if Map.get(tt, :default) do %>
                  <span class="badge badge-xs">default</span>
                <% end %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-100 rounded-lg p-3 border border-base-300 mb-4">
            <p class="text-sm font-bold mb-1"><%= @active_table_type.label %></p>
            <p class="text-xs opacity-70 mb-1"><%= @active_table_type.description %></p>
            <p class="text-xs"><span class="font-bold">Behavior: </span><%= @active_table_type.behavior %></p>
          </div>
        </div>
      </div>

      <!-- Interactive ETS Simulation -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Simulated ETS Table (<%= @active_table_type.label %>)</h3>

          <!-- Insert Form -->
          <form phx-submit="ets_insert" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Key</span></label>
              <input
                type="text"
                name="key"
                value={@insert_key}
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
                value={@insert_value}
                placeholder="Alice"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">:ets.insert</button>
          </form>

          <!-- Lookup Form -->
          <form phx-submit="ets_lookup" phx-target={@myself} class="flex gap-2 items-end mb-4">
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
            <button type="submit" class="btn btn-accent btn-sm">:ets.lookup</button>
          </form>

          <!-- Lookup Result -->
          <%= if @lookup_result do %>
            <div class={"alert text-sm mb-4 " <> if(@lookup_result.found, do: "alert-success", else: "alert-warning")}>
              <div class="font-mono text-xs">
                <div class="opacity-60">:ets.lookup(:my_table, "<%= @lookup_result.key %>")</div>
                <div class="font-bold mt-1"><%= @lookup_result.display %></div>
              </div>
            </div>
          <% end %>

          <!-- Table Contents -->
          <div class="bg-base-300 rounded-lg p-3 mb-4">
            <div class="flex items-center justify-between mb-2">
              <div class="text-xs font-bold opacity-60">
                :ets.tab2list(:my_table) &mdash; <%= length(@table_entries) %> entries
              </div>
              <%= if length(@table_entries) > 0 do %>
                <button
                  phx-click="ets_clear"
                  phx-target={@myself}
                  class="btn btn-ghost btn-xs text-error"
                >
                  :ets.delete(:my_table)
                </button>
              <% end %>
            </div>

            <%= if length(@table_entries) > 0 do %>
              <div class="overflow-x-auto">
                <table class="table table-xs">
                  <thead>
                    <tr>
                      <th class="font-mono">Key</th>
                      <th class="font-mono">Value</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for {entry, idx} <- Enum.with_index(@table_entries) do %>
                      <tr>
                        <td class="font-mono text-primary"><%= entry.key %></td>
                        <td class="font-mono text-accent"><%= entry.value %></td>
                        <td>
                          <button
                            phx-click="ets_delete"
                            phx-target={@myself}
                            phx-value-idx={idx}
                            class="btn btn-ghost btn-xs text-error"
                          >
                            delete
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% else %>
              <div class="text-xs opacity-40 text-center py-2">Table is empty</div>
            <% end %>
          </div>

          <!-- Quick Insert Examples -->
          <div class="flex flex-wrap gap-2">
            <span class="text-xs opacity-50 self-center">Quick inserts:</span>
            <%= for {key, value} <- sample_data() do %>
              <button
                phx-click="quick_insert"
                phx-target={@myself}
                phx-value-key={key}
                phx-value-value={value}
                class="btn btn-xs btn-outline"
              >
                &lbrace;"<%= key %>", "<%= value %>"&rbrace;
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <!-- ETS vs Agent/GenServer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">When to Use ETS</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto mb-4">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Feature</th>
                    <th>ETS</th>
                    <th>Agent/GenServer</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-bold">Concurrent reads</td>
                    <td class="text-success">Lock-free, very fast</td>
                    <td class="text-warning">Sequential (message queue)</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Concurrent writes</td>
                    <td class="text-warning">Possible with :public</td>
                    <td class="text-success">Serialized, safe</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Data lives in</td>
                    <td>Separate memory (no GC impact)</td>
                    <td>Process heap (GC applies)</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Persistence</td>
                    <td class="text-error">In-memory only (lost on restart)</td>
                    <td class="text-error">In-memory only</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Pattern matching</td>
                    <td class="text-success">Built-in match specs</td>
                    <td class="text-warning">Manual in handle_call</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Complex logic</td>
                    <td class="text-warning">Limited</td>
                    <td class="text-success">Full Elixir code</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="alert alert-info text-sm">
              <div>
                <strong>Rule of thumb:</strong> Use ETS for read-heavy, shared data (caches, counters, lookup tables).
                Use Agent/GenServer when you need complex logic, sequential writes, or process lifecycle management.
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
              rows="5"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={"table = :ets.new(:demo, [:set])\n:ets.insert(table, {\"key1\", \"value1\"})\n:ets.insert(table, {\"key2\", \"value2\"})\nresult = :ets.tab2list(table)\n:ets.delete(table)\nresult"}
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
              <span><strong>ETS</strong> provides in-memory key-value storage with concurrent read access, separate from any process heap.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Four table types: <code class="font-mono bg-base-100 px-1 rounded">:set</code> (unique keys), <code class="font-mono bg-base-100 px-1 rounded">:ordered_set</code> (sorted unique), <code class="font-mono bg-base-100 px-1 rounded">:bag</code> (multi-value), <code class="font-mono bg-base-100 px-1 rounded">:duplicate_bag</code> (full duplicates).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Data is stored as tuples. The <strong>first element</strong> is always the key.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>ETS is <strong>not persisted</strong> &mdash; data is lost when the owning process terminates or the VM shuts down.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Use ETS for <strong>read-heavy, shared data</strong> like caches and lookup tables. Use Agent/GenServer for complex stateful logic.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_api", %{"id" => id}, socket) do
    api = Enum.find(api_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_api: api)}
  end

  def handle_event("select_table_type", %{"id" => id}, socket) do
    tt = Enum.find(table_types(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_table_type: tt)
     |> assign(table_entries: [])
     |> assign(lookup_result: nil)}
  end

  def handle_event("ets_insert", %{"key" => key, "value" => value}, socket) do
    key = String.trim(key)
    value = String.trim(value)

    if key == "" do
      {:noreply, socket}
    else
      value = if value == "", do: "nil", else: value
      entries = socket.assigns.table_entries
      table_type = socket.assigns.active_table_type.id

      new_entries =
        case table_type do
          "set" ->
            # Replace existing key
            if Enum.any?(entries, &(&1.key == key)) do
              Enum.map(entries, fn e -> if e.key == key, do: %{key: key, value: value}, else: e end)
            else
              entries ++ [%{key: key, value: value}]
            end

          "ordered_set" ->
            # Replace existing key, keep sorted
            filtered = Enum.reject(entries, &(&1.key == key))
            (filtered ++ [%{key: key, value: value}])
            |> Enum.sort_by(& &1.key)

          "bag" ->
            # Allow same key, but no exact duplicates
            entry = %{key: key, value: value}
            if Enum.member?(entries, entry) do
              entries
            else
              entries ++ [entry]
            end

          "duplicate_bag" ->
            # Allow everything
            entries ++ [%{key: key, value: value}]

          _ ->
            entries ++ [%{key: key, value: value}]
        end

      {:noreply,
       socket
       |> assign(table_entries: new_entries)
       |> assign(insert_key: "")
       |> assign(insert_value: "")}
    end
  end

  def handle_event("ets_lookup", %{"key" => key}, socket) do
    key = String.trim(key)

    if key == "" do
      {:noreply, socket}
    else
      matches = Enum.filter(socket.assigns.table_entries, &(&1.key == key))

      result =
        if length(matches) > 0 do
          entries_display =
            matches
            |> Enum.map(fn e -> "{\"#{e.key}\", \"#{e.value}\"}" end)
            |> Enum.join(", ")

          %{found: true, key: key, display: "[#{entries_display}]"}
        else
          %{found: false, key: key, display: "[]"}
        end

      {:noreply, assign(socket, lookup_key: key, lookup_result: result)}
    end
  end

  def handle_event("ets_delete", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, table_entries: List.delete_at(socket.assigns.table_entries, idx))}
  end

  def handle_event("ets_clear", _params, socket) do
    {:noreply, assign(socket, table_entries: [], lookup_result: nil)}
  end

  def handle_event("quick_insert", %{"key" => key, "value" => value}, socket) do
    handle_event("ets_insert", %{"key" => key, "value" => value}, socket)
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
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

  defp table_types, do: @table_types
  defp api_examples, do: @api_examples

  defp sample_data do
    [
      {"name", "Alice"},
      {"name", "Bob"},
      {"role", "admin"},
      {"age", "30"},
      {"city", "Portland"}
    ]
  end

  defp sandbox_examples do
    [
      {"set basics",
       "table = :ets.new(:demo, [:set])\n:ets.insert(table, {\"a\", 1})\n:ets.insert(table, {\"b\", 2})\n:ets.insert(table, {\"a\", 99})\nresult = :ets.tab2list(table)\n:ets.delete(table)\nresult"},
      {"ordered_set",
       "table = :ets.new(:demo, [:ordered_set])\n:ets.insert(table, {\"c\", 3})\n:ets.insert(table, {\"a\", 1})\n:ets.insert(table, {\"b\", 2})\nresult = :ets.tab2list(table)\n:ets.delete(table)\nresult"},
      {"bag",
       "table = :ets.new(:demo, [:bag])\n:ets.insert(table, {\"x\", 1})\n:ets.insert(table, {\"x\", 2})\n:ets.insert(table, {\"x\", 1})\nresult = :ets.tab2list(table)\n:ets.delete(table)\nresult"},
      {"lookup",
       "table = :ets.new(:demo, [:set])\n:ets.insert(table, {\"key1\", \"val1\"})\nresult = :ets.lookup(table, \"key1\")\n:ets.delete(table)\nresult"}
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
