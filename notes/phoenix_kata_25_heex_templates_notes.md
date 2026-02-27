# Kata 25: HEEx Templates

## What is HEEx?

HEEx (HTML + Embedded Elixir) is Phoenix's template engine. It combines HTML with Elixir code, providing:

- **Compile-time validation** of HTML structure
- **Automatic XSS protection** (all expressions are escaped)
- **Component support** with attributes and slots

---

## Expressions

### Output Expression: `{expression}`

```heex
<h1>{@product.name}</h1>
<p>Price: ${@product.price}</p>
<span>{String.upcase(@user.name)}</span>
```

Expressions are **automatically HTML-escaped**. `<script>` in data becomes `&lt;script&gt;`.

### The `@` Shorthand

`@name` is shorthand for `assigns.name`:

```heex
<p>{@title}</p>
<!-- Same as: {assigns.title} -->
```

---

## Conditionals

### if/else

```heex
<%= if @logged_in do %>
  <p>Welcome, {@user.name}!</p>
<% else %>
  <p>Please <a href="/login">log in</a>.</p>
<% end %>
```

### Case

```heex
<%= case @role do %>
  <% :admin -> %>
    <span class="badge-red">Admin</span>
  <% :user -> %>
    <span class="badge-blue">User</span>
  <% _ -> %>
    <span class="badge-gray">Guest</span>
<% end %>
```

---

## Loops

### for

```heex
<ul>
  <%= for product <- @products do %>
    <li>{product.name} - ${product.price}</li>
  <% end %>
</ul>
```

### :for (attribute syntax — preferred)

```heex
<ul>
  <li :for={product <- @products}>
    {product.name} - ${product.price}
  </li>
</ul>
```

The `:for` attribute is cleaner and is the preferred style in Phoenix.

---

## Conditional Attributes

### :if

```heex
<div :if={@show_sidebar} class="sidebar">
  Sidebar content
</div>
```

Renders the element only if the condition is true. Equivalent to wrapping in `<%= if ... %>`.

### Dynamic CSS Classes

```heex
<div class={[
  "base-class",
  @active && "bg-blue-500",
  @disabled && "opacity-50 cursor-not-allowed"
]}>
  Content
</div>
```

`false` and `nil` values are filtered out. Only truthy values are included.

---

## Attributes

### Static Attributes

```heex
<input type="text" name="query" placeholder="Search..." />
```

### Dynamic Attributes

```heex
<input type="text" name={@field_name} value={@value} />
<a href={~p"/products/#{@product}"}>View</a>
```

### Boolean Attributes

```heex
<input type="checkbox" checked={@is_checked} />
<button disabled={@loading}>Submit</button>
```

If the value is `false` or `nil`, the attribute is omitted entirely.

### Spreading Attributes

```heex
<input {@rest} />
```

Where `@rest` is a keyword list or map of attributes.

---

## Raw HTML (Dangerous)

If you truly need unescaped HTML:

```heex
{raw(@html_content)}
```

**Warning**: Only use with trusted content. Never use with user input — XSS risk!

---

## `<%= %>` vs `{ }`

| Syntax | Purpose |
|--------|---------|
| `{expr}` | Output in attributes and text |
| `<%= expr %>` | Block expressions (if, for, case) |
| `<% expr %>` | Non-output expressions (else, end, ->) |

In modern Phoenix, prefer `{}` for simple outputs and `:for`/`:if` attributes for control flow.

---

## Key Takeaways

1. **HEEx** = HTML + Embedded Elixir with compile-time validation
2. `{@variable}` outputs escaped content (XSS-safe by default)
3. Use `:for` and `:if` attributes instead of `<%= for/if %>` blocks
4. Dynamic classes use lists: `class={["base", condition && "extra"]}`
5. Boolean attributes are auto-handled: `disabled={@loading}`
6. All expressions are **HTML-escaped** by default — use `raw/1` only with trusted content
7. `@name` is shorthand for `assigns.name`
