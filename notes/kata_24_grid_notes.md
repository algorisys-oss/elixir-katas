# Kata 24: The Grid

## Goal
Implement a dynamic **CSS Grid** layout where user input controls the number of columns. This shows how to bind styles to state.

## Core Concepts

### 1. CSS Grid & Repeat
The `repeat(N, 1fr)` function is powerful for creating equal-width columns.
```css
grid-template-columns: repeat(3, minmax(0, 1fr));
```

### 2. Dynamic Style Binding
Inject the state variable directly into the style attribute.
```elixir
style={"grid-template-columns: repeat(#{@cols}, minmax(0, 1fr))"}
```

## Implementation Details

1.  **State**: `items`, `cols` (integer).
2.  **UI**:
    - Buttons to pick column count (1, 2, 3, 4).
    - A container div with `display: grid` and the dynamic style.
3.  **Events**:
    - `set_cols`: Updates the integer state.

## Tips
- `minmax(0, 1fr)` is often safer than just `1fr` to prevent grid blowouts when content (like long words) overflows.

## Challenge
Add buttons to control the **Gap** size: "Small" (4px), "Medium" (16px), "Large" (32px).

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># State: gap (e.g., "1rem" or class name if using Tailwind safelist, but inline style is easier for arbitrary values)
style={"...; gap: #{@gap}"}</code></pre>
</details>
