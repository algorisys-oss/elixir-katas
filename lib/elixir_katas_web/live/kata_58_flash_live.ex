defmodule ElixirKatasWeb.Kata58FlashLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:show_flash, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Interactive flash demonstration.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">

          <button phx-click="show_message" phx-target={@myself} class="px-4 py-2 bg-indigo-600 text-white rounded">
            Show Flash Message
          </button>
          <%= if @show_flash do %>
            <div class="mt-4 p-4 bg-green-50 border border-green-200 rounded flex justify-between">
              <span class="text-green-800">Success! Your action was completed.</span>
              <button phx-click="hide_flash" phx-target={@myself} class="text-green-600">×</button>
            </div>
          <% end %>
    
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_flash", _, socket) do
    {:noreply, assign(socket, show_flash: !socket.assigns.show_flash)}
  end

  def handle_event("show_message", _, socket) do
    {:noreply, assign(socket, show_flash: true)}
  end

  def handle_event("hide_flash", _, socket) do
    {:noreply, assign(socket, show_flash: false)}
  end

  def handle_event("prevent_close", _, socket) do
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
