# Kata 48: Broadcasting & Presence

## Phoenix.PubSub — The Engine Under the Hood

Every `broadcast!` in a Channel, every `Endpoint.broadcast` from a background job, and every LiveView subscription flows through **Phoenix.PubSub**. Processes **subscribe** to topics, and broadcasts to that topic reach every subscriber. This works across distributed BEAM nodes automatically.

```elixir
# Subscribe the current process to a topic:
Phoenix.PubSub.subscribe(MyApp.PubSub, "orders:updates")

# Broadcast a message to all subscribers:
Phoenix.PubSub.broadcast(MyApp.PubSub, "orders:updates", %{
  event: "order_placed",
  order_id: 42
})

# Broadcast to all subscribers EXCEPT the sender:
Phoenix.PubSub.broadcast_from(MyApp.PubSub, self(), "orders:updates", message)
```

PubSub is configured in your application supervision tree:

```elixir
# lib/my_app/application.ex
children = [
  {Phoenix.PubSub, name: MyApp.PubSub},
  MyAppWeb.Endpoint
]
```

---

## Three Ways to Broadcast

Phoenix gives you three broadcast mechanisms depending on where you are calling from:

| Function | Where to Use | Topic |
|----------|-------------|-------|
| `broadcast!/3` | Inside a Channel | Uses the channel's own topic |
| `Endpoint.broadcast/3` | Anywhere in your app | You specify the topic |
| `PubSub.broadcast/3` | Anywhere in your app | You specify the topic |

```elixir
# 1. Inside a channel — broadcasts to the channel's topic automatically:
broadcast!(socket, "new_msg", %{body: "Hello"})

# 2. From anywhere — same effect, you specify the topic:
MyAppWeb.Endpoint.broadcast("room:lobby", "new_msg", %{body: "Hello"})

# 3. Direct PubSub — subscribers receive the raw message in handle_info:
Phoenix.PubSub.broadcast(MyApp.PubSub, "room:lobby", %{
  event: "new_msg",
  payload: %{body: "Hello"}
})
```

**When to use which:**
- `broadcast!/3` — inside `handle_in/3` in a Channel module
- `Endpoint.broadcast/3` — from a context module, background job, or GenServer
- `PubSub.broadcast/3` — when you want LiveView processes or custom GenServers to receive raw messages (not wrapped in the Channel protocol)

---

## The Fan-out Pattern

**Fan-out** means one event reaches many independent subscribers. The BEAM excels at this because each subscriber is its own process, handling the message concurrently:

```elixir
defmodule MyApp.Orders do
  def place_order(user_id, items) do
    {:ok, order} = Repo.insert(%Order{user_id: user_id, items: items})

    # One broadcast, many receivers:
    Phoenix.PubSub.broadcast(MyApp.PubSub, "orders", %{
      event: "order_placed",
      order: order
    })

    {:ok, order}
  end
end
```

Who might be subscribed to `"orders"`?
- A **kitchen display** LiveView showing pending orders
- An **admin dashboard** LiveView tracking all orders
- A **user notification** channel pushing updates to the customer
- An **analytics tracker** logging order events

All of these receive the same message simultaneously and process it in their own process, independently.

---

## PubSub in LiveView

LiveView processes can subscribe to PubSub topics to receive real-time updates:

```elixir
defmodule MyAppWeb.OrdersLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Only subscribe when the WebSocket is connected.
      # On the initial static render, connected?/1 returns false.
      Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
    end

    {:ok, assign(socket, orders: Orders.list_recent())}
  end

  # Handle the broadcast message:
  def handle_info(%{event: "order_placed", order: order}, socket) do
    {:noreply, update(socket, :orders, &[order | &1])}
  end
end
```

**Why check `connected?(socket)`?** LiveView renders twice: once as static HTML (for SEO and fast first paint), then again when the WebSocket connects. If you subscribe during the static render, you will get duplicate subscriptions and double messages.

---

## Broadcasting from Context Modules

Broadcast from your business logic after database operations. This keeps Channels thin:

```elixir
defmodule MyApp.Orders do
  alias Phoenix.PubSub

  def create_order(attrs) do
    with {:ok, order} <- Repo.insert(Order.changeset(%Order{}, attrs)) do
      PubSub.broadcast(MyApp.PubSub, "orders", %{
        event: "order_created", order: order
      })
      {:ok, order}
    end
  end

  def update_order_status(order, new_status) do
    with {:ok, order} <- Repo.update(Order.changeset(order, %{status: new_status})) do
      PubSub.broadcast(MyApp.PubSub, "user:#{order.user_id}", %{
        event: "order_updated", order: order
      })
      {:ok, order}
    end
  end
end
```

Channels and LiveViews subscribe and render; contexts handle business logic and broadcast.

---

## Phoenix.Presence — Who Is Online?

Phoenix.Presence tracks connected users using **CRDTs (Conflict-free Replicated Data Types)**, which work correctly across multiple distributed BEAM nodes without coordination.

In a distributed system, tracking who is online is hard: User A connects to Server 1, User B to Server 2, and if Server 1 crashes, how does Server 2 know User A is gone? CRDTs solve this by letting each node maintain its own state and merge with others. The merge is **mathematically guaranteed** to converge correctly.

---

## Setting Up Presence

### 1. Define the Presence Module

```elixir
defmodule MyAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub
end
```

### 2. Add to the Supervision Tree

