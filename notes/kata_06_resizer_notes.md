# Kata 06: The Resizer

## Goal
Use state values to control the **dimensions** of an element dynamically. This reinforces the concept of property binding.

## Core Concepts

### 1. Binding Dimensions
Bind integer state values to CSS `width` and `height` properties via the `style` attribute.

```elixir
<div style={"width: #{@width}px; height: #{@height}px;"}></div>
```

### 2. Number Inputs
Use `<input type="number">` for precise integer control. This gives you native browser validation (min/max).

```html
<input type="number" name="width" value={@width} min="50" max="500" />
```

## Implementation Details

1.  **State**: Initialize `width` and `height` (e.g., 200px).
2.  **UI**:
    - Two number inputs (Width, Height).
    - A `div` acting as the resizable box.
    - CSS `transition` property on the box for smooth resizing effects.
3.  **Events**:
    - Handle the `phx-change` event from the form to update `width` and `height`.

## Tips
- Always include the unit (`px`) in your style string if the numbers are raw integers.
- Add `transition-all` in CSS to make the resize action feel animated and polished.

## Challenge
Add a **Max Limit**. Ensure that neither the width nor the height can exceed 500px, even if the user types a larger number.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("resize", %{"width" => w, "height" => h}, socket) do
  w = min(String.to_integer(w), 500)
  h = min(String.to_integer(h), 500)
  {:noreply, assign(socket, width: w, height: h)}
end</code></pre>
</details>
