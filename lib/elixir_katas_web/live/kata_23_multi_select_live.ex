defmodule ElixirKatasWeb.Kata23MultiSelectLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    items = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
    
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:items, items)
      |> assign(:selected, MapSet.new())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Selecting multiple items from a list
        </div>

        <div class="mt-6 flex flex-col gap-6">
          <!-- Selection Area -->
          <div class="space-y-2">
            <p class="text-sm font-medium text-gray-700">Available Fruits (Click to select)</p>
            <div class="flex flex-wrap gap-2">
              <%= for item <- @items do %>
                <button
                  phx-click="toggle" phx-target={@myself}
                  phx-value-item={item}
                  class={[
                    "px-3 py-1 rounded-full border text-sm font-medium transition-colors",
                    if(MapSet.member?(@selected, item), 
                      do: "bg-indigo-100 text-indigo-700 border-indigo-200 hover:bg-indigo-200", 
                      else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50")
                  ]}
                >
                  <%= item %>
                  <%= if MapSet.member?(@selected, item) do %>
                    <span class="ml-1 text-indigo-500">&times;</span>
                  <% end %>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Selected Items Summary -->
          <div class="p-4 bg-gray-50 border rounded-lg">
            <h3 class="text-sm font-bold text-gray-900 mb-2">Selected Items:</h3>
            <%= if MapSet.size(@selected) == 0 do %>
              <p class="text-gray-500 text-sm italic">None selected.</p>
            <% else %>
              <ul class="list-disc list-inside text-sm text-gray-800">
                <%= for item <- Enum.sort(MapSet.to_list(@selected)) do %>
                  <li><%= item %></li>
                <% end %>
              </ul>
            <% end %>
          </div>
          
          <!-- Action -->
          <div>
            <button phx-click="clear" phx-target={@myself} class="text-sm text-red-600 hover:underline">
              Clear Selection
            </button>
          </div>
        </div>

         <div class="mt-12 bg-gray-50 p-4 rounded-lg border text-sm text-gray-600">
          <h3 class="font-bold mb-2">How it works:</h3>
          <p>
            We use a <code>MapSet</code> to track selected items efficiently. 
            Clicking an toggles its presence in the set. 
            MapSets are great for unique collections where order doesn't matter (though we sort for display).
          </p>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle", %{"item" => item}, socket) do
    selected = socket.assigns.selected
    
    new_selected =
      if MapSet.member?(selected, item) do
        MapSet.delete(selected, item)
      else
        MapSet.put(selected, item)
      end

    {:noreply, assign(socket, :selected, new_selected)}
  end
  
  def handle_event("clear", _params, socket) do
     {:noreply, assign(socket, :selected, MapSet.new())}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
