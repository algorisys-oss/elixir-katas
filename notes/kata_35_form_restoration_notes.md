# Kata 35: Form Restoration

## Goal
Demonstrate LiveView's ability to automatically restore form input values when the server process crashes and the client reconnects. This is a key resilience feature.

## Core Concepts

### 1. Recovery
When a LiveView crashes, the JavaScript client attempts to reconnect. Upon reconnection, it re-sends the last known state of the form inputs to the new server process via the `phx-change` event.

### 2. Ephemeral Process State
Any state in `socket.assigns` that *wasn't* in the form form inputs is lost on crash (unless stored elsewhere). However, the text inside the inputs is preserved by the browser and re-synced.

## Implementation Details

1.  **State**: A simple text area for an "Essay".
2.  **Crash Mechanism**: A button that raises an exception to kill the process.
3.  **Observation**: Type text -> Crash -> Observe that text remains (restored).

## Tips
- This behavior relies on the form having a `phx-change` binding.
- It protects users from losing long form entries due to server deployments or transient bugs.

## Challenge
Add a second input field called **"Title"**. Verify that it also restores correctly after a crash.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># 1. Add <input name="title" ... /> to the form.
# 2. Update initial state and to_form map.
# 3. Crash and verify.
</code></pre>
</details>
