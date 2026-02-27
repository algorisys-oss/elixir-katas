defmodule ElixirKatasWeb.PhoenixApiKata14PaginationLive do
  use ElixirKatasWeb, :live_component

  @sample_data (
    for i <- 1..50 do
      %{
        id: i,
        name: "Product #{String.pad_leading(Integer.to_string(i), 2, "0")}",
        price: Float.round(10.0 + :rand.uniform() * 90, 2),
        category: Enum.at(["Electronics", "Books", "Clothing", "Home", "Sports"], rem(i - 1, 5)),
        cursor: "cursor_#{Base.url_encode64(Integer.to_string(i), padding: false)}"
      }
    end
  )

  def phoenix_source do
    """
    # Pagination in Phoenix APIs
    #
    # Two main approaches: offset-based and cursor-based.

    # ────── Offset-Based Pagination ──────
    #
    # GET /api/products?page=2&per_page=10
    # Simple but has consistency issues with concurrent inserts/deletes.

    defmodule MyAppWeb.Api.ProductController do
      use MyAppWeb, :controller

      @default_page 1
      @default_per_page 10
      @max_per_page 100

      def index(conn, params) do
        page = parse_int(params["page"], @default_page)
        per_page = parse_int(params["per_page"], @default_per_page)
        per_page = min(per_page, @max_per_page)

        offset = (page - 1) * per_page

        products =
          Product
          |> order_by(asc: :id)
          |> limit(^per_page)
          |> offset(^offset)
          |> Repo.all()

        total = Repo.aggregate(Product, :count)
        total_pages = ceil(total / per_page)

        json(conn, %{
          data: products,
          meta: %{
            page: page,
            per_page: per_page,
            total: total,
            total_pages: total_pages
          }
        })
      end

      defp parse_int(nil, default), do: default
      defp parse_int(val, default) do
        case Integer.parse(val) do
          {n, _} when n > 0 -> n
          _ -> default
        end
      end
    end

    # ────── Cursor-Based Pagination ──────
    #
    # GET /api/products?after=cursor_xyz&limit=10
    # Uses an opaque cursor (encoded ID) for stable pagination.

    defmodule MyAppWeb.Api.ProductController do
      use MyAppWeb, :controller

      @default_limit 10
      @max_limit 100

      def index(conn, params) do
        limit = parse_int(params["limit"], @default_limit)
        limit = min(limit, @max_limit)

        query =
          Product
          |> order_by(asc: :id)
          |> limit(^(limit + 1))  # Fetch one extra to check has_next

        query =
          case decode_cursor(params["after"]) do
            {:ok, id} -> where(query, [p], p.id > ^id)
            :error -> query
          end

        results = Repo.all(query)
        has_next = length(results) > limit
        products = Enum.take(results, limit)

        last_cursor =
          case List.last(products) do
            nil -> nil
            product -> encode_cursor(product.id)
          end

        json(conn, %{
          data: products,
          meta: %{
            limit: limit,
            has_next: has_next,
            next_cursor: if(has_next, do: last_cursor)
          }
        })
      end

      defp encode_cursor(id), do: Base.url_encode64(to_string(id))
      defp decode_cursor(nil), do: :error
      defp decode_cursor(cursor) do
        case Base.url_decode64(cursor) do
          {:ok, val} ->
            case Integer.parse(val) do
              {id, ""} -> {:ok, id}
              _ -> :error
            end
          :error -> :error
        end
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    per_page = 10
    page_data = Enum.take(@sample_data, per_page)

    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(all_data: @sample_data)
     |> assign(total: length(@sample_data))
     |> assign(mode: "offset")
     |> assign(page: 1)
     |> assign(per_page: per_page)
     |> assign(limit: per_page)
     |> assign(after_cursor: nil)
     |> assign(page_data: page_data)
     |> assign(has_next: true)
     |> assign(show_pros_cons: false)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Pagination</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Toggle between offset-based and cursor-based pagination. Watch the query params, Ecto query,
        and response metadata change.
      </p>

      <!-- Mode Toggle -->
      <div class="flex rounded-lg border-2 border-gray-200 dark:border-gray-700 overflow-hidden">
        <button
          phx-click="set_mode"
          phx-value-mode="offset"
          phx-target={@myself}
          class={["flex-1 px-6 py-3 text-sm font-semibold transition-colors cursor-pointer",
            if(@mode == "offset",
              do: "bg-rose-600 text-white",
              else: "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700")
          ]}
        >
          Offset-Based
        </button>
        <button
          phx-click="set_mode"
          phx-value-mode="cursor"
          phx-target={@myself}
          class={["flex-1 px-6 py-3 text-sm font-semibold transition-colors cursor-pointer",
            if(@mode == "cursor",
              do: "bg-rose-600 text-white",
              else: "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700")
          ]}
        >
          Cursor-Based
        </button>
      </div>

      <!-- URL Preview -->
      <div class="p-4 rounded-lg bg-gray-900 border border-gray-700">
        <div class="text-xs text-gray-500 mb-1 font-mono">GET Request URL</div>
        <div class="font-mono text-sm">
          <span class="text-blue-400">GET</span>
          <span class="text-white ml-2">/api/products</span>
          <span class="text-yellow-400">?</span>
          <span class="text-emerald-400"><%= query_params(assigns) %></span>
        </div>
      </div>

      <!-- Ecto Query -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Ecto Query</h3>
        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
          <pre class="text-gray-300 whitespace-pre-wrap"><%= ecto_query(assigns) %></pre>
        </div>
      </div>

      <!-- Data Table -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
            Results
            <%= if @mode == "offset" do %>
              <span class="text-sm font-normal text-gray-500 dark:text-gray-400">
                (page {@page} of {total_pages(assigns)})
              </span>
            <% else %>
              <span class="text-sm font-normal text-gray-500 dark:text-gray-400">
                (showing {length(@page_data)} items)
              </span>
            <% end %>
          </h3>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b-2 border-gray-200 dark:border-gray-700">
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">ID</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Name</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Price</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Category</th>
                <%= if @mode == "cursor" do %>
                  <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Cursor</th>
                <% end %>
              </tr>
            </thead>
            <tbody>
              <%= for row <- @page_data do %>
                <tr class="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30">
                  <td class="py-2 px-3 text-gray-500 dark:text-gray-400 font-mono">{row.id}</td>
                  <td class="py-2 px-3 text-gray-900 dark:text-white font-medium">{row.name}</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400 font-mono">{"$#{:erlang.float_to_binary(row.price, decimals: 2)}"}</td>
                  <td class="py-2 px-3">
                    <span class={["px-2 py-0.5 rounded-full text-xs font-semibold", category_badge(row.category)]}>
                      {row.category}
                    </span>
                  </td>
                  <%= if @mode == "cursor" do %>
                    <td class="py-2 px-3 text-gray-400 font-mono text-xs">{row.cursor}</td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <!-- Pagination Controls -->
        <div class="mt-4 flex items-center justify-between border-t border-gray-200 dark:border-gray-700 pt-4">
          <%= if @mode == "offset" do %>
            <button
              phx-click="prev_page"
              phx-target={@myself}
              disabled={@page <= 1}
              class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer",
                if(@page <= 1,
                  do: "bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed",
                  else: "bg-rose-600 hover:bg-rose-700 text-white")
              ]}
            >
              Previous
            </button>
            <div class="flex items-center gap-1">
              <%= for p <- page_range(assigns) do %>
                <button
                  phx-click="goto_page"
                  phx-value-page={p}
                  phx-target={@myself}
                  class={["w-8 h-8 rounded-lg text-sm font-medium transition-colors cursor-pointer flex items-center justify-center",
                    if(p == @page,
                      do: "bg-rose-600 text-white",
                      else: "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")
                  ]}
                >
                  {p}
                </button>
              <% end %>
            </div>
            <button
              phx-click="next_page"
              phx-target={@myself}
              disabled={@page >= total_pages(assigns)}
              class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer",
                if(@page >= total_pages(assigns),
                  do: "bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed",
                  else: "bg-rose-600 hover:bg-rose-700 text-white")
              ]}
            >
              Next
            </button>
          <% else %>
            <div class="text-sm text-gray-500 dark:text-gray-400">
              <%= if @after_cursor do %>
                {"after: \"#{@after_cursor}\""}
              <% else %>
                First page (no cursor)
              <% end %>
            </div>
            <div class="flex gap-2">
              <button
                phx-click="cursor_first"
                phx-target={@myself}
                class="px-4 py-2 rounded-lg text-sm font-medium bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
              >
                First
              </button>
              <button
                phx-click="cursor_next"
                phx-target={@myself}
                disabled={!@has_next}
                class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer",
                  if(@has_next,
                    do: "bg-rose-600 hover:bg-rose-700 text-white",
                    else: "bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed")
                ]}
              >
                Next Page
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Response Metadata -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Response Metadata</h3>
        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
          <pre class="text-gray-300 whitespace-pre-wrap"><%= response_metadata(assigns) %></pre>
        </div>
      </div>

      <!-- Pros / Cons Comparison -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Offset vs Cursor: Pros & Cons</h3>
          <button
            phx-click="toggle_pros_cons"
            phx-target={@myself}
            class="px-4 py-1.5 text-sm rounded-lg font-medium bg-rose-600 hover:bg-rose-700 text-white transition-colors cursor-pointer"
          >
            <%= if @show_pros_cons, do: "Hide", else: "Show" %>
          </button>
        </div>

        <%= if @show_pros_cons do %>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Offset -->
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700">
              <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Offset-Based</h4>
              <div class="space-y-2 text-sm">
                <div class="flex items-start gap-2">
                  <span class="text-emerald-500 flex-shrink-0 mt-0.5">+</span>
                  <span class="text-gray-700 dark:text-gray-300">Simple to implement and understand</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-emerald-500 flex-shrink-0 mt-0.5">+</span>
                  <span class="text-gray-700 dark:text-gray-300">Can jump to any page directly</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-emerald-500 flex-shrink-0 mt-0.5">+</span>
                  <span class="text-gray-700 dark:text-gray-300">Total count and page numbers are intuitive</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-red-500 flex-shrink-0 mt-0.5">-</span>
                  <span class="text-gray-700 dark:text-gray-300">Skipped/duplicated items when data changes between requests</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-red-500 flex-shrink-0 mt-0.5">-</span>
                  <span class="text-gray-700 dark:text-gray-300">OFFSET gets slower on large tables (scans and discards rows)</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-red-500 flex-shrink-0 mt-0.5">-</span>
                  <span class="text-gray-700 dark:text-gray-300">COUNT query can be expensive</span>
                </div>
              </div>
            </div>

            <!-- Cursor -->
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700">
              <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Cursor-Based</h4>
              <div class="space-y-2 text-sm">
                <div class="flex items-start gap-2">
                  <span class="text-emerald-500 flex-shrink-0 mt-0.5">+</span>
                  <span class="text-gray-700 dark:text-gray-300">Consistent: no skipped/duplicated items</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-emerald-500 flex-shrink-0 mt-0.5">+</span>
                  <span class="text-gray-700 dark:text-gray-300">Fast on large tables (WHERE id > cursor uses index)</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-emerald-500 flex-shrink-0 mt-0.5">+</span>
                  <span class="text-gray-700 dark:text-gray-300">No COUNT query needed</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-red-500 flex-shrink-0 mt-0.5">-</span>
                  <span class="text-gray-700 dark:text-gray-300">Cannot jump to an arbitrary page</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-red-500 flex-shrink-0 mt-0.5">-</span>
                  <span class="text-gray-700 dark:text-gray-300">No total count (or requires separate query)</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-red-500 flex-shrink-0 mt-0.5">-</span>
                  <span class="text-gray-700 dark:text-gray-300">More complex for multi-column sort keys</span>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">When to Use Which</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          Use <strong>offset-based</strong> for admin dashboards, internal tools, and small datasets where
          users need to jump to specific pages. Use <strong>cursor-based</strong> for public APIs, feeds,
          infinite scroll, and large datasets where consistency and performance matter more than random
          page access. Many APIs (GitHub, Stripe, Slack) use cursor-based pagination.
        </p>
      </div>
    </div>
    """
  end

  defp category_badge("Electronics"), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp category_badge("Books"), do: "bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400"
  defp category_badge("Clothing"), do: "bg-pink-100 dark:bg-pink-900/30 text-pink-700 dark:text-pink-400"
  defp category_badge("Home"), do: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400"
  defp category_badge("Sports"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp category_badge(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp total_pages(assigns) do
    ceil(assigns.total / assigns.per_page)
  end

  defp page_range(assigns) do
    tp = total_pages(assigns)
    current = assigns.page

    start_page = max(1, current - 2)
    end_page = min(tp, start_page + 4)
    start_page = max(1, end_page - 4)

    Enum.to_list(start_page..end_page)
  end

  defp query_params(%{mode: "offset"} = assigns) do
    "page=#{assigns.page}&per_page=#{assigns.per_page}"
  end

  defp query_params(%{mode: "cursor"} = assigns) do
    if assigns.after_cursor do
      "after=#{assigns.after_cursor}&limit=#{assigns.limit}"
    else
      "limit=#{assigns.limit}"
    end
  end

  defp ecto_query(%{mode: "offset"} = assigns) do
    offset = (assigns.page - 1) * assigns.per_page

    """
    Product
    |> order_by(asc: :id)
    |> limit(#{assigns.per_page})
    |> offset(#{offset})
    |> Repo.all()

    # Also: Repo.aggregate(Product, :count)  # for total\
    """
  end

  defp ecto_query(%{mode: "cursor"} = assigns) do
    fetch_count = assigns.limit + 1

    if assigns.after_cursor do
      """
      Product
      |> order_by(asc: :id)
      |> where([p], p.id > ^decode_cursor("#{assigns.after_cursor}"))
      |> limit(#{fetch_count})   # limit + 1 to detect has_next
      |> Repo.all()\
      """
    else
      """
      Product
      |> order_by(asc: :id)
      |> limit(#{fetch_count})   # limit + 1 to detect has_next
      |> Repo.all()\
      """
    end
  end

  defp response_metadata(%{mode: "offset"} = assigns) do
    tp = total_pages(assigns)

    """
    {
      "data": [...],
      "meta": {
        "page": #{assigns.page},
        "per_page": #{assigns.per_page},
        "total": #{assigns.total},
        "total_pages": #{tp}
      }
    }\
    """
  end

  defp response_metadata(%{mode: "cursor"} = assigns) do
    last = List.last(assigns.page_data)
    next_cursor = if assigns.has_next && last, do: "\"#{last.cursor}\"", else: "null"

    """
    {
      "data": [...],
      "meta": {
        "limit": #{assigns.limit},
        "has_next": #{assigns.has_next},
        "next_cursor": #{next_cursor}
      }
    }\
    """
  end

  defp compute_offset_page(all_data, page, per_page) do
    all_data
    |> Enum.drop((page - 1) * per_page)
    |> Enum.take(per_page)
  end

  defp compute_cursor_page(all_data, nil, limit) do
    items = Enum.take(all_data, limit)
    has_next = length(all_data) > limit
    {items, has_next}
  end

  defp compute_cursor_page(all_data, after_cursor, limit) do
    remaining =
      all_data
      |> Enum.drop_while(fn row -> row.cursor != after_cursor end)
      |> Enum.drop(1)

    items = Enum.take(remaining, limit)
    has_next = length(remaining) > limit
    {items, has_next}
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) do
    per_page = socket.assigns.per_page
    page_data = compute_offset_page(@sample_data, 1, per_page)

    {:noreply,
     socket
     |> assign(mode: mode, page: 1, after_cursor: nil, page_data: page_data, has_next: true)
    }
  end

  def handle_event("prev_page", _params, socket) do
    new_page = max(1, socket.assigns.page - 1)
    page_data = compute_offset_page(@sample_data, new_page, socket.assigns.per_page)
    {:noreply, assign(socket, page: new_page, page_data: page_data)}
  end

  def handle_event("next_page", _params, socket) do
    tp = total_pages(socket.assigns)
    new_page = min(tp, socket.assigns.page + 1)
    page_data = compute_offset_page(@sample_data, new_page, socket.assigns.per_page)
    {:noreply, assign(socket, page: new_page, page_data: page_data)}
  end

  def handle_event("goto_page", %{"page" => page_str}, socket) do
    page = String.to_integer(page_str)
    page_data = compute_offset_page(@sample_data, page, socket.assigns.per_page)
    {:noreply, assign(socket, page: page, page_data: page_data)}
  end

  def handle_event("cursor_first", _params, socket) do
    {items, has_next} = compute_cursor_page(@sample_data, nil, socket.assigns.limit)
    {:noreply, assign(socket, after_cursor: nil, page_data: items, has_next: has_next)}
  end

  def handle_event("cursor_next", _params, socket) do
    last = List.last(socket.assigns.page_data)

    if last do
      {items, has_next} = compute_cursor_page(@sample_data, last.cursor, socket.assigns.limit)
      {:noreply, assign(socket, after_cursor: last.cursor, page_data: items, has_next: has_next)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_pros_cons", _params, socket) do
    {:noreply, assign(socket, show_pros_cons: !socket.assigns.show_pros_cons)}
  end
end
