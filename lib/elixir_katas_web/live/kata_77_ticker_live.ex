defmodule ElixirKatasWeb.Kata77TheTickerLive do
  use ElixirKatasWeb, :live_component

  @topic "stock:ticker"

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
      socket = assign(socket, assigns)
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
      
      # Start the ticker process if not already running
      start_ticker()
    end

    stocks = get_initial_stocks()

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:stocks, stocks)
      |> assign(:market_open, true)
      {:ok, socket}
    end

  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Real-time stock price updates synchronized across all connected clients via PubSub.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-medium">Stock Ticker</h3>
            <div class="flex items-center gap-2">
              <div class={"w-2 h-2 rounded-full " <> if @market_open, do: "bg-green-500 animate-pulse", else: "bg-red-500"}></div>
              <span class="text-sm text-gray-600">
                <%= if @market_open, do: "Market Open", else: "Market Closed" %>
              </span>
            </div>
          </div>
          
          <div class="grid grid-cols-2 gap-4">
            <%= for stock <- @stocks do %>
              <div class="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div class="flex justify-between items-start mb-2">
                  <div>
                    <div class="font-bold text-lg"><%= stock.symbol %></div>
                    <div class="text-sm text-gray-600"><%= stock.name %></div>
                  </div>
                  <div class="text-right">
                    <div class="text-2xl font-bold text-gray-900">
                      $<%= :erlang.float_to_binary(stock.price, decimals: 2) %>
                    </div>
                    <%= if stock.change do %>
                      <div class={"text-sm font-medium flex items-center justify-end gap-1 " <> 
                                  if stock.change > 0, do: "text-green-600", else: "text-red-600"}>
                        <%= if stock.change > 0 do %>
                          <span>↑</span>
                        <% else %>
                          <span>↓</span>
                        <% end %>
                        <%= :erlang.float_to_binary(abs(stock.change), decimals: 2) %>%
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
          
          <div class="mt-4 text-xs text-gray-500 text-center">
            Prices update every 2 seconds • Open in multiple tabs to see synchronized updates
          </div>
        </div>
      </div>
    
    """
  end

  def handle_info({:stock_update, stocks}, socket) do
    {:noreply, assign(socket, :stocks, stocks)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp get_initial_stocks do
    [
      %{symbol: "AAPL", name: "Apple Inc.", price: 150.00, change: nil},
      %{symbol: "GOOGL", name: "Alphabet Inc.", price: 2800.00, change: nil},
      %{symbol: "MSFT", name: "Microsoft Corp.", price: 380.00, change: nil},
      %{symbol: "TSLA", name: "Tesla Inc.", price: 250.00, change: nil},
    ]
  end

  defp start_ticker do
    # Check if ticker process is already running
    case Process.whereis(:stock_ticker) do
      nil ->
        # Start a new ticker process
        pid = spawn(fn -> ticker_loop(get_initial_stocks()) end)
        Process.register(pid, :stock_ticker)
      _pid ->
        # Ticker already running
        :ok
    end
  end

  defp ticker_loop(stocks) do
    Process.sleep(2000)
    
    # Update stock prices
    updated_stocks = Enum.map(stocks, fn stock ->
      # Simulate price change (-2% to +2%)
      change_percent = (:rand.uniform() - 0.5) * 0.04
      change_amount = change_percent * stock.price
      new_price = stock.price + change_amount
      
      %{stock | price: new_price, change: change_percent * 100}
    end)
    
    # Broadcast to all subscribers
    Phoenix.PubSub.broadcast(
      ElixirKatas.PubSub,
      @topic,
      {:stock_update, updated_stocks}
    )
    
    ticker_loop(updated_stocks)
  end
end
