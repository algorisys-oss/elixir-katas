defmodule ElixirKatasWeb.ElixirKata08MapsKeywordsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:map_entries, fn -> %{"name" => "Elixir", "version" => "1.16", "type" => "language"} end)
     |> assign_new(:kw_entries, fn -> [{"env", "dev"}, {"port", "4000"}, {"env", "test"}] end)
     |> assign_new(:map_key, fn -> "" end)
     |> assign_new(:map_value, fn -> "" end)
     |> assign_new(:kw_key, fn -> "" end)
     |> assign_new(:kw_value, fn -> "" end)
     |> assign_new(:active_tab, fn -> "map" end)
     |> assign_new(:map_old_display, fn -> nil end)
     |> assign_new(:map_get_key, fn -> "" end)
     |> assign_new(:map_get_default, fn -> "nil" end)
     |> assign_new(:map_get_result, fn -> nil end)
     |> assign_new(:kw_get_key, fn -> "" end)
     |> assign_new(:kw_get_result, fn -> nil end)
     |> assign_new(:kw_get_all_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Maps & Keyword Lists Explorer</h2>
      <p class="text-sm opacity-70 mb-6">
        Maps are the go-to key-value store in Elixir. Keyword lists are specialized lists of &lbrace;key, value&rbrace; tuples where keys are atoms.
      </p>

      <!-- Tab Switcher -->
      <div class="tabs tabs-boxed mb-6 bg-base-200">
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="map"
          class={"tab " <> if(@active_tab == "map", do: "tab-active", else: "")}
        >
          Maps
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="keyword"
          class={"tab " <> if(@active_tab == "keyword", do: "tab-active", else: "")}
        >
          Keyword Lists
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="compare"
          class={"tab " <> if(@active_tab == "compare", do: "tab-active", else: "")}
        >
          Comparison
        </button>
      </div>

      <!-- Map Panel -->
      <%= if @active_tab == "map" do %>
        <div class="space-y-6">
          <!-- Map Display -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">Current Map</h3>
                <span class="badge badge-primary">size: <%= map_size(@map_entries) %></span>
              </div>

              <!-- Code Representation -->
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-3">
                %&lbrace;<%= for {k, v} <- @map_entries do %>
                  <span class="text-info">"<%= k %>"</span> =&gt; <span class="text-success">"<%= v %>"</span><%= unless k == List.last(Map.keys(@map_entries)), do: ", " %>
                <% end %>&rbrace;
              </div>

              <!-- Table View -->
              <%= if map_size(@map_entries) > 0 do %>
                <div class="overflow-x-auto">
                  <table class="table table-sm table-zebra">
                    <thead>
                      <tr>
                        <th>Key</th>
                        <th>Value</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for {k, v} <- @map_entries do %>
                        <tr>
                          <td class="font-mono text-info">"<%= k %>"</td>
                          <td class="font-mono text-success">"<%= v %>"</td>
                          <td>
                            <button
                              phx-click="map_delete"
                              phx-target={@myself}
                              phx-value-key={k}
                              class="btn btn-error btn-xs btn-outline"
                            >
                              Map.delete
                            </button>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% else %>
                <div class="text-center py-4 opacity-50">%&lbrace;&rbrace; (empty map)</div>
              <% end %>

              <!-- Immutability display -->
              <%= if @map_old_display do %>
                <div class="mt-3 space-y-1 text-sm">
                  <div class="flex items-center gap-2">
                    <span class="badge badge-ghost badge-sm">old</span>
                    <code class="font-mono opacity-50 line-through text-xs"><%= @map_old_display %></code>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="badge badge-success badge-sm">new</span>
                    <code class="font-mono font-bold text-xs"><%= inspect(@map_entries) %></code>
                  </div>
                  <p class="text-xs text-warning">The original map is unchanged! Map operations return new maps.</p>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Add / Update Entry -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm">Add / Update Entry</h3>
              <p class="text-xs opacity-60 mb-2">If the key exists, its value will be updated (shows immutability).</p>
              <form phx-submit="map_put" phx-target={@myself} class="flex gap-2 items-end">
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Key</span></label>
                  <input
                    type="text"
                    name="key"
                    value={@map_key}
                    placeholder="key"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Value</span></label>
                  <input
                    type="text"
                    name="value"
                    value={@map_value}
                    placeholder="value"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <button type="submit" class="btn btn-primary btn-sm">Map.put</button>
              </form>
            </div>
          </div>

          <!-- Map.get with Default -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm">Access Patterns</h3>
              <form phx-submit="map_get" phx-target={@myself} class="flex gap-2 items-end mb-3">
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Key</span></label>
                  <input
                    type="text"
                    name="key"
                    value={@map_get_key}
                    placeholder="key to look up"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Default</span></label>
                  <input
                    type="text"
                    name="default"
                    value={@map_get_default}
                    placeholder="default"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <button type="submit" class="btn btn-accent btn-sm">Map.get</button>
              </form>

              <%= if @map_get_result do %>
                <div class="bg-base-300 rounded-lg p-3 font-mono text-sm space-y-1">
                  <div>
                    <span class="opacity-50">Map.get(map, "<%= @map_get_result.key %>", "<%= @map_get_result.default %>")</span>
                    <span class="text-success font-bold ml-2"><%= @map_get_result.value %></span>
                  </div>
                  <div>
                    <span class="opacity-50">map["<%= @map_get_result.key %>"]</span>
                    <span class="text-info font-bold ml-2"><%= @map_get_result.bracket_value %></span>
                  </div>
                  <div class="text-xs opacity-50 mt-2">
                    map["key"] returns nil for missing keys. Map.get/3 lets you specify a default.
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Reset -->
          <div class="flex gap-2">
            <button phx-click="map_clear" phx-target={@myself} class="btn btn-error btn-sm btn-outline">Clear Map</button>
            <button phx-click="map_reset" phx-target={@myself} class="btn btn-ghost btn-sm">Reset to Default</button>
          </div>
        </div>
      <% end %>

      <!-- Keyword List Panel -->
      <%= if @active_tab == "keyword" do %>
        <div class="space-y-6">
          <!-- Keyword List Display -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-3">
                <h3 class="card-title text-sm">Current Keyword List</h3>
                <span class="badge badge-secondary">length: <%= length(@kw_entries) %></span>
              </div>

              <!-- Code Representation -->
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-3">
                [<%= for {{k, v}, idx} <- Enum.with_index(@kw_entries) do %>
                  <span class="text-secondary"><%= k %></span>: <span class="text-success">"<%= v %>"</span><%= unless idx == length(@kw_entries) - 1, do: ", " %>
                <% end %>]
              </div>

              <!-- Visual Cards -->
              <div class="flex flex-wrap gap-2 mb-3">
                <%= for {{k, v}, idx} <- Enum.with_index(@kw_entries) do %>
                  <div class="flex items-center gap-1 border border-base-300 rounded-lg px-3 py-1.5 bg-base-100">
                    <span class="font-mono text-secondary font-bold text-sm"><%= k %>:</span>
                    <span class="font-mono text-success text-sm">"<%= v %>"</span>
                    <button
                      phx-click="kw_delete"
                      phx-target={@myself}
                      phx-value-index={idx}
                      class="btn btn-ghost btn-xs text-error ml-1"
                    >
                      x
                    </button>
                  </div>
                <% end %>
              </div>

              <!-- Duplicate Keys Highlight -->
              <%= if has_duplicate_keys?(@kw_entries) do %>
                <div class="alert alert-warning text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
                  <span>Duplicate keys detected! Keyword lists allow this. Keyword.get/2 returns the first match.</span>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Add Entry -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm">Add Entry</h3>
              <p class="text-xs opacity-60 mb-2">Keyword list keys must be atoms. Duplicate keys are allowed!</p>
              <form phx-submit="kw_put" phx-target={@myself} class="flex gap-2 items-end">
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Key (atom)</span></label>
                  <input
                    type="text"
                    name="key"
                    value={@kw_key}
                    placeholder="key name"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Value</span></label>
                  <input
                    type="text"
                    name="value"
                    value={@kw_value}
                    placeholder="value"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <button type="submit" class="btn btn-secondary btn-sm">Add</button>
              </form>
            </div>
          </div>

          <!-- Keyword.get vs Keyword.get_values -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm">Keyword.get vs Keyword.get_values</h3>
              <form phx-submit="kw_get" phx-target={@myself} class="flex gap-2 items-end mb-3">
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Key to look up</span></label>
                  <input
                    type="text"
                    name="key"
                    value={@kw_get_key}
                    placeholder="key name"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <button type="submit" class="btn btn-accent btn-sm">Look up</button>
              </form>

              <%= if @kw_get_result do %>
                <div class="bg-base-300 rounded-lg p-3 font-mono text-sm space-y-2">
                  <div>
                    <span class="opacity-50">Keyword.get(kw, :<%= @kw_get_result.key %>)</span>
                    <span class="text-success font-bold ml-2"><%= @kw_get_result.first_value %></span>
                    <span class="text-xs opacity-40 ml-2">(first match only)</span>
                  </div>
                  <div>
                    <span class="opacity-50">Keyword.get_values(kw, :<%= @kw_get_result.key %>)</span>
                    <span class="text-info font-bold ml-2"><%= @kw_get_result.all_values %></span>
                    <span class="text-xs opacity-40 ml-2">(all matches)</span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Ordering Preserved Note -->
          <div class="alert alert-info text-sm">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span>Keyword lists preserve insertion order. This is why they are used for options where order matters (e.g., Ecto queries).</span>
          </div>

          <!-- Reset -->
          <div class="flex gap-2">
            <button phx-click="kw_clear" phx-target={@myself} class="btn btn-error btn-sm btn-outline">Clear</button>
            <button phx-click="kw_reset" phx-target={@myself} class="btn btn-ghost btn-sm">Reset to Default</button>
          </div>
        </div>
      <% end %>

      <!-- Comparison Panel -->
      <%= if @active_tab == "compare" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-4">When to Use Map vs Keyword List</h3>

              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Feature</th>
                      <th class="text-primary">Map</th>
                      <th class="text-secondary">Keyword List</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td class="font-semibold">Key types</td>
                      <td>Any type</td>
                      <td>Atoms only</td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Duplicate keys</td>
                      <td><span class="badge badge-error badge-xs">No</span></td>
                      <td><span class="badge badge-success badge-xs">Yes</span></td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Ordered</td>
                      <td><span class="badge badge-error badge-xs">No</span></td>
                      <td><span class="badge badge-success badge-xs">Yes</span></td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Pattern matching</td>
                      <td><span class="badge badge-success badge-xs">Excellent</span></td>
                      <td><span class="badge badge-warning badge-xs">Limited</span></td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Lookup speed</td>
                      <td><span class="badge badge-success badge-xs">O(log n)</span></td>
                      <td><span class="badge badge-warning badge-xs">O(n)</span></td>
                    </tr>
                    <tr>
                      <td class="font-semibold">Best for</td>
                      <td>General key-value data, structs</td>
                      <td>Options, DSLs, small configs</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- Pattern Matching Examples -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Pattern Matching</h3>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Map Pattern Matching -->
                <div class="bg-primary/10 border border-primary/30 rounded-lg p-4">
                  <h4 class="font-bold text-primary text-sm mb-2">Map Patterns</h4>
                  <div class="font-mono text-xs space-y-3">
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Match on specific keys</div>
                      <div>%&lbrace;"name" =&gt; name&rbrace; = %&lbrace;"name" =&gt; "Elixir", "v" =&gt; "1.16"&rbrace;</div>
                      <div class="text-success mt-1">name = "Elixir"</div>
                    </div>
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Update syntax (key must exist!)</div>
                      <div>%&lbrace;map | "name" =&gt; "Phoenix"&rbrace;</div>
                    </div>
                  </div>
                </div>

                <!-- Keyword Pattern Matching -->
                <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-4">
                  <h4 class="font-bold text-secondary text-sm mb-2">Keyword Patterns</h4>
                  <div class="font-mono text-xs space-y-3">
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Common in function options</div>
                      <div>def query(opts \\ []) do</div>
                      <div>  limit = Keyword.get(opts, :limit, 10)</div>
                      <div>  order = Keyword.get(opts, :order, :asc)</div>
                      <div>end</div>
                    </div>
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Last argument sugar</div>
                      <div>query(limit: 5, order: :desc)</div>
                      <div class="text-secondary mt-1"># Same as: query([limit: 5, order: :desc])</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Quick Decision Guide -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Quick Decision Guide</h3>
              <div class="space-y-2 text-sm">
                <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">Map</span>
                  <span>Need to store structured data with unique keys (like a user record)</span>
                </div>
                <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">Map</span>
                  <span>Need fast lookups by key</span>
                </div>
                <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">Map</span>
                  <span>Keys might be strings, integers, or mixed types</span>
                </div>
                <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                  <span class="badge badge-secondary badge-sm mt-0.5">KW</span>
                  <span>Passing optional arguments to a function</span>
                </div>
                <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                  <span class="badge badge-secondary badge-sm mt-0.5">KW</span>
                  <span>Need duplicate keys (e.g., multiple :where clauses in Ecto)</span>
                </div>
                <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
                  <span class="badge badge-secondary badge-sm mt-0.5">KW</span>
                  <span>Order of entries matters</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Event Handlers

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  # -- Map Events --

  def handle_event("map_put", %{"key" => key, "value" => value}, socket) do
    key = String.trim(key)
    value = String.trim(value)

    if key != "" and value != "" do
      old_display = inspect(socket.assigns.map_entries)
      new_map = Map.put(socket.assigns.map_entries, key, value)

      {:noreply,
       socket
       |> assign(map_entries: new_map)
       |> assign(map_key: "")
       |> assign(map_value: "")
       |> assign(map_old_display: old_display)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("map_delete", %{"key" => key}, socket) do
    old_display = inspect(socket.assigns.map_entries)
    new_map = Map.delete(socket.assigns.map_entries, key)

    {:noreply,
     socket
     |> assign(map_entries: new_map)
     |> assign(map_old_display: old_display)}
  end

  def handle_event("map_get", %{"key" => key, "default" => default}, socket) do
    key = String.trim(key)

    if key != "" do
      map = socket.assigns.map_entries
      get_result = Map.get(map, key, default)
      bracket_result = map[key]

      {:noreply,
       socket
       |> assign(map_get_key: key)
       |> assign(map_get_default: default)
       |> assign(map_get_result: %{
         key: key,
         default: default,
         value: inspect(get_result),
         bracket_value: inspect(bracket_result)
       })}
    else
      {:noreply, socket}
    end
  end

  def handle_event("map_clear", _params, socket) do
    {:noreply,
     socket
     |> assign(map_entries: %{})
     |> assign(map_old_display: nil)
     |> assign(map_get_result: nil)}
  end

  def handle_event("map_reset", _params, socket) do
    {:noreply,
     socket
     |> assign(map_entries: %{"name" => "Elixir", "version" => "1.16", "type" => "language"})
     |> assign(map_key: "")
     |> assign(map_value: "")
     |> assign(map_old_display: nil)
     |> assign(map_get_result: nil)}
  end

  # -- Keyword List Events --

  def handle_event("kw_put", %{"key" => key, "value" => value}, socket) do
    key = String.trim(key)
    value = String.trim(value)

    if key != "" and value != "" do
      new_entries = socket.assigns.kw_entries ++ [{key, value}]

      {:noreply,
       socket
       |> assign(kw_entries: new_entries)
       |> assign(kw_key: "")
       |> assign(kw_value: "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("kw_delete", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    new_entries = List.delete_at(socket.assigns.kw_entries, idx)

    {:noreply, assign(socket, kw_entries: new_entries)}
  end

  def handle_event("kw_get", %{"key" => key}, socket) do
    key = String.trim(key)

    if key != "" do
      entries = socket.assigns.kw_entries

      # Find first match
      first_match =
        case Enum.find(entries, fn {k, _v} -> k == key end) do
          {_k, v} -> inspect(v)
          nil -> "nil"
        end

      # Find all matches
      all_matches =
        entries
        |> Enum.filter(fn {k, _v} -> k == key end)
        |> Enum.map(fn {_k, v} -> v end)

      {:noreply,
       socket
       |> assign(kw_get_key: key)
       |> assign(kw_get_result: %{
         key: key,
         first_value: first_match,
         all_values: inspect(all_matches)
       })}
    else
      {:noreply, socket}
    end
  end

  def handle_event("kw_clear", _params, socket) do
    {:noreply,
     socket
     |> assign(kw_entries: [])
     |> assign(kw_get_result: nil)}
  end

  def handle_event("kw_reset", _params, socket) do
    {:noreply,
     socket
     |> assign(kw_entries: [{"env", "dev"}, {"port", "4000"}, {"env", "test"}])
     |> assign(kw_key: "")
     |> assign(kw_value: "")
     |> assign(kw_get_result: nil)}
  end

  # Helpers

  defp has_duplicate_keys?(entries) do
    keys = Enum.map(entries, fn {k, _v} -> k end)
    length(keys) != length(Enum.uniq(keys))
  end
end
