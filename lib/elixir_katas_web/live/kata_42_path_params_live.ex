defmodule ElixirKatasWeb.Kata42PathParamsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    items = [
      %{id: 1, name: "Phoenix Framework", description: "Web framework for Elixir"},
      %{id: 2, name: "LiveView", description: "Real-time server-rendered apps"},
      %{id: 3, name: "Ecto", description: "Database wrapper and query generator"},
      %{id: 4, name: "Plug", description: "Composable web middleware"}
    ]
    
    params = assigns[:params] || %{}
    id = params["id"]
    
    selected_item = 
       if id do
         Enum.find(items, &(Integer.to_string(&1.id) == id))
       else
         nil
       end

    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:items, items)
      |> assign(:selected_item, selected_item)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Click an item below. Notice the URL changes to <code>/katas/42-path-params/:id</code>
        </div>

        <div class="grid grid-cols-2 gap-6">
          <!-- Items List -->
          <div class="bg-white p-4 rounded-lg shadow-sm border">
            <h3 class="text-sm font-medium text-gray-900 mb-3">Items</h3>
            <div class="space-y-2">
              <%= for item <- @items do %>
                <.link
                  patch={~p"/katas/42-path-params/#{item.id}"}
                  class={"block p-3 rounded transition-colors " <> 
                         if(@selected_item && @selected_item.id == item.id, 
                            do: "bg-indigo-50 border-2 border-indigo-500", 
                            else: "bg-gray-50 hover:bg-gray-100 border-2 border-transparent")}
                >
                  <div class="font-medium text-sm"><%= item.name %></div>
                  <div class="text-xs text-gray-500">ID: <%= item.id %></div>
                </.link>
              <% end %>
            </div>
          </div>

          <!-- Selected Item Detail -->
          <div class="bg-white p-4 rounded-lg shadow-sm border">
            <h3 class="text-sm font-medium text-gray-900 mb-3">Details</h3>
            <%= if @selected_item do %>
              <div class="space-y-3">
                <div>
                  <label class="text-xs text-gray-500">ID</label>
                  <div class="font-mono text-sm"><%= @selected_item.id %></div>
                </div>
                <div>
                  <label class="text-xs text-gray-500">Name</label>
                  <div class="font-medium"><%= @selected_item.name %></div>
                </div>
                <div>
                  <label class="text-xs text-gray-500">Description</label>
                  <div class="text-sm text-gray-700"><%= @selected_item.description %></div>
                </div>
                <div class="pt-3 border-t">
                  <label class="text-xs text-gray-500">Current URL</label>
                  <div class="font-mono text-xs text-indigo-600">
                    /katas/42-path-params/<%= @selected_item.id %>
                  </div>
                </div>
              </div>
            <% else %>
              <div class="text-sm text-gray-400 italic text-center py-8">
                Select an item to view details
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
