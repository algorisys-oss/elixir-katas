defmodule ElixirKatasWeb.Kata59SkeletonLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:loading, true)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Loading state placeholders.
        </div>

        <div class="space-y-6">
          <button
            phx-click="toggle_loading" phx-target={@myself}
            class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
          >
            Toggle Loading
          </button>

          <%= if @loading do %>
            <div class="bg-white p-6 rounded-lg shadow-sm border space-y-4 animate-pulse">
              <div class="h-4 bg-gray-200 rounded w-3/4"></div>
              <div class="h-4 bg-gray-200 rounded w-1/2"></div>
              <div class="h-32 bg-gray-200 rounded"></div>
              <div class="flex gap-2">
                <div class="h-8 bg-gray-200 rounded w-20"></div>
                <div class="h-8 bg-gray-200 rounded w-20"></div>
              </div>
            </div>
          <% else %>
            <div class="bg-white p-6 rounded-lg shadow-sm border space-y-4">
              <h3 class="text-lg font-bold">Content Loaded!</h3>
              <p class="text-gray-600">This is the actual content that appears after loading.</p>
              <div class="h-32 bg-gradient-to-r from-indigo-500 to-purple-500 rounded flex items-center justify-center text-white">
                Image Placeholder
              </div>
              <div class="flex gap-2">
                <button class="px-4 py-2 bg-indigo-600 text-white rounded">Action 1</button>
                <button class="px-4 py-2 bg-gray-200 rounded">Action 2</button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_loading", _, socket) do
    {:noreply, assign(socket, loading: !socket.assigns.loading)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
