# Kata 41: Multi-Context Interactions

## Why Contexts Need to Talk

Real applications have multiple contexts that need to share data. An e-commerce order, for example, touches:

- **Accounts** — who is the user?
- **Catalog** — what product are they buying, and at what price?
- **Orders** — create the order and line items
- **Notifications** — send a confirmation email

These contexts each own their own data, but the order placement flow needs all of them.

---

## The Core Rules

### 1. Only call public API functions

```elixir
# GOOD — calling the public API
user = Accounts.get_user!(user_id)
product = Catalog.get_product!(product_id)

# BAD — bypassing the context boundary
user = Repo.get!(Accounts.User, user_id)        # imports internal schema
product = Repo.get!(Catalog.Product, product_id) # bypasses Catalog entirely
```

### 2. Dependencies flow one direction — no cycles

```
Web layer (controllers, LiveViews)
  └── calls: Accounts, Catalog, Orders, Notifications

Orders
  └── calls: Accounts (get_user!), Catalog (get_product!)

Catalog
  └── (foundational — calls nothing)

Accounts
  └── (foundational — calls nothing)

Notifications
  └── calls: Accounts (to get user email)
             (gets order data via PubSub, not by calling Orders)
```

If Orders calls Accounts and Accounts also called Orders, you have a circular dependency — a code smell that signals misplaced responsibilities.

### 3. Pass IDs across context calls, not opaque structs

```elixir
# Preferred: pass the ID, let the context load what it needs
Orders.place_order(user_id, product_id, quantity)

# Acceptable: pass a loaded struct (but watch for coupling)
# If Orders takes a %User{}, it now depends on User's shape
Orders.place_order(user, product, quantity)
```

---

## Calling Across Contexts

### From a controller

The controller is a natural coordinator — it has access to all contexts and orchestrates their calls:

```elixir
defmodule MyAppWeb.OrderController do
  alias MyApp.{Accounts, Catalog, Orders}

  def create(conn, %{"order" => params}) do
    user = conn.assigns.current_user
    product = Catalog.get_product!(params["product_id"])

    attrs = %{
      user_id: user.id,
      product_id: product.id,
      quantity: String.to_integer(params["quantity"]),
      unit_price: product.price
    }

    case Orders.place_order(attrs) do
      {:ok, order} ->
        conn |> put_flash(:info, "Order placed!") |> redirect(to: ~p"/orders/#{order.id}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset, product: product)
    end
  end
end
```

### From a context function

A context can also call another context's API when it needs external data to complete its logic:

```elixir
defmodule MyApp.Orders do
  alias MyApp.Catalog  # declared as a dependency

  def place_order(attrs) do
    # Validate the product exists before creating the order:
    product = Catalog.get_product!(attrs.product_id)

    unless product.available do
      {:error, :product_unavailable}
    else
      attrs_with_price = Map.put(attrs, :unit_price, product.price)
      %Order{}
      |> Order.changeset(attrs_with_price)
      |> Repo.insert()
    end
  end
end
```

`Orders` depends on `Catalog` — that's fine. `Catalog` does not depend on `Orders` — no cycle.

---

## Atomic Cross-Context Operations with Ecto.Multi

When two contexts must succeed or fail together — for example, creating an order AND decrementing inventory — use `Ecto.Multi`:

```elixir
def purchase(user_id, product_id, quantity) do
  product = Catalog.get_product!(product_id)

  Ecto.Multi.new()
  |> Ecto.Multi.insert(:order,
      Order.changeset(%Order{}, %{
        user_id: user_id,
        product_id: product_id,
        quantity: quantity,
        total: Decimal.mult(product.price, quantity)
      }))
  |> Ecto.Multi.update_all(:decrement_stock, fn %{order: order} ->
      from p in Catalog.Product,
        where: p.id == ^order.product_id,
        update: [inc: [stock: -^order.quantity]]
    end, [])
  |> Repo.transaction()
end

# Returns:
# {:ok, %{order: %Order{}, decrement_stock: {1, nil}}}
# {:error, :order, changeset, %{}}           (order insert failed)
# {:error, :decrement_stock, reason, changes} (stock update failed)
```

