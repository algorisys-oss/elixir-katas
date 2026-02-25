# Kata 14: Keybindings

## Goal
Implement **global keyboard shortcuts** that work regardless of where the focus is on the page.

## Core Concepts

### 1. Window Binding
Attach the event listener to the window object using `phx-window-keydown`. This captures key presses anywhere in the browser tab.

```html
<div phx-window-keydown="handle_key">...</div>
```

### 2. Pattern Matching Keys
Match specific keys in your event handler to perform actions.

```elixir
def handle_event("handle_key", %{"key" => "Escape"}, socket) do
  {:noreply, assign(socket, modal_open: false)}
end
```

## Implementation Details

1.  **State**: A counter or tracker to demonstrate the effect.
2.  **UI**: Visual feedback of the last key pressed.
3.  **Events**:
    - `handle_event` matching on specific keys like "j" (down), "k" (up).
    - A catch-all clause (`_`) to handle other keys gracefully without crashing.

## Tips
- Be careful not to override essential browser shortcuts (like Ctrl+P).
- This is the standard way to implement power-user navigation (e.g., Gmail shortcuts).

## Challenge
Detect **Shift+K** vs **k**. (In `phx-window-keydown`, the key value comes as "K" if Shift is held, or check metadata).

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("keydown", %{"key" => key}, socket) do
  case key do
    "K" -> ... # Shift is held (uppercase)
    "k" -> ... # Lowercase
  end
end</code></pre>
</details>
