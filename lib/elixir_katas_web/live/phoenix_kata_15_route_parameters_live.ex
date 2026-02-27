defmodule ElixirKatasWeb.PhoenixKata15RouteParametersLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Path parameters — dynamic URL segments
    # Route: get "/users/:id", UserController, :show
    # URL:   /users/42
    def show(conn, %{"id" => id}) do
      # id = "42" (always a string!)
      user = Accounts.get_user!(String.to_integer(id))
      render(conn, :show, user: user)
    end

    # Query parameters — after ? in URL
    # URL: /products?page=2&sort=name&category=books
    def index(conn, params) do
      page = Map.get(params, "page", "1") |> String.to_integer()
      per_page = Map.get(params, "per_page", "20") |> String.to_integer()
      sort = params["sort"] || "inserted_at"
    end

    # Pattern matching on params
    def show(conn, %{"format" => "json"}) do
      json(conn, %{data: "..."})
    end

    def show(conn, %{"format" => "html"}) do
      render(conn, :show)
    end

    # Catch-all (glob) routes
    get "/files/*path", FileController, :show

    # /files/images/photos/sunset.jpg
    def show(conn, %{"path" => path}) do
      # path = ["images", "photos", "sunset.jpg"]
      full = Enum.join(path, "/")
    end

    # Slug routes
    get "/blog/:slug", BlogController, :show

    def show(conn, %{"slug" => slug}) do
      post = Blog.get_by_slug!(slug)
      render(conn, :show, post: post)
    end

    # Nested resources
    resources "/users", UserController do
      resources "/posts", PostController
    end

    # Generates: GET /users/:user_id/posts
    #            GET /users/:user_id/posts/:id
    def index(conn, %{"user_id" => uid}) do
      posts = Blog.list_posts(uid)
    end

    # Verified routes (~p) — compile-time checked
    ~p"/users/\#{user.id}"
    <.link navigate={~p"/users/\#{@user}"}>View Profile</.link>
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "path",
       test_url: "/users/42?tab=posts&page=2",
       parsed: parse_url("/users/42?tab=posts&page=2")
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Route Parameters</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Extract dynamic data from URLs — path params, query strings, and catch-all routes.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["path", "query", "patterns", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400 border-b-2 border-teal-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Path params -->
      <%= if @active_tab == "path" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Path parameters capture dynamic segments of a URL. Type a URL to see how it's parsed.
          </p>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">URL</label>
            <input type="text" phx-change="update_url" phx-target={@myself} name="url" value={@test_url}
              class="w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm font-mono"
              placeholder="/users/42?tab=posts" />
          </div>

          <!-- Quick examples -->
          <div class="flex flex-wrap gap-2">
            <button :for={url <- ["/users/42", "/users/5/posts/99", "/products?page=2&sort=name", "/files/images/photos/sunset.jpg", "/blog/my-first-post"]}
              phx-click="set_url"
              phx-target={@myself}
              phx-value-url={url}
              class="px-3 py-1 text-xs rounded-full bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 font-mono cursor-pointer">
              {url}
            </button>
          </div>

          <!-- Parsed result -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20">
              <h4 class="font-semibold text-blue-700 dark:text-blue-300 mb-2">Path Params</h4>
              <%= if @parsed.path_params == %{} do %>
                <p class="text-sm text-gray-500 italic">No path parameters</p>
              <% else %>
                <div class="space-y-1">
                  <%= for {k, v} <- @parsed.path_params do %>
                    <div class="flex gap-2 font-mono text-sm">
                      <span class="text-blue-600 dark:text-blue-400">:{k}</span>
                      <span class="text-gray-400">=</span>
                      <span class="text-green-600 dark:text-green-400">"{v}"</span>
                    </div>
                  <% end %>
                </div>
              <% end %>
              <p class="text-xs text-gray-500 mt-2">Route: <span class="font-mono">{@parsed.route_pattern}</span></p>
            </div>

            <div class="p-4 rounded-lg border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/20">
              <h4 class="font-semibold text-amber-700 dark:text-amber-300 mb-2">Query Params</h4>
              <%= if @parsed.query_params == %{} do %>
                <p class="text-sm text-gray-500 italic">No query parameters</p>
              <% else %>
                <div class="space-y-1">
                  <%= for {k, v} <- @parsed.query_params do %>
                    <div class="flex gap-2 font-mono text-sm">
                      <span class="text-amber-600 dark:text-amber-400">{k}</span>
                      <span class="text-gray-400">=</span>
                      <span class="text-green-600 dark:text-green-400">"{v}"</span>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <!-- conn.params -->
          <div class="p-4 rounded-lg bg-gray-900 font-mono text-sm overflow-x-auto">
            <p class="text-gray-500 mb-1"># In your controller:</p>
            <pre class="text-green-400 whitespace-pre">{format_controller_params(@parsed)}</pre>
          </div>
        </div>
      <% end %>

      <!-- Query params deep dive -->
      <%= if @active_tab == "query" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Query parameters come after <code>?</code> in the URL. They're merged with path params into one map.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
            <p class="text-gray-500"># URL: /products?page=2&sort=name&category=books</p>
            <pre class="text-green-400 whitespace-pre mt-2">{query_params_example()}</pre>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Safe Defaults</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{safe_defaults_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Pattern Matching</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{pattern_match_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Remember: All params are strings!</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Path param <code>:id</code> from <code>/users/42</code> gives you <code>"42"</code> (a string), not <code>42</code> (an integer).
              Always convert: <code>String.to_integer(id)</code>.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Advanced patterns -->
      <%= if @active_tab == "patterns" do %>
        <div class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Catch-All (Glob)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{glob_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Verified Routes (~p)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{verified_routes_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Slug Routes</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{slug_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Nested Resources</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{nested_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Controller with All Param Patterns</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_controller_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("update_url", %{"url" => url}, socket) do
    {:noreply, assign(socket, test_url: url, parsed: parse_url(url))}
  end

  def handle_event("set_url", %{"url" => url}, socket) do
    {:noreply, assign(socket, test_url: url, parsed: parse_url(url))}
  end

  defp tab_label("path"), do: "Path Params"
  defp tab_label("query"), do: "Query Params"
  defp tab_label("patterns"), do: "Advanced"
  defp tab_label("code"), do: "Source Code"

  defp parse_url(url) do
    {path, query_string} =
      case String.split(url, "?", parts: 2) do
        [p, q] -> {p, q}
        [p] -> {p, ""}
      end

    query_params =
      if query_string != "" do
        URI.decode_query(query_string)
      else
        %{}
      end

    segments = String.split(path, "/") |> Enum.reject(&(&1 == ""))

    {route_pattern, path_params} = infer_route(segments)

    %{
      path: path,
      query_string: query_string,
      path_params: path_params,
      query_params: query_params,
      route_pattern: route_pattern
    }
  end

  defp infer_route(segments) do
    # Simple heuristic: numeric segments become :id, others stay literal
    {pattern_parts, params} =
      segments
      |> Enum.reduce({[], %{}}, fn seg, {parts, params} ->
        if Regex.match?(~r/^\d+$/, seg) do
          actual_name = if map_size(params) == 0, do: "id", else: "#{Enum.at(parts, -1) |> String.replace(":", "") |> String.trim_trailing("s")}_id"
          {parts ++ [":#{actual_name}"], Map.put(params, actual_name, seg)}
        else
          {parts ++ [seg], params}
        end
      end)

    {"/" <> Enum.join(pattern_parts, "/"), params}
  end

  defp format_controller_params(parsed) do
    all_params = Map.merge(parsed.path_params, parsed.query_params)

    if all_params == %{} do
      "def action(conn, params) do\n  # params = %{}\nend"
    else
      params_str =
        all_params
        |> Enum.map(fn {k, v} -> "  \"#{k}\" => \"#{v}\"" end)
        |> Enum.join(",\n")

      "def action(conn, params) do\n  # params = %{\n#{params_str}\n  # }\nend"
    end
  end

  defp query_params_example do
    """
    def index(conn, params) do
      # params = %{
      #   "page" => "2",
      #   "sort" => "name",
      #   "category" => "books"
      # }
      page = String.to_integer(params["page"] || "1")
      sort = params["sort"] || "name"
    end\
    """
    |> String.trim()
  end

  defp safe_defaults_code do
    """
    def index(conn, params) do
      page = Map.get(params, "page", "1")
        |> String.to_integer()
      per_page = Map.get(params, "per_page", "20")
        |> String.to_integer()
      sort = params["sort"] || "inserted_at"
      # ...
    end\
    """
    |> String.trim()
  end

  defp pattern_match_code do
    """
    # Match specific param values:
    def show(conn, %{"format" => "json"}) do
      json(conn, %{data: "..."})
    end

    def show(conn, %{"format" => "html"}) do
      render(conn, :show)
    end

    # Default:
    def show(conn, _params) do
      render(conn, :show)
    end\
    """
    |> String.trim()
  end

  defp glob_code do
    """
    # Catch multiple segments:
    get "/files/*path", FileController, :show

    # /files/images/photos/sunset.jpg
    def show(conn, %{"path" => path}) do
      # path = ["images", "photos", "sunset.jpg"]
      full = Enum.join(path, "/")
    end\
    """
    |> String.trim()
  end

  defp verified_routes_code do
    """
    # Compile-time checked paths:
    ~p"/users/\#{user.id}"

    # In templates:
    <.link navigate={~p"/users/\#{@user}"}>
      View Profile
    </.link>

    # Typos caught at compile time!\
    """
    |> String.trim()
  end

  defp slug_code do
    """
    get "/blog/:slug", BlogController, :show

    # /blog/my-first-post
    def show(conn, %{"slug" => slug}) do
      post = Blog.get_by_slug!(slug)
      render(conn, :show, post: post)
    end\
    """
    |> String.trim()
  end

  defp nested_code do
    """
    resources "/users", UserController do
      resources "/posts", PostController
    end

    # Generates:
    # GET /users/:user_id/posts
    # GET /users/:user_id/posts/:id

    def index(conn, %{"user_id" => uid}) do
      posts = Blog.list_posts(uid)
    end\
    """
    |> String.trim()
  end

  defp full_controller_code do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      # List with pagination & filtering
      def index(conn, params) do
        opts = [
          page: to_int(params["page"], 1),
          per_page: to_int(params["per_page"], 20),
          sort: params["sort"] || "inserted_at",
          category: params["category"]
        ]
        products = Products.list(opts)
        render(conn, :index, products: products, opts: opts)
      end

      # Show by ID
      def show(conn, %{"id" => id}) do
        product = Products.get!(id)
        render(conn, :show, product: product)
      end

      # Pattern match on format
      def export(conn, %{"format" => "csv"}) do
        csv = Products.to_csv()
        send_download(conn, {:binary, csv},
          filename: "products.csv")
      end

      def export(conn, %{"format" => "json"}) do
        products = Products.list_all()
        json(conn, %{products: products})
      end

      defp to_int(nil, default), do: default
      defp to_int(str, default) do
        case Integer.parse(str) do
          {n, ""} -> n
          _ -> default
        end
      end
    end\
    """
    |> String.trim()
  end
end
