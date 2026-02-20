defmodule ElixirKatasWeb.Kata83TheGameStateLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:player1_score, 0)
      |> assign(:player2_score, 0)
      |> assign(:current_turn, :player1)
      |> assign(:game_log, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Simple multiplayer game state management demonstration.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="grid grid-cols-2 gap-4 mb-6">
            <!-- Player 1 -->
            <div class={"p-4 rounded-lg " <> if @current_turn == :player1, do: "bg-blue-100 border-2 border-blue-500", else: "bg-gray-50"}>
              <div class="text-center mb-3">
                <div class="text-lg font-bold">Player 1</div>
                <div class="text-3xl font-bold text-blue-600"><%= @player1_score %></div>
                <%= if @current_turn == :player1 do %>
                  <div class="text-sm text-blue-600 mt-1">Your Turn!</div>
                <% end %>
              </div>
              <button 
                phx-click="score_point" phx-target={@myself} 
                phx-value-player="player1"
                disabled={@current_turn != :player1}
                class="w-full px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Score Point
              </button>
            </div>

            <!-- Player 2 -->
            <div class={"p-4 rounded-lg " <> if @current_turn == :player2, do: "bg-green-100 border-2 border-green-500", else: "bg-gray-50"}>
              <div class="text-center mb-3">
                <div class="text-lg font-bold">Player 2</div>
                <div class="text-3xl font-bold text-green-600"><%= @player2_score %></div>
                <%= if @current_turn == :player2 do %>
                  <div class="text-sm text-green-600 mt-1">Your Turn!</div>
                <% end %>
              </div>
              <button 
                phx-click="score_point" phx-target={@myself} 
                phx-value-player="player2"
                disabled={@current_turn != :player2}
                class="w-full px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Score Point
              </button>
            </div>
          </div>

          <div class="flex gap-2 mb-4">
            <button 
              phx-click="reset_game" phx-target={@myself}
              class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
            >
              Reset Game
            </button>
          </div>

          <!-- Game Log -->
          <div class="border-t pt-4">
            <h3 class="font-medium mb-2">Game Log</h3>
            <div class="space-y-1 max-h-40 overflow-y-auto">
              <%= if Enum.empty?(@game_log) do %>
                <div class="text-sm text-gray-400">No actions yet</div>
              <% else %>
                <%= for entry <- Enum.reverse(@game_log) do %>
                  <div class="text-sm text-gray-600"><%= entry %></div>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("score_point", %{"player" => player}, socket) do
    player_atom = String.to_atom(player)
    
    socket = case player_atom do
      :player1 -> 
        socket
        |> update(:player1_score, &(&1 + 1))
        |> assign(:current_turn, :player2)
        |> add_log("Player 1 scored! Score: #{socket.assigns.player1_score + 1}")
      :player2 -> 
        socket
        |> update(:player2_score, &(&1 + 1))
        |> assign(:current_turn, :player1)
        |> add_log("Player 2 scored! Score: #{socket.assigns.player2_score + 1}")
    end

    {:noreply, socket}
  end

  def handle_event("reset_game", _, socket) do
    {:noreply,
     socket
     |> assign(:player1_score, 0)
     |> assign(:player2_score, 0)
     |> assign(:current_turn, :player1)
     |> assign(:game_log, ["Game reset"])}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp add_log(socket, message) do
    timestamp = Calendar.strftime(DateTime.utc_now(), "%H:%M:%S")
    log_entry = "[#{timestamp}] #{message}"
    assign(socket, :game_log, [log_entry | socket.assigns.game_log])
  end
end
