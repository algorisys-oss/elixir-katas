defmodule ElixirKatasWeb.Kata88ThemeSwitcherLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:theme, "light")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">Toggle between light and dark themes.</div>
        <div class={"p-6 rounded-lg shadow-sm border transition-colors " <> if @theme == "dark", do: "bg-gray-900 text-white border-gray-700", else: "bg-white text-gray-900"}>
          <div class="flex justify-between items-center mb-6">
            <h3 class="text-lg font-medium">Theme Demo</h3>
            <button phx-click="toggle_theme" phx-target={@myself} class={"px-4 py-2 rounded transition-colors " <> if @theme == "dark", do: "bg-yellow-500 text-gray-900 hover:bg-yellow-400", else: "bg-gray-800 text-white hover:bg-gray-700"}>
              <%= if @theme == "dark", do: "☀️ Light", else: "🌙 Dark" %>
            </button>
          </div>
          <div class="space-y-4">
            <div class={"p-4 rounded " <> if @theme == "dark", do: "bg-gray-800", else: "bg-gray-100"}>
              <div class="font-medium mb-2">Current Theme: <%= String.capitalize(@theme) %></div>
              <div class="text-sm opacity-75">This content adapts to the selected theme.</div>
            </div>
            <div class="grid grid-cols-3 gap-4">
              <%= for color <- ["blue", "green", "purple"] do %>
                <div class={"p-4 rounded text-center " <> "bg-#{color}-#{if @theme == "dark", do: "700", else: "100"} text-#{color}-#{if @theme == "dark", do: "100", else: "900"}"}>
                  <%= String.capitalize(color) %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_theme", _, socket) do
    new_theme = if socket.assigns.theme == "light", do: "dark", else: "light"
    {:noreply, assign(socket, :theme, new_theme)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, active_tab: tab)}
end
