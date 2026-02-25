# Kata 77: The Ticker (PubSub)

## Goal
Broadcast real-time data to multiple connected clients using `Phoenix.PubSub`.

## Core Concepts

### 1. `Phoenix.PubSub.subscribe`
Subscribes the current process to a topic.
`subscribe(MyApp.PubSub, "topic")`.

### 2. `Phoenix.PubSub.broadcast`
Sends a message to *all* subscribers of a topic.

## Implementation Details

1.  **Producer**: A background process (or simple spawn) that loops and broadcasts.
2.  **Consumer**: The LiveView listens for `{:stock_update, ...}` messages.

## Tips
- In production, use `start_link` and a proper GenServer for the producer, under a Supervisor.

## Challenge
Implement **Pause**. Add a button that "Pauses" the updates **locally** (i.e., the LiveView ignores the incoming messages).
(Note: The server keeps broadcasting, but this client chooses not to update its state).

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_info({:stock_update, _}, %{assigns: %{paused: true}} = socket), do: {:noreply, socket}
</code></pre>
</details>
