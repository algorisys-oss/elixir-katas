defmodule ElixirKatasWeb.Kata54ModalLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:show_modal, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Modal dialog with show/hide functionality.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <button
            phx-click="toggle_modal" phx-target={@myself}
            class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
          >
            Open Modal
          </button>

          <%= if @show_modal do %>
            <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" phx-click="toggle_modal" phx-target={@myself}>
              <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4" phx-click="prevent_close" phx-target={@myself}>
                <h3 class="text-lg font-bold mb-4">Modal Title</h3>
                <p class="text-gray-600 mb-6">
                  This is a modal dialog. Click outside or press the close button to dismiss.
                </p>
                <div class="flex justify-end gap-2">
                  <button
                    phx-click="toggle_modal" phx-target={@myself}
                    class="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
                  >
                    Cancel
                  </button>
                  <button
                    phx-click="toggle_modal" phx-target={@myself}
                    class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
                  >
                    Confirm
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_modal", _, socket) do
    {:noreply, assign(socket, show_modal: !socket.assigns.show_modal)}
  end

  def handle_event("prevent_close", _, socket) do
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
