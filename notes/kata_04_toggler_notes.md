# Kata 04: The Toggler

## Goal
Learn how to **conditionally render content** and apply **dynamic CSS classes** based on state. This is fundamental for UI interactivity like showing/hiding menus or highlighting active items.

## Core Concepts

### 1. Conditional Rendering
Use standard Elixir `if` expressions inside `{ }` blocks to show or hide HTML elements.

```elixir
{if @visible do}
  <div>I am visible!</div>
{else}
  <div>I am hidden.</div>
{end}
# Or using the special attribute syntax:
<div :if={@visible}>I am visible!</div>
```

### 2. Dynamic Classes
You can interpolate values into the `class` attribute.

```elixir
<div class={if @active, do: "bg-blue-500", else: "bg-gray-200"}>
```

A cleaner way for multiple classes is using a list:

```elixir
class={["base-class", @active && "active-class"]}
```

## Implementation Details

1.  **State**: Initialize `show_details` (boolean) and `is_active` (boolean).
2.  **UI**:
    - A button to toggle a "Secrets" section.
    - A card that changes execution styling (color/border) when active.
3.  **Events**:
    - `handle_event` to toggle the boolean states (`!value`).

## Tips
- The `:if` attribute (HEEx shortcut) is often cleaner than wrapping blocks in `{if ...} ... {end}`.

## Challenge
Add a "Self Destruct" button. When clicked, the button itself should disappear from the UI.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># In mount
assign(socket, alive: true)

# In render
&lt;button :if={@alive} phx-click="destruct"&gt;Self Destruct&lt;/button&gt;

# In module
def handle_event("destruct", _, socket) do
  {:noreply, assign(socket, alive: false)}
end</code></pre>
</details>
