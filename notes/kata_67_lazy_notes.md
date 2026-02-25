# Kata 67: Lazy Loading

## Goal
Defer the loading of expensive components to improve initial page load time.

## Core Concepts

### 1. Placeholder State
Initialize with `loaded: false`. Render a spinner or skeleton.

### 2. Async Work
In `mount` or `update`, kick off a task or send a message to self (`Process.send_after`) to simulate data fetching.
Once complete, set `loaded: true`.

## Implementation Details

1.  **State**: `loading` (bool), `loaded` (bool).
2.  **Event**: Button click triggers the async load flow.

## Tips
- Use `connected?(socket)` check to avoid doing expensive work on the initial dead render.

## Challenge
Simulate an **Error**. Add a 10% chance that the loading fails. If it fails, show a "Retry" button instead of the content.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># In handle_info:
if :rand.uniform(10) == 1 do
  # failure
else
  # success
end
</code></pre>
</details>
