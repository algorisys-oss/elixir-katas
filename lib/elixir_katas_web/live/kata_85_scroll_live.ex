defmodule ElixirKatasWeb.Kata85ScrollToBottomLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    messages = for i <- 1..5 do
      %{id: i, text: "Message #{i}", time: "12:0#{i}"}
    end

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:messages, messages)
      |> assign(:next_id, 6)
      |> assign(:auto_scroll, true)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Auto-scroll chat interface demonstration.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex justify-between items-center mb-4">
            <h3 class="font-medium">Chat Messages</h3>
            <label class="flex items-center gap-2 text-sm">
              <input 
                type="checkbox" 
                checked={@auto_scroll}
                phx-click="toggle_auto_scroll" phx-target={@myself}
                class="rounded"
              />
              Auto-scroll
            </label>
          </div>

          <div 
            id="message-container"
            class="h-64 overflow-y-auto border rounded p-4 space-y-2 bg-gray-50"
          >
            <%= for msg <- @messages do %>
              <div class="bg-white p-3 rounded shadow-sm">
                <div class="text-sm text-gray-600"><%= msg.text %></div>
                <div class="text-xs text-gray-400 mt-1"><%= msg.time %></div>
              </div>
            <% end %>
            <%= if @auto_scroll do %>
              <div id="scroll-anchor" phx-hook="ScrollToBottom"></div>
            <% end %>
          </div>

          <div class="mt-4 flex gap-2">
            <button 
              phx-click="add_message" phx-target={@myself}
              class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Add Message
            </button>
            <button 
              phx-click="scroll_to_bottom" phx-target={@myself}
              class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
            >
              Scroll to Bottom
            </button>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("add_message", _, socket) do
    id = socket.assigns.next_id
    new_message = %{
      id: id,
      text: "Message #{id}",
      time: Calendar.strftime(DateTime.utc_now(), "%H:%M")
    }

    {:noreply,
     socket
     |> assign(:messages, socket.assigns.messages ++ [new_message])
     |> assign(:next_id, id + 1)}
  end

  def handle_event("toggle_auto_scroll", _, socket) do
    {:noreply, assign(socket, :auto_scroll, !socket.assigns.auto_scroll)}
  end

  def handle_event("scroll_to_bottom", _, socket) do
    # In a real implementation, this would trigger a JS hook
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
