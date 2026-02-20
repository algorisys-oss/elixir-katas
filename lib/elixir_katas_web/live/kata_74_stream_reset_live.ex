defmodule ElixirKatasWeb.Kata74StreamResetLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:filter, "all")
      |> load_items("all")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Reset streams to clear and repopulate with filtered data.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex gap-2 mb-4">
            <button phx-click="filter" phx-target={@myself} phx-value-type="all" 
                    class={"px-4 py-2 rounded " <> if @filter == "all", do: "bg-indigo-600 text-white", else: "bg-gray-200"}>
              All
            </button>
            <button phx-click="filter" phx-target={@myself} phx-value-type="active" 
                    class={"px-4 py-2 rounded " <> if @filter == "active", do: "bg-green-600 text-white", else: "bg-gray-200"}>
              Active
            </button>
            <button phx-click="filter" phx-target={@myself} phx-value-type="completed" 
                    class={"px-4 py-2 rounded " <> if @filter == "completed", do: "bg-blue-600 text-white", else: "bg-gray-200"}>
              Completed
            </button>
          </div>

          <div id="items" phx-update="stream" class="space-y-2">
            <%= for {dom_id, item} <- @streams.items do %>
              <div id={dom_id} class="p-3 bg-gray-50 rounded flex justify-between items-center">
                <span><%= item.name %></span>
                <span class={"px-2 py-1 rounded text-xs " <> 
                            if item.status == "active", do: "bg-green-100 text-green-800", else: "bg-blue-100 text-blue-800"}>
                  <%= item.status %>
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("filter", %{"type" => filter}, socket) do
    {:noreply, load_items(socket, filter)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp load_items(socket, filter) do
    all_items = [
      %{id: 1, name: "Task 1", status: "active"},
      %{id: 2, name: "Task 2", status: "completed"},
      %{id: 3, name: "Task 3", status: "active"},
      %{id: 4, name: "Task 4", status: "completed"},
      %{id: 5, name: "Task 5", status: "active"},
    ]
    
    items = case filter do
      "all" -> all_items
      "active" -> Enum.filter(all_items, &(&1.status == "active"))
      "completed" -> Enum.filter(all_items, &(&1.status == "completed"))
    end
    
    socket
    |> stream(:items, items, reset: true)
    |> assign(:filter, filter)
  end
end
