defmodule ElixirKatasWeb.Kata71StreamsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Generate initial items
    items = for i <- 1..20, do: %{id: i, name: "Item #{i}", created_at: DateTime.utc_now()}

    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:next_id, 21)
      |> stream(:items, items)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Streams efficiently handle large lists by only sending diffs to the client.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex gap-2 mb-4">
            <button 
              phx-click="add_item" phx-target={@myself} 
              class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
            >
              Add Item
            </button>
            <button 
              phx-click="add_bulk" phx-target={@myself} 
              class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Add 10 Items
            </button>
          </div>

          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded text-sm">
            <strong>Stream Benefits:</strong> Only changes are sent to client, not the entire list. 
            Try adding many items - the UI stays fast!
          </div>

          <div id="items" phx-update="stream" class="space-y-2 max-h-96 overflow-y-auto">
            <%= for {dom_id, item} <- @streams.items do %>
              <div 
                id={dom_id} 
                class="flex items-center justify-between p-3 bg-gray-50 rounded hover:bg-gray-100"
              >
                <div>
                  <span class="font-medium"><%= item.name %></span>
                  <span class="text-xs text-gray-500 ml-2">ID: <%= item.id %></span>
                </div>
                <button 
                  phx-click="delete_item" phx-target={@myself} 
                  phx-value-id={item.id}
                  class="px-3 py-1 bg-red-500 text-white rounded text-sm hover:bg-red-600"
                >
                  Delete
                </button>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("add_item", _, socket) do
    id = socket.assigns.next_id
    item = %{id: id, name: "Item #{id}", created_at: DateTime.utc_now()}
    
    {:noreply, 
     socket
     |> stream_insert(:items, item)
     |> assign(:next_id, id + 1)}
  end

  def handle_event("add_bulk", _, socket) do
    start_id = socket.assigns.next_id
    items = for i <- start_id..(start_id + 9) do
      %{id: i, name: "Item #{i}", created_at: DateTime.utc_now()}
    end
    
    {:noreply,
     socket
     |> stream(:items, items)
     |> assign(:next_id, start_id + 10)}
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, stream_delete_by_dom_id(socket, :items, "items-#{id}")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
