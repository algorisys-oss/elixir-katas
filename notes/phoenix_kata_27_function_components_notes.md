# Kata 27: Function Components

## What is a Function Component?

A function component is a reusable UI piece defined as an Elixir function that returns HEEx markup. They accept **attributes** and **slots** — like HTML elements with custom behavior.

```elixir
def button(assigns) do
  ~H"""
  <button class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
    {@label}
  </button>
  """
end
```

Usage: `<.button label="Click me" />`

---

## Defining Attributes with `attr`

```elixir
attr :label, :string, required: true
attr :variant, :string, default: "primary", values: ["primary", "secondary", "danger"]
attr :disabled, :boolean, default: false
attr :rest, :global  # Catches any extra attributes

def button(assigns) do
  ~H"""
  <button
    class={["px-4 py-2 rounded font-medium", variant_class(@variant)]}
    disabled={@disabled}
    {@rest}
  >
    {@label}
  </button>
  """
end
```

### Attribute Types

| Type | Example |
|------|---------|
| `:string` | `"hello"` |
| `:integer` | `42` |
| `:float` | `3.14` |
| `:boolean` | `true` / `false` |
| `:atom` | `:info` |
| `:list` | `[1, 2, 3]` |
| `:map` | `%{key: "value"}` |
| `:any` | Anything |
| `:global` | Catch-all for extra attrs |

---

## Slots

Slots let you pass content blocks into components:

### Default Slot

```elixir
slot :inner_block, required: true

def card(assigns) do
  ~H"""
  <div class="p-4 rounded-lg border bg-white shadow">
    {render_slot(@inner_block)}
  </div>
  """
end
```

Usage:
```heex
<.card>
  <h2>Card Title</h2>
  <p>Card content here.</p>
</.card>
```

### Named Slots

```elixir
slot :title, required: true
slot :actions
slot :inner_block, required: true

def card(assigns) do
  ~H"""
  <div class="rounded-lg border bg-white shadow">
    <div class="px-4 py-3 border-b flex items-center justify-between">
      <h3 class="font-semibold">{render_slot(@title)}</h3>
      <div :if={@actions != []}>{render_slot(@actions)}</div>
    </div>
    <div class="p-4">
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end
```

Usage:
```heex
<.card>
  <:title>Product Details</:title>
  <:actions>
    <button>Edit</button>
  </:actions>

  <p>Product description here.</p>
</.card>
```

---

## Component Composition

Components can use other components:

```elixir
def page_header(assigns) do
  ~H"""
  <div class="mb-6">
    <h1 class="text-2xl font-bold">{@title}</h1>
    <p :if={@subtitle} class="text-gray-500">{@subtitle}</p>
  </div>
  """
end

def product_page(assigns) do
  ~H"""
  <.page_header title="Products" subtitle="Browse our catalog" />
  <.card :for={product <- @products}>
    <:title>{product.name}</:title>
    <p>{product.description}</p>
  </.card>
  """
end
```

---

## Remote Components

Use components from other modules:

```heex
<%# Same module — dot prefix: %>
<.button label="Click" />

<%# From another module — full module path: %>
<MyAppWeb.CoreComponents.button label="Click" />

<%# With import: %>
<%# import MyAppWeb.CoreComponents %>
<.button label="Click" />
```

---

## Key Takeaways

1. Function components are **functions** that return HEEx markup
2. Use `attr` to declare **typed attributes** with defaults and validations
3. Use `slot` for **content blocks** (inner_block for default, named for specific areas)
4. `render_slot(@slot_name)` renders slot content
5. `:global` catches extra attributes for pass-through
6. Components compose — use components inside other components
7. Call with `<.name />` (same module) or `<Module.name />` (remote)
