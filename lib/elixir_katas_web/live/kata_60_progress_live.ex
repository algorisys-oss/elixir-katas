defmodule ElixirKatasWeb.Kata60ProgressLive do
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
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:progress, 0)
      {:ok, socket}
    end

  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Server-driven progress updates.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border space-y-6">
          <div>
            <div class="flex justify-between text-sm mb-2">
              <span>Progress</span>
              <span><%= @progress %>%</span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-4">
              <div
                class="bg-indigo-600 h-4 rounded-full transition-all duration-300"
                style={"width: #{@progress}%"}
              >
              </div>
            </div>
          </div>

          <div class="flex gap-2">
            <button
              phx-click="start_progress" phx-target={@myself}
              class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
            >
              Start
            </button>
            <button
              phx-click="reset_progress" phx-target={@myself}
              class="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
            >
              Reset
            </button>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("start_progress", _, socket) do
    if socket.assigns.progress < 100 do
      Process.send_after(self(), :increment_progress, 100)
    end
    {:noreply, socket}
  end

  def handle_event("reset_progress", _, socket) do
    {:noreply, assign(socket, progress: 0)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info(:increment_progress, socket) do
    new_progress = min(socket.assigns.progress + 10, 100)
    socket = assign(socket, progress: new_progress)
    
    if new_progress < 100 do
      Process.send_after(self(), :increment_progress, 100)
    end
    
    {:noreply, socket}
  end
end
