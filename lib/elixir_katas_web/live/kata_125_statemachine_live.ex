defmodule ElixirKatasWeb.Kata125StatemachineLive do
  use ElixirKatasWeb, :live_component
  alias ElixirKatas.Workers.VendingMachine

  @topic "vending_machine:updates"

  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:__initialized__] do
      {:ok, assign(socket, assigns)}
    else
      socket = assign(socket, assigns)
      socket = assign(socket, :__initialized__, true)

      if connected?(socket) do
        Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
      end

      # Get initial state
      {state, data} = VendingMachine.get_status()

      socket =
        socket
        |> assign(active_tab: "interactive")
        |> assign(:machine_state, state)
        |> assign(:machine_data, data)

      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl mx-auto">
      <div class="mb-6">
        <h2 class="text-2xl font-bold mb-2">State Machine: Vending Machine</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400">
          Demonstrates complex state management using <code>:gen_statem</code>.
          Watch the transitions in real-time.
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <!-- Machine UI -->
        <div class="bg-zinc-800 p-8 rounded-3xl border-8 border-zinc-700 shadow-2xl relative overflow-hidden">
          <!-- Light indicator -->
          <div class="absolute top-4 right-4 flex gap-2">
            <div class={[
              "w-3 h-3 rounded-full transition-all duration-300",
              if(@machine_state == :idle, do: "bg-green-500 shadow-[0_0_10px_rgba(34,197,94,0.8)]", else: "bg-green-900")
            ]}></div>
            <div class={[
              "w-3 h-3 rounded-full transition-all duration-300",
              if(@machine_state == :ready, do: "bg-yellow-500 shadow-[0_0_10px_rgba(234,179,8,0.8)]", else: "bg-yellow-900")
            ]}></div>
            <div class={[
              "w-3 h-3 rounded-full transition-all duration-300",
              if(@machine_state == :dispensing, do: "bg-blue-500 shadow-[0_0_10px_rgba(59,130,246,0.8)]", else: "bg-blue-900")
            ]}></div>
          </div>

          <!-- Display -->
          <div class="bg-black p-4 rounded border-4 border-zinc-600 mb-8 font-mono shadow-inner">
            <div class="text-green-500 text-lg mb-1 animate-pulse"><%= @machine_data.message %></div>
            <div class="text-green-800 text-sm">STATE: <%= @machine_state |> Atom.to_string() |> String.upcase() %></div>
            <div class="text-green-800 text-sm">BALANCE: $<%= :erlang.float_to_binary(@machine_data.balance / 100, [decimals: 2]) %></div>
          </div>

          <!-- Items Grid -->
          <div class="grid grid-cols-1 gap-4 mb-8">
            <%= for {id, item} <- @machine_data.items do %>
              <div class={[
                "flex items-center justify-between p-3 rounded-lg border-2 transition-all",
                if(@machine_state == :ready and @machine_data.balance >= item.price and item.stock > 0, 
                  do: "bg-zinc-700 border-indigo-500 cursor-pointer hover:bg-zinc-600", 
                  else: "bg-zinc-900 border-zinc-800 opacity-50 cursor-not-allowed")
              ]}
              phx-click={if @machine_state == :ready and @machine_data.balance >= item.price and item.stock > 0, do: "select_item"}
              phx-value-id={id}
              phx-target={@myself}>
                <div class="flex items-center gap-3">
                  <span class="w-8 h-8 flex items-center justify-center bg-zinc-800 rounded text-zinc-400 font-bold"><%= id %></span>
                  <div>
                    <div class="text-white font-medium"><%= item.name %></div>
                    <div class="text-xs text-zinc-500">$<%= :erlang.float_to_binary(item.price / 100, [decimals: 2]) %> | Stock: <%= item.stock %></div>
                  </div>
                </div>
                <%= if item.stock == 0 do %>
                  <span class="text-red-500 text-xs font-bold uppercase">Sold Out</span>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Controls -->
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <div class="text-zinc-500 text-xs font-bold uppercase mb-1">Insert Money</div>
              <div class="flex flex-wrap gap-2">
                <button phx-click="insert_coin" phx-value-amount="25" phx-target={@myself} class="w-10 h-10 rounded-full bg-zinc-600 hover:bg-zinc-500 active:bg-zinc-400 text-white text-xs font-bold shadow-lg flex items-center justify-center border-2 border-zinc-500">25¢</button>
                <button phx-click="insert_coin" phx-value-amount="50" phx-target={@myself} class="w-10 h-10 rounded-full bg-zinc-600 hover:bg-zinc-500 active:bg-zinc-400 text-white text-xs font-bold shadow-lg flex items-center justify-center border-2 border-zinc-500">50¢</button>
                <button phx-click="insert_coin" phx-value-amount="100" phx-target={@myself} class="w-12 h-12 rounded-full bg-zinc-600 hover:bg-zinc-500 active:bg-zinc-400 text-white text-xs font-bold shadow-lg flex items-center justify-center border-2 border-zinc-500">$1</button>
              </div>
            </div>
            <div class="flex items-end justify-end">
              <button 
                phx-click="cancel" 
                phx-target={@myself}
                disabled={@machine_data.balance == 0}
                class="px-6 py-3 bg-red-900/50 hover:bg-red-800/50 disabled:opacity-30 disabled:cursor-not-allowed text-red-500 rounded-xl border-2 border-red-800 font-bold shadow-lg transition-all"
              >
                RETURN
              </button>
            </div>
          </div>
        </div>

        <!-- Explanation Sidebar -->
        <div class="space-y-6">
          <div class="bg-white dark:bg-zinc-800 p-6 rounded-2xl border shadow-sm">
            <h3 class="font-bold text-lg mb-4 flex items-center gap-2">
              <.icon name="hero-cpu-chip" class="w-5 h-5 text-indigo-500" />
              Machine Internals
            </h3>
            <div class="space-y-4 text-sm">
              <div class="flex items-center justify-between p-2 rounded bg-zinc-50 dark:bg-zinc-900/50">
                <span class="text-zinc-500">Current State</span>
                <span class="font-mono text-indigo-500 font-bold">:<%= @machine_state %></span>
              </div>
              <div>
                <div class="text-zinc-500 mb-2">State Diagram</div>
                <div class="p-4 bg-zinc-50 dark:bg-zinc-900 rounded font-mono text-[10px] space-y-1">
                  <div class={if @machine_state == :idle, do: "text-indigo-500 font-bold", else: "text-zinc-400"}>
                    idle -> insert_coin -> ready
                  </div>
                  <div class={if @machine_state == :ready, do: "text-indigo-500 font-bold", else: "text-zinc-400"}>
                    ready -> select_item -> dispensing
                  </div>
                  <div class={if @machine_state == :dispensing, do: "text-indigo-500 font-bold", else: "text-zinc-400"}>
                    dispensing -> (wait) -> idle
                  </div>
                  <div class="text-zinc-400">
                    ready -> cancel -> idle
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-indigo-50 dark:bg-indigo-900/20 p-6 rounded-2xl border border-indigo-100 dark:border-indigo-800">
             <h4 class="font-bold text-indigo-700 dark:text-indigo-400 mb-2 italic">Why :gen_statem?</h4>
             <p class="text-xs text-indigo-900/80 dark:text-indigo-200/80 leading-relaxed">
               While GenServer is great for generic state, <code>:gen_statem</code> is purpose-built for finite state machines. It handles:
             </p>
             <ul class="text-xs text-indigo-900/80 dark:text-indigo-200/80 mt-2 space-y-1 list-disc list-inside">
               <li><strong>State Enter events</strong>: Automatically trigger logic when entering a state.</li>
               <li><strong>Internal events</strong>: Transition without waiting for user input.</li>
               <li><strong>Implicit state</strong>: No more nested <code>case state do ...</code> blocks.</li>
             </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("insert_coin", %{"amount" => amount}, socket) do
    VendingMachine.insert_coin(String.to_integer(amount))
    {:noreply, socket}
  end

  def handle_event("select_item", %{"id" => id}, socket) do
    VendingMachine.select_item(String.to_integer(id))
    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    VendingMachine.cancel()
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info({:vending_machine_updated, state, data}, socket) do
    {:noreply,
     socket
     |> assign(:machine_state, state)
     |> assign(:machine_data, data)}
  end
end
