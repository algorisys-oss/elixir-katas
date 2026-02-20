defmodule ElixirKatasWeb.Kata95AsyncAssignsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> load_async_data()

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Loading data asynchronously with loading states and error handling
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex justify-between items-center mb-6">
            <h3 class="text-lg font-medium">Async Dashboard</h3>
            <button 
              phx-click="reload" phx-target={@myself} 
              class="px-4 py-2 bg-indigo-600 text-white text-sm rounded hover:bg-indigo-700 transition"
            >
              Reload Data
            </button>
          </div>
          
          <div class="grid gap-6">
            <!-- Stats Card (Loads Quickly) -->
            <.async_result :let={stats} assign={@stats}>
              <:loading>
                <div class="animate-pulse bg-gray-100 p-4 rounded-lg h-24"></div>
              </:loading>
              <:failed :let={_failure}>
                 <div class="bg-red-50 p-4 rounded-lg text-red-600 text-sm">
                   Failed to load stats
                 </div>
              </:failed>
              <div class="bg-indigo-50 p-4 rounded-lg border border-indigo-100">
                <div class="text-sm text-indigo-600 font-medium">Total Revenue</div>
                <div class="text-2xl font-bold text-indigo-900"><%= stats.revenue %></div>
                <div class="text-xs text-indigo-500 mt-1">+<%= stats.growth %>% from last month</div>
              </div>
            </.async_result>

            <!-- Users List (Loads Slowly) -->
             <.async_result :let={users} assign={@users}>
              <:loading>
                <div class="space-y-3">
                   <div class="animate-pulse bg-gray-100 h-10 rounded w-full"></div>
                   <div class="animate-pulse bg-gray-100 h-10 rounded w-full"></div>
                   <div class="animate-pulse bg-gray-100 h-10 rounded w-full"></div>
                </div>
              </:loading>
              <:failed :let={_failure}>
                 <div class="bg-red-50 p-4 rounded-lg text-red-600 text-sm flex items-center justify-between">
                   <span>Failed to load user data.</span>
                   <button phx-click="reload" phx-target={@myself} class="text-red-800 underline">Retry</button>
                 </div>
              </:failed>
              
              <div class="border rounded-lg overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for user <- users do %>
                      <tr>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900"><%= user.name %></td>
                        <td class="px-6 py-4 text-sm">
                          <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                            <%= user.status %>
                          </span>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </.async_result>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("reload", _, socket) do
    {:noreply, load_async_data(socket)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp load_async_data(socket) do
    socket
    |> assign_async(:stats, fn -> 
      Process.sleep(500) # Fast load
      {:ok, %{stats: %{revenue: "$124,500", growth: 12}}} 
    end)
    |> assign_async(:users, fn ->
      Process.sleep(2000) # Slow load
      {:ok, %{users: [
        %{name: "John Doe", status: "Active"},
        %{name: "Jane Smith", status: "Active"},
        %{name: "Bob Johnson", status: "Away"}
      ]}}
    end)
  end
end
