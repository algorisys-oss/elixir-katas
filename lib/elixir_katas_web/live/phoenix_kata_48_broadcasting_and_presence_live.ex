defmodule ElixirKatasWeb.PhoenixKata48BroadcastingAndPresenceLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Broadcasting & Presence

    # 1. Phoenix.PubSub — publish/subscribe system
    # Subscribe current process to a topic:
    Phoenix.PubSub.subscribe(MyApp.PubSub, "orders:updates")

    # Broadcast to all subscribers:
    Phoenix.PubSub.broadcast(MyApp.PubSub, "orders:updates", %{
      event: "order_placed", order_id: 42
    })

    # 2. PubSub in LiveView
    defmodule MyAppWeb.OrdersLive do
      use MyAppWeb, :live_view

      def mount(_params, _session, socket) do
        if connected?(socket) do
          Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
        end
        {:ok, assign(socket, orders: Orders.list())}
      end

      def handle_info(%{event: "order_placed", order: order}, socket) do
        {:noreply, update(socket, :orders, &[order | &1])}
      end
    end

    # 3. Broadcasting from context functions
    defmodule MyApp.Orders do
      def create_order(attrs) do
        with {:ok, order} <- Repo.insert(Order.changeset(attrs)) do
          Phoenix.PubSub.broadcast(MyApp.PubSub, "orders",
            %{event: "created", order: order})
          {:ok, order}
        end
      end
    end

    # 4. Presence module
    defmodule MyAppWeb.Presence do
      use Phoenix.Presence,
        otp_app: :my_app,
        pubsub_server: MyApp.PubSub
    end

    # 5. Tracking presence in a channel
    defmodule MyAppWeb.RoomChannel do
      use MyAppWeb, :channel
      alias MyAppWeb.Presence

      def join("room:" <> room_id, _params, socket) do
        send(self(), :after_join)
        {:ok, assign(socket, room_id: room_id)}
      end

      def handle_info(:after_join, socket) do
        user = socket.assigns.current_user
        {:ok, _} = Presence.track(socket, user.id, %{
          name: user.name, online_at: System.os_time(:second)
        })
        push(socket, "presence_state", Presence.list(socket))
        {:noreply, socket}
      end
    end

    # 6. Presence in LiveView
    defmodule MyAppWeb.RoomLive do
      use MyAppWeb, :live_view
      alias MyAppWeb.Presence

      def mount(%{"room_id" => room_id}, _session, socket) do
        topic = "room:\#{room_id}"
        if connected?(socket) do
          Phoenix.PubSub.subscribe(MyApp.PubSub, topic)
          {:ok, _} = Presence.track(self(), topic,
            socket.assigns.current_user.id, %{
              name: socket.assigns.current_user.name
            })
        end
        {:ok, assign(socket, online_users: Presence.list(topic))}
      end

      def handle_info(%Phoenix.Socket.Broadcast{
            event: "presence_diff", payload: diff}, socket) do
        online_users = Presence.handle_diff(socket.assigns.online_users, diff)
        {:noreply, assign(socket, online_users: online_users)}
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "broadcast")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Broadcasting &amp; Presence</h2>
      <p class="text-gray-600 dark:text-gray-300">
        broadcast, PubSub, presence tracking, and online users — real-time awareness in Phoenix applications.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "pubsub", "presence", "liveview", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border-b-2 border-emerald-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["broadcast", "pubsub", "fanout"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-emerald-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">broadcast!</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Send to all clients subscribed to a topic.</p>
            </div>
            <div class="p-4 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
              <p class="text-sm font-semibold text-emerald-700 dark:text-emerald-300 mb-1">PubSub</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Distributed pub/sub via pg (process groups). Works across nodes.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Presence</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Tracks who's online with CRDT-based distributed state.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- PubSub -->
      <%= if @active_tab == "pubsub" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix.PubSub is the underlying engine for all channel broadcasts. You can use it directly outside of channels too.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{pubsub_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">PubSub in LiveView</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{pubsub_liveview_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">From Context/Background</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{pubsub_context_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Presence -->
      <%= if @active_tab == "presence" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix.Presence tracks who is online using CRDT (Conflict-free Replicated Data Types) — works correctly across distributed nodes.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{presence_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Presence Map Structure</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{presence_map_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">In a Channel</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{presence_channel_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- LiveView Presence -->
      <%= if @active_tab == "liveview" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Presence works seamlessly with LiveView — track active users on a page.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{liveview_presence_code()}</div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">How Presence Diffs Work</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Instead of sending the full presence list on every change, Presence sends diffs: which users joined (<code>joins</code>) and which left (<code>leaves</code>). This is efficient even with many users.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Presence + Broadcast Example</h4>
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
  defp tab_label("pubsub"), do: "PubSub"
  defp tab_label("presence"), do: "Presence"
  defp tab_label("liveview"), do: "LiveView Presence"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("broadcast"), do: "broadcast!"
  defp topic_label("pubsub"), do: "PubSub"
  defp topic_label("fanout"), do: "Fan-out Pattern"

  defp overview_code("broadcast") do
    """
    # Three broadcast functions in channels:

    # 1. broadcast!/3 - to ALL subscribers (including sender):
    broadcast!(socket, "new_msg", %{body: "Hello"})

    # 2. broadcast_from!/3 - to all EXCEPT sender:
    broadcast_from!(socket, "user_typing", %{user: "Alice"})

    # 3. Endpoint.broadcast/3 - from ANYWHERE in your app:
    MyAppWeb.Endpoint.broadcast("room:lobby", "update", payload)

    # All three route through Phoenix.PubSub under the hood.
    # The topic is the channel topic ("room:lobby").
    # Any process subscribed to that topic gets the message.\
    """
    |> String.trim()
  end

  defp overview_code("pubsub") do
    """
    # Phoenix.PubSub - publish/subscribe system

    # Subscribe current process to a topic:
    Phoenix.PubSub.subscribe(MyApp.PubSub, "orders:updates")

    # Publish to all subscribers:
    Phoenix.PubSub.broadcast(MyApp.PubSub, "orders:updates", %{
      event: "order_placed",
      order_id: 42
    })

    # Receive in GenServer or LiveView:
    def handle_info(%{event: "order_placed", order_id: id}, state) do
      IO.puts("Order \#{id} was placed!")
      {:noreply, state}
    end

    # PubSub is configured in Application.start:
    children = [
      {Phoenix.PubSub, name: MyApp.PubSub},
      ...
    ]\
    """
    |> String.trim()
  end

  defp overview_code("fanout") do
    """
    # Fan-out pattern: one event reaches many subscribers
    #
    # Example: when an order is placed, notify:
    # - The customer (user:42 channel)
    # - The admin dashboard
    # - The kitchen display system
    # - A LiveView tracking open orders
    #
    defmodule MyApp.Orders do
      def place_order(user_id, items) do
        {:ok, order} = Repo.insert(%Order{...})

        # Fan-out via PubSub:
        Phoenix.PubSub.broadcast(MyApp.PubSub, "orders", %{
          event: "order_placed",
          order: order
        })

        {:ok, order}
      end
    end
    #
    # All subscribers react independently:
    # Kitchen display, admin LiveView, user notification
    # all receive the same message simultaneously.\
    """
    |> String.trim()
  end

  defp pubsub_code do
    """
    # Phoenix.PubSub API:

    # 1. Configure in application.ex:
    children = [
      {Phoenix.PubSub, name: MyApp.PubSub}
    ]

    # 2. Subscribe a process to a topic:
    Phoenix.PubSub.subscribe(MyApp.PubSub, "topic:name")

    # 3. Broadcast to all subscribers:
    Phoenix.PubSub.broadcast(MyApp.PubSub, "topic:name", message)

    # 4. Broadcast from (all except local subscriber):
    Phoenix.PubSub.broadcast_from(
      MyApp.PubSub, self(), "topic:name", message)

    # 5. List subscribers (not common in production):
    # subscribers get the raw message in handle_info

    # Topics are just strings — choose naming convention:
    "orders"              # all orders
    "orders:pending"      # pending orders only
    "user:42:orders"      # orders for user 42
    "room:lobby:messages" # messages in lobby\
    """
    |> String.trim()
  end

  defp pubsub_liveview_code do
    """
    defmodule MyAppWeb.OrdersLive do
      use MyAppWeb, :live_view

      def mount(_params, _session, socket) do
        if connected?(socket) do
          # Subscribe when WebSocket is connected:
          Phoenix.PubSub.subscribe(
            MyApp.PubSub, "orders")
        end

        {:ok, assign(socket, orders: Orders.list())}
      end

      # Handle the broadcast:
      def handle_info(%{event: "order_placed",
                        order: order}, socket) do
        {:noreply,
         update(socket, :orders, &[order | &1])}
      end
    end\
    """
    |> String.trim()
  end

  defp pubsub_context_code do
    """
    # Broadcast from a context function:
    defmodule MyApp.Orders do
      alias Phoenix.PubSub

      def create_order(attrs) do
        with {:ok, order} <- Repo.insert(Order.changeset(attrs)) do
          # Notify all subscribers after DB insert:
          PubSub.broadcast(MyApp.PubSub, "orders",
            %{event: "created", order: order})
          {:ok, order}
        end
      end
    end

    # Or from a background job (Oban, etc.):
    defmodule MyApp.Workers.NotifyJob do
      use Oban.Worker

      def perform(%{args: %{"order_id" => id}}) do
        order = Orders.get_order!(id)
        Phoenix.PubSub.broadcast(MyApp.PubSub,
          "user:\#{order.user_id}", %{
            event: "order_ready",
            order_id: id
          })
        :ok
      end
    end\
    """
    |> String.trim()
  end

  defp presence_code do
    """
    # Define a Presence module:
    defmodule MyAppWeb.Presence do
      use Phoenix.Presence,
        otp_app: :my_app,
        pubsub_server: MyApp.PubSub
    end

    # Add to supervision tree (application.ex):
    children = [
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Presence,   # <-- add this
      ...
    ]

    # Track a user in a channel:
    def join(topic, _params, socket) do
      send(self(), :after_join)
      {:ok, socket}
    end

    def handle_info(:after_join, socket) do
      {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
        online_at: inspect(System.os_time(:second)),
        name: socket.assigns.user.name
      })

      # Push current presence list to new joiner:
      push(socket, "presence_state",
        Presence.list(socket))

      {:noreply, socket}
    end\
    """
    |> String.trim()
  end

  defp presence_map_code do
    """
    # Presence.list/1 returns a map:
    %{
      "user_42" => %{
        metas: [
          %{
            online_at: "1234567890",
            name: "Alice",
            phx_ref: "abc123"
          }
        ]
      },
      "user_99" => %{
        metas: [
          %{online_at: "...", name: "Bob", phx_ref: "..."}
        ]
      }
    }

    # A user can have multiple metas (multiple tabs):
    "user_42" => %{
      metas: [
        %{name: "Alice", tab: "chat"},    # tab 1
        %{name: "Alice", tab: "profile"}  # tab 2
      ]
    }

    # JS: receive presence diffs:
    # import {Presence} from "phoenix"
    # let presence = new Presence(channel)
    # presence.onSync(() => renderUsers(presence.list()))\
    """
    |> String.trim()
  end

  defp presence_channel_code do
    """
    defmodule MyAppWeb.RoomChannel do
      use MyAppWeb, :channel
      alias MyAppWeb.Presence

      def join("room:" <> room_id, _params, socket) do
        send(self(), :after_join)
        {:ok, assign(socket, room_id: room_id)}
      end

      def handle_info(:after_join, socket) do
        user = socket.assigns.current_user

        # Track this user in the channel:
        {:ok, _} = Presence.track(socket, user.id, %{
          name: user.name,
          avatar: user.avatar_url,
          online_at: System.os_time(:second)
        })

        # Send current users to new joiner:
        push(socket, "presence_state",
          Presence.list(socket))

        {:noreply, socket}
      end
    end\
    """
    |> String.trim()
  end

  defp liveview_presence_code do
    """
    defmodule MyAppWeb.RoomLive do
      use MyAppWeb, :live_view
      alias MyAppWeb.Presence

      def mount(%{"room_id" => room_id}, _session, socket) do
        topic = "room:\#{room_id}"

        if connected?(socket) do
          # Subscribe to presence diffs:
          Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

          # Track this user:
          {:ok, _} = Presence.track(self(), topic,
            socket.assigns.current_user.id, %{
              name: socket.assigns.current_user.name,
              joined_at: System.os_time(:second)
            })
        end

        online_users = Presence.list(topic)

        {:ok, assign(socket,
          room_id: room_id,
          online_users: online_users
        )}
      end

      # Handle presence diffs:
      def handle_info(%Phoenix.Socket.Broadcast{
            event: "presence_diff",
            payload: diff}, socket) do

        online_users =
          socket.assigns.online_users
          |> Presence.handle_diff(diff)

        {:noreply, assign(socket, online_users: online_users)}
      end
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete online users feature:

    # 1. Presence module:
    defmodule MyAppWeb.Presence do
      use Phoenix.Presence,
        otp_app: :my_app,
        pubsub_server: MyApp.PubSub
    end

    # 2. Channel with presence:
    defmodule MyAppWeb.RoomChannel do
      use MyAppWeb, :channel
      alias MyAppWeb.Presence

      def join("room:" <> room_id, _params, socket) do
        send(self(), {:after_join, room_id})
        {:ok, socket}
      end

      def handle_info({:after_join, room_id}, socket) do
        user = socket.assigns.user

        # Track presence:
        {:ok, _} = Presence.track(socket, user.id, %{
          name: user.name,
          status: "online",
          room_id: room_id
        })

        # Push full list to joiner:
        push(socket, "presence_state", Presence.list(socket))
        {:noreply, socket}
      end

      # Broadcast is automatic — Presence broadcasts diffs
    end

    # 3. JS client:
    # import {Presence} from "phoenix"
    # let presence = new Presence(channel)
    # presence.onSync(() => {
    #   let users = presence.list((id, {metas: [first, ...rest]}) => {
    #     return {id, name: first.name, count: rest.length + 1}
    #   })
    #   renderUserList(users)
    # })

    # 4. LiveView with PubSub subscribe:
    defmodule MyAppWeb.DashboardLive do
      use MyAppWeb, :live_view

      def mount(_params, _session, socket) do
        if connected?(socket) do
          Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
        end
        {:ok, assign(socket, orders: Orders.recent())}
      end

      def handle_info(%{event: "created", order: order}, socket) do
        {:noreply, update(socket, :orders, &[order | &1])}
      end
    end\
    """
    |> String.trim()
  end
end
