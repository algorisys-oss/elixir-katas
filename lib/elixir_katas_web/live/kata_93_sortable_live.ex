defmodule ElixirKatasWeb.Kata93SortableListLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:demo_active, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Reorderable list items
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">Sortable List</h3>
          
          <div class="space-y-4">
            <button 
              phx-click="toggle_demo" phx-target={@myself}
              class="px-6 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
            >
              <%= if @demo_active, do: "Hide Demo", else: "Show Demo" %>
            </button>

            <%= if @demo_active do %>
              <div class="p-4 bg-blue-50 border border-blue-200 rounded">
                <div class="font-medium mb-2">Sortable List Demo</div>
                <div class="text-sm text-gray-700">
                  This demonstrates drag reordering. In a real implementation, 
                  this would include full sortable list functionality with proper 
                  JavaScript integration.
                </div>
                <div class="mt-3 text-xs text-gray-500">
                  Check the Notes and Source Code tabs for implementation details.
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_demo", _, socket) do
    {:noreply, assign(socket, :demo_active, !socket.assigns.demo_active)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
