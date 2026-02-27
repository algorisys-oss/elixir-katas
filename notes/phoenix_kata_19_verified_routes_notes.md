# Kata 19: Verified Routes

## The Problem: Broken Links

With string-based paths, typos cause **runtime 404s** that are hard to catch:

```elixir
# Typo! Should be "/products" — but compiles fine
redirect(conn, to: "/prodcuts/#{product.id}")

# Discovered only when a user clicks the link...
```

---

## The Solution: ~p Sigil

Phoenix's **verified routes** check paths at **compile time**:

```elixir
# If /products/:id doesn't exist in the router → compile error!
redirect(conn, to: ~p"/products/#{product}")
```

The `~p` sigil:
1. Checks the path exists in your router
2. Checks it has the right number of parameters
3. Raises a **compile-time error** for any mismatch

---

## How to Use ~p

### In Controllers

```elixir
def create(conn, %{"product" => params}) do
  case Catalog.create_product(params) do
    {:ok, product} ->
      conn
      |> put_flash(:info, "Created!")
      |> redirect(to: ~p"/products/#{product}")

    {:error, changeset} ->
      render(conn, :new, changeset: changeset)
  end
end
```

### In Templates (HEEx)

```heex
<.link navigate={~p"/products"}>All Products</.link>

<.link navigate={~p"/products/#{@product}"}>
  View Product
</.link>

<.link navigate={~p"/products/#{@product}/edit"}>
  Edit
</.link>
```

### In LiveView

```elixir
def handle_event("go_to_product", %{"id" => id}, socket) do
  {:noreply, push_navigate(socket, to: ~p"/products/#{id}")}
end
```

---

## ~p vs String Paths

| Feature | String path | Verified (~p) |
|---------|-------------|---------------|
| Compile check | No | Yes |
| Typo detection | Runtime 404 | Compile error |
| Param count | Not checked | Checked |
| Refactor safety | Manual search | Compiler tells you |

### What Gets Caught

```elixir
# Router has:
get "/products/:id", ProductController, :show

# These would cause COMPILE errors:
~p"/prodcuts/#{id}"        # Typo in path
~p"/products"              # Missing required :id param (when needed)
~p"/nonexistent/#{id}"     # Route doesn't exist
```

---

## How It Works Under the Hood

1. When you write `~p"/products/#{product}"`, the compiler:
   - Looks up `/products/:id` in your router
   - Verifies it exists
   - Compiles it to a simple string concatenation

2. At runtime, `~p"/products/#{product}"` becomes just `"/products/42"` — zero overhead.

3. The verification happens via the `Phoenix.VerifiedRoutes` module, which is imported in your web module.

---

## Setup

Verified routes are automatically set up in new Phoenix projects:

```elixir
# In lib/my_app_web.ex:
defp html_helpers do
  quote do
    use Phoenix.VerifiedRoutes,
      endpoint: MyAppWeb.Endpoint,
      router: MyAppWeb.Router,
      statics: MyAppWeb.static_paths()
  end
end
```

This makes `~p` available in controllers, views, and templates.

---

## Static Assets

`~p` also works with static assets (CSS, JS, images):

```heex
<link rel="stylesheet" href={~p"/assets/app.css"} />
<script src={~p"/assets/app.js"}></script>
<img src={~p"/images/logo.png"} />
```

For static files, `~p` adds a **cache-busting hash** in production:
```
/assets/app-ABC123.css
```

This ensures browsers load the latest version after deploys.

---

## Query Parameters

Add query params with a map:

```elixir
~p"/products?#{%{page: 2, sort: "name"}}"
# → "/products?page=2&sort=name"

~p"/products/#{product}?#{%{tab: "reviews"}}"
# → "/products/42?tab=reviews"
```

---

## Migrating from Path Helpers

### Old Style (Deprecated)

```elixir
# Path helpers — still work but deprecated:
product_path(conn, :index)           # "/products"
product_path(conn, :show, 42)        # "/products/42"
product_path(conn, :show, 42, tab: "reviews") # "/products/42?tab=reviews"
```

### New Style (Verified Routes)

```elixir
# Verified routes — preferred:
~p"/products"                        # "/products"
~p"/products/#{product}"             # "/products/42"
~p"/products/#{product}?#{%{tab: "reviews"}}" # "/products/42?tab=reviews"
```

---

## Key Takeaways

1. `~p"/path"` provides **compile-time verification** of route paths
2. Catches typos, missing params, and nonexistent routes **before deployment**
3. Zero runtime overhead — compiles to simple string concatenation
4. Works in controllers, templates, LiveViews, and for static assets
5. Adds **cache-busting hashes** for static files in production
6. Replaces the older `*_path` helper functions
7. Use `?#{%{key: value}}` for query parameters
