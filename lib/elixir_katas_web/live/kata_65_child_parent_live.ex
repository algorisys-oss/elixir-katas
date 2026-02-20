defmodule ElixirKatasWeb.Kata65ChildParentLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:child_message, "")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Demonstrating child component sending messages to parent.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="space-y-4">
            <div class="p-4 bg-blue-50 border border-blue-200 rounded">
              <div class="text-sm font-medium mb-2">Child Component</div>
              <button phx-click="send_to_parent" phx-target={@myself} class="px-4 py-2 bg-blue-600 text-white rounded text-sm hover:bg-blue-700">
                Send Message to Parent
              </button>
            </div>
            <div class="p-4 bg-gray-50 rounded">
              <div class="text-sm text-gray-500 mb-1">Parent received:</div>
              <div class="font-medium text-lg">
                <%= if @child_message == "", do: "(no message yet)", else: @child_message %>
              </div>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("send_to_parent", _, socket) do
    {:noreply, assign(socket, :child_message, "Hello from child! 👋")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
