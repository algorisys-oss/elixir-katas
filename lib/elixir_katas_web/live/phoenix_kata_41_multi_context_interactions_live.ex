defmodule ElixirKatasWeb.PhoenixKata41MultiContextInteractionsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Cross-context interactions: call public APIs, keep deps one-directional

    # Orders context calls Accounts and Catalog public APIs:
    defmodule MyApp.Orders do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Orders.{Order, LineItem}
      alias MyApp.Catalog   # controlled dependency

      def place_order(user_id, items) when is_list(items) do
        enriched_items =
          Enum.map(items, fn %{product_id: pid, quantity: qty} ->
            product = Catalog.get_product!(pid)
            %{product_id: pid, quantity: qty,
              unit_price: product.price, name: product.name}
          end)

        total =
          Enum.reduce(enriched_items, Decimal.new(0), fn item, acc ->
            Decimal.add(acc, Decimal.mult(item.unit_price, item.quantity))
          end)

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:order,
            Order.changeset(%Order{}, %{
              user_id: user_id, total: total, status: :pending
            }))
        |> Ecto.Multi.run(:line_items, fn _repo, %{order: order} ->
            results =
              Enum.map(enriched_items, fn attrs ->
                %LineItem{}
                |> LineItem.changeset(Map.put(attrs, :order_id, order.id))
                |> Repo.insert()
              end)
            if Enum.all?(results, fn {s, _} -> s == :ok end) do
              {:ok, Enum.map(results, fn {:ok, li} -> li end)}
            else
              {:error, :line_item_failed}
            end
          end)
        |> Repo.transaction()
        |> case do
            {:ok, %{order: order}} ->
              # Broadcast event — loose coupling via PubSub:
              Phoenix.PubSub.broadcast(MyApp.PubSub, "orders", {:order_placed, order})
              {:ok, order}
            {:error, :order, changeset, _} ->
              {:error, changeset}
          end
      end
    end

    # PubSub for loose coupling (side effects without hard deps):
    # Orders broadcasts; Notifications subscribes independently.
    defmodule MyApp.Notifications.Worker do
      use GenServer

      def init(state) do
        Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
        {:ok, state}
      end

      def handle_info({:order_placed, order}, state) do
        Notifications.send_order_confirmation(order)
        {:noreply, state}
      end
    end

    # Rules:
    # 1. Only call public context functions, never another context's Repo/schemas
    # 2. Dependencies flow ONE way — no circular deps
    # 3. Pass IDs or plain values across boundaries
    # 4. Use PubSub for optional side effects (email, analytics, audit)
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "problem")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Multi-Context Interactions</h2>
      <p class="text-gray-600 dark:text-gray-300">
        How contexts talk to each other: calling across boundaries, coordinating data flow,
        and keeping context dependencies clean and one-directional.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "calling", "events", "boundaries", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-400 border-b-2 border-indigo-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["problem", "solution", "rules"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-indigo-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 border border-indigo-200 dark:border-indigo-800">
              <p class="text-sm font-semibold text-indigo-700 dark:text-indigo-300 mb-1">Call the Public API</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">One context calls another's public functions, never its schemas or internal modules.</p>
            </div>
            <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800">
              <p class="text-sm font-semibold text-teal-700 dark:text-teal-300 mb-1">One Direction</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Dependencies flow one way. A depends on B, but B never depends on A. No cycles.</p>
            </div>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Shared Data by ID</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Pass IDs or plain values across context boundaries, not opaque structs from the other context.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Calling across contexts -->
      <%= if @active_tab == "calling" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Contexts commonly need data from each other. The right way: call the public API of the other context.
            The wrong way: import the other context's schemas or call its Repo directly.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{calling_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">From a controller</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{controller_multi_ctx_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">From a context</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{context_calls_context_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Atomic cross-context operations with Ecto.Multi</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{atomic_cross_ctx_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Events and side effects -->
      <%= if @active_tab == "events" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            When Context A needs to notify Context B about something without creating a hard dependency,
            use Phoenix.PubSub to broadcast events.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{events_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Broadcasting</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{pubsub_broadcast_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Subscribing</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{pubsub_subscribe_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
            <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">When to use PubSub vs direct calls</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{pubsub_vs_direct_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Keeping boundaries clean -->
      <%= if @active_tab == "boundaries" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Good boundary design prevents tangled dependencies. Think carefully about what each context should own.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{boundaries_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Clean dependency graph</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{clean_deps_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <p class="text-sm font-semibold text-red-700 dark:text-red-300 mb-2">Warning signs</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{warning_signs_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Resolving circular dependencies</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{resolve_circular_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Order placement across Accounts + Catalog + Orders</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("overview"), do: "Overview"
  defp tab_label("calling"), do: "Cross-Context Calls"
  defp tab_label("events"), do: "Events & PubSub"
  defp tab_label("boundaries"), do: "Clean Boundaries"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("problem"), do: "The Problem"
  defp topic_label("solution"), do: "The Solution"
  defp topic_label("rules"), do: "The Rules"

  defp overview_code("problem") do
    """
    # Real apps have multiple contexts that share data.
    # For example: placing an order requires:
    #   - Accounts context  → who is the user?
    #   - Catalog context   → what product are they buying?
    #   - Orders context    → create the order and line items
    #   - Notifications ctx → send a confirmation email

    # The naive (broken) approach — Orders reaches into Accounts:
    defmodule MyApp.Orders do
      def place_order(user_id, product_id, quantity) do
        user = MyApp.Repo.get!(MyApp.Accounts.User, user_id)  # BAD!
        product = MyApp.Repo.get!(MyApp.Catalog.Product, product_id)  # BAD!
        # ...
      end
    end

    # This couples Orders directly to the internal
    # implementation of Accounts and Catalog.
    # If User's schema changes, Orders breaks.\
    """
    |> String.trim()
  end

  defp overview_code("solution") do
    """
    # The correct approach — call public context APIs:
    defmodule MyApp.Orders do
      alias MyApp.{Accounts, Catalog}

      def place_order(user_id, product_id, quantity) do
        # Call the PUBLIC API of each context:
        user = Accounts.get_user!(user_id)
        product = Catalog.get_product!(product_id)

        # Use the data to build the order:
        attrs = %{
          user_id: user.id,
          total: Decimal.mult(product.price, quantity)
        }

        %Order{}
        |> Order.changeset(attrs)
        |> Repo.insert()
      end
    end

    # Orders depends on Accounts and Catalog — one direction.
    # Accounts and Catalog do NOT know about Orders.\
    """
    |> String.trim()
  end

  defp overview_code("rules") do
    """
    # Rules for clean cross-context interactions:

    # 1. Only call public functions — never use another
    #    context's schemas or Repo directly.
    Accounts.get_user!(id)      # GOOD
    Repo.get!(Accounts.User, id)  # BAD (bypasses the boundary)

    # 2. Dependencies flow ONE way — no cycles.
    # Orders can depend on Accounts.
    # Accounts must NOT depend on Orders.

    # 3. Pass IDs or plain values across boundaries.
    Orders.place_order(user_id, product_id, qty)    # GOOD
    Orders.place_order(%User{...}, %Product{...})    # OK but watch out

    # 4. Coordinate complex cross-context work in the web layer
    #    (controller / LiveView) or a dedicated service function.

    # 5. Use PubSub for loose coupling (e.g. send email after order)
    #    instead of hard function calls between contexts.\
    """
    |> String.trim()
  end

  defp calling_code do
    """
    # Pattern: controller coordinates multiple contexts
    defmodule MyAppWeb.OrderController do
      use MyAppWeb, :controller
      alias MyApp.{Accounts, Catalog, Orders}

      def create(conn, %{"order" => params}) do
        user = conn.assigns.current_user

        # Get data from other contexts via their public APIs:
        product = Catalog.get_product!(params["product_id"])

        # Delegate the business logic to the Orders context:
        attrs = %{
          user_id: user.id,
          product_id: product.id,
          quantity: String.to_integer(params["quantity"]),
          unit_price: product.price
        }

        case Orders.place_order(attrs) do
          {:ok, order} ->
            conn
            |> put_flash(:info, "Order placed!")
            |> redirect(to: ~p"/orders/\#{order.id}")

          {:error, changeset} ->
            render(conn, :new, changeset: changeset,
                               product: product)
        end
      end
    end\
    """
    |> String.trim()
  end

  defp controller_multi_ctx_code do
    """
    # Controllers often need data from multiple contexts
    # to render a single page:
    def show(conn, %{"id" => id}) do
      order = Orders.get_order_with_items!(id)

      # Enrich with data from other contexts:
      user = Accounts.get_user!(order.user_id)
      products = Catalog.list_products_by_ids(
        Enum.map(order.line_items, & &1.product_id)
      )

      render(conn, :show,
        order: order,
        user: user,
        products: products)
    end\
    """
    |> String.trim()
  end

  defp context_calls_context_code do
    """
    # A context can call another context's public API:
    defmodule MyApp.Orders do
      alias MyApp.Catalog  # declared dependency

      def place_order(attrs) do
        # Validate product exists and is available:
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

    # Orders calls Catalog — this is fine.
    # Catalog does NOT call Orders — no circular dep.\
    """
    |> String.trim()
  end

  defp atomic_cross_ctx_code do
    """
    # Use Ecto.Multi when two contexts must succeed or fail together:
    def purchase(user_id, product_id, quantity) do
      product = Catalog.get_product!(product_id)

      Ecto.Multi.new()
      # Step 1: create order in Orders context:
      |> Ecto.Multi.insert(:order,
          Order.changeset(%Order{}, %{
            user_id: user_id,
            product_id: product_id,
            quantity: quantity,
            total: Decimal.mult(product.price, quantity)
          }))
      # Step 2: decrement stock in Catalog context:
      |> Ecto.Multi.update_all(:stock, fn %{order: order} ->
          from p in Catalog.Product,
            where: p.id == ^order.product_id,
            update: [inc: [stock: -^order.quantity]]
        end, [])
      |> Repo.transaction()
    end
    # Both succeed or both roll back — no partial state\
    """
    |> String.trim()
  end

  defp events_code do
    """
    # PubSub decouples side effects from the triggering context.
    # Orders context broadcasts when an order is placed.
    # Notifications context listens and sends the email.
    # Orders does NOT need to know about Notifications.

    # Orders broadcasts an event:
    defmodule MyApp.Orders do
      def place_order(attrs) do
        case Repo.insert(Order.changeset(%Order{}, attrs)) do
          {:ok, order} = result ->
            Phoenix.PubSub.broadcast(
              MyApp.PubSub,
              "orders",
              {:order_placed, order}
            )
            result

          error ->
            error
        end
      end
    end

    # Notifications subscribes and reacts:
    defmodule MyApp.Notifications.Worker do
      use GenServer

      def start_link(_opts) do
        GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
      end

      def init(state) do
        Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
        {:ok, state}
      end

      def handle_info({:order_placed, order}, state) do
        Notifications.send_order_confirmation(order)
        {:noreply, state}
      end
    end\
    """
    |> String.trim()
  end

  defp pubsub_broadcast_code do
    """
    # Broadcasting an event from a context function:
    def complete_order(%Order{} = order) do
      case Repo.update(Order.changeset(order, %{status: :completed})) do
        {:ok, completed_order} = result ->
          # Broadcast to anyone listening on "orders:{id}":
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "orders:\#{completed_order.id}",
            {:order_completed, completed_order}
          )

          # Broadcast to general orders topic:
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "orders",
            {:order_status_changed, completed_order}
          )

          result

        error -> error
      end
    end\
    """
    |> String.trim()
  end

  defp pubsub_subscribe_code do
    """
    # Subscribing in a LiveView (real-time UI updates):
    defmodule MyAppWeb.OrderLive.Show do
      use MyAppWeb, :live_view
      alias MyApp.Orders

      def mount(%{"id" => id}, _session, socket) do
        order = Orders.get_order!(id)
        Phoenix.PubSub.subscribe(MyApp.PubSub, "orders:\#{id}")

        {:ok, assign(socket, order: order)}
      end

      # Handle the broadcast message:
      def handle_info({:order_completed, updated_order}, socket) do
        {:noreply,
         socket
         |> assign(order: updated_order)
         |> put_flash(:info, "Your order has been completed!")}
      end
    end\
    """
    |> String.trim()
  end

  defp pubsub_vs_direct_code do
    """
    # Use DIRECT calls when:
    # - You need the result synchronously
    # - The other context is a required dependency
    # - Failure in the other context should halt this operation
    user = Accounts.get_user!(user_id)           # need the user now
    product = Catalog.get_product!(product_id)   # need the price now

    # Use PubSub when:
    # - The action is a side effect, not required for success
    # - You want loose coupling (easy to add/remove subscribers)
    # - Multiple things should react to the same event
    # - The reaction can happen asynchronously
    Phoenix.PubSub.broadcast(MyApp.PubSub, "orders", {:order_placed, order})
    # ^ Notifications, analytics, audit log all subscribe independently\
    """
    |> String.trim()
  end

  defp boundaries_code do
    """
    # Good dependency graph (acyclic, one direction):
    #
    #   Web (controllers, LiveViews)
    #     └── calls: Accounts, Catalog, Orders, Notifications
    #
    #   Orders
    #     └── calls: Accounts (get_user!), Catalog (get_product!)
    #
    #   Catalog
    #     └── calls: (nothing — foundational context)
    #
    #   Accounts
    #     └── calls: (nothing — foundational context)
    #
    #   Notifications
    #     └── calls: Accounts (get_user! for email), Orders (via PubSub)

    # The direction: Web → feature contexts → foundational contexts
    # Foundational contexts (Accounts, Catalog) know nothing
    # about Orders or the web layer.\
    """
    |> String.trim()
  end

  defp clean_deps_code do
    """
    # Foundational (no outbound deps):
    defmodule MyApp.Accounts do
      # User management — knows nothing about orders
    end

    defmodule MyApp.Catalog do
      # Product catalog — knows nothing about orders or users
    end

    # Feature (depends on foundational):
    defmodule MyApp.Orders do
      alias MyApp.{Accounts, Catalog}  # explicit, controlled
      # Order logic — calls Accounts and Catalog APIs
    end

    # Coordination at the web layer:
    defmodule MyAppWeb.CheckoutController do
      alias MyApp.{Accounts, Catalog, Orders, Notifications}
      # Orchestrates the full purchase flow
    end\
    """
    |> String.trim()
  end

  defp warning_signs_code do
    """
    # Red flags for context boundary problems:

    # 1. Circular dependency:
    defmodule MyApp.Accounts do
      alias MyApp.Orders  # BAD if Orders also aliases Accounts
    end

    # 2. Leaking schema across boundary:
    defmodule MyApp.Orders do
      # BAD: importing a schema from another context
      alias MyApp.Accounts.User
      def orders_for(%User{} = user), do: ...
      # Better: take the user_id integer instead
    end

    # 3. Context doing too many unrelated things:
    defmodule MyApp.Stuff do
      # users, products, orders, emails, reports — all in one
      # Split into Accounts, Catalog, Orders, Notifications, Reports
    end

    # 4. Web layer calling Repo directly:
    def index(conn, _params) do
      users = MyApp.Repo.all(MyApp.Accounts.User)  # BAD
    end\
    """
    |> String.trim()
  end

  defp resolve_circular_code do
    """
    # Problem: Orders and Notifications both need each other
    # Orders.place_order -> Notifications.send_email
    # Notifications.send_email -> Orders.get_order (for order details)

    # Solution 1: PubSub to break the cycle
    # Orders broadcasts; Notifications subscribes without calling back.

    # Solution 2: Extract shared data to a parameter
    # Instead of Notifications calling Orders.get_order,
    # pass the order data directly:
    defmodule MyApp.Notifications do
      def send_order_confirmation(order) do
        # order is already a struct — no need to call Orders context
        # Notifications doesn't import Orders at all
      end
    end

    # Solution 3: Extract a shared helper context
    defmodule MyApp.Core do
      # Shared types, validators, helpers used by multiple contexts
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Scenario: e-commerce checkout touching 3 contexts

    # lib/my_app/orders.ex
    defmodule MyApp.Orders do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Orders.{Order, LineItem}
      alias MyApp.Catalog   # controlled dependency

      def place_order(user_id, items) when is_list(items) do
        # Validate and enrich with catalog data:
        enriched_items =
          Enum.map(items, fn %{product_id: pid, quantity: qty} ->
            product = Catalog.get_product!(pid)
            unless product.available do
              throw {:unavailable, product}
            end
            %{product_id: pid, quantity: qty,
              unit_price: product.price,
              name: product.name}
          end)

        total =
          Enum.reduce(enriched_items, Decimal.new(0), fn item, acc ->
            Decimal.add(acc, Decimal.mult(item.unit_price, item.quantity))
          end)

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:order,
            Order.changeset(%Order{}, %{
              user_id: user_id,
              total: total,
              status: :pending
            }))
        |> Ecto.Multi.run(:line_items, fn _repo, %{order: order} ->
            results =
              Enum.map(enriched_items, fn attrs ->
                %LineItem{}
                |> LineItem.changeset(Map.put(attrs, :order_id, order.id))
                |> Repo.insert()
              end)

            if Enum.all?(results, fn {status, _} -> status == :ok end) do
              {:ok, Enum.map(results, fn {:ok, li} -> li end)}
            else
              {:error, :line_item_failed}
            end
          end)
        |> Repo.transaction()
        |> case do
            {:ok, %{order: order}} ->
              Phoenix.PubSub.broadcast(
                MyApp.PubSub, "orders",
                {:order_placed, order})
              {:ok, order}

            {:error, :order, changeset, _} ->
              {:error, changeset}

            {:error, :line_items, reason, _} ->
              {:error, reason}
          end
      catch
        {:unavailable, product} ->
          {:error, :product_unavailable, product.name}
      end

      def list_orders_for_user(user_id) do
        from(o in Order,
          where: o.user_id == ^user_id,
          order_by: [desc: o.inserted_at],
          preload: [:line_items])
        |> Repo.all()
      end

      def get_order!(id), do: Repo.get!(Order, id)
    end

    # lib/my_app_web/controllers/checkout_controller.ex
    defmodule MyAppWeb.CheckoutController do
      use MyAppWeb, :controller
      alias MyApp.{Catalog, Orders}

      def create(conn, %{"items" => items_params}) do
        user = conn.assigns.current_user

        parsed_items =
          Enum.map(items_params, fn item ->
            %{product_id: item["product_id"],
              quantity: String.to_integer(item["quantity"])}
          end)

        case Orders.place_order(user.id, parsed_items) do
          {:ok, order} ->
            conn
            |> put_flash(:info, "Order placed! Order #\#{order.id}")
            |> redirect(to: ~p"/orders/\#{order.id}")

          {:error, :product_unavailable, name} ->
            conn
            |> put_flash(:error, "\#{name} is no longer available.")
            |> redirect(to: ~p"/cart")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Could not place order.")
            |> redirect(to: ~p"/cart")
        end
      end
    end\
    """
    |> String.trim()
  end
end
