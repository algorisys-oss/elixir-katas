defmodule ElixirKatasWeb.Kata67LazyLive do
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
      
      
      |> assign(:loaded, false)
      |> assign(:loading, false)
      {:ok, socket}
    end

  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Demonstrating asynchronous component loading.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <%= if @loaded do %>
            <div class="p-6 bg-green-50 border border-green-200 rounded">
              <h3 class="font-bold text-lg mb-2 text-green-800">✓ Component Loaded!</h3>
              <p class="text-sm text-gray-600">This component was loaded asynchronously after a delay.</p>
              <button phx-click="reset" phx-target={@myself} class="mt-4 px-4 py-2 bg-gray-600 text-white rounded text-sm hover:bg-gray-700">
                Reset
              </button>
            </div>
          <% else %>
            <%= if @loading do %>
              <div class="text-center py-8">
                <div class="inline-block animate-spin text-4xl mb-4">⟳</div>
                <div class="text-gray-600">Loading component...</div>
              </div>
            <% else %>
              <button phx-click="load_component" phx-target={@myself} class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700">
                Load Component Async
              </button>
            <% end %>
          <% end %>
        </div>
      </div>
    
    """
  end

  def handle_event("load_component", _, socket) do
    socket = assign(socket, loading: true)
    Process.send_after(self(), :finish_loading, 1500)
    {:noreply, socket}
  end

  def handle_event("reset", _, socket) do
    {:noreply, assign(socket, loaded: false, loading: false)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info(:finish_loading, socket) do
    {:noreply, assign(socket, loaded: true, loading: false)}
  end
end
