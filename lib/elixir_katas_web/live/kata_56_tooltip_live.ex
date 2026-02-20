defmodule ElixirKatasWeb.Kata56TooltipLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Interactive tooltip demonstration.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">

          <div class="space-y-4">
            <!-- Added 'group' class for hover state targeting -->
            <div class="relative inline-block group">
              <button class="px-4 py-2 bg-indigo-600 text-white rounded">
                Hover me
              </button>
              
              <!-- CSS-only tooltip: invisible by default, visible on group-hover -->
              <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-900 text-white text-sm rounded whitespace-nowrap invisible opacity-0 group-hover:visible group-hover:opacity-100 transition-all duration-200">
                This is a tooltip!
                <!-- Little arrow -->
                <div class="absolute top-full left-1/2 transform -translate-x-1/2 border-4 border-transparent border-t-gray-900"></div>
              </div>
            </div>
          </div>
    
        </div>
      </div>
    
    """
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
