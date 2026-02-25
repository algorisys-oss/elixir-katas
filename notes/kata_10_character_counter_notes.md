# Kata 10: The Character Counter

## Goal
Create a text input that tracks character count, validates it against a limit, and provides real-time visual feedback.

## Core Concepts

### 1. Computed Checks
You don't need to store "is_error" in the state if it can be derived from existing data.
Calculate it in the render or a helper function:

```elixir
current_length = String.length(@text)
is_error = current_length > @limit
```

### 2. String.length/1
Elixir handles Unicode correctly. `String.length("José")` is 4, even though it might be more bytes.

## Implementation Details

1.  **State**: `text` ("") and `limit` (e.g., 100).
2.  **UI**:
    - A `<textarea>` bound to `@text`.
    - A counter display: `{String.length(@text)} / {@limit}`.
    - Conditional classes: turn the counter red if `length > limit`.
3.  **Events**:
    - `phx-change` or `phx-keyup` to update the text state on every keystroke.

## Tips
- Use a helper function (e.g., `count_class/2`) in your view to keep the HTML template clean if the logic gets complex (e.g., warning at 90%, error at 100%).

## Challenge
Count **Words** instead of characters.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Helper
def word_count(text) do
  text
  |> String.split(~r/\s+/, trim: true)
  |> length()
end

# Usage
{word_count(@text)} words</code></pre>
</details>