Both operations succeed or both roll back — no partial state.

---

## PubSub for Loose Coupling

When one context needs to trigger side effects in another, but you don't want a hard dependency, use `Phoenix.PubSub`:

### Broadcasting (in the triggering context)

```elixir
defmodule MyApp.Orders do
  def place_order(attrs) do
    case Repo.insert(Order.changeset(%Order{}, attrs)) do
      {:ok, order} = result ->
        # Broadcast — anyone subscribed reacts independently
        Phoenix.PubSub.broadcast(MyApp.PubSub, "orders", {:order_placed, order})
        result
      error ->
        error
    end
  end
end
```

### Subscribing (in the reacting context)

```elixir
defmodule MyApp.Notifications.Worker do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(state) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
    {:ok, state}
  end

  def handle_info({:order_placed, order}, state) do
    Notifications.send_order_confirmation(order)
    {:noreply, state}
  end
end
```

`Orders` never calls `Notifications`. `Notifications` subscribes independently. Adding analytics, audit logs, or other side effects doesn't touch `Orders` at all.

### Subscribing in a LiveView (real-time updates)

```elixir
defmodule MyAppWeb.OrderLive.Show do
  use MyAppWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order!(id)
    Phoenix.PubSub.subscribe(MyApp.PubSub, "orders:#{id}")
    {:ok, assign(socket, order: order)}
  end

  def handle_info({:order_status_changed, updated_order}, socket) do
    {:noreply, assign(socket, order: updated_order)}
  end
end
```

---

## When to Use Direct Calls vs PubSub

| Direct calls | PubSub |
|---|---|
| You need the result synchronously | Side effect, result not needed immediately |
| Failure should halt the operation | Failure should not halt the triggering operation |
| Required dependency (must succeed) | Optional reaction (can add/remove independently) |
| One consumer | Many consumers possible |

---

## Clean Boundary Design

### Dependency graph (what is acceptable)

```
Accounts  ←──  Orders  ←──  Web
Catalog   ←──  Orders
                        ←──  Web
Notifications  ←──(PubSub)──  Orders
               ←──  Web
```

Arrows point from dependent → dependency. No cycles.

### Warning signs

```elixir
# 1. Circular imports
defmodule MyApp.Accounts do
  alias MyApp.Orders   # bad if Orders also aliases Accounts
end

# 2. Importing another context's schema
defmodule MyApp.Orders do
  alias MyApp.Accounts.User   # leaks internal schema across boundary
  def orders_for(%User{} = user), do: ...
  # Better: def orders_for_user(user_id), do: ...
end

# 3. Calling Repo from the web layer
def index(conn, _params) do
  users = Repo.all(Accounts.User)   # bypasses the context entirely
end

# 4. A "catch-all" context
defmodule MyApp.Stuff do
  # users, products, orders, emails — all mixed together
end
```

### Resolving circular dependencies

If two contexts genuinely need each other's data:

**Option 1: PubSub** — break the cycle with events instead of direct calls.

**Option 2: Pass data as arguments** — instead of Context B calling Context A to get data, the coordinator passes the data to B:

```elixir
# Instead of Notifications calling Orders.get_order(id):
Notifications.send_confirmation(%{order: order, user: user})
# Notifications never calls Orders at all
```

**Option 3: Extract a shared context** — if both contexts need the same thing, maybe it belongs in a third, foundational context:

```elixir
defmodule MyApp.Core do
  # shared types, validators, lookup tables
end
```

---

## Key Takeaways

1. **Call public APIs** — never reach into another context's schemas or Repo
2. **One-directional dependencies** — Accounts and Catalog know nothing about Orders
3. **Web layer coordinates** — controllers and LiveViews often orchestrate calls to multiple contexts
4. **Ecto.Multi** keeps cross-context DB operations atomic
5. **PubSub decouples side effects** — broadcasts let many things react without tight coupling
6. **Pass IDs, not schemas** across context boundaries to avoid shape coupling
7. **No circular dependencies** — if you need one, extract shared logic to a third context or use PubSub
