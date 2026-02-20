defmodule ElixirKatasWeb.Kata57DropdownLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:show_dropdown, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Click the button to toggle the dropdown menu.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="relative inline-block">
            <button phx-click="toggle_dropdown" phx-target={@myself} class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700">
              Menu ▼
            </button>
            <%= if @show_dropdown do %>
              <div class="absolute top-full left-0 mt-2 w-48 bg-white rounded shadow-lg border z-10">
                <a href="#" phx-click="close_dropdown" phx-target={@myself} class="block px-4 py-2 hover:bg-gray-50 text-gray-700">Option 1</a>
                <a href="#" phx-click="close_dropdown" phx-target={@myself} class="block px-4 py-2 hover:bg-gray-50 text-gray-700">Option 2</a>
                <a href="#" phx-click="close_dropdown" phx-target={@myself} class="block px-4 py-2 hover:bg-gray-50 text-gray-700">Option 3</a>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_dropdown", _, socket) do
    {:noreply, assign(socket, show_dropdown: !socket.assigns.show_dropdown)}
  end

  def handle_event("close_dropdown", _, socket) do
    {:noreply, assign(socket, show_dropdown: false)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
