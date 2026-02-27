# Kata 28: Helpers & Assigns

## Assigns

Assigns are the data pipeline from controllers/LiveViews to templates.

### Setting Assigns in Controllers

```elixir
def show(conn, %{"id" => id}) do
  product = Catalog.get_product!(id)
  render(conn, :show, product: product, page_title: product.name)
  # @product and @page_title available in template
end
```

### Setting Assigns in LiveView

```elixir
def mount(_params, _session, socket) do
  {:ok, assign(socket, count: 0, loading: false)}
end

def handle_event("increment", _, socket) do
  {:noreply, assign(socket, count: socket.assigns.count + 1)}
end
```

### Multiple Assigns

```elixir
assign(socket,
  products: products,
  page: page,
  total_pages: total_pages,
  loading: false
)
```

---

## Verified Routes (~p)

Compile-time checked paths:

```elixir
~p"/products"                    # "/products"
~p"/products/#{product}"         # "/products/42"
~p"/products?#{%{page: 2}}"     # "/products?page=2"
```

---

## Link Components

### Navigation Links

```heex
<%# Client-side navigation (LiveView): %>
<.link navigate={~p"/products"}>Products</.link>

<%# LiveView patch (same LiveView, new params): %>
<.link patch={~p"/products?#{%{page: 2}}"}>Page 2</.link>

<%# Full page navigation: %>
<.link href={~p"/products"}>Products</.link>
```

### Method Links (PUT, DELETE)

```heex
<.link href={~p"/logout"} method="delete">Log out</.link>
<.link href={~p"/products/#{@product}"} method="delete"
  data-confirm="Are you sure?">
  Delete
</.link>
```

---

## Page Title

### Static

```elixir
# In mount:
{:ok, assign(socket, page_title: "Products")}
```

### Dynamic

```elixir
# In handle_params:
def handle_params(%{"id" => id}, _uri, socket) do
  product = Catalog.get_product!(id)
  {:noreply, assign(socket, product: product, page_title: product.name)}
end
```

### In Root Layout

```heex
<.live_title>{assigns[:page_title] || "MyApp"}</.live_title>
```

---

## Key Takeaways

1. Assigns pass data from controllers/LiveViews to templates via `@name`
2. Use `~p"/path"` for compile-time verified routes
3. `<.link navigate={path}>` for client-side navigation
4. `<.link patch={path}>` for same-LiveView URL changes
5. `<.link method="delete">` for non-GET requests
6. Set `page_title` assign for dynamic browser tab titles
