# Kata 39: Star Rating

## Goal
Build a custom form control (Star Rating) that updates a hidden input field. This demonstrates how to build rich UI components that still play nicely with standard HTML forms.

## Core Concepts

### 1. Visual vs Value
The user interacts with Button elements (Star icons), but the *data* is sent via a `<input type="hidden" name="rating">`.

### 2. Interactive Feedback
Highlight stars up to the current rating.

## Implementation Details

1.  **State**: `rating` (Integer 1-5).
2.  **UI**: 5 Loop buttons.
    *   If index <= rating, render Filled Star.
    *   Else, render Empty Star.
3.  **Events**:
    *   `rate`: Sets the rating state.

## Tips
- Use CSS `:hover` on a parent container to create a "preview" effect where stars light up under the mouse (advanced CSS trick: `flex-direction: row-reverse`).

## Challenge
Add a **"Reset"** button to clear the rating back to 0.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("reset", _, socket) do
  {:noreply, assign(socket, rating: 0)}
end
</code></pre>
</details>
