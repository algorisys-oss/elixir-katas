defmodule ElixirKatasWeb.Kata79TypingIndicatorLive do
  use ElixirKatasWeb, :live_component

  @topic "typing:demo"
  @typing_timeout 3000

  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:username] do
      {:ok, assign(socket, assigns)}
    else
      username = "User#{:rand.uniform(9999)}"

      if connected?(socket) do
        Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
      end

      socket =
        socket
        |> assign(assigns)
        |> assign(:typing_users, MapSet.new())
        |> assign(:message, "")
        |> assign(:username, username)
        |> assign(:timer_ref, nil)

      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Multi-user typing indicators with PubSub. Open in multiple tabs to test!
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="mb-4 text-sm text-gray-600">
            You are: <span class="font-medium text-indigo-600"><%= @username %></span>
          </div>
          
          <div class="mb-4 h-20 flex items-center">
            <%= if MapSet.size(@typing_users) > 0 do %>
              <div class="flex items-center gap-2 text-gray-500">
                <div class="flex gap-1">
                  <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0ms"></span>
                  <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 150ms"></span>
                  <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 300ms"></span>
                </div>
                <span class="text-sm">
                  <%= typing_text(@typing_users) %>
                </span>
              </div>
            <% else %>
              <div class="text-gray-400 text-sm">No one is typing...</div>
            <% end %>
          </div>
          
          <form phx-change="typing" phx-target={@myself}>
            <input 
              type="text" 
              name="value"
              value={@message}
              placeholder="Type something to broadcast typing indicator..."
              class="w-full px-4 py-2 border rounded"
              phx-debounce="300"
              autocomplete="off"
            />
          </form>
          
          <div class="mt-4 text-xs text-gray-500">
            Open this page in multiple browser tabs and type in different tabs to see typing indicators.
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("typing", %{"value" => value}, socket) do
    typing = String.length(value) > 0
    
    if typing do
      # Broadcast that this user is typing
      Phoenix.PubSub.broadcast(
        ElixirKatas.PubSub,
        @topic,
        {:user_typing, socket.assigns.username}
      )
      
      # Cancel existing timer if any
      if socket.assigns.timer_ref do
        Process.cancel_timer(socket.assigns.timer_ref)
      end
      
      # Set a timer to stop typing after timeout
      timer_ref = Process.send_after(self(), :stop_typing, @typing_timeout)
      
      {:noreply, assign(socket, message: value, timer_ref: timer_ref)}
    else
      # User cleared the input, stop typing
      Phoenix.PubSub.broadcast(
        ElixirKatas.PubSub,
        @topic,
        {:user_stopped_typing, socket.assigns.username}
      )
      
      {:noreply, assign(socket, message: value, timer_ref: nil)}
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info({:user_typing, username}, socket) do
    # Don't show own typing indicator
    if username != socket.assigns.username do
      typing_users = MapSet.put(socket.assigns.typing_users, username)
      {:noreply, assign(socket, :typing_users, typing_users)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:user_stopped_typing, username}, socket) do
    typing_users = MapSet.delete(socket.assigns.typing_users, username)
    {:noreply, assign(socket, :typing_users, typing_users)}
  end

  def handle_info(:stop_typing, socket) do
    # Broadcast that this user stopped typing
    Phoenix.PubSub.broadcast(
      ElixirKatas.PubSub,
      @topic,
      {:user_stopped_typing, socket.assigns.username}
    )
    
    {:noreply, assign(socket, timer_ref: nil)}
  end

  defp typing_text(typing_users) do
    users = MapSet.to_list(typing_users)
    count = length(users)
    
    cond do
      count == 1 -> "#{hd(users)} is typing..."
      count == 2 -> "#{Enum.join(users, " and ")} are typing..."
      count > 2 -> "#{count} people are typing..."
      true -> ""
    end
  end
end
