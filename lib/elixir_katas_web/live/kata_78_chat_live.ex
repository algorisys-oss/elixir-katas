defmodule ElixirKatasWeb.Kata78ChatRoomLive do
  use ElixirKatasWeb, :live_component

  @topic "chat:lobby"

  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:__initialized__] do
      {:ok, assign(socket, assigns)}
    else
      socket = assign(socket, assigns)
      socket = assign(socket, :__initialized__, true)
      socket = assign(socket, assigns)
    # Generate a random username
    username = "User#{:rand.uniform(9999)}"

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:messages, [])
      |> assign(:message_input, "")
      |> assign(:username, username)
      |> assign(:username_set, false)
      {:ok, socket}
    end

  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Multi-user chat room with PubSub broadcasting. Open in multiple tabs to test!
        </div>

        <%= if !@username_set do %>
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <h3 class="text-lg font-medium mb-4">Enter the Chat Room</h3>
            <form phx-submit="set_username" phx-target={@myself} class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Your Username</label>
                <input 
                  type="text" 
                  name="username" 
                  value={@username}
                  placeholder="Enter your username"
                  class="w-full px-4 py-2 border rounded"
                  required
                />
              </div>
              <button type="submit" class="w-full px-6 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700">
                Join Chat
              </button>
            </form>
          </div>
        <% else %>
          <div class="bg-white rounded-lg shadow-sm border">
            <div class="border-b p-4 bg-gray-50">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-medium">Chat Lobby</h3>
                <div class="text-sm text-gray-600">
                  Logged in as <span class="font-medium text-indigo-600"><%= @username %></span>
                </div>
              </div>
            </div>
            
            <div id="messages" class="h-96 overflow-y-auto p-4 space-y-3" phx-hook="ScrollPosition" data-scroll-key="chat">
              <%= if Enum.empty?(@messages) do %>
                <div class="text-center text-gray-400 mt-20">
                  <div class="text-4xl mb-2">💬</div>
                  <div>No messages yet. Start the conversation!</div>
                </div>
              <% else %>
                <%= for {msg, idx} <- Enum.with_index(@messages) do %>
                  <div class={"flex gap-3 " <> if msg.user == @username, do: "flex-row-reverse", else: ""}>
                    <div class="flex-shrink-0 w-10 h-10 bg-indigo-500 rounded-full flex items-center justify-center text-white font-medium">
                      <%= String.first(msg.user) %>
                    </div>
                    <div class={"flex-1 max-w-md " <> if msg.user == @username, do: "text-right", else: ""}>
                      <div class="text-sm font-medium text-gray-900"><%= msg.user %></div>
                      <div class={"inline-block px-4 py-2 rounded-lg " <> 
                                  if msg.user == @username, 
                                    do: "bg-indigo-600 text-white", 
                                    else: "bg-gray-100 text-gray-900"}>
                        <%= msg.text %>
                      </div>
                      <div class="text-xs text-gray-400 mt-1"><%= msg.time %></div>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
            
            <div class="border-t p-4">
              <form phx-submit="send_message" phx-target={@myself} class="flex gap-2">
                <input 
                  type="text" 
                  name="message" 
                  value={@message_input}
                  phx-change="update_input" phx-target={@myself}
                  placeholder="Type a message..."
                  class="flex-1 px-4 py-2 border rounded"
                  autocomplete="off"
                />
                <button type="submit" class="px-6 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700">
                  Send
                </button>
              </form>
            </div>
          </div>
        <% end %>
      </div>
    
    """
  end

  def handle_event("set_username", %{"username" => username}, socket) when username != "" do
    # Subscribe to chat topic
    Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
    
    # Broadcast join message
    message = %{
      user: "System",
      text: "#{username} joined the chat",
      time: Calendar.strftime(DateTime.utc_now(), "%H:%M:%S"),
      type: :system
    }
    
    Phoenix.PubSub.broadcast(ElixirKatas.PubSub, @topic, {:new_message, message})
    
    {:noreply, assign(socket, username: username, username_set: true)}
  end

  def handle_event("set_username", _, socket), do: {:noreply, socket}

  def handle_event("update_input", %{"message" => text}, socket) do
    {:noreply, assign(socket, :message_input, text)}
  end

  def handle_event("send_message", %{"message" => text}, socket) when text != "" do
    message = %{
      user: socket.assigns.username,
      text: text,
      time: Calendar.strftime(DateTime.utc_now(), "%H:%M:%S"),
      type: :user
    }
    
    # Broadcast to all subscribers
    Phoenix.PubSub.broadcast(ElixirKatas.PubSub, @topic, {:new_message, message})
    
    {:noreply, assign(socket, :message_input, "")}
  end

  def handle_event("send_message", _, socket), do: {:noreply, socket}

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
  end
end
