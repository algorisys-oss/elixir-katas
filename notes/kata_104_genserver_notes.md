# Kata 104: GenServer Job Queue

## Goal
Manage a background job queue using a dedicated GenServer process, with real-time updates via PubSub.

## Core Concepts

### 1. GenServer as Source of Truth
The `JobQueue` GenServer holds the state (jobs list).
The LiveView is just a client that sends commands (`add_job`, `cancel_job`) and listens for events.

### 2. Process Isolation
If the LiveView crashes (e.g., user refreshes), the GenServer stays alive, and the jobs continue processing.

## Implementation Details

1.  **Commands**: `JobQueue.add_job(name, duration)`.
2.  **Events**: `{:queue_updated, status}` broadcasted to `@topic`.

## Tips
- Using `Process.send_after` inside the GenServer handles the "processing" delay.

## Challenge
**Pause/Resume Queue**.
Add a `paused` state to the GenServer.
When paused, no *new* jobs should start processing (pending jobs stay pending). Existing processing jobs continue.
Add a "Pause" / "Resume" button in the UI.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># GenServer: handle_call(:toggle_pause, ...)
# Logic: in `schedule_next_job`, check if paused.
</code></pre>
</details>
