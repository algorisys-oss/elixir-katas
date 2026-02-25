defmodule ElixirKatasWeb.Kata46SearchUrlLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    all_items = [
      "Elixir", "Phoenix", "LiveView", "Ecto", "Plug",
      "Erlang", "OTP", "GenServer", "Supervisor", "ETS",
      "PostgreSQL", "Redis", "Docker", "Kubernetes", "AWS"
    ]
    
    params = assigns[:params] || %{}
    query = params["q"] || ""
    
    results = search(all_items, query)

    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:all_items, all_items)
      |> assign(:results, results)
      |> assign(:query, query)

    {:ok, socket}
  end

  defp search(items, query) do
    if query == "" do
      items
    else
      query_lower = String.downcase(query)
      Enum.filter(items, fn item ->
        String.contains?(String.downcase(item), query_lower)
      end)
    end
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Type to search. The URL updates with <code>?q=...</code> so you can share/bookmark results.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <!-- Search Input -->
          <form phx-change="search" phx-target={@myself} phx-submit="search" phx-target={@myself}>
            <input
              type="text"
              name="q"
              value={@query}
              placeholder="Search..."
              phx-debounce="300"
              class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </form>

          <!-- Current URL -->
          <div class="mt-3 p-3 bg-gray-50 rounded text-xs font-mono">
            Current URL: <span class="text-indigo-600">?q=<%= @query %></span>
          </div>

          <!-- Results -->
          <div class="mt-6">
            <h3 class="text-sm font-medium text-gray-900 mb-3">
              Results (<%= length(@results) %>)
            </h3>
            <%= if @results == [] do %>
              <div class="text-center py-8 text-gray-400 italic">
                No results found for "<%= @query %>"
              </div>
            <% else %>
              <div class="space-y-2">
                <%= for item <- @results do %>
                  <div class="p-3 bg-gray-50 rounded">
                    <%= item %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, push_patch(socket, to: ~p"/liveview-katas/46-search-url?q=#{URI.encode(query)}")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
