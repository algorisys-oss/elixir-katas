defmodule ElixirKatasWeb.PhoenixKata47ChannelBasicsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Channel Basics — Socket, Topic, Join, handle_in, push

    # 1. UserSocket — authenticates and routes to channels
    defmodule MyAppWeb.UserSocket do
      use Phoenix.Socket

      channel "room:*", MyAppWeb.RoomChannel
      channel "user:*", MyAppWeb.UserChannel

      @impl true
      def connect(%{"token" => token}, socket, _connect_info) do
        case Phoenix.Token.verify(socket, "user_token", token,
               max_age: 86400) do
          {:ok, user_id} ->
            {:ok, assign(socket, :user_id, user_id)}
          {:error, _} ->
            :error
        end
      end

      @impl true
      def id(socket), do: "users_socket:\#{socket.assigns.user_id}"
    end

    # 2. RoomChannel — handles join, events, and broadcasts
    defmodule MyAppWeb.RoomChannel do
      use MyAppWeb, :channel
      alias MyApp.Chat

      @impl true
      def join("room:" <> room_id, _params, socket) do
        if Chat.room_member?(room_id, socket.assigns.user_id) do
          send(self(), :after_join)
          {:ok, assign(socket, :room_id, room_id)}
        else
          {:error, %{reason: "unauthorized"}}
        end
      end

      def handle_info(:after_join, socket) do
        messages = Chat.recent_messages(socket.assigns.room_id)
        push(socket, "history", %{messages: messages})
        {:noreply, socket}
      end

      @impl true
      def handle_in("new_msg", %{"body" => body}, socket) do
        msg = Chat.save_message(socket.assigns.user_id, body)
        broadcast!(socket, "new_msg", %{
          body: msg.body, user: msg.user.name, at: msg.inserted_at
        })
        {:noreply, socket}
      end

      def handle_in("typing", _payload, socket) do
        broadcast_from!(socket, "user_typing", %{
          user_id: socket.assigns.user_id
        })
        {:reply, {:ok, %{}}, socket}
      end
    end

    # 3. Pushing messages
    push(socket, "event_name", payload)          # to THIS client
    broadcast!(socket, "event_name", payload)    # to ALL on topic
    broadcast_from!(socket, "event_name", payload) # all EXCEPT sender

    # From outside a channel process:
    MyAppWeb.Endpoint.broadcast("room:lobby", "new_msg", %{body: "Hi"})

    # 4. JS Client
    # const channel = socket.channel("room:lobby", {})
    # channel.join()
    #   .receive("ok", resp => console.log("Joined!"))
    #   .receive("error", resp => console.log("Failed:", resp))
    # channel.on("new_msg", msg => appendMessage(msg))
    # channel.push("new_msg", {body: "Hello!"})
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "lifecycle")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Channel Basics</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Socket, topic, join, handle_in, push — the building blocks of Phoenix Channels for real-time bidirectional communication.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "socket", "channel", "client", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-orange-50 dark:bg-orange-900/30 text-orange-700 dark:text-orange-400 border-b-2 border-orange-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["lifecycle", "topics", "events"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-orange-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Socket</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">One WebSocket connection. Holds auth state. Routes messages to channels.</p>
            </div>
            <div class="p-4 rounded-lg bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800">
              <p class="text-sm font-semibold text-orange-700 dark:text-orange-300 mb-1">Channel</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">One Elixir process per client per topic. Handles events and holds state.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Topic</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">String identifier like "room:lobby". Pattern: "resource:id".</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Socket -->
      <%= if @active_tab == "socket" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The UserSocket authenticates the connection and defines which channel topics are available.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{socket_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Socket vs Channel</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>Socket</strong>: 1 per browser tab (WebSocket connection)</li>
                <li><strong>Channel</strong>: many per socket (1 per topic joined)</li>
                <li>Socket is the multiplexer — routes to channels</li>
                <li>Socket assigns are shared across channels</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Endpoint Mount</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{endpoint_socket_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Channel -->
      <%= if @active_tab == "channel" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            A Channel module handles join, incoming events, and can push messages to clients.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{channel_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Return Values from handle_in</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><code>&#123;:noreply, socket&#125;</code> — no response to caller</li>
                <li><code>&#123;:reply, &#123;:ok, data&#125;, socket&#125;</code> — reply to caller</li>
                <li><code>&#123;:reply, &#123;:error, reason&#125;, socket&#125;</code> — error reply</li>
                <li><code>&#123;:stop, reason, socket&#125;</code> — terminate channel</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Pushing to Client</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{push_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Client -->
      <%= if @active_tab == "client" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The phoenix.js client connects, joins channels, and handles events.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{client_code()}</div>

          <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
            <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">Reconnection</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              phoenix.js automatically reconnects on disconnect with exponential backoff. Channels automatically rejoin. Your app just keeps working.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Chat Room Channel</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("overview"), do: "Overview"
  defp tab_label("socket"), do: "UserSocket"
  defp tab_label("channel"), do: "Channel Module"
  defp tab_label("client"), do: "JS Client"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("lifecycle"), do: "Lifecycle"
  defp topic_label("topics"), do: "Topics"
  defp topic_label("events"), do: "Events"

  defp overview_code("lifecycle") do
    """
    # Channel lifecycle:
    #
    # 1. Client connects WebSocket to /socket
    #    UserSocket.connect/2 is called
    #    -> {:ok, socket} to accept, {:error} to reject
    #
    # 2. Client joins a topic "room:lobby"
    #    RoomChannel.join("room:lobby", params, socket)
    #    -> {:ok, socket} to allow, {:error, reason} to reject
    #    -> A new GenServer process spawns for this channel
    #
    # 3. Client sends event "new_msg" with payload
    #    RoomChannel.handle_in("new_msg", payload, socket)
    #    -> {:noreply, socket}  or  {:reply, {:ok, data}, socket}
    #
    # 4. Server pushes event to client
    #    push(socket, "user_joined", %{name: "Alice"})
    #
    # 5. Client leaves or disconnects
    #    RoomChannel.terminate(reason, socket) is called\
    """
    |> String.trim()
  end

  defp overview_code("topics") do
    """
    # Topics are strings that identify a channel.
    # Convention: "resource_type:resource_id"
    #
    # Examples:
    "room:lobby"        # public room
    "room:42"           # room with ID 42
    "user:123"          # user-specific channel
    "game:chess_abc"    # game session
    "notifications:*"   # wildcard (matches in channel)
    #
    # In UserSocket, you declare which patterns match:
    channel "room:*", MyAppWeb.RoomChannel
    channel "user:*", MyAppWeb.UserChannel
    #
    # The * glob is available in the channel as topic:
    def join("room:" <> room_id, _params, socket) do
      {:ok, assign(socket, :room_id, room_id)}
    end\
    """
    |> String.trim()
  end

  defp overview_code("events") do
    """
    # Events are named messages between client and server.
    # Direction:
    #   Client -> Server: handle_in/3
    #   Server -> Client: push/3 or broadcast/3

    # Standard Phoenix events (internal):
    "phx_join"          # client joining channel
    "phx_leave"         # client leaving
    "phx_reply"         # server reply to client push
    "phx_error"         # error from server
    "phx_close"         # channel closed

    # Your custom events:
    "new_msg"           # user sent a message
    "typing"            # user is typing
    "user_joined"       # someone joined the room
    "update"            # resource was updated
    "delete"            # resource was deleted

    # Events are just strings — name them clearly.\
    """
    |> String.trim()
  end

  defp socket_code do
    """
    defmodule MyAppWeb.UserSocket do
      use Phoenix.Socket

      # Declare channels this socket can access:
      channel "room:*", MyAppWeb.RoomChannel
      channel "user:*", MyAppWeb.UserChannel

      # Called when client connects (/socket WebSocket):
      @impl true
      def connect(%{"token" => token}, socket, _connect_info) do
        case Phoenix.Token.verify(socket, "user_token", token,
               max_age: 86400) do
          {:ok, user_id} ->
            {:ok, assign(socket, :user_id, user_id)}
          {:error, _} ->
            :error
        end
      end

      # Fallback for no-auth connections (dev only):
      def connect(_params, socket, _connect_info) do
        {:ok, socket}
      end

      # Unique identifier for this socket connection:
      @impl true
      def id(socket), do: "users_socket:\#{socket.assigns.user_id}"
    end\
    """
    |> String.trim()
  end

  defp endpoint_socket_code do
    """
    # lib/my_app_web/endpoint.ex:
    socket "/socket", MyAppWeb.UserSocket,
      websocket: true,
      longpoll: false

    # In app.js — connect with auth token:
    let socket = new Socket("/socket", {
      params: {token: window.userToken}
    })
    socket.connect()

    # In layout, provide the token:
    # <script>
    #   window.userToken = "<%= user_token %>";
    # </script>

    # In controller, generate token:
    token = Phoenix.Token.sign(
      conn, "user_token", conn.assigns.current_user.id
    )\
    """
    |> String.trim()
  end

  defp channel_code do
    """
    defmodule MyAppWeb.RoomChannel do
      use MyAppWeb, :channel
      alias MyApp.Chat

      # Called when client joins "room:*":
      @impl true
      def join("room:" <> room_id, _params, socket) do
        # Authorize: is the user allowed in this room?
        if Chat.room_member?(room_id, socket.assigns.user_id) do
          {:ok, assign(socket, :room_id, room_id)}
        else
          {:error, %{reason: "unauthorized"}}
        end
      end

      # Handle "new_msg" event from client:
      @impl true
      def handle_in("new_msg", %{"body" => body}, socket) do
        room_id = socket.assigns.room_id
        user_id = socket.assigns.user_id

        msg = Chat.create_message!(room_id, user_id, body)

        # Broadcast to all clients in this topic:
        broadcast!(socket, "new_msg", %{
          id: msg.id,
          body: msg.body,
          user_id: user_id,
          inserted_at: msg.inserted_at
        })

        {:noreply, socket}
      end

      # Handle "typing" event, reply with ok:
      def handle_in("typing", _payload, socket) do
        broadcast_from!(socket, "user_typing", %{
          user_id: socket.assigns.user_id
        })
        {:reply, {:ok, %{}}, socket}
      end

      # Called when client leaves:
      @impl true
      def terminate(_reason, _socket), do: :ok
    end\
    """
    |> String.trim()
  end

  defp push_code do
    """
    # Push to THIS specific client:
    push(socket, "event_name", payload)

    # Broadcast to ALL clients on this topic
    # (including the sender):
    broadcast!(socket, "event_name", payload)

    # Broadcast to all EXCEPT the sender:
    broadcast_from!(socket, "event_name", payload)

    # Push from outside a channel process:
    MyAppWeb.Endpoint.broadcast(
      "room:lobby",     # topic
      "new_msg",        # event
      %{body: "Hello"}  # payload
    )

    # Broadcast to a specific user's socket:
    MyAppWeb.Endpoint.broadcast(
      "users_socket:42",  # id/1 from UserSocket
      "logout",
      %{}
    )\
    """
    |> String.trim()
  end

  defp client_code do
    """
    // app.js - Phoenix Channels client:
    import {Socket} from "phoenix"

    // 1. Create and connect the socket:
    const socket = new Socket("/socket", {
      params: {token: window.userToken}
    })
    socket.connect()

    // 2. Join a channel (topic):
    const channel = socket.channel("room:lobby", {})

    channel.join()
      .receive("ok", resp => {
        console.log("Joined room:lobby!", resp)
      })
      .receive("error", resp => {
        console.log("Failed to join:", resp)
      })
      .receive("timeout", () => {
        console.log("Join timed out")
      })

    // 3. Listen for events from server:
    channel.on("new_msg", msg => {
      appendMessage(msg.body, msg.user_id)
    })

    channel.on("user_typing", ({user_id}) => {
      showTypingIndicator(user_id)
    })

    // 4. Push events to server:
    channel.push("new_msg", {body: "Hello!"})
      .receive("ok", () => console.log("Sent!"))
      .receive("error", err => console.log("Error:", err))

    // 5. Leave the channel:
    channel.leave()\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete chat room example:

    # 1. UserSocket:
    defmodule MyAppWeb.UserSocket do
      use Phoenix.Socket
      channel "room:*", MyAppWeb.RoomChannel

      def connect(%{"token" => token}, socket, _info) do
        case Phoenix.Token.verify(socket, "user token", token,
                                  max_age: 86_400) do
          {:ok, user_id} -> {:ok, assign(socket, user_id: user_id)}
          _ -> :error
        end
      end
      def id(socket), do: "user_socket:\#{socket.assigns.user_id}"
    end

    # 2. RoomChannel:
    defmodule MyAppWeb.RoomChannel do
      use MyAppWeb, :channel

      def join("room:" <> _id, _params, socket) do
        # Send recent messages on join:
        send(self(), :after_join)
        {:ok, socket}
      end

      def handle_info(:after_join, socket) do
        messages = Chat.recent_messages(socket.assigns.room_id)
        push(socket, "history", %{messages: messages})
        {:noreply, socket}
      end

      def handle_in("new_msg", %{"body" => body}, socket) do
        msg = Chat.save_message(socket.assigns.user_id, body)
        broadcast!(socket, "new_msg", %{
          body: msg.body,
          user: msg.user.name,
          at: msg.inserted_at
        })
        {:noreply, socket}
      end
    end

    # 3. JS client:
    # const ch = socket.channel("room:42", {})
    # ch.join().receive("ok", () => console.log("In!"))
    # ch.on("new_msg", ({body, user}) =>
    #   addMessage(user, body))
    # ch.push("new_msg", {body: input.value})\
    """
    |> String.trim()
  end
end
