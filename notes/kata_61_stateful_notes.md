# Kata 61: Stateful Components

## The Concept
A **LiveComponent** can have its own isolated state (`@count`) that is independent of the parent LiveView.
This allows for encapsulated logic (like a self-contained Counter or Form).

## The Elixir Way
*   **PID**: Returns the *same* PID as the parent LiveView. It runs in the same process.
*   **State**: Stored in the component's own socket struct, separate from the parent's assigns.
*   **Lifecycle**: Init -> Update -> Render. `handle_event` stays inside the component if `phx-target={@myself}` is used.

## Deep Dive

### 1. `update(assigns, socket)`
This callback is the "constructor" and "updater" rolled into one.
It runs:
1.  On initial mount.
2.  Whenever the parent changes the attributes passed to the component (`<.live_component id="x" count={@count} />`).
3.  When `send_update` is called.

### 2. ID is Mandatory
Stateful components **must** have an `:id`.
This ID allows LiveView to find the component state in memory when an event arrives.

### 3. Cost of State
While convenient, stateful components add memory overhead tracking diffs for each ID.
Use **Function Components** (stateless) by default. Use **LiveComponents** (stateful) only when you need:
*   `handle_event` (self-managed events).
*   `mount`/`update` (data fetching on init).
*   `check_errors` (form recovery).

## Common Pitfalls

1.  **Missing ID**: LiveView will raise an error if you define a `render` function but forget to pass `id` when calling `live_component`.
2.  **Parent Communication**: The component cannot simple `assign(socket, parent_val: 1)`. Use `send(self(), {:updated, 1})` to talk to the parent (since `self()` is the same process).