```elixir
# lib/my_app/application.ex
children = [
  {Phoenix.PubSub, name: MyApp.PubSub},
  MyAppWeb.Presence,    # <-- add this BEFORE the Endpoint
  MyAppWeb.Endpoint
]
```

### 3. Use in a Channel

```elixir
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel
  alias MyAppWeb.Presence

  def join("room:" <> room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, room_id: room_id)}
  end

  def handle_info(:after_join, socket) do
    user = socket.assigns.current_user

    # Track this user in the channel's presence:
    {:ok, _ref} = Presence.track(socket, user.id, %{
      name: user.name,
      avatar: user.avatar_url,
      status: "online",
      joined_at: System.os_time(:second)
    })

    # Push the full presence list to the new joiner:
    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end
end
```

**Why `send(self(), :after_join)`?** Because `join/3` must return quickly. Deferring to `handle_info/2` lets the join complete immediately.

---

## Presence Data Structure

`Presence.list/1` returns a map keyed by the tracked identifier (usually user ID):

```elixir
Presence.list("room:lobby")
# => %{
#   "user_42" => %{metas: [%{name: "Alice", status: "online", phx_ref: "F1abc123"}]},
#   "user_99" => %{metas: [%{name: "Bob", status: "away", phx_ref: "F1def456"}]}
# }
```

A user with multiple tabs has **multiple metas** (one per connection). Each `phx_ref` is unique. When one tab closes, only that meta is removed. The user stays in the list until all connections are gone.

---

## Presence Diffs — Efficient Updates

Instead of sending the full presence list on every change (which would be expensive with many users), Presence sends **diffs** — only what changed:

```elixir
# A presence_diff message looks like:
%{
  joins: %{
    "user_42" => %{metas: [%{name: "Alice", status: "online"}]}
  },
  leaves: %{
    "user_99" => %{metas: [%{name: "Bob", status: "away"}]}
  }
}
```

Presence broadcasts these diffs automatically — you do **not** need to broadcast join/leave events yourself. When `Presence.track/3` is called, a diff is sent. When the tracking process exits, a leave diff is sent.

---

## Presence in LiveView

```elixir
defmodule MyAppWeb.RoomLive do
  use MyAppWeb, :live_view
  alias MyAppWeb.Presence

  def mount(%{"room_id" => room_id}, _session, socket) do
    topic = "room:#{room_id}"

    if connected?(socket) do
      # Subscribe to presence diffs:
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      # Track this LiveView process in presence:
      {:ok, _} = Presence.track(self(), topic,
        socket.assigns.current_user.id, %{
          name: socket.assigns.current_user.name,
          joined_at: System.os_time(:second)
        })
    end

    {:ok, assign(socket,
      room_id: room_id,
      online_users: Presence.list(topic)
    )}
  end

  # When someone joins or leaves, a presence_diff is broadcast:
  def handle_info(%Phoenix.Socket.Broadcast{
        event: "presence_diff",
        payload: _diff}, socket) do
    # Re-fetch the full list (simplest approach):
    topic = "room:#{socket.assigns.room_id}"
    {:noreply, assign(socket, online_users: Presence.list(topic))}
  end
end
```

**Note**: In Channels, `Presence.track(socket, ...)` takes the channel socket. In LiveView, `Presence.track(self(), topic, ...)` takes the LiveView process pid and the topic string explicitly.

---

## JavaScript Presence Client

On the client side, `phoenix.js` includes a `Presence` module that handles state syncing and diffing:

```javascript
import {Presence} from "phoenix"

const presence = new Presence(channel)

// Called whenever presence state changes (join or leave):
presence.onSync(() => {
  const users = presence.list((id, {metas: [first, ...rest]}) => ({
    id,
    name: first.name,
    status: first.status,
    tabCount: rest.length + 1  // how many tabs this user has open
  }))

  renderOnlineUserList(users)
})
```

The `Presence` class automatically handles `"presence_state"` (initial full state), `"presence_diff"` (incremental updates), and merging diffs into local state.

---

## Targeting Specific Users

Using the `id/1` function from UserSocket, you can broadcast to a specific user across all their connections:

```elixir
# In UserSocket:
def id(socket), do: "users_socket:#{socket.assigns.user_id}"

# From anywhere — target user 42 (force logout, notifications, etc.):
MyAppWeb.Endpoint.broadcast("users_socket:42", "force_logout", %{})
```

---

## Key Takeaways

1. **Phoenix.PubSub** is the underlying engine for all real-time messaging — subscribe any process, broadcast from anywhere
2. Use `broadcast!/3` inside channels, `Endpoint.broadcast/3` from contexts/jobs, and `PubSub.broadcast/3` for raw messages
3. **Always check `connected?(socket)`** in LiveView before subscribing — prevents double subscriptions
4. **Phoenix.Presence** uses CRDTs for distributed state — correct across multiple nodes without coordination
5. Presence broadcasts `"presence_diff"` automatically — you never manually broadcast join/leave events
6. A user with multiple open tabs has **multiple metas** in the presence map, each with a unique `phx_ref`
7. Use `Endpoint.broadcast("users_socket:ID", ...)` to target a specific user across all their connections
8. The fan-out pattern (one broadcast, many subscribers) is natural on the BEAM where each subscriber is its own lightweight process
9. Keep Channels thin — put business logic in context modules and broadcast from there
