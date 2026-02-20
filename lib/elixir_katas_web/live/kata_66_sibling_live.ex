defmodule ElixirKatasWeb.Kata66SiblingLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:sibling_data, "")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Demonstrating sibling components communicating via parent coordinator.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="grid grid-cols-2 gap-4">
            <div class="p-4 bg-green-50 border border-green-200 rounded">
              <div class="text-sm font-medium mb-3">Sibling A</div>
              <button phx-click="sibling_a_send" phx-target={@myself} class="px-4 py-2 bg-green-600 text-white rounded text-sm hover:bg-green-700">
                Send to Sibling B
              </button>
            </div>
            <div class="p-4 bg-purple-50 border border-purple-200 rounded">
              <div class="text-sm font-medium mb-3">Sibling B</div>
              <div class="text-sm">
                <%= if @sibling_data == "" do %>
                  <span class="text-gray-500 italic">Waiting for message...</span>
                <% else %>
                  <span class="text-purple-700 font-medium">Received: <%= @sibling_data %> 📨</span>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("sibling_a_send", _, socket) do
    {:noreply, assign(socket, :sibling_data, "Data from Sibling A")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
