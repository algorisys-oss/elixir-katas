# Kata 07: The Spoiler

## Goal
Create a component that **obscures content** until specifically requested by the user. This demonstrates toggling UI states without removing elements from the DOM.

## Core Concepts

### 1. Conditional Classes (The Blur)
Instead of removing the content (like variables), we often want to keep it but hide it visually. We can swap CSS classes based on state.

```elixir
class={if @visible, do: "", else: "blur-md select-none"}
```

### 2. Event Toggling
A simple boolean toggle manages the state.

```elixir
def handle_event("toggle", _, socket) do
  {:noreply, update(socket, :visible, &(!&1))}
end
```

## Implementation Details

1.  **State**: Initialize `visible` to `false`.
2.  **UI**:
    - A container with text content.
    - Apply a blur filter class when `visible` is false.
    - An overlay button ("Reveal Spoiler") that is only shown when hidden.
3.  **Events**:
    - Clicking the overlay toggles `visible` to `true`.
    - (Optional) A button to "Hide" it again.

## Tips
- `select-none` (user-select: none) is important! Otherwise, users could still copy the blurred text.
- `backdrop-blur` can be used on the overlay for a nice glassmorphism effect.

## Challenge
Reveal the spoiler on **Hover** (MouseEnter) instead of Click.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># In render
&lt;div phx-mouseenter="reveal" phx-mouseleave="hide"&gt;...&lt;/div&gt;

# In module
def handle_event("reveal", _, socket), do: {:noreply, assign(socket, visible: true)}
def handle_event("hide", _, socket), do: {:noreply, assign(socket, visible: false)}
</code></pre>
</details>
