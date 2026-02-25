# Kata 94: Audio Player

## Goal
Control an HTML5 `<audio>` element with custom LiveView buttons.

## Core Concepts

### 1. Hook: `AudioPlayer`
- Listens for `play` / `pause` server events -> calls `audio.play()`.
- Listens for `timeupdate` JS event -> pushes `progress` to server (debounce heavily!).

## Implementation Details

1.  **State**: `is_playing`, `current_time`.
2.  **Events**: Toggle playback.

## Tips
- Updating `current_time` from server every second via WebSocket is overkill and choppy. Update a CSS variable or use client-side animation for the progress bar, only syncing play/pause state.

## Challenge
Implement **Volume Control**.
Add a range input `<input type="range" min="0" max="1">`.
On change, push event `set_volume`. Hook sets `audio.volume`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Server: push_event("volume", %{level: val})
# Client Hook: this.audio.volume = e.level
</code></pre>
</details>
