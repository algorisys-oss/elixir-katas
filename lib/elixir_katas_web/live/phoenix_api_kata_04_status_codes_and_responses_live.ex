defmodule ElixirKatasWeb.PhoenixApiKata04StatusCodesAndResponsesLive do
  use ElixirKatasWeb, :live_component

  @status_codes %{
    "2xx" => %{
      label: "2xx Success",
      color: "emerald",
      codes: [
        %{code: 200, atom: ":ok", name: "OK",
          when: "GET, PUT, PATCH succeeded. The most common success code.",
          phoenix: "conn |> put_status(:ok) |> json(%{data: user})"},
        %{code: 201, atom: ":created", name: "Created",
          when: "POST succeeded and a new resource was created.",
          phoenix: "conn |> put_status(:created) |> json(%{data: user})"},
        %{code: 204, atom: ":no_content", name: "No Content",
          when: "DELETE succeeded. No response body needed.",
          phoenix: "send_resp(conn, :no_content, \"\")"}
      ]
    },
    "3xx" => %{
      label: "3xx Redirection",
      color: "blue",
      codes: [
        %{code: 301, atom: ":moved_permanently", name: "Moved Permanently",
          when: "Resource permanently moved to a new URL. Rare in APIs.",
          phoenix: "conn |> put_status(:moved_permanently) |> put_resp_header(\"location\", new_url) |> json(%{})"},
        %{code: 304, atom: ":not_modified", name: "Not Modified",
          when: "Client's cached version is still valid (ETag/If-None-Match).",
          phoenix: "send_resp(conn, :not_modified, \"\")"}
      ]
    },
    "4xx" => %{
      label: "4xx Client Error",
      color: "amber",
      codes: [
        %{code: 400, atom: ":bad_request", name: "Bad Request",
          when: "Malformed request — bad JSON syntax, missing required headers.",
          phoenix: "conn |> put_status(:bad_request) |> json(%{error: \"Invalid JSON\"})"},
        %{code: 401, atom: ":unauthorized", name: "Unauthorized",
          when: "Not authenticated. Missing or invalid auth token.",
          phoenix: "conn |> put_status(:unauthorized) |> json(%{error: \"Missing or invalid token\"})"},
        %{code: 403, atom: ":forbidden", name: "Forbidden",
          when: "Authenticated but not authorized for this action.",
          phoenix: "conn |> put_status(:forbidden) |> json(%{error: \"Not allowed\"})"},
        %{code: 404, atom: ":not_found", name: "Not Found",
          when: "Resource does not exist at this URL.",
          phoenix: "conn |> put_status(:not_found) |> json(%{error: \"Not found\"})"},
        %{code: 409, atom: ":conflict", name: "Conflict",
          when: "Request conflicts with current state (e.g., duplicate email).",
          phoenix: "conn |> put_status(:conflict) |> json(%{error: \"Email already taken\"})"},
        %{code: 422, atom: ":unprocessable_entity", name: "Unprocessable Entity",
          when: "Valid JSON but failed validation (changeset errors).",
          phoenix: "conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})"},
        %{code: 429, atom: ":too_many_requests", name: "Too Many Requests",
          when: "Rate limit exceeded. Client should back off.",
          phoenix: "conn |> put_status(:too_many_requests) |> json(%{error: \"Rate limit exceeded\"})"}
      ]
    },
    "5xx" => %{
      label: "5xx Server Error",
      color: "red",
      codes: [
        %{code: 500, atom: ":internal_server_error", name: "Internal Server Error",
          when: "Unhandled exception. Something broke on the server.",
          phoenix: "# Usually automatic — Phoenix returns 500 for unhandled exceptions"},
        %{code: 502, atom: ":bad_gateway", name: "Bad Gateway",
          when: "Upstream service (database, external API) returned invalid response.",
          phoenix: "conn |> put_status(:bad_gateway) |> json(%{error: \"Upstream service error\"})"},
        %{code: 503, atom: ":service_unavailable", name: "Service Unavailable",
          when: "Server is temporarily down for maintenance.",
          phoenix: "conn |> put_status(:service_unavailable) |> json(%{error: \"Under maintenance\"})"}
      ]
    }
  }

  @category_order ["2xx", "3xx", "4xx", "5xx"]

  def phoenix_source do
    """
    # HTTP Status Codes & Responses in Phoenix APIs
    #
    # Phoenix provides put_status/2 to set the status code.
    # You can use integer codes or atom names.

    defmodule MyAppWeb.Api.UserController do
      use MyAppWeb, :controller

      # 200 OK (default for json/2)
      def index(conn, _params) do
        users = Accounts.list_users()
        json(conn, %{data: users})
      end

      # 201 Created — always set for POST success
      def create(conn, %{"user" => params}) do
        case Accounts.create_user(params) do
          {:ok, user} ->
            conn
            |> put_status(:created)                              # 201
            |> put_resp_header("location", ~p"/api/users/\#{user}")
            |> json(%{data: user})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)                 # 422
            |> json(%{errors: format_changeset_errors(changeset)})
        end
      end

      # 204 No Content — use send_resp, not json
      def delete(conn, %{"id" => id}) do
        user = Accounts.get_user!(id)
        Accounts.delete_user(user)
        send_resp(conn, :no_content, "")                         # 204
      end

      # 404 Not Found — explicit handling
      def show(conn, %{"id" => id}) do
        case Accounts.get_user(id) do
          nil ->
            conn
            |> put_status(:not_found)                            # 404
            |> json(%{error: "User not found"})

          user ->
            json(conn, %{data: user})                            # 200
        end
      end
    end

    # Atom status codes Phoenix understands:
    # :ok                    => 200
    # :created               => 201
    # :no_content            => 204
    # :bad_request           => 400
    # :unauthorized          => 401
    # :forbidden             => 403
    # :not_found             => 404
    # :unprocessable_entity  => 422
    # :internal_server_error => 500

    # json/2 vs send_resp/3:
    # json(conn, data)           — sets content-type to JSON, encodes data
    # send_resp(conn, status, body) — raw response, you control everything
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(status_codes: @status_codes)
     |> assign(category_order: @category_order)
     |> assign(selected_code: nil)
     |> assign(selected_category: nil)
     |> assign(filter_category: "all")
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">HTTP Status Codes & Responses</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Click any status code to see when to use it and the Phoenix code to produce it.
      </p>

      <!-- Category Filter -->
      <div class="flex flex-wrap gap-2">
        <button
          phx-click="filter_category"
          phx-value-cat="all"
          phx-target={@myself}
          class={["px-3 py-1.5 rounded-lg text-sm font-medium transition-colors cursor-pointer",
            if(@filter_category == "all",
              do: "bg-rose-600 text-white",
              else: "bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700")
          ]}
        >
          All
        </button>
        <%= for cat <- @category_order do %>
          <button
            phx-click="filter_category"
            phx-value-cat={cat}
            phx-target={@myself}
            class={["px-3 py-1.5 rounded-lg text-sm font-medium transition-colors cursor-pointer",
              if(@filter_category == cat,
                do: "bg-#{cat_color(cat)}-600 text-white",
                else: "bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700")
            ]}
          >
            {Map.get(@status_codes, cat).label}
          </button>
        <% end %>
      </div>

      <!-- Status Code Grid -->
      <%= for cat <- visible_categories(@filter_category, @category_order) do %>
        <% cat_data = Map.get(@status_codes, cat) %>
        <div>
          <h3 class={"text-lg font-semibold mb-2 text-#{cat_data.color}-700 dark:text-#{cat_data.color}-400"}>
            {cat_data.label}
          </h3>
          <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2">
            <%= for sc <- cat_data.codes do %>
              <button
                phx-click="select_code"
                phx-value-code={sc.code}
                phx-value-category={cat}
                phx-target={@myself}
                class={["p-3 rounded-lg border-2 transition-all cursor-pointer text-left",
                  if(@selected_code == sc.code,
                    do: "border-#{cat_data.color}-500 bg-#{cat_data.color}-50 dark:bg-#{cat_data.color}-900/30 shadow-md",
                    else: "border-gray-200 dark:border-gray-700 hover:border-#{cat_data.color}-300 dark:hover:border-#{cat_data.color}-700 bg-white dark:bg-gray-800")
                ]}
              >
                <div class={"text-2xl font-bold text-#{cat_data.color}-600 dark:text-#{cat_data.color}-400"}>
                  {sc.code}
                </div>
                <div class="text-sm text-gray-600 dark:text-gray-400 mt-0.5">{sc.name}</div>
              </button>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Selected Code Detail -->
      <%= if @selected_code do %>
        <% detail = find_code(@status_codes, @selected_code) %>
        <%= if detail do %>
          <div class={"p-5 rounded-lg border-2 border-#{cat_color(@selected_category)}-300 dark:border-#{cat_color(@selected_category)}-700 bg-white dark:bg-gray-800"}>
            <div class="flex items-baseline gap-3 mb-3">
              <span class={"text-3xl font-bold text-#{cat_color(@selected_category)}-600 dark:text-#{cat_color(@selected_category)}-400"}>
                {detail.code}
              </span>
              <span class="text-xl text-gray-900 dark:text-white font-semibold">{detail.name}</span>
              <code class="text-sm text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-900/20 px-2 py-0.5 rounded">
                {detail.atom}
              </code>
            </div>

            <div class="mb-4">
              <h4 class="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">When to Use</h4>
              <p class="text-gray-700 dark:text-gray-300">{detail.when}</p>
            </div>

            <div>
              <h4 class="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">Phoenix Code</h4>
              <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm">
                <pre class="text-green-400 whitespace-pre-wrap"><%= detail.phoenix %></pre>
              </div>
            </div>
          </div>
        <% end %>
      <% end %>

      <!-- Quick Reference -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">Quick Reference: Atom vs Integer</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400 mb-3">
          Phoenix accepts both atom names and integer codes in <code>put_status/2</code>.
          Atoms are more readable and idiomatic.
        </p>
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-2 text-sm font-mono">
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:ok</span> = 200</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:created</span> = 201</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:no_content</span> = 204</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:bad_request</span> = 400</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:unauthorized</span> = 401</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:forbidden</span> = 403</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:not_found</span> = 404</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:unprocessable_entity</span> = 422</div>
          <div class="text-gray-700 dark:text-gray-300"><span class="text-rose-600 dark:text-rose-400">:internal_server_error</span> = 500</div>
        </div>
      </div>

      <!-- json/2 vs send_resp/3 -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h4 class="font-semibold text-gray-900 dark:text-white mb-2">json/2</h4>
          <ul class="text-sm text-gray-600 dark:text-gray-400 space-y-1">
            <li>Sets <code>Content-Type: application/json</code></li>
            <li>Encodes the data with Jason</li>
            <li>Default status is <code>200</code></li>
            <li>Use for most API responses</li>
          </ul>
          <div class="mt-2 bg-gray-900 rounded p-2 font-mono text-xs text-green-400">
            {"json(conn, %{data: users})"}
          </div>
        </div>
        <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h4 class="font-semibold text-gray-900 dark:text-white mb-2">send_resp/3</h4>
          <ul class="text-sm text-gray-600 dark:text-gray-400 space-y-1">
            <li>Raw response — you control everything</li>
            <li>Does <strong>not</strong> set Content-Type</li>
            <li>Body is a plain string</li>
            <li>Use for 204 No Content or non-JSON</li>
          </ul>
          <div class="mt-2 bg-gray-900 rounded p-2 font-mono text-xs text-green-400">
            send_resp(conn, :no_content, "")
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp visible_categories("all", order), do: order
  defp visible_categories(cat, _order), do: [cat]

  defp cat_color("2xx"), do: "emerald"
  defp cat_color("3xx"), do: "blue"
  defp cat_color("4xx"), do: "amber"
  defp cat_color("5xx"), do: "red"
  defp cat_color(_), do: "gray"

  defp find_code(status_codes, code) do
    status_codes
    |> Map.values()
    |> Enum.flat_map(& &1.codes)
    |> Enum.find(&(&1.code == code))
  end

  def handle_event("select_code", %{"code" => code_str, "category" => cat}, socket) do
    code = String.to_integer(code_str)
    new_code = if socket.assigns.selected_code == code, do: nil, else: code
    new_cat = if new_code, do: cat, else: nil
    {:noreply, assign(socket, selected_code: new_code, selected_category: new_cat)}
  end

  def handle_event("filter_category", %{"cat" => cat}, socket) do
    {:noreply, assign(socket, filter_category: cat, selected_code: nil, selected_category: nil)}
  end
end
