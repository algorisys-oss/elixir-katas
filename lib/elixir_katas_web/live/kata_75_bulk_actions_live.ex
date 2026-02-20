defmodule ElixirKatasWeb.Kata75BulkActionsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    items = for i <- 1..10, do: %{id: i, name: "Item #{i}", selected: false}

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:selected_ids, MapSet.new())
      |> stream(:items, items)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Select multiple items and perform bulk operations.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex gap-2 mb-4">
            <button phx-click="select_all" phx-target={@myself} class="px-4 py-2 bg-indigo-600 text-white rounded">
              Select All
            </button>
            <button phx-click="deselect_all" phx-target={@myself} class="px-4 py-2 bg-gray-600 text-white rounded">
              Deselect All
            </button>
            <button phx-click="delete_selected" phx-target={@myself} disabled={MapSet.size(@selected_ids) == 0}
                    class="px-4 py-2 bg-red-600 text-white rounded disabled:opacity-50">
              Delete Selected (<%= MapSet.size(@selected_ids) %>)
            </button>
          </div>

          <div id="items" phx-update="stream" class="space-y-2">
            <%= for {dom_id, item} <- @streams.items do %>
              <div id={dom_id} class={"p-3 rounded flex items-center gap-3 " <> 
                                      if MapSet.member?(@selected_ids, item.id), do: "bg-indigo-50 border-2 border-indigo-500", else: "bg-gray-50"}>
                <input type="checkbox" 
                       checked={MapSet.member?(@selected_ids, item.id)}
                       phx-click="toggle_select" phx-target={@myself} 
                       phx-value-id={item.id}
                       class="w-4 h-4" />
                <span class="flex-1"><%= item.name %></span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_select", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected_ids = if MapSet.member?(socket.assigns.selected_ids, id) do
      MapSet.delete(socket.assigns.selected_ids, id)
    else
      MapSet.put(socket.assigns.selected_ids, id)
    end
    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  def handle_event("select_all", _, socket) do
    # Get all item IDs from the stream
    all_ids = socket.assigns.streams.items
    |> Enum.map(fn {_, item} -> item.id end)
    |> MapSet.new()
    
    {:noreply, assign(socket, :selected_ids, all_ids)}
  end

  def handle_event("deselect_all", _, socket) do
    {:noreply, assign(socket, :selected_ids, MapSet.new())}
  end

  def handle_event("delete_selected", _, socket) do
    socket = Enum.reduce(socket.assigns.selected_ids, socket, fn id, acc ->
      stream_delete_by_dom_id(acc, :items, "items-#{id}")
    end)
    
    {:noreply, assign(socket, :selected_ids, MapSet.new())}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
