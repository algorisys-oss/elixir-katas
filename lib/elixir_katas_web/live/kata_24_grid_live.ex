defmodule ElixirKatasWeb.Kata24GridLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Simulating a dataset
    data = [
      %{id: 1, name: "Alice", role: "Admin", status: "Active"},
      %{id: 2, name: "Bob", role: "Editor", status: "Inactive"},
      %{id: 3, name: "Charlie", role: "Viewer", status: "Active"},
      %{id: 4, name: "Dave", role: "Admin", status: "Active"},
      %{id: 5, name: "Eve", role: "Viewer", status: "Inactive"}
    ]

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:data, data)
      |> assign(:grid_cols, 3) # Controls how many columns in grid view

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Rendering data in a responsive grid layout
        </div>

        <div class="flex flex-col gap-6">
          
          <!-- Controls -->
          <div class="flex items-center gap-4">
            <label class="text-sm font-medium text-gray-700">Grid Columns:</label>
            <div class="flex gap-2">
              <button phx-click="set_cols" phx-target={@myself} phx-value-cols="1" class={"px-3 py-1 rounded border " <> if(@grid_cols == 1, do: "bg-blue-500 text-white", else: "bg-white")}>1</button>
              <button phx-click="set_cols" phx-target={@myself} phx-value-cols="2" class={"px-3 py-1 rounded border " <> if(@grid_cols == 2, do: "bg-blue-500 text-white", else: "bg-white")}>2</button>
              <button phx-click="set_cols" phx-target={@myself} phx-value-cols="3" class={"px-3 py-1 rounded border " <> if(@grid_cols == 3, do: "bg-blue-500 text-white", else: "bg-white")}>3</button>
              <button phx-click="set_cols" phx-target={@myself} phx-value-cols="4" class={"px-3 py-1 rounded border " <> if(@grid_cols == 4, do: "bg-blue-500 text-white", else: "bg-white")}>4</button>
            </div>
          </div>

          <!-- Metric: CSS Grid -->
          <div 
            class="grid gap-4 transition-all duration-300 ease-in-out"
            style={"grid-template-columns: repeat(#{@grid_cols}, minmax(0, 1fr));"}
          >
            <%= for user <- @data do %>
              <div class="bg-white border rounded-lg shadow-sm p-4 hover:shadow-md transition-shadow">
                <div class="flex items-center justify-between mb-2">
                  <h3 class="font-bold text-lg"><%= user.name %></h3>
                  <span class={"px-2 py-0.5 rounded text-xs font-semibold " <> status_color(user.status)}>
                    <%= user.status %>
                  </span>
                </div>
                <p class="text-sm text-gray-600">Role: <%= user.role %></p>
                <div class="mt-4 flex gap-2">
                   <button class="text-xs bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded">Edit</button>
                   <button class="text-xs bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded">Delete</button>
                </div>
              </div>
            <% end %>
          </div>

        </div>

         <div class="mt-12 bg-gray-50 p-4 rounded-lg border text-sm text-gray-600">
          <h3 class="font-bold mb-2">How it works:</h3>
          <p>
            We use CSS Grid with an inline style to strictly control the number of columns based on the <code>@grid_cols</code> assign.
            <code>grid-template-columns: repeat(@grid_cols, minmax(0, 1fr))</code> makes it responsive and explicit.
          </p>
        </div>
      </div>
    
    """
  end

  def handle_event("set_cols", %{"cols" => cols}, socket) do
    cols = String.to_integer(cols)
    {:noreply, assign(socket, :grid_cols, cols)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp status_color("Active"), do: "bg-green-100 text-green-700"
  defp status_color("Inactive"), do: "bg-gray-100 text-gray-500"
end
