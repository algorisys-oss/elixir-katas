defmodule ElixirKatasWeb.Kata139VirtualScrollingLive do
  use ElixirKatasWeb, :live_component

  @items_per_page 50
  @item_height 80 # pixels

  def update(%{event: event, params: params}, socket) do
    # IO.inspect({event, params}, label: "FORWARDED EVENT")
    handle_event(event, params, socket)
    |> case do
      {:noreply, socket} -> {:ok, socket}
    end
  end

  def update(%{info_msg: msg}, socket) do
    # IO.inspect(msg, label: "INFO MSG")
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:__initialized__] do
      {:ok, assign(socket, assigns)}
    else
      socket = assign(socket, assigns)
      socket = assign(socket, :__initialized__, true)

      # Load all data once
      all_items = load_large_dataset()

      socket =
        socket
        |> assign(active_tab: "interactive")
        |> assign(:all_items, all_items)
        |> assign(:total_items, length(all_items))
        |> assign(:item_height, @item_height)
        |> assign(:items_per_page, @items_per_page)
        |> assign(:container_height, 600)
        |> assign(:search_query, "")
        |> assign(:filter_category, "all")
        |> assign(:filter_status, "all")
        |> assign(:visible_start, 0)
        |> assign(:visible_end, @items_per_page)
        |> assign(:scroll_top, 0)
      
      # Initial calculation
      filtered = apply_filters(socket.assigns)
      visible = slice_items(filtered, 0, @items_per_page + 100) # Increased buffer

      socket = 
        socket
        |> assign(:filtered_items, filtered)
        |> assign(:visible_items, visible)
        |> assign(:filtered_count, length(filtered))

      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-6xl mx-auto">
        <div class="mb-6">
          <h2 class="text-2xl font-bold mb-2">Virtual Scrolling</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400">
            Efficiently rendering <%= @total_items %> items using window-based rendering.
            Only <%= @items_per_page %> items are rendered at a time.
          </p>
        </div>

        <!-- Filters -->
        <div class="mb-4 bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm border space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <!-- Search -->
            <div>
              <label class="block text-sm font-medium mb-2">Search</label>
              <form phx-change="search" phx-target={@myself}>
                <input 
                  type="text" 
                  phx-debounce="300"
                  name="query"
                  value={@search_query}
                  placeholder="Search items..."
                  class="w-full px-3 py-2 border rounded"
                />
              </form>
            </div>

            <!-- Category Filter -->
            <div>
              <label class="block text-sm font-medium mb-2">Category</label>
              <form phx-change="filter_category" phx-target={@myself}>
                <select 
                  name="category"
                  class="w-full px-3 py-2 border rounded"
                >
                  <option value="all" selected={@filter_category == "all"}>All Categories</option>
                  <option value="Technology" selected={@filter_category == "Technology"}>Technology</option>
                  <option value="Science" selected={@filter_category == "Science"}>Science</option>
                  <option value="Art" selected={@filter_category == "Art"}>Art</option>
                  <option value="Music" selected={@filter_category == "Music"}>Music</option>
                  <option value="Sports" selected={@filter_category == "Sports"}>Sports</option>
                  <option value="Food" selected={@filter_category == "Food"}>Food</option>
                  <option value="Travel" selected={@filter_category == "Travel"}>Travel</option>
                  <option value="Books" selected={@filter_category == "Books"}>Books</option>
                </select>
              </form>
            </div>

            <!-- Status Filter -->
            <div>
              <label class="block text-sm font-medium mb-2">Status</label>
              <form phx-change="filter_status" phx-target={@myself}>
                <select 
                  name="status"
                  class="w-full px-3 py-2 border rounded"
                >
                  <option value="all" selected={@filter_status == "all"}>All Statuses</option>
                  <option value="active" selected={@filter_status == "active"}>Active</option>
                  <option value="pending" selected={@filter_status == "pending"}>Pending</option>
                  <option value="completed" selected={@filter_status == "completed"}>Completed</option>
                  <option value="archived" selected={@filter_status == "archived"}>Archived</option>
                </select>
              </form>
            </div>
          </div>

          <div class="text-sm text-gray-600">
            Showing <%= Enum.count(@visible_items) %> of <%= @filtered_count %> items
            <%= if @search_query != "" or @filter_category != "all" or @filter_status != "all" do %>
              (filtered from <%= @total_items %> total)
            <% end %>
          </div>
        </div>

        <!-- Virtual Scroll Container -->
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border overflow-hidden">
          <div 
            id={"virtual-scroll-container-#{@id}"}
            phx-hook="VirtualScroll"
            phx-target={@myself}
            data-item-height={@item_height}
            data-container-height={@container_height}
            data-total-items={@filtered_count}
            style={"height: #{@container_height}px; overflow-y: auto; position: relative;"}
            class="virtual-scroll-container"
          >
            <!-- Spacer to create scrollable height -->
            <div style={"height: #{@filtered_count * @item_height}px; position: relative;"}>
              <!-- Visible items -->
              <div style={"position: absolute; top: #{@visible_start * @item_height}px; width: 100%;"}>
                <%= for item <- @visible_items do %>
                  <div 
                    id={"item-#{item["id"]}"}
                    class="item-row border-b p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                    style={"height: #{@item_height}px;"}
                    data-item-id={item["id"]}
                  >
                    <div class="flex items-start justify-between">
                      <div class="flex-1">
                        <div class="flex items-center gap-3 mb-1">
                          <h3 class="font-semibold text-gray-900 dark:text-white">
                            <%= item["name"] %>
                          </h3>
                          <span class={[
                            "px-2 py-0.5 text-xs rounded",
                            status_class(item["status"])
                          ]}>
                            <%= item["status"] %>
                          </span>
                        </div>
                        <p class="text-sm text-gray-600 dark:text-gray-400 mb-2 line-clamp-1">
                          <%= item["description"] %>
                        </p>
                        <div class="flex items-center gap-4 text-xs text-gray-500">
                          <span class="flex items-center gap-1">
                            <span class="font-medium">Category:</span>
                            <%= item["category"] %>
                          </span>
                          <span class="flex items-center gap-1">
                            <span class="font-medium">Tags:</span>
                            <%= Enum.join(item["tags"], ", ") %>
                          </span>
                        </div>
                      </div>
                      <div class="text-right ml-4">
                        <div class="text-lg font-bold text-indigo-600">\$<%= item["price"] %></div>
                        <div class="text-xs text-gray-500">ID: <%= item["id"] %></div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <!-- Performance Stats -->
        <div class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
          <div class="flex items-start gap-2">
            <div class="text-blue-600 dark:text-blue-400 font-bold">💡</div>
            <div class="text-sm text-blue-900 dark:text-blue-100">
              <strong>Performance:</strong> Instead of rendering all <%= @total_items %> items (which would create <%= @total_items %> DOM nodes),
              we only render <%= @items_per_page %> items at a time. As you scroll, we update which items are visible.
              This keeps the DOM small and performance smooth even with huge datasets.
            </div>
          </div>
        </div>
      </div>
    """
  end

  def handle_event("scroll", %{"scrollTop" => scroll_top_str}, socket) do
    scroll_top = 
      case Float.parse(scroll_top_str) do
        {f, _} -> round(f)
        :error -> 0
      end
    
    # IO.inspect(scroll_top, label: "SCROLL TOP")
    
    # Increase buffers significantly for preloading (Overscan)
    visible_start = max(0, div(scroll_top, @item_height) - 50) # 50 items above
    visible_end = min(
      socket.assigns.filtered_count,
      visible_start + @items_per_page + 100 # 100 items below
    )

    # IO.inspect({visible_start, visible_end}, label: "WINDOW")

    visible = slice_items(socket.assigns.filtered_items, visible_start, visible_end)

    {:noreply, 
     socket
     |> assign(:scroll_top, scroll_top)
     |> assign(:visible_start, visible_start)
     |> assign(:visible_end, visible_end)
     |> assign(:visible_items, visible)
    }
  end

  def handle_event("search", %{"query" => query}, socket) do
    socket = assign(socket, :search_query, query)
    {:noreply, update_filtered_and_visible(socket)}
  end

  def handle_event("filter_category", %{"category" => category}, socket) do
    socket = assign(socket, :filter_category, category)
    {:noreply, update_filtered_and_visible(socket)}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    socket = assign(socket, :filter_status, status)
    {:noreply, update_filtered_and_visible(socket)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp update_filtered_and_visible(socket) do
    filtered = apply_filters(socket.assigns)
    count = length(filtered)
    visible = slice_items(filtered, 0, @items_per_page + 80) # Preload cushion

    socket
    |> assign(:filtered_items, filtered)
    |> assign(:filtered_count, count)
    |> assign(:visible_items, visible)
    |> assign(:visible_start, 0)
    |> assign(:visible_end, @items_per_page + 80)
    |> assign(:scroll_top, 0)
  end

  defp apply_filters(assigns) do
    assigns.all_items
    |> filter_by_search(assigns.search_query)
    |> filter_by_category(assigns.filter_category)
    |> filter_by_status(assigns.filter_status)
  end

  defp slice_items(items, start, finish) do
    Enum.slice(items, start, max(0, finish - start))
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Private functions

  defp load_large_dataset do
    case File.read("priv/static/data/large_dataset.json") do
      {:ok, content} ->
        Jason.decode!(content)
      {:error, _} ->
        # Fallback: generate sample data if file doesn't exist
        Enum.map(1..10_000, fn i ->
          %{
            "id" => i,
            "name" => "Item #{i}",
            "description" => "Sample description for item #{i}",
            "category" => Enum.random(["Technology", "Science", "Art"]),
            "price" => "#{:rand.uniform(1000)}.99",
            "status" => Enum.random(["active", "pending"]),
            "tags" => ["sample"]
          }
        end)
    end
  end

  defp filter_by_search(items, ""), do: items
  defp filter_by_search(items, query) do
    query_lower = String.downcase(query)
    Enum.filter(items, fn item ->
      String.contains?(String.downcase(item["name"]), query_lower) or
      String.contains?(String.downcase(item["description"]), query_lower)
    end)
  end

  defp filter_by_category(items, "all"), do: items
  defp filter_by_category(items, category) do
    Enum.filter(items, fn item -> item["category"] == category end)
  end

  defp filter_by_status(items, "all"), do: items
  defp filter_by_status(items, status) do
    Enum.filter(items, fn item -> item["status"] == status end)
  end

  defp status_class("active"), do: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
  defp status_class("pending"), do: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
  defp status_class("completed"), do: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"
  defp status_class("archived"), do: "bg-gray-100 text-gray-700 dark:bg-gray-700/30 dark:text-gray-400"
  defp status_class(_), do: "bg-gray-100 text-gray-700"
end
