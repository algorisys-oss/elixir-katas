defmodule ElixirKatasWeb.ElixirKata07ListsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:items, fn -> [1, 2, 3, 4, 5] end)
     |> assign_new(:new_item, fn -> "" end)
     |> assign_new(:remove_item, fn -> "" end)
     |> assign_new(:highlighted, fn -> nil end)
     |> assign_new(:operation_log, fn -> ["Initial list: [1, 2, 3, 4, 5]"] end)
     |> assign_new(:concat_input, fn -> "" end)
     |> assign_new(:subtract_input, fn -> "" end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">List Explorer</h2>
      <p class="text-sm opacity-70 mb-6">
        Lists in Elixir are linked lists. Understanding their structure explains why prepend is O(1) and append is O(n).
      </p>

      <!-- Linked List Visualization -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">List Visualization</h3>
            <span class="badge badge-primary">length: <%= length(@items) %></span>
          </div>

          <%= if @items == [] do %>
            <div class="text-center py-6 opacity-50 font-mono">[ ] (empty list)</div>
          <% else %>
            <!-- Linked boxes visualization -->
            <div class="flex flex-wrap items-center gap-0 overflow-x-auto pb-2">
              <%= for {item, idx} <- Enum.with_index(@items) do %>
                <div class="flex items-center">
                  <div class={"flex flex-col items-center border-2 rounded-lg px-3 py-2 min-w-[60px] transition-all " <>
                    cond do
                      @highlighted == :head and idx == 0 -> "border-success bg-success/20 shadow-lg scale-110"
                      @highlighted == :tail and idx > 0 -> "border-info bg-info/20"
                      @highlighted == :tail and idx == 0 -> "border-base-300 bg-base-100 opacity-50"
                      true -> "border-base-300 bg-base-100"
                    end}>
                    <span class="text-xs opacity-40">
                      <%= cond do %>
                        <% idx == 0 and @highlighted == :head -> %>
                          <span class="text-success font-bold">hd</span>
                        <% idx == 0 -> %>
                          head
                        <% true -> %>
                          [<%= idx %>]
                      <% end %>
                    </span>
                    <span class="font-mono font-bold text-lg"><%= item %></span>
                  </div>
                  <%= if idx < length(@items) - 1 do %>
                    <div class="flex items-center px-1">
                      <svg class="w-6 h-3 text-warning" viewBox="0 0 24 12" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M0 6h20M16 2l4 4-4 4" />
                      </svg>
                    </div>
                  <% else %>
                    <div class="flex items-center px-1">
                      <svg class="w-6 h-3 opacity-30" viewBox="0 0 24 12" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M0 6h10" />
                        <circle cx="16" cy="6" r="3" fill="currentColor" />
                      </svg>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>

            <!-- Head | Tail Destructuring -->
            <div class="mt-4 p-3 bg-base-300 rounded-lg font-mono text-sm">
              <div class="text-xs opacity-50 mb-1"># Pattern matching destructuring</div>
              <div>[<span class="text-success font-bold"><%= hd(@items) %></span> | <span class="text-info"><%= inspect(tl(@items)) %></span>] = <%= inspect(@items) %></div>
              <div class="mt-1 text-xs">
                <span class="text-success">head = <%= hd(@items) %></span>
                <span class="mx-2 opacity-30">|</span>
                <span class="text-info">tail = <%= inspect(tl(@items)) %></span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Operation Controls -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <!-- Prepend (O(1)) -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <div class="flex items-center gap-2 mb-2">
              <h3 class="card-title text-sm">Prepend [val | list]</h3>
              <span class="badge badge-success badge-xs">O(1)</span>
            </div>
            <form phx-submit="prepend" phx-target={@myself} class="flex gap-2">
              <input
                type="text"
                name="value"
                value={@new_item}
                placeholder="Value..."
                class="input input-bordered input-sm flex-1 font-mono"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-success btn-sm">Prepend</button>
            </form>
            <p class="text-xs opacity-50 mt-1">
              Just creates a new node pointing to the existing list. Instant!
            </p>
          </div>
        </div>

        <!-- Append (O(n)) -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <div class="flex items-center gap-2 mb-2">
              <h3 class="card-title text-sm">Append list ++ [val]</h3>
              <span class="badge badge-warning badge-xs">O(n)</span>
            </div>
            <form phx-submit="append" phx-target={@myself} class="flex gap-2">
              <input
                type="text"
                name="value"
                value=""
                placeholder="Value..."
                class="input input-bordered input-sm flex-1 font-mono"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-warning btn-sm">Append</button>
            </form>
            <p class="text-xs opacity-50 mt-1">
              Must traverse the entire list to reach the end. Slow for large lists!
            </p>
          </div>
        </div>
      </div>

      <!-- hd/tl and ++ / -- -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <!-- hd / tl -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-2">hd/1 and tl/1</h3>
            <div class="flex gap-2">
              <button
                phx-click="highlight"
                phx-target={@myself}
                phx-value-part="head"
                class={"btn btn-sm " <> if(@highlighted == :head, do: "btn-success", else: "btn-outline btn-success")}
                disabled={@items == []}
              >
                hd(list)
              </button>
              <button
                phx-click="highlight"
                phx-target={@myself}
                phx-value-part="tail"
                class={"btn btn-sm " <> if(@highlighted == :tail, do: "btn-info", else: "btn-outline btn-info")}
                disabled={@items == []}
              >
                tl(list)
              </button>
              <button
                phx-click="highlight"
                phx-target={@myself}
                phx-value-part="none"
                class="btn btn-sm btn-ghost"
              >
                Clear
              </button>
            </div>
            <%= if @items != [] do %>
              <div class="mt-2 text-sm font-mono">
                <%= if @highlighted == :head do %>
                  <span class="text-success">hd = <%= hd(@items) %></span>
                <% end %>
                <%= if @highlighted == :tail do %>
                  <span class="text-info">tl = <%= inspect(tl(@items)) %></span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- ++ and -- -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-2">++ (concat) and -- (subtract)</h3>
            <form phx-submit="concat" phx-target={@myself} class="flex gap-2 mb-2">
              <input
                type="text"
                name="value"
                value={@concat_input}
                placeholder="e.g. 10, 20"
                class="input input-bordered input-sm flex-1 font-mono"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-sm btn-accent">++</button>
            </form>
            <form phx-submit="subtract" phx-target={@myself} class="flex gap-2">
              <input
                type="text"
                name="value"
                value={@subtract_input}
                placeholder="e.g. 2, 3"
                class="input input-bordered input-sm flex-1 font-mono"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-sm btn-error btn-outline">--</button>
            </form>
            <p class="text-xs opacity-50 mt-1">
              Enter comma-separated values. ++ appends, -- removes first occurrence of each.
            </p>
          </div>
        </div>
      </div>

      <!-- Reset -->
      <div class="flex gap-2 mb-6">
        <button phx-click="clear_list" phx-target={@myself} class="btn btn-error btn-sm btn-outline">
          Clear List
        </button>
        <button phx-click="reset_list" phx-target={@myself} class="btn btn-ghost btn-sm">
          Reset to Default
        </button>
      </div>

      <!-- Operation Log -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Operation Log</h3>
          <div class="max-h-40 overflow-y-auto space-y-1">
            <%= for {entry, idx} <- Enum.with_index(@operation_log) do %>
              <div class={"font-mono text-xs p-1.5 rounded " <> if(idx == 0, do: "bg-primary/10 font-bold", else: "bg-base-300")}>
                <%= entry %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Performance Explanation -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Why Prepend is O(1) and Append is O(n)</h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Prepend Explanation -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <h4 class="font-bold text-success text-sm mb-2">Prepend: [new | existing]</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="opacity-70">existing = [1, 2, 3]</div>
                <div class="opacity-70"># Just point new node to existing list:</div>
                <div class="font-bold">[0 | existing] = [0, 1, 2, 3]</div>
              </div>
              <p class="text-xs mt-3 opacity-70">
                A new cell is created pointing to the head of the existing list.
                The original list is reused entirely (structural sharing). No copying needed.
              </p>
            </div>

            <!-- Append Explanation -->
            <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
              <h4 class="font-bold text-warning text-sm mb-2">Append: existing ++ [new]</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="opacity-70">existing = [1, 2, 3]</div>
                <div class="opacity-70"># Must copy every cell to change the last pointer:</div>
                <div class="font-bold">existing ++ [4] = [1, 2, 3, 4]</div>
              </div>
              <p class="text-xs mt-3 opacity-70">
                The entire list must be traversed and copied because each cell points to the next.
                You cannot modify the last cell (immutability!) so all cells must be recreated.
              </p>
            </div>
          </div>

          <div class="mt-4 p-3 bg-base-300 rounded-lg text-sm">
            <span class="font-bold text-info">Tip: Build lists by prepending, then Enum.reverse/1</span>
            <pre class="mt-2 font-mono text-xs opacity-80"><%= "# Instead of appending in a loop:\nlist = Enum.reduce(1..1000, [], fn i, acc ->\n  [i | acc]   # O(1) prepend\nend) |> Enum.reverse()  # One O(n) pass at the end" %></pre>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("prepend", %{"value" => value}, socket) do
    value = String.trim(value)

    if value != "" do
      parsed = parse_item(value)
      new_items = [parsed | socket.assigns.items]
      log_entry = "[#{inspect(parsed)} | list] => #{inspect(new_items)}"

      {:noreply,
       socket
       |> assign(items: new_items)
       |> assign(new_item: "")
       |> assign(highlighted: nil)
       |> add_log(log_entry)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("append", %{"value" => value}, socket) do
    value = String.trim(value)

    if value != "" do
      parsed = parse_item(value)
      new_items = socket.assigns.items ++ [parsed]
      log_entry = "list ++ [#{inspect(parsed)}] => #{inspect(new_items)}"

      {:noreply,
       socket
       |> assign(items: new_items)
       |> assign(highlighted: nil)
       |> add_log(log_entry)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("highlight", %{"part" => part}, socket) do
    highlighted =
      case part do
        "head" -> :head
        "tail" -> :tail
        _ -> nil
      end

    {:noreply, assign(socket, highlighted: highlighted)}
  end

  def handle_event("concat", %{"value" => value}, socket) do
    items_to_add = parse_csv(value)

    if items_to_add != [] do
      new_items = socket.assigns.items ++ items_to_add
      log_entry = "#{inspect(socket.assigns.items)} ++ #{inspect(items_to_add)} => #{inspect(new_items)}"

      {:noreply,
       socket
       |> assign(items: new_items)
       |> assign(concat_input: "")
       |> assign(highlighted: nil)
       |> add_log(log_entry)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("subtract", %{"value" => value}, socket) do
    items_to_remove = parse_csv(value)

    if items_to_remove != [] do
      new_items = socket.assigns.items -- items_to_remove
      log_entry = "#{inspect(socket.assigns.items)} -- #{inspect(items_to_remove)} => #{inspect(new_items)}"

      {:noreply,
       socket
       |> assign(items: new_items)
       |> assign(subtract_input: "")
       |> assign(highlighted: nil)
       |> add_log(log_entry)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("clear_list", _params, socket) do
    {:noreply,
     socket
     |> assign(items: [])
     |> assign(highlighted: nil)
     |> add_log("Cleared list => []")}
  end

  def handle_event("reset_list", _params, socket) do
    {:noreply,
     socket
     |> assign(items: [1, 2, 3, 4, 5])
     |> assign(highlighted: nil)
     |> assign(new_item: "")
     |> assign(remove_item: "")
     |> assign(concat_input: "")
     |> assign(subtract_input: "")
     |> add_log("Reset list => [1, 2, 3, 4, 5]")}
  end

  # Helpers

  defp add_log(socket, entry) do
    logs = [entry | socket.assigns.operation_log] |> Enum.take(20)
    assign(socket, operation_log: logs)
  end

  defp parse_item(str) do
    case Integer.parse(str) do
      {n, ""} -> n
      _ ->
        case Float.parse(str) do
          {f, ""} -> f
          _ -> str
        end
    end
  end

  defp parse_csv(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_item/1)
  end
end
