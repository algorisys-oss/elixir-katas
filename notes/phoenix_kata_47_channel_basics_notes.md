# Kata 47: Channel Basics

## What are Phoenix Channels?

Phoenix Channels provide a **real-time, bidirectional communication layer** on top of WebSockets. While a raw WebSocket gives you a pipe to send bytes through, Channels add structure: topics, events, authentication, multiplexing, and automatic reconnection.

Think of it this way:
- **WebSocket** = the transport (a pipe)
- **Channel** = the application protocol (what you send through the pipe, and how)

---

## Core Concepts

| Concept | What It Is | Analogy |
|---------|-----------|---------|
| **Socket** | One WebSocket connection per browser tab. Authenticates the user and routes messages to channels. | The phone line |
| **Channel** | One Elixir process per client per topic. Handles events and holds state. | A conversation on that phone line |
| **Topic** | String identifier like `"room:lobby"`. Convention: `"resource:id"`. | The phone number you dialed |
| **Event** | Named message between client and server (e.g., `"new_msg"`, `"typing"`). | What you say in the conversation |

**Key insight**: A single Socket (one WebSocket connection) can multiplex **many Channels**. If a user is in three chat rooms, that is one Socket and three Channel processes, all sharing the same WebSocket connection.

---

## Channel Lifecycle

Understanding the lifecycle is critical. Here is exactly what happens, step by step:

```
1. Client connects WebSocket to /socket
   UserSocket.connect/2 is called
   -> {:ok, socket} to accept the connection
   -> :error to reject (e.g., bad auth token)

2. Client joins a topic "room:lobby"
   RoomChannel.join("room:lobby", params, socket) is called
   -> {:ok, socket} spawns a new GenServer process for this channel
   -> {:error, %{reason: "unauthorized"}} rejects the join

3. Client sends an event "new_msg" with a payload
   RoomChannel.handle_in("new_msg", payload, socket) is called
   -> {:noreply, socket} or {:reply, {:ok, data}, socket}

4. Server pushes an event to the client
   push(socket, "user_joined", %{name: "Alice"})
   broadcast!(socket, "new_msg", %{body: "Hello everyone"})

5. Client leaves or disconnects
   RoomChannel.terminate(reason, socket) is called
   The channel GenServer process exits
```

Each Channel is its own GenServer process. This means:
- Channels have isolated state (one crashing channel does not affect others)
- You can use `assign/3` to store per-channel state in the socket
- Channels can receive OTP messages via `handle_info/2`

---

## UserSocket — The Gateway

The UserSocket authenticates the WebSocket connection and declares which channel topic patterns this socket can access:

```elixir
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket

  # Declare which topics route to which channel modules:
  channel "room:*", MyAppWeb.RoomChannel
  channel "user:*", MyAppWeb.UserChannel
  channel "notifications:*", MyAppWeb.NotificationsChannel

  # Called once when the client opens the WebSocket connection.
  # This is your chance to authenticate.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user_token", token,
                              max_age: 86_400) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} ->
        :error  # reject the connection
    end
  end

  # Reject connections with no token:
  def connect(_params, _socket, _connect_info), do: :error

  # Unique identifier for this socket.
  # Used for targeted broadcasts (e.g., force logout).
  @impl true
  def id(socket), do: "users_socket:#{socket.assigns.user_id}"
end
```

### Mounting in the Endpoint

```elixir
# lib/my_app_web/endpoint.ex
socket "/socket", MyAppWeb.UserSocket,
  websocket: true,
  longpoll: false
```

### Socket vs Channel — What Lives Where

| | Socket | Channel |
|--|--------|---------|
| **Count** | 1 per browser tab | 1 per topic the client has joined |
| **Process** | Manages the WebSocket | Its own GenServer per topic |
| **State** | Auth info (user_id, etc.) | Topic-specific state (room_id, etc.) |
| **Assigns** | Shared across all channels | Scoped to this channel only |

Socket assigns set in `connect/3` are available to all channels via `socket.assigns`. Each channel can then add its own assigns on top.

---

## Channel Module — Handling Events

```elixir
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel
  alias MyApp.Chat

  # Called when a client joins "room:*".
  # The pattern match extracts the room_id from the topic.
  @impl true
  def join("room:" <> room_id, _params, socket) do
    if Chat.room_member?(room_id, socket.assigns.user_id) do
      # Send history after joining (using send/2 to self):
      send(self(), :after_join)
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # handle_info receives OTP messages (like the :after_join above):
  def handle_info(:after_join, socket) do
    messages = Chat.recent_messages(socket.assigns.room_id)
    push(socket, "history", %{messages: messages})
    {:noreply, socket}
  end

  # handle_in receives events from the client:
  @impl true
  def handle_in("new_msg", %{"body" => body}, socket) do
    msg = Chat.create_message!(
      socket.assigns.room_id,
      socket.assigns.user_id,
      body
    )

    # Broadcast to ALL clients subscribed to this topic:
    broadcast!(socket, "new_msg", %{
      id: msg.id,
      body: msg.body,
      user_id: msg.user_id,
      inserted_at: msg.inserted_at
    })

    {:noreply, socket}
  end

  # Typing indicator — broadcast to everyone except the sender:
  def handle_in("typing", _payload, socket) do
    broadcast_from!(socket, "user_typing", %{
      user_id: socket.assigns.user_id
    })
    {:reply, {:ok, %{}}, socket}
  end

  # Ping/pong — reply directly to the caller:
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{pong: true}}, socket}
  end

  @impl true
  def terminate(_reason, _socket), do: :ok
end
```

