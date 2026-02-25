# Kata 50: The Component System

## The Concept
**Composition**. Breaking complex UIs into small, reusable LEGO bricks.
Phoenix 1.7 introduced a unified "Function Component" system that uses normal Elixir functions and declarative definitions (`attr`/`slot`).

## The Elixir Way
*   **Pure Functions**: A component is just `f(assigns) -> ~H"..."`.
*   **Declarative Interface**: The `attr` and `slot` macros serve as compile-time documentation AND validation. If you pass a string where an integer is required, the compiler warns you.

## Deep Dive

### 1. The HEEx Syntax
Calling a function component uses the dot syntax: `<.button />`.
*   **Local**: Defined in the same module (`defp button`).
*   **Remote**: Defined in another module (`<Core.button />`).
This distinguishes them from standard HTML tags (`<button>`) and LiveComponents (`<.live_component>`).

### 2. `attr` Macro
```elixir
attr :variant, :string, default: "primary", values: ["primary", "secondary"]
```
*   **Safety**: Validates types and allowed values.
*   **Docs**: Generates documentation automatically.
*   **Defaults**: Reduces boilerplate code (no more `assign_new`).

### 3. `slot` Macro
Slots are sections of content passed from the parent.
*   **Default Slot**: `<.btn>Click Me</.btn>`. The text "Click Me" is assigned to `@inner_block`.
*   **Named Slots**: `<.modal><:header>Title</:header> ...`.
*   **Slot Assigns**: You can pass data *back* to the slot: `<:col :let={item}>`.

## Common Pitfalls

1.  **Block vs Inline**: HEEx is strict about HTML validity. You cannot put a `<div>` inside a `<p>`.
2.  **Required Slots**: If you mark a slot `required: true`, the call site fails compilation if it's missing.
3.  **Global Attributes**: Use `attr :rest, :global` to allow standard HTML attributes (`class`, `id`, `phx-click`) to passthrough. Always output them with `{@rest}`.
