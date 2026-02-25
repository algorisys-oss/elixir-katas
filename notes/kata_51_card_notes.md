# Kata 51: The Card Component

## The Concept
A **Card** is the archetypal "Container Component". It often has distinct sections: Header, Body, Footer.
This kata teaches **Named Slots**, allowing flexible content injection into specific layout zones.

## The Elixir Way
We define the structure once, and let the consumer fill the holes.
```elixir
<.card>
  <:header>Welcome</:header>
  This is the body.
  <:footer>Read more</:footer>
</.card>
```

## Deep Dive

### 1. Structuring Slots
Inside the component, slots are Lists of Maps.
*   `@inner_block`: List of default content pieces.
*   `@header`: List of header pieces.
Even if you only pass one header, it is a list `[%{inner_block: ...}]`.
Standard rendering: `<%= render_slot(@header) %>`.

### 2. Conditional Containers
If the user *doesn't* provide a footer, we shouldn't render the `div` wrapper (which might have padding/border).
```elixir
<%= if @footer != [] do %>
  <div class="border-t p-4">
    <%= render_slot(@footer) %>
  </div>
<% end %>
```
This keeps the UI clean.

### 3. Slot Attributes (props)
Slots can take attributes too!
```elixir
slot :header do
  attr :class, :string
end
```
Usage: `<:header class="bg-red-500">...`.

## Common Pitfalls

1.  **Multiple Entries**: By default, slots capture *all* entries.
    ```elixir
    <:action>Edit</:action>
    <:action>Delete</:action>
    ```
    If you `render_slot(@action)`, both buttons appear. This is a feature, not a bug, but be aware of it.
2.  **Context**: The content inside the slot renders in the **Parent's** context. It can access `@parent_assigns` but not the private assigns of the card component itself.
