# Kata 52: The Button Component

## The Concept
The most used component in any system. It must handle **Design Tokens** (primary/secondary colors) and **Behavior** (loading, disabled).

## The Elixir Way
*   **Centralized Styles**: We don't sprinkle `bg-blue-500` everywhere. We define `variant="primary"` and map it to classes in one place.
*   **Rest Attributes**: `attr :rest` enables the button to accept *any* standard HTML attribute (`phx-click`, `form`, `type`, `data-id`) without extra work.

## Deep Dive

### 1. `attr :rest, :global`
This is magic.
```elixir
attr :rest, :global
...
<button {@rest}>
```
It collects everything else passed to the component tag and splats it onto the HTML element.
**Note**: You can specify `include: ~w(disabled form)` to restrict what is allowed, but usually `:global` is best for flexibility.

### 2. Loading Mechanics
A good button handles its own "busy" state.
```elixir
attr :loading, :boolean, default: false
...
<button class={[..., @loading && "opacity-50"]} disabled={@loading} ...>
  <%= if @loading, do: "Processing...", else: render_slot(@inner_block) %>
</button>
```
This prevents double-submission bugs automatically.

### 3. Merging Classes
When passing `class="mt-4"`, you want it to *merge* with the button's base classes, not replace them.
`Phoenix.Component.to_class` (or simple interpolation) handles this. The `{@rest}` attribute handles `class` merging intelligently in newer Phoenix versions.

## Common Pitfalls

1.  **Icon Alignment**: Centering text `Processing...` next to a spinner requires Flexbox (`flex items-center gap-2`).
2.  **Type="button"**: By default, `<button>` inside a form acts as a Submit button. Always explicitly set `type="button"` for non-submit actions to avoid accidental form submission.
