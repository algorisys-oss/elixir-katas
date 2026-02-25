# Kata 37: Multi-Step Wizard

## Goal
Build a **Wizard** (stepper) that breaks a complex form into multiple steps, accumulating data along the way before a final submission.

## Core Concepts

### 1. Step State
Track `current_step` (integer) in the socket. Render different content blocks based on this index.

### 2. Accumulating Data
Store the "Master Data" in a separate assign (`wizard_data`) effectively merging params from each step as the user proceeds.

## Implementation Details

1.  **State**: `current_step`, `wizard_data`, and separate `changesets` or `forms` for each step if needed.
2.  **Events**:
    *   `next_step`: Merge current step params into `wizard_data` and increment `current_step`.
    *   `prev_step`: Decrement `current_step`.
    *   `save`: Final submission of `wizard_data`.

## Tips
- Using a `case` statement in the `render` function is the cleanest way to handle step switching.
- Ensure you validate the current step's data before allowing `next_step`.

## Challenge
Add a **"Start Over"** button on the final Review step that resets everything (step to 1, data to empty).

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("start_over", _, socket) do
  {:noreply, 
   socket
   |> assign(current_step: 1)
   |> assign(wizard_data: %{})
   |> assign(step1_form: to_form(%{}))} # Reset forms too
end
</code></pre>
</details>
