defmodule ElixirKatasWeb.Kata72InfiniteScrollLive do
  use ElixirKatasWeb, :live_component

  @per_page 10

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:page, 1)
      |> assign(:has_more, true)
      |> load_items(1)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Scroll down to automatically load more items. Uses IntersectionObserver for efficient detection.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div 
            id="infinite-scroll-container" 
            phx-hook="InfiniteScroll"
            class="space-y-2 max-h-[600px] overflow-y-auto"
          >
            <div id="items-list" phx-update="stream" class="space-y-2">
              <%= for {dom_id, item} <- @streams.items do %>
                <div id={dom_id} class="p-4 bg-gradient-to-r from-indigo-50 to-purple-50 rounded-lg border border-indigo-100">
                  <div class="flex items-center justify-between">
                    <div>
                      <div class="font-medium text-lg"><%= item.title %></div>
                      <div class="text-sm text-gray-500">Item #<%= item.id %></div>
                    </div>
                    <div class="text-xs text-gray-400">
                      Page <%= div(item.id - 1, @per_page) + 1 %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
            
            <%= if @has_more do %>
              <div data-infinite-scroll-sentinel class="py-8 text-center">
                <div class="inline-flex items-center gap-2 text-gray-500">
                  <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>Loading more items...</span>
                </div>
                <div class="text-xs text-gray-400 mt-2">
                  Page <%= @page %> of 10
                </div>
              </div>
            <% else %>
              <div class="py-8 text-center">
                <div class="text-gray-500 font-medium">🎉 All items loaded!</div>
                <div class="text-xs text-gray-400 mt-1">
                  Loaded <%= @page %> pages with <%= @page * @per_page %> total items
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("load-more", _, socket) do
    if socket.assigns.has_more do
      next_page = socket.assigns.page + 1
      {:noreply, load_items(socket, next_page)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp load_items(socket, page) do
    start_id = (page - 1) * @per_page + 1
    items = for i <- start_id..(start_id + @per_page - 1) do
      %{id: i, title: "Item #{i}"}
    end
    
    has_more = page < 10  # Limit to 10 pages for demo
    
    socket
    |> stream(:items, items)
    |> assign(:page, page)
    |> assign(:has_more, has_more)
    |> assign(:per_page, @per_page)
  end
end
