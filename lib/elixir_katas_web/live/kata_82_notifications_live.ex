defmodule ElixirKatasWeb.Kata82DistributedNotificationsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:notifications, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Trigger notifications that could be broadcast across nodes.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border space-y-4">
          <div class="flex gap-2">
            <button 
              phx-click="send_notification" phx-target={@myself} 
              phx-value-type="info"
              class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Info Notification
            </button>
            <button 
              phx-click="send_notification" phx-target={@myself} 
              phx-value-type="success"
              class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
            >
              Success Notification
            </button>
            <button 
              phx-click="send_notification" phx-target={@myself} 
              phx-value-type="warning"
              class="px-4 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700"
            >
              Warning Notification
            </button>
            <button 
              phx-click="send_notification" phx-target={@myself} 
              phx-value-type="error"
              class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
            >
              Error Notification
            </button>
          </div>

          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <h3 class="font-medium">Notifications</h3>
              <%= if length(@notifications) > 0 do %>
                <button 
                  phx-click="clear_all" phx-target={@myself}
                  class="text-sm text-gray-500 hover:text-gray-700"
                >
                  Clear All
                </button>
              <% end %>
            </div>

            <%= if Enum.empty?(@notifications) do %>
              <div class="text-center py-8 text-gray-400">
                No notifications yet. Click a button above to trigger one.
              </div>
            <% else %>
              <div class="space-y-2">
                <%= for {notif, idx} <- Enum.with_index(@notifications) do %>
                  <div class={"p-3 rounded-lg flex justify-between items-start " <>
                              case notif.type do
                                "info" -> "bg-blue-50 border border-blue-200"
                                "success" -> "bg-green-50 border border-green-200"
                                "warning" -> "bg-yellow-50 border border-yellow-200"
                                "error" -> "bg-red-50 border border-red-200"
                              end}>
                    <div class="flex-1">
                      <div class="font-medium capitalize"><%= notif.type %></div>
                      <div class="text-sm text-gray-600"><%= notif.message %></div>
                      <div class="text-xs text-gray-400 mt-1"><%= notif.time %></div>
                    </div>
                    <button 
                      phx-click="dismiss" phx-target={@myself} 
                      phx-value-idx={idx}
                      class="text-gray-400 hover:text-gray-600"
                    >
                      ✕
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("send_notification", %{"type" => type}, socket) do
    message = case type do
      "info" -> "This is an informational message"
      "success" -> "Operation completed successfully!"
      "warning" -> "Please review this warning"
      "error" -> "An error occurred"
    end

    notification = %{
      type: type,
      message: message,
      time: Calendar.strftime(DateTime.utc_now(), "%H:%M:%S")
    }

    {:noreply, assign(socket, :notifications, [notification | socket.assigns.notifications])}
  end

  def handle_event("dismiss", %{"idx" => idx}, socket) do
    idx = String.to_integer(idx)
    notifications = List.delete_at(socket.assigns.notifications, idx)
    {:noreply, assign(socket, :notifications, notifications)}
  end

  def handle_event("clear_all", _, socket) do
    {:noreply, assign(socket, :notifications, [])}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
