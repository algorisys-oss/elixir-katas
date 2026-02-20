defmodule ElixirKatasWeb.Kata41UrlParamsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    all_items = [
      %{id: 1, name: "Elixir", category: "language"},
      %{id: 2, name: "Phoenix", category: "framework"},
      %{id: 3, name: "LiveView", category: "framework"},
      %{id: 4, name: "Ecto", category: "database"},
      %{id: 5, name: "Erlang", category: "language"},
      %{id: 6, name: "PostgreSQL", category: "database"},
      %{id: 7, name: "Plug", category: "framework"},
      %{id: 8, name: "OTP", category: "language"}
    ]

    params = assigns[:params] || %{}
    filter = params["filter"] || "all"
    
    filtered_items = 
      if filter == "all" do
        all_items
      else
        Enum.filter(all_items, &(&1.category == filter))
      end

    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:all_items, all_items)
      |> assign(:items, filtered_items)
      |> assign(:current_filter, filter)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Click filters below. Notice the URL changes with <code>?filter=...</code> and the list updates.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <!-- Filter Buttons -->
          <div class="flex gap-2 mb-6 flex-wrap">
            <button
              phx-click="set_filter" phx-target={@myself}
              phx-value-filter="all"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors " <> 
                     if(@current_filter == "all", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
            >
              All (<%= length(@all_items) %>)
            </button>
            <button
              phx-click="set_filter" phx-target={@myself}
              phx-value-filter="language"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors " <> 
                     if(@current_filter == "language", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
            >
              Languages
            </button>
            <button
              phx-click="set_filter" phx-target={@myself}
              phx-value-filter="framework"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors " <> 
                     if(@current_filter == "framework", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
            >
              Frameworks
            </button>
            <button
              phx-click="set_filter" phx-target={@myself}
              phx-value-filter="database"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors " <> 
                     if(@current_filter == "database", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
            >
              Database
            </button>
          </div>

          <!-- Current URL Display -->
          <div class="mb-4 p-3 bg-gray-50 rounded text-xs font-mono">
            Current URL: <span class="text-indigo-600">?filter=<%= @current_filter %></span>
          </div>

          <!-- Items List -->
          <div class="space-y-2">
            <h3 class="text-sm font-medium text-gray-900 mb-3">
              Results (<%= length(@items) %>)
            </h3>
            <%= for item <- @items do %>
              <div class="flex items-center justify-between p-3 bg-gray-50 rounded">
                <span class="font-medium"><%= item.name %></span>
                <span class="text-xs px-2 py-1 bg-white rounded border">
                  <%= item.category %>
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("set_filter", %{"filter" => filter}, socket) do
    # Use push_patch to update URL without remounting
    # This will trigger handle_params/3
    {:noreply, push_patch(socket, to: ~p"/katas/41-url-params?filter=#{filter}")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
