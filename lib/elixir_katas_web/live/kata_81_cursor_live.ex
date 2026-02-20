defmodule ElixirKatasWeb.Kata81LiveCursorLive do
  use ElixirKatasWeb, :live_component

  @topic "cursor:demo"

  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  # Handle forwarded events from KataHostLive (e.g., cursor-move from hooks)
  def update(%{event: "cursor-move", params: %{"x" => x, "y" => y}}, socket) do
    # Broadcast cursor position to all subscribers
    Phoenix.PubSub.broadcast(
      ElixirKatas.PubSub,
      @topic,
      {:cursor_update, socket.assigns.username, x, y, socket.assigns.color}
    )
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:__initialized__] do
      {:ok, assign(socket, assigns)}
    else
      socket = assign(socket, assigns)
      socket = assign(socket, :__initialized__, true)
      
      username = "User#{:rand.uniform(9999)}"
      color = generate_color(username)

      if connected?(socket) do
        Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
      end

      socket =
        socket
        |> assign(active_tab: "notes")
        |> assign(:username, username)
        |> assign(:color, color)
        |> assign(:cursors, %{})
      
      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Multi-user cursor tracking with PubSub. Open in multiple tabs and move your mouse!
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="mb-4 flex items-center justify-between">
            <div class="text-sm text-gray-600">
              You are: <span class="font-medium" style={"color: #{@color}"}><%= @username %></span>
            </div>
            <div class="text-sm text-gray-500">
              <%= map_size(@cursors) %> other cursor(s) visible
            </div>
          </div>
          
          <div 
            id="cursor-area"
            class="h-96 bg-gradient-to-br from-indigo-50 via-purple-50 to-pink-50 rounded relative overflow-hidden"
            phx-hook="CursorTracker"
            phx-target={@myself}
          >
            <div class="absolute top-4 left-4 bg-white/90 backdrop-blur px-4 py-2 rounded-lg shadow-md">
              <div class="text-xs text-gray-500 mb-2">Move your mouse in this area</div>
              <div class="font-mono text-sm space-y-1">
                <div style={"color: #{@color}"} class="font-bold">Your cursor: <%= @username %></div>
              </div>
            </div>
            
            <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center text-gray-400 pointer-events-none">
              <div class="text-lg mb-2">🖱️ Move your mouse here</div>
              <div class="text-sm">Cursors from other tabs will appear</div>
            </div>
            
            <%!-- Render other users' cursors --%>
            <%= for {user, cursor} <- @cursors do %>
              <div 
                class="absolute pointer-events-none transition-all duration-75"
                style={"left: #{cursor.x}px; top: #{cursor.y}px; transform: translate(-50%, -50%);"}
              >
                <%!-- Cursor dot --%>
                <div 
                  class="w-4 h-4 rounded-full"
                  style={"background-color: #{cursor.color}"}
                >
                  <div class="absolute inset-0 rounded-full animate-ping opacity-75" style={"background-color: #{cursor.color}"}></div>
                </div>
                <%!-- Username label --%>
                <div 
                  class="absolute top-6 left-0 px-2 py-1 rounded text-xs font-medium text-white whitespace-nowrap shadow-lg"
                  style={"background-color: #{cursor.color}"}
                >
                  <%= user %>
                </div>
              </div>
            <% end %>
          </div>
          
          <div class="mt-4 text-xs text-gray-500 text-center">
            Open this page in multiple browser tabs and move your mouse to see live cursor tracking
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("cursor-move", %{"x" => x, "y" => y}, socket) do
    # Broadcast cursor position to all subscribers
    Phoenix.PubSub.broadcast(
      ElixirKatas.PubSub,
      @topic,
      {:cursor_update, socket.assigns.username, x, y, socket.assigns.color}
    )
    
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info({:cursor_update, username, x, y, color}, socket) do
    # Don't show own cursor
    if username != socket.assigns.username do
      cursors = Map.put(socket.assigns.cursors, username, %{x: x, y: y, color: color})
      {:noreply, assign(socket, :cursors, cursors)}
    else
      {:noreply, socket}
    end
  end

  defp generate_color(username) do
    # Generate a consistent color based on username
    hash = :erlang.phash2(username, 360)
    "hsl(#{hash}, 70%, 50%)"
  end
end
