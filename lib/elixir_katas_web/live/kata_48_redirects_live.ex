defmodule ElixirKatasWeb.Kata48RedirectsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    
    params = assigns[:params] || %{}
    page = params["page"]
    page_int = if page, do: String.to_integer(page), else: 1
    
    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:page, page_int)
      |> assign(:patch_count, 0)
      |> assign(:navigate_count, 0)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Compare <code>push_patch</code> (stays in same LiveView) vs <code>push_navigate</code> (remounts).
        </div>

        <div class="grid grid-cols-2 gap-6">
          <!-- push_patch Demo -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <h3 class="text-lg font-medium mb-2">push_patch</h3>
            <p class="text-sm text-gray-600 mb-4">
              Fast, no remount. Triggers handle_params/3.
            </p>
            
            <div class="space-y-3">
              <div class="p-3 bg-gray-50 rounded">
                <div class="text-xs text-gray-500">Current Page</div>
                <div class="text-2xl font-bold text-indigo-600"><%= @page %></div>
              </div>
              
              <div class="flex gap-2">
                <button
                  phx-click="patch_prev" phx-target={@myself}
                  disabled={@page == 1}
                  class="flex-1 px-3 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-sm"
                >
                  ← Prev
                </button>
                <button
                  phx-click="patch_next" phx-target={@myself}
                  class="flex-1 px-3 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 text-sm"
                >
                  Next →
                </button>
              </div>
              
              <div class="text-xs text-gray-500 text-center">
                Patch count: <%= @patch_count %>
              </div>
            </div>
          </div>

          <!-- push_navigate Demo -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <h3 class="text-lg font-medium mb-2">push_navigate</h3>
            <p class="text-sm text-gray-600 mb-4">
              Full remount. Use for different LiveViews.
            </p>
            
            <div class="space-y-3">
              <div class="p-3 bg-yellow-50 border border-yellow-200 rounded">
                <p class="text-xs text-yellow-800">
                  In this demo, we'll navigate to other katas to show the difference.
                </p>
              </div>
              
              <button
                phx-click="navigate_home" phx-target={@myself}
                class="w-full px-3 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 text-sm"
              >
                Navigate to Home
              </button>
              
              <button
                phx-click="navigate_kata1" phx-target={@myself}
                class="w-full px-3 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 text-sm"
              >
                Navigate to Kata 1
              </button>
              
              <div class="text-xs text-gray-500 text-center">
                Navigate count: <%= @navigate_count %>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 p-4 bg-blue-50 border border-blue-200 rounded">
          <h4 class="text-sm font-medium text-blue-900 mb-2">Key Differences</h4>
          <ul class="text-sm text-blue-800 space-y-1">
            <li>• <strong>push_patch</strong>: Same LiveView, fast, preserves state</li>
            <li>• <strong>push_navigate</strong>: Different LiveView, full remount</li>
          </ul>
        </div>
      </div>
    
    """
  end

  def handle_event("patch_prev", _params, socket) do
    new_page = max(1, socket.assigns.page - 1)
    {:noreply, 
     socket
     |> update(:patch_count, &(&1 + 1))
     |> push_patch(to: ~p"/liveview-katas/48-redirects?page=#{new_page}")}
  end

  def handle_event("patch_next", _params, socket) do
    new_page = socket.assigns.page + 1
    {:noreply, 
     socket
     |> update(:patch_count, &(&1 + 1))
     |> push_patch(to: ~p"/liveview-katas/48-redirects?page=#{new_page}")}
  end

  def handle_event("navigate_home", _params, socket) do
    {:noreply, 
     socket
     |> update(:navigate_count, &(&1 + 1))
     |> push_navigate(to: ~p"/")}
  end

  def handle_event("navigate_kata1", _params, socket) do
    {:noreply, 
     socket
     |> update(:navigate_count, &(&1 + 1))
     |> push_navigate(to: ~p"/liveview-katas/01-hello-world")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
