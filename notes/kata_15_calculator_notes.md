# Kata 15: The Calculator

## Goal
Build a functional basic calculator. This challenges you to manage **interacting state** (accumulator, current operation, new entry flag) and implement a small state machine.

## Core Concepts

### 1. State Machine
A calculator has distinct modes:
- **Entering Number**: Appending digits to the display.
- **Operator Selected**: Getting ready to start a new number, while remembering the pending operation.
- **Calculated**: Result displayed, next keypress starts fresh.

### 2. Formatting
Converting between String (display) and Number (calculation) logic.
- Integers vs Floats differentiation.

## Implementation Details

1.  **State**:
    - `display`: String shown on screen ("0").
    - `acc`: Pending value (number or nil).
    - `op`: Pending operator string ("+", "-", etc).
    - `new_entry`: Boolean flag. If true, the next digit replaces the display instead of appending.
2.  **Events**:
    - `num`: Appends digit. Respects `new_entry` flag.
    - `op`: calculating pending result (if any), updates `acc`, sets `op`, sets `new_entry = true`.
    - `eval`: Calculates final result.

## Tips
- Simplicity first: evaluating strictly left-to-right (no order of operations) is acceptable for a basic calculator kata.

## Challenge
Add a **CE (Clear Entry)** button. It should clear only the current `display` (reset to "0") but keep the accumulated value (`acc`) and operation (`op`) intact.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("ce", _, socket) do
  {:noreply, assign(socket, display: "0", new_entry: true)}
end</code></pre>
</details>
