defmodule ElixirKatasWeb.Kata47ProtectedLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:authenticated, false)
      |> assign(:current_view, "login")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Simulated protected route. Toggle authentication to access protected content.
        </div>

        <%= if @authenticated do %>
          <!-- Protected Content -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium">Protected Dashboard</h3>
              <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded">
                Authenticated
              </span>
            </div>
            
            <p class="text-gray-600 mb-4">
              This is protected content only visible to authenticated users.
            </p>
            
            <div class="space-y-3">
              <div class="p-3 bg-gray-50 rounded">
                <div class="text-sm font-medium">User Profile</div>
                <div class="text-xs text-gray-500">Manage your account settings</div>
              </div>
              <div class="p-3 bg-gray-50 rounded">
                <div class="text-sm font-medium">Private Data</div>
                <div class="text-xs text-gray-500">View your sensitive information</div>
              </div>
            </div>
            
            <button
              phx-click="logout" phx-target={@myself}
              class="mt-4 w-full px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
            >
              Logout
            </button>
          </div>
        <% else %>
          <!-- Login Screen -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium">Login Required</h3>
              <span class="px-2 py-1 bg-red-100 text-red-800 text-xs rounded">
                Not Authenticated
              </span>
            </div>
            
            <p class="text-gray-600 mb-4">
              You need to login to access protected content.
            </p>
            
            <div class="p-4 bg-yellow-50 border border-yellow-200 rounded mb-4">
              <p class="text-sm text-yellow-800">
                <strong>Note:</strong> In a real app, `on_mount` would check session/cookies and redirect to login page.
              </p>
            </div>
            
            <button
              phx-click="login" phx-target={@myself}
              class="w-full px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
            >
              Simulate Login
            </button>
          </div>
        <% end %>
      </div>
    
    """
  end

  def handle_event("login", _params, socket) do
    {:noreply, assign(socket, authenticated: true)}
  end

  def handle_event("logout", _params, socket) do
    {:noreply, assign(socket, authenticated: false)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
