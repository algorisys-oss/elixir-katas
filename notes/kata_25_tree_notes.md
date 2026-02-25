# Kata 25: The Recursive Tree

## The Concept
This kata demonstrates how to render **hierarchical data** of arbitrary depth (like a file system) using **recursive functional components**. In many UI frameworks, recursion is a common pattern for trees, but in LiveView, it interacts uniquely with the process model and event targeting.

## The Elixir Way
In Object-Oriented systems, a tree node might be a stateful class instance. In Elixir/LiveView:
*   **Data is separated from UI**: The tree structure is just a List of Maps. It is immutable.
*   **State is minimal**: We don't modify the tree nodes to add `expanded: true`. Instead, we maintain a separate `MapSet` of expanded IDs. This keeps the "source of truth" (the data) pure and the UI state (expansion) ephemeral.
*   **Functional Components**: We use a stateless function component (`.tree_node`) that calls itself. It doesn't have its own process; it renders *inline* within the parent LiveComponent.

## Deep Dive

### 1. Recursive Logic in HEEx
The core logic relies on the component calling itself within its own template.
```elixir
def tree_node(assigns) do
  ~H"""
  <li>
    <!-- Content -->
    <%= if @expanded do %>
       <!-- Recursion -->
       <.tree_node :for={child <- @node.children} node={child} ... />
    <% end %>
  </li>
  """
end
```
**Key Technical Detail**: This recursion happens at **render time**. LiveView's diff tracking engine is smart enough to handle this, but deeply nested trees can produce large DOM patches if not careful.

### 2. The `myself` Targeting Issue
A critical aspect of LiveView is event targeting.
*   **LiveViews** handle events with `handle_event/3`.
*   **LiveComponents** handle events only if `phx-target={@myself}` is present.

**The Problem**: Function components (like `.tree_node`) are **stateless**. They do not use `myself`. They run inside the context of whoever called them.
**The Fix**: When a LiveComponent renders a recursive function component, the function component *loses access* to the parent LiveComponent's `@myself` assign unless specifically passed down.

```elixir
# In the LiveComponent
<.tree_node node={root} myself={@myself} />

# In the recursive function component
<.tree_node node={child} myself={@myself} />
```
Without passing `myself` recursively, the button deep inside the tree won't know which component to target, and the event will either crash or bubble up to the wrong place.

### 3. Efficient State with MapSet
We use `MapSet` for `expanded_ids` instead of a List.
*   **Lookup**: Checking `MapSet.member?` is **O(1)** (constant time).
*   **List**: Checking `Enum.member?` on a list is **O(n)** (linear time).
As the user expands hundreds of folders, `MapSet` ensures the UI remains snappy.

## Common Pitfalls

1.  **Infinite Recursion**: Always ensure your recursion has a base case. In a tree, the base case is implicit: `for child <- @node.children` naturally stops when `children` is empty.
2.  **Missing `phx-target`**: As demonstrated above, forgetting to pass `@myself` down the recursion chain is the #1 bug in nested LiveComponents.
3.  **State Pollution**: Avoid "decorating" your data (e.g., adding `expanded: true` to the database structs). It creates a sync nightmare. Keep UI state (expansions, selections) separate from Data state.

## Advanced Challenge
Try adding a "Select All" feature that traverses the entire tree structure to collect all IDs. You will need to write a recursive helper function in your Elixir module (not the template) to walk the nodes.
