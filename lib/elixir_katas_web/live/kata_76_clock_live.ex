defmodule ElixirKatasWeb.Kata76ClockLive do
  use ElixirKatasWeb, :live_component

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
      :timer.send_interval(1000, self(), :tick)
    end

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:current_time, DateTime.utc_now())
      {:ok, socket}
    end

  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Server-driven clock that updates every second.
        </div>

        <div class="bg-white p-8 rounded-lg shadow-sm border text-center">
          <div class="text-6xl font-bold text-indigo-600 mb-4">
            <%= Calendar.strftime(@current_time, "%H:%M:%S") %>
          </div>
          <div class="text-xl text-gray-600">
            <%= Calendar.strftime(@current_time, "%A, %B %d, %Y") %>
          </div>
          <div class="mt-4 text-sm text-gray-500">
            Updates automatically every second
          </div>
        </div>
      </div>
    
    """
  end

  def handle_info(:tick, socket) do
    {:noreply, assign(socket, :current_time, DateTime.utc_now())}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