---

## Return Values from handle_in

These are the possible return values from `handle_in/3`:

```elixir
# No response sent to the client:
{:noreply, socket}

# Reply with success data to the calling client only:
{:reply, {:ok, %{data: "some value"}}, socket}

# Reply with an error to the calling client:
{:reply, {:error, %{reason: "not allowed"}}, socket}

# Terminate this channel process:
{:stop, :normal, socket}
```

**When to use which:**
- `{:noreply, socket}` — when you broadcast instead of replying, or the event needs no response
- `{:reply, {:ok, ...}, socket}` — when the client needs confirmation or data back (like a ping)
- `{:reply, {:error, ...}, socket}` — when the request is invalid and the client should know why
- `{:stop, ...}` — when you want to kick the client out of the channel

---

## Pushing Messages to Clients

Phoenix provides three functions for sending messages:

```elixir
# 1. push/3 — send to THIS specific client only:
push(socket, "welcome", %{message: "Hello!"})

# 2. broadcast!/3 — send to ALL clients on this topic
#    (including the sender):
broadcast!(socket, "new_msg", %{body: "Hello everyone"})

# 3. broadcast_from!/3 — send to ALL clients on this topic
#    EXCEPT the sender:
broadcast_from!(socket, "user_typing", %{user_id: 42})

# 4. Endpoint.broadcast/3 — send from OUTSIDE a channel
#    (e.g., from a context module, background job, or LiveView):
MyAppWeb.Endpoint.broadcast("room:lobby", "announcement", %{
  text: "Server maintenance in 5 minutes"
})

# 5. Target a specific user's socket (using the id/1 return value):
MyAppWeb.Endpoint.broadcast("users_socket:42", "force_logout", %{})
```

---

## Topics — Naming Convention

Topics are just strings. The convention is `"resource_type:resource_id"`:

```elixir
# In UserSocket — declare which patterns route where:
channel "room:*",          MyAppWeb.RoomChannel
channel "user:*",          MyAppWeb.UserChannel
channel "notifications:*", MyAppWeb.NotificationsChannel

# The wildcard (*) part is accessible via pattern matching in join/3:
def join("room:" <> room_id, _params, socket) do
  # room_id = "lobby", "42", "general", etc.
  {:ok, assign(socket, room_id: room_id)}
end

# Example topic strings:
# "room:lobby"        -> public chat room
# "room:42"           -> private room with database ID 42
# "user:123"          -> user-specific channel for notifications
# "game:chess_abc"    -> a specific game session
```

---

## Standard Phoenix Events

Phoenix reserves several event names for its internal protocol:

| Event | Direction | Purpose |
|-------|-----------|---------|
| `"phx_join"` | Client -> Server | Client is joining a channel |
| `"phx_leave"` | Client -> Server | Client is leaving a channel |
| `"phx_reply"` | Server -> Client | Server's reply to a client push |
| `"phx_error"` | Server -> Client | Error from the server |
| `"phx_close"` | Server -> Client | Channel has been closed |

Your custom events can be any string. Common examples:
- `"new_msg"`, `"typing"`, `"user_joined"`, `"update"`, `"delete"`

---

## JavaScript Client

```javascript
import {Socket} from "phoenix"

// 1. Create and connect the socket:
const socket = new Socket("/socket", {
  params: {token: window.userToken}
})
socket.connect()

// 2. Join a channel (topic):
const channel = socket.channel("room:lobby", {})

channel.join()
  .receive("ok", resp => console.log("Joined!", resp))
  .receive("error", resp => console.log("Failed:", resp))
  .receive("timeout", () => console.log("Join timed out"))

// 3. Listen for server events:
channel.on("new_msg", msg => appendMessage(msg.body))
channel.on("user_typing", ({user_id}) => showTypingIndicator(user_id))

// 4. Push events to server (with response handling):
channel.push("new_msg", {body: "Hello!"})
  .receive("ok", () => console.log("Sent!"))
  .receive("error", err => console.log("Failed:", err))

// 5. Leave the channel:
channel.leave()
```

**Automatic reconnection**: `phoenix.js` reconnects with exponential backoff when the WebSocket disconnects. Channels automatically rejoin after reconnection.

---

## Providing the Auth Token

Generate a signed token in the controller and expose it to JavaScript:

```elixir
# Controller:
token = Phoenix.Token.sign(conn, "user_token", conn.assigns.current_user.id)
render(conn, :index, user_token: token)
```

```html
<!-- Layout template: -->
<script>window.userToken = "<%= @user_token %>";</script>
```

The token is verified in `UserSocket.connect/2` via `Phoenix.Token.verify/4`. Tokens expire after `max_age` (e.g., 86,400 seconds = 24 hours).

---

## Key Takeaways

1. One **Socket** per WebSocket connection; one **Channel** GenServer process per topic joined
2. `UserSocket.connect/2` authenticates — return `:error` to reject bad tokens
3. `channel "room:*"` in UserSocket pattern-matches any topic starting with `"room:"`
4. `join/3` returns `{:ok, socket}` to allow or `{:error, reason}` to deny access
5. `handle_in/3` handles client events — can reply, broadcast, or silently process
6. `broadcast!/3` sends to ALL subscribers; `broadcast_from!/3` skips the sender
7. `push/3` sends to only the current client; `Endpoint.broadcast/3` sends from anywhere
8. Channels are GenServer processes — they can hold state, receive OTP messages via `handle_info/2`
9. The `phoenix.js` client handles reconnection and channel rejoin automatically
