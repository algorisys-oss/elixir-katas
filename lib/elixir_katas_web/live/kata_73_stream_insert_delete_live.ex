defmodule ElixirKatasWeb.Kata73StreamInsertDeleteLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    items = for i <- 1..5, do: %{id: i, name: "Item #{i}", status: "active"}

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:next_id, 6)
      |> stream(:items, items)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Real-time stream updates - add and remove items efficiently.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex gap-2 mb-4">
            <button phx-click="add_top" phx-target={@myself} class="px-4 py-2 bg-green-600 text-white rounded">
              Add to Top
            </button>
            <button phx-click="add_bottom" phx-target={@myself} class="px-4 py-2 bg-blue-600 text-white rounded">
              Add to Bottom
            </button>
          </div>

          <div id="items" phx-update="stream" class="space-y-2">
            <%= for {dom_id, item} <- @streams.items do %>
              <div id={dom_id} class="flex items-center justify-between p-3 bg-gray-50 rounded">
                <span><%= item.name %> (ID: <%= item.id %>)</span>
                <button phx-click="delete" phx-target={@myself} phx-value-id={item.id} class="px-3 py-1 bg-red-500 text-white rounded text-sm">
                  Delete
                </button>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("add_top", _, socket) do
    id = socket.assigns.next_id
    item = %{id: id, name: "Item #{id}", status: "active"}
    
    {:noreply,
     socket
     |> stream_insert(:items, item, at: 0)
     |> assign(:next_id, id + 1)}
  end

  def handle_event("add_bottom", _, socket) do
    id = socket.assigns.next_id
    item = %{id: id, name: "Item #{id}", status: "active"}
    
    {:noreply,
     socket
     |> stream_insert(:items, item, at: -1)
     |> assign(:next_id, id + 1)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, stream_delete_by_dom_id(socket, :items, "items-#{id}")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
