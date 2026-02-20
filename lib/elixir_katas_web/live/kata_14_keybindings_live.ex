defmodule ElixirKatasWeb.Kata14KeybindingsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, 
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(count: 0)
     |> assign(last_key: nil)}
  end

  def render(assigns) do
    ~H"""
    
      <div 
        class="flex flex-col items-center justify-center p-8 gap-8 min-h-[400px]"
        phx-window-keydown="keydown_event"
      >
        <div class="text-center space-y-4">
          <h3 class="text-2xl font-bold">Global Keybindings Enabled</h3>
          <p class="text-gray-600 dark:text-gray-400">
            Press <kbd class="kbd kbd-lg">j</kbd> to decrease, <kbd class="kbd kbd-lg">k</kbd> to increase.
          </p>
          <p class="text-sm text-gray-500">
            (Focus anywhere on the page, the window event captures it)
          </p>
        </div>

        <div class="stat w-64 shadow bg-base-100 rounded-xl border border-gray-200 dark:border-gray-700">
          <div class="stat-figure text-primary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
          </div>
          <div class="stat-title">Current Count</div>
          <div class="stat-value text-primary transition-all duration-300 scale-100 transform" id="counter">{@count}</div>
          <div class="stat-desc">Last Key: <span class="badge badge-outline font-mono">{@last_key || "-"}</span></div>
        </div>
      </div>
    
    """
  end

  def handle_event("keydown_event", %{"key" => key}, socket) do
    case key do
      "k" -> {:noreply, update(socket, :count, &(&1 + 1)) |> assign(last_key: key)}
      "j" -> {:noreply, update(socket, :count, &(&1 - 1)) |> assign(last_key: key)}
      _ -> {:noreply, assign(socket, last_key: key)}
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, socket}
    end
  end
end
