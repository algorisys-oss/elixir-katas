# Kata 78: Chat Room (PubSub)

## The Concept
**Real-time Broadcasting**. User A types something, User B sees it instantly.
This enables collaborative apps (Chat, Docs, Dashboards).

## The Elixir Way
**Phoenix.PubSub** is built-in. No Redis or external message queue required.
*   **Topic**: A string identifier "room:123".
*   **Subscribe**: `Phoenix.PubSub.subscribe(PubSub, topic)`.
*   **Broadcast**: `Phoenix.PubSub.broadcast(PubSub, topic, message)`.

## Deep Dive

### 1. The Flow
1.  **Join**: `mount` calls `subscribe("chat")`.
2.  **Send**: `handle_event("send")` calls `broadcast("chat", {:text, "..."})`.
3.  **Receive**: *Every* process subscribed (including the sender!) receives `handle_info({:text, ...})` and updates its list.

### 2. Temporary Assigns (Optimization)
For a chat log with 10,000 messages, keeping the list in memory is expensive.
```elixir
socket = stream(socket, :messages, [])
```
Using **Streams** (Kata 71) is highly recommended for chat logs to keep server memory usage constant (O(1)).

### 3. Presence vs PubSub
PubSub sends messages. **Presence** (Kata 80) tracks *who* is connected. They are often used together.

## Common Pitfalls

1.  **Broadcasting too much**: Sending the *entire* state object over PubSub is wasteful. Send only the delta (`{:new_msg, m}`).
2.  **Self-Messaging**: By default, the sender receives their own broadcast.
    *   *Optimization*: Use `broadcast_from(self(), ...)` if you want to skip the sender (e.g. if you optimistically added the message to the UI already).
