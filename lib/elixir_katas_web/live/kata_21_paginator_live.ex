defmodule ElixirKatasWeb.Kata21PaginatorLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Let's generate a list of items to paginate.
    items = Enum.map(1..100, fn i -> "Item ##{i}" end)
    
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:items, items)
      |> assign(:page, 1)
      |> assign(:per_page, 5)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Simple offset-based pagination Logic
        </div>

        <div class="flex flex-col gap-4">
          <!-- Controls -->
          <div class="flex items-center justify-between bg-gray-100 p-4 rounded-lg">
            <div class="text-sm text-gray-600">
              Page <%= @page %> of <%= total_pages(@items, @per_page) %>
            </div>
            <div class="space-x-2">
               <button
                phx-click="prev" phx-target={@myself}
                disabled={@page <= 1}
                class="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              <button
                phx-click="next" phx-target={@myself}
                disabled={@page >= total_pages(@items, @per_page)}
                class="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          </div>

          <!-- List -->
          <ul class="border rounded-lg divide-y">
            <%= for item <- paginated_items(@items, @page, @per_page) do %>
              <li class="p-4 hover:bg-gray-50 transition-colors">
                <%= item %>
              </li>
            <% end %>
          </ul>

           <!-- Pagination Info -->
          <div class="text-xs text-gray-500 text-center">
            Showing <%= (@page - 1) * @per_page + 1 %> - <%= min(@page * @per_page, length(@items)) %> of <%= length(@items) %> items
          </div>
        </div>

        <div class="mt-12 bg-gray-50 p-4 rounded-lg border text-sm text-gray-600">
          <h3 class="font-bold mb-2">How it works:</h3>
          <p>
            We rely on <code>Enum.slice/3</code> or <code>Enum.chunk_every/2</code> logic to calculate the subset of data to display based on the current <code>@page</code> and <code>@per_page</code> assigns.
          </p>
        </div>
      </div>
    
    """
  end

  def handle_event("next", _params, socket) do
    total = total_pages(socket.assigns.items, socket.assigns.per_page)
    new_page = min(socket.assigns.page + 1, total)
    {:noreply, assign(socket, :page, new_page)}
  end

  def handle_event("prev", _params, socket) do
    new_page = max(socket.assigns.page - 1, 1)
    {:noreply, assign(socket, :page, new_page)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp total_pages(items, per_page) do
    ceil(length(items) / per_page)
  end

  defp paginated_items(items, page, per_page) do
    start_index = (page - 1) * per_page
    Enum.slice(items, start_index, per_page)
  end
end
