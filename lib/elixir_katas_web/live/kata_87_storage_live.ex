defmodule ElixirKatasWeb.Kata87LocalStorageLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:stored_data, %{})
      |> assign(:key, "")
      |> assign(:value, "")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">Browser local storage simulation for data persistence.</div>
        <div class="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">Key</label>
              <input type="text" phx-change="update_key" phx-target={@myself} name="key" value={@key} placeholder="Enter key" class="w-full px-4 py-2 border rounded"/>
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Value</label>
              <input type="text" phx-change="update_value" phx-target={@myself} name="value" value={@value} placeholder="Enter value" class="w-full px-4 py-2 border rounded"/>
            </div>
          </div>
          <div class="flex gap-2">
            <button phx-click="save" phx-target={@myself} class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">Save to Storage</button>
            <button phx-click="clear" phx-target={@myself} class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700">Clear All</button>
          </div>
          <div class="border-t pt-4">
            <h3 class="font-medium mb-2">Stored Data:</h3>
            <%= if map_size(@stored_data) == 0 do %>
              <div class="text-sm text-gray-400">No data stored yet</div>
            <% else %>
              <div class="space-y-2">
                <%= for {k, v} <- @stored_data do %>
                  <div class="flex justify-between items-center p-2 bg-gray-50 rounded">
                    <div class="font-mono text-sm"><span class="text-gray-600"><%= k %>:</span> <%= v %></div>
                    <button phx-click="remove" phx-target={@myself} phx-value-key={k} class="text-red-600 hover:text-red-800 text-sm">Remove</button>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("update_key", %{"key" => key}, socket), do: {:noreply, assign(socket, :key, key)}
  def handle_event("update_value", %{"value" => value}, socket), do: {:noreply, assign(socket, :value, value)}
  
  def handle_event("save", _, socket) do
    if socket.assigns.key != "" and socket.assigns.value != "" do
      {:noreply, socket |> update(:stored_data, &Map.put(&1, socket.assigns.key, socket.assigns.value)) |> assign(key: "", value: "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove", %{"key" => key}, socket) do
    {:noreply, update(socket, :stored_data, &Map.delete(&1, key))}
  end

  def handle_event("clear", _, socket), do: {:noreply, assign(socket, :stored_data, %{})}
  def handle_event("set_tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, active_tab: tab)}
end
