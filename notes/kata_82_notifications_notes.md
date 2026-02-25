# Kata 82: Notifications

## The Concept
**System-wide Alerts**. "Server going down for maintenance", "New Order Received".
Notifications that originate from *outside* the current user's workflow.

## The Elixir Way
*   **PubSub Topic**: `user_notifications:{user_id}`.
*   **Broadcast**: Can be triggered from a Cron job, a Controller, or another LiveView.
*   **UI**: A "Toast" component that subscribes to the topic.

## Deep Dive

### 1. Decoupled Architecture
The Navbar (or Layout) subscribes to the topic. The Page doesn't need to know about it.
This allows "Global" features to be implemented cleanly in the root layout.

### 2. Transient vs Persistent
*   **PubSub**: Transient. If the user is offline, they miss the message.
*   **Database**: Persistent. Save to `notifications` table first, *then* broadcast. On connect, load unread from DB.

## Common Pitfalls

1.  **Multiple Tabs**: If a user has 5 tabs open, all 5 receive the broadcast and show the toast.
    *   *Solution*: This is usually desired! If not, use SharedWorkers (advanced JS) or Leader Election logic.
2.  **Security**: Ensure users can only subscribe to their own topics. Validate topics in `mount`.
