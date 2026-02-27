defmodule ElixirKatasWeb.PhoenixApiKata13FilteringAndSortingLive do
  use ElixirKatasWeb, :live_component

  @sample_data [
    %{id: 1, name: "Alice Johnson", email: "alice@example.com", role: "admin", status: "active", joined: "2024-01-15"},
    %{id: 2, name: "Bob Smith", email: "bob@example.com", role: "editor", status: "active", joined: "2024-03-22"},
    %{id: 3, name: "Carol Davis", email: "carol@example.com", role: "viewer", status: "inactive", joined: "2024-02-10"},
    %{id: 4, name: "Dan Wilson", email: "dan@example.com", role: "editor", status: "active", joined: "2024-04-05"},
    %{id: 5, name: "Eve Martinez", email: "eve@example.com", role: "admin", status: "suspended", joined: "2023-11-30"},
    %{id: 6, name: "Frank Lee", email: "frank@example.com", role: "viewer", status: "active", joined: "2024-05-18"},
    %{id: 7, name: "Grace Kim", email: "grace@example.com", role: "editor", status: "inactive", joined: "2024-01-08"},
    %{id: 8, name: "Henry Brown", email: "henry@example.com", role: "viewer", status: "active", joined: "2024-06-01"}
  ]

  @available_filters [
    %{field: "status", values: ["active", "inactive", "suspended"]},
    %{field: "role", values: ["admin", "editor", "viewer"]}
  ]

  @sortable_fields ["name", "email", "role", "status", "joined"]

  def phoenix_source do
    """
    # Filtering & Sorting in Phoenix APIs
    #
    # Build composable Ecto queries from URL query params.
    # GET /api/users?status=active&role=admin&sort=name&order=asc

    defmodule MyAppWeb.Api.UserController do
      use MyAppWeb, :controller

      def index(conn, params) do
        users =
          User
          |> apply_filters(params)
          |> apply_sorting(params)
          |> Repo.all()

        json(conn, %{data: users})
      end

      # --- Composable Filtering ---

      defp apply_filters(query, params) do
        query
        |> filter_by_status(params)
        |> filter_by_role(params)
      end

      defp filter_by_status(query, %{"status" => status})
           when status in ~w(active inactive suspended) do
        where(query, [u], u.status == ^status)
      end
      defp filter_by_status(query, _params), do: query

      defp filter_by_role(query, %{"role" => role})
           when role in ~w(admin editor viewer) do
        where(query, [u], u.role == ^role)
      end
      defp filter_by_role(query, _params), do: query

      # --- Composable Sorting ---

      @allowed_sort_fields ~w(name email role status joined)

      defp apply_sorting(query, %{"sort" => field, "order" => order})
           when field in @allowed_sort_fields and order in ~w(asc desc) do
        direction = String.to_existing_atom(order)
        field_atom = String.to_existing_atom(field)
        order_by(query, [u], [{^direction, field(u, ^field_atom)}])
      end
      defp apply_sorting(query, %{"sort" => field})
           when field in @allowed_sort_fields do
        field_atom = String.to_existing_atom(field)
        order_by(query, [u], asc: field(u, ^field_atom))
      end
      defp apply_sorting(query, _params) do
        order_by(query, [u], asc: u.id)
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(all_data: @sample_data)
     |> assign(available_filters: @available_filters)
     |> assign(sortable_fields: @sortable_fields)
     |> assign(active_filters: %{})
     |> assign(sort_field: nil)
     |> assign(sort_order: "asc")
     |> assign(filtered_data: @sample_data)
     |> assign(show_query: false)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Filtering & Sorting</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Add filters and sorting to see the URL query string build up and the equivalent
        Ecto query that would be generated.
      </p>

      <!-- URL Preview -->
      <div class="p-4 rounded-lg bg-gray-900 border border-gray-700">
        <div class="text-xs text-gray-500 mb-1 font-mono">GET Request URL</div>
        <div class="font-mono text-sm flex flex-wrap items-center gap-0">
          <span class="text-blue-400">GET</span>
          <span class="text-white ml-2">/api/users</span>
          <%= if has_params?(assigns) do %>
            <span class="text-yellow-400">?</span>
            <span class="text-emerald-400"><%= build_query_string(assigns) %></span>
          <% end %>
        </div>
      </div>

      <!-- Filters -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Filters</h3>
          <%= if map_size(@active_filters) > 0 do %>
            <button
              phx-click="clear_filters"
              phx-target={@myself}
              class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
            >
              Clear All
            </button>
          <% end %>
        </div>

        <div class="space-y-4">
          <%= for filter <- @available_filters do %>
            <div>
              <div class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2 capitalize">{filter.field}</div>
              <div class="flex flex-wrap gap-2">
                <%= for value <- filter.values do %>
                  <% is_active = Map.get(@active_filters, filter.field) == value %>
                  <button
                    phx-click="toggle_filter"
                    phx-value-field={filter.field}
                    phx-value-value={value}
                    phx-target={@myself}
                    class={["px-3 py-1.5 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
                      if(is_active,
                        do: "border-rose-500 bg-rose-600 text-white",
                        else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
                    ]}
                  >
                    {value}
                    <%= if is_active do %>
                      <span class="ml-1 opacity-75">x</span>
                    <% end %>
                  </button>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Sorting -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Sort By</h3>
        <div class="flex flex-wrap gap-2">
          <%= for field <- @sortable_fields do %>
            <% is_active = @sort_field == field %>
            <button
              phx-click="set_sort"
              phx-value-field={field}
              phx-target={@myself}
              class={["px-3 py-1.5 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2 flex items-center gap-1",
                if(is_active,
                  do: "border-rose-500 bg-rose-600 text-white",
                  else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
              ]}
            >
              {field}
              <%= if is_active do %>
                <%= if @sort_order == "asc" do %>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                  </svg>
                <% else %>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                <% end %>
              <% end %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Data Table -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
            Results
            <span class="text-sm font-normal text-gray-500 dark:text-gray-400">
              ({length(@filtered_data)} of {length(@all_data)} records)
            </span>
          </h3>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b-2 border-gray-200 dark:border-gray-700">
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">ID</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Name</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Email</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Role</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Status</th>
                <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Joined</th>
              </tr>
            </thead>
            <tbody>
              <%= if length(@filtered_data) > 0 do %>
                <%= for row <- @filtered_data do %>
                  <tr class="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30">
                    <td class="py-2 px-3 text-gray-500 dark:text-gray-400 font-mono">{row.id}</td>
                    <td class="py-2 px-3 text-gray-900 dark:text-white font-medium">{row.name}</td>
                    <td class="py-2 px-3 text-gray-600 dark:text-gray-400 font-mono text-xs">{row.email}</td>
                    <td class="py-2 px-3">
                      <span class={["px-2 py-0.5 rounded-full text-xs font-semibold", role_badge(row.role)]}>
                        {row.role}
                      </span>
                    </td>
                    <td class="py-2 px-3">
                      <span class={["px-2 py-0.5 rounded-full text-xs font-semibold", status_badge(row.status)]}>
                        {row.status}
                      </span>
                    </td>
                    <td class="py-2 px-3 text-gray-600 dark:text-gray-400 text-xs font-mono">{row.joined}</td>
                  </tr>
                <% end %>
              <% else %>
                <tr>
                  <td colspan="6" class="py-8 text-center text-gray-500 dark:text-gray-400">
                    No records match the current filters.
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Ecto Query -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Generated Ecto Query</h3>
          <button
            phx-click="toggle_query"
            phx-target={@myself}
            class="px-4 py-1.5 text-sm rounded-lg font-medium bg-rose-600 hover:bg-rose-700 text-white transition-colors cursor-pointer"
          >
            <%= if @show_query, do: "Hide", else: "Show" %> Full Pattern
          </button>
        </div>

        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
          <pre class="text-gray-300 whitespace-pre-wrap"><%= build_ecto_query(assigns) %></pre>
        </div>

        <%= if @show_query do %>
          <div class="mt-4 bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
            <div class="text-gray-500 mb-2"># The composable pattern:</div>
            <pre class="text-gray-300 whitespace-pre-wrap"><%= composable_pattern() %></pre>
          </div>
        <% end %>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Composable Queries</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          Each filter is a separate function that receives and returns a query. If the param is missing,
          the function returns the query unchanged. This pattern is safe against injection because
          you whitelist allowed values with guard clauses (<code>when status in ~w(active inactive suspended)</code>)
          and use <code>^</code> to parameterize values in Ecto queries.
        </p>
      </div>
    </div>
    """
  end

  defp role_badge("admin"), do: "bg-rose-100 dark:bg-rose-900/30 text-rose-700 dark:text-rose-400"
  defp role_badge("editor"), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp role_badge("viewer"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp role_badge(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp status_badge("active"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp status_badge("inactive"), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"
  defp status_badge("suspended"), do: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
  defp status_badge(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp has_params?(assigns) do
    map_size(assigns.active_filters) > 0 or assigns.sort_field != nil
  end

  defp build_query_string(assigns) do
    filter_parts =
      assigns.active_filters
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)

    sort_parts =
      if assigns.sort_field do
        ["sort=#{assigns.sort_field}", "order=#{assigns.sort_order}"]
      else
        []
      end

    (filter_parts ++ sort_parts) |> Enum.join("&")
  end

  defp build_ecto_query(assigns) do
    lines = ["User"]

    lines =
      Enum.reduce(assigns.active_filters, lines, fn {field, value}, acc ->
        acc ++ ["|> where([u], u.#{field} == \"#{value}\")"]
      end)

    lines =
      if assigns.sort_field do
        lines ++ ["|> order_by([u], #{assigns.sort_order}: u.#{assigns.sort_field})"]
      else
        lines ++ ["|> order_by([u], asc: u.id)"]
      end

    lines = lines ++ ["|> Repo.all()"]
    Enum.join(lines, "\n")
  end

  defp composable_pattern do
    """
    defp apply_filters(query, params) do
      query
      |> filter_by_status(params)
      |> filter_by_role(params)
    end

    # Each filter: if the param exists and is valid, add a WHERE clause.
    # If the param is missing, return the query unchanged.
    defp filter_by_status(query, %{"status" => status})
         when status in ~w(active inactive suspended) do
      where(query, [u], u.status == ^status)
    end
    defp filter_by_status(query, _params), do: query

    defp apply_sorting(query, %{"sort" => field, "order" => order})
         when field in @allowed_sort_fields and order in ~w(asc desc) do
      direction = String.to_existing_atom(order)
      field_atom = String.to_existing_atom(field)
      order_by(query, [u], [{^direction, field(u, ^field_atom)}])
    end
    defp apply_sorting(query, _params), do: query\
    """
  end

  defp apply_client_filters(data, filters) do
    Enum.reduce(filters, data, fn {field, value}, acc ->
      field_atom = String.to_existing_atom(field)
      Enum.filter(acc, fn row -> Map.get(row, field_atom) == value end)
    end)
  end

  defp apply_client_sort(data, nil, _order), do: data

  defp apply_client_sort(data, field, order) do
    field_atom = String.to_existing_atom(field)

    sorted = Enum.sort_by(data, &Map.get(&1, field_atom))

    if order == "desc", do: Enum.reverse(sorted), else: sorted
  end

  defp recompute_data(socket) do
    filtered =
      @sample_data
      |> apply_client_filters(socket.assigns.active_filters)
      |> apply_client_sort(socket.assigns.sort_field, socket.assigns.sort_order)

    assign(socket, filtered_data: filtered)
  end

  def handle_event("toggle_filter", %{"field" => field, "value" => value}, socket) do
    current = socket.assigns.active_filters

    new_filters =
      if Map.get(current, field) == value do
        Map.delete(current, field)
      else
        Map.put(current, field, value)
      end

    socket =
      socket
      |> assign(active_filters: new_filters)
      |> recompute_data()

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign(active_filters: %{})
      |> recompute_data()

    {:noreply, socket}
  end

  def handle_event("set_sort", %{"field" => field}, socket) do
    {new_field, new_order} =
      if socket.assigns.sort_field == field do
        if socket.assigns.sort_order == "asc" do
          {field, "desc"}
        else
          {nil, "asc"}
        end
      else
        {field, "asc"}
      end

    socket =
      socket
      |> assign(sort_field: new_field, sort_order: new_order)
      |> recompute_data()

    {:noreply, socket}
  end

  def handle_event("toggle_query", _params, socket) do
    {:noreply, assign(socket, show_query: !socket.assigns.show_query)}
  end
end
