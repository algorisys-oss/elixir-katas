defmodule ElixirKatasWeb.Kata36DebounceLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:query, "")
      |> assign(:results, [])
      |> assign(:search_count, 0)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Type quickly below. Notice the "Search Count" only increments when you stop typing (Debounce 500ms).
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border space-y-6">
          <form phx-change="search" phx-target={@myself} onsubmit="return false;">
            <label for="search" class="block text-sm font-medium text-gray-700">Search Contacts</label>
            <div class="mt-1 relative rounded-md shadow-sm">
              <input
                type="text"
                name="query"
                id="search"
                class="focus:ring-indigo-500 focus:border-indigo-500 block w-full pr-10 sm:text-sm border-gray-300 rounded-md p-2 border"
                placeholder="Start typing..."
                phx-debounce="500"
                value={@query}
              />
              <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                <!-- Simple spinner that shows when "search" event is processing -->
                <svg class="animate-spin h-5 w-5 text-gray-400 opacity-0 phx-change-loading:opacity-100 transition-opacity" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              </div>
            </div>
            <p class="mt-2 text-xs text-gray-500">
              Debounce set to <code>500ms</code>.
            </p>
          </form>

          <div class="border-t pt-4">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-sm font-medium text-gray-900">Results</h3>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                Searches: <%= @search_count %>
              </span>
            </div>
            
            <ul role="list" class="divide-y divide-gray-200">
              <%= if @results == [] do %>
                 <li class="py-4 text-center text-sm text-gray-500 italic">No results found.</li>
              <% else %>
                <%= for item <- @results do %>
                  <li class="py-3 flex items-center justify-between">
                     <span class="text-sm font-medium text-gray-900"><%= item %></span>
                  </li>
                <% end %>
              <% end %>
            </ul>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("search", %{"query" => query}, socket) do
    # Simulate a small delay to make the spinner visible if desired, 
    # but the main point is simply that this event fired at all.
    results = perform_search(query)
    
    {:noreply, 
     socket
     |> assign(:query, query)
     |> assign(:results, results)
     |> update(:search_count, &(&1 + 1))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp perform_search(""), do: []
  defp perform_search(query) do
    # Dummy data search
    items = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew"]
    
    Enum.filter(items, fn item -> 
      String.contains?(String.downcase(item), String.downcase(query))
    end)
  end
end
