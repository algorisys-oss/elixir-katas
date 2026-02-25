# Kata 34: Live Feedback (Blur vs Change)

## Goal
Improve user experience by controlling *when* errors are shown. Displaying "Invalid format" while the user is still typing the first character is annoying. Showing it on **Blur** (when leaving the field) is often better.

## Core Concepts

### 1. The `phx-blur` Binding
Fires an event when an input loses focus. We can use this to mark a field as "touched".

### 2. "Touched" State
We track a `MapSet` of field names that the user has visited.
- If a field is **Valid**: Show success immediately (optional).
- If a field is **Invalid**: Show error *only if* it has been touched.

## Implementation Details

1.  **State**: `touched` (MapSet).
2.  **Events**:
    *   `handle_event("blur", ...)`: Add field name to `touched`.
    *   `handle_event("validate", ...)`: Run validation logic but don't change `touched`. (Standard `phx-change`).

## Tips
- When the user hits "Submit", you should mark **all** fields as touched so that any remaining errors become visible.

## Challenge
Implement **Instant Fix Feedback**: If a field is currently showing an error (because it was touched), clear the error *immediately* as soon as the user starts typing valid data (on proper validation in `phx-change`), without waiting for another blur. (Note: The current implementation already mostly supports this via reactive updates, but explicitly try to ensure the error disappears instantly).

**Harder Challenge**: Add a "Reset Form" button that clears all data AND resets the `touched` state so no errors are shown.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("reset", _, socket) do
  {:noreply, assign(socket, form: ..., touched: MapSet.new())}
end
</code></pre>
</details>
