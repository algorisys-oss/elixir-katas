# Kata 31: Dependent Inputs

## The Concept
This kata explores **Dependent Validation**: when changing one form input (Parent) drastically alters the available options or state of another input (Child). A classic example is Country -> City selection.

## The Elixir Way
In client-side frameworks (React/Vue), you often wire `onChange` handlers to local state variables.
In LiveView, **the Server is the Source of Truth**. Even UI interactions like "picking a country" go to the server, which recalculates the state and pushes down the specific DOM patch (the new list of cities).
*   **Latency**: LiveView is optimized to make this round-trip feel instant (ms latency).
*   **Safety**: Validation logic lives in one place (the server), so you can't bypass business rules.

## Deep Dive

### 1. The `_target` Parameter
When a form sends a `change` event, LiveView includes a special `_target` parameter in the payload. This tells you exactly which input triggered the event.

```elixir
def handle_event("validate", %{"_target" => ["country"], "country" => country} = params, socket) do
  # Code that runs ONLY when Country changes
end
```
**Why this matters**: A generic `validate` handler runs on *every* keystroke or change. If you have expensive logic (like fetching cities from a DB), you only want to run it when the relevant input changes, not when the user is typing their name.

### 2. State synchronization
When the Country changes, two things must happen atomically:
1.  **Load Data**: The `cities` list must update.
2.  **Reset Child**: The `city` selection must be cleared (because "Paris" is not in "USA").

If you forget step 2, the UI might show "USA" selected but the value remaining as "Paris", creating an invalid state.

### 3. The "Disabled" Attribute
Logic for disabling inputs should be explicit in your assigns (`@city_disabled`), calculated from the data.
*   **Bad**: `<select disabled={@form[:country].value == ""}>`. This relies on the form struct which can be complex.
*   **Good**: `<select disabled={@city_disabled}>`. This is a derived state calculated in your update function. It is testable and explicit.

## Common Pitfalls

1.  **Race Conditions**: If you use a generic handler without `_target`, typing in a different field might accidentally reset your dependent fields if your logic is flawed.
2.  **Missing `phx-target`**: If this form lives in a Component, forgetting `phx-target={@myself}` sends the event to the parent LiveView, which will likely ignore it or crash.
3.  **Form Library Quirks**: `Phoenix.HTML.Form` and `to_form` can be tricky. Always inspect your `@form` params to see exactly what string/atom keys are being passed.
