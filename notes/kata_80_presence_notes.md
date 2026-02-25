# Kata 80: Presence (Who is Online?)

## The Concept
Tracking "Who is here". In a distributed system with multiple servers, this is hard (no single source of truth).
Phoenix Presence uses a **CRDT** (Conflict-free Replicated Data Type) to sync lists across the cluster with no central database.

## The Elixir Way
*   `Presence.track(self(), topic, key, meta)`: "I am here."
*   `handle_info(%{event: "presence_diff"}, ...)`: "Someone joined/left."

## Deep Dive

### 1. The Meta Map
You don't just track a User ID. You track metadata:
```elixir
%{
  online_at: DateTime.utc_now(),
  device: "Mobile",
  status: "Away"
}
```
This allows rich UI ("User is typing...", "User is on mobile").

### 2. List vs Track
*   `list(topic)`: Returns the current state.
*   `track(...)`: Registers a process. When that process crashes or disconnects, Presence detects it and automatically broadcasts a "leave" event.

### 3. Bubble-up Events
Presence batches updates. If 100 users join at once, you might receive one large diff instead of 100 small messages, saving CPU.

## Common Pitfalls

1.  **Tracking in Mount**: Always wrap `Presence.track` in `if connected?(socket)` to avoid tracking the static HTTP render (which creates "ghost" users that disappear immediately).
2.  **Key Collisions**: The `key` (3rd arg) identifies the user. If a user has 2 tabs open, and you use `user.id` as the key, Presence groups them under one entry with 2 `metas`. If you want strictly separate entries, use a unique ref.
