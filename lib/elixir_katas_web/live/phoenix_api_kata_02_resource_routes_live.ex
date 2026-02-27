defmodule ElixirKatasWeb.PhoenixApiKata02ResourceRoutesLive do
  use ElixirKatasWeb, :live_component

  @resources %{
    "posts" => %{singular: "post", context: "Blog", schema: "Post"},
    "comments" => %{singular: "comment", context: "Blog", schema: "Comment"},
    "users" => %{singular: "user", context: "Accounts", schema: "User"},
    "products" => %{singular: "product", context: "Catalog", schema: "Product"},
    "orders" => %{singular: "order", context: "Sales", schema: "Order"}
  }

  @routes [
    %{action: :index, method: "GET", path_suffix: "", desc: "List all resources"},
    %{action: :show, method: "GET", path_suffix: "/:id", desc: "Get a single resource by ID"},
    %{action: :create, method: "POST", path_suffix: "", desc: "Create a new resource"},
    %{action: :update, method: "PUT/PATCH", path_suffix: "/:id", desc: "Update an existing resource"},
    %{action: :delete, method: "DELETE", path_suffix: "/:id", desc: "Delete a resource"}
  ]

  def phoenix_source do
    """
    # API Resource Routes & Controllers
    #
    # The `resources` macro generates RESTful routes for a resource.
    # For APIs, we exclude :new and :edit (those render HTML forms).

    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :api do
        plug :accepts, ["json"]
      end

      scope "/api", MyAppWeb.Api do
        pipe_through :api

        # Generates: index, show, create, update, delete
        # Excludes: new, edit (browser-only form pages)
        resources "/posts", PostController, except: [:new, :edit]

        # Nested resources for relationships
        resources "/posts", PostController, except: [:new, :edit] do
          resources "/comments", CommentController, except: [:new, :edit]
        end
      end
    end

    # The generated controller uses json/2, not render/2
    defmodule MyAppWeb.Api.PostController do
      use MyAppWeb, :controller

      alias MyApp.Blog

      # GET /api/posts
      def index(conn, _params) do
        posts = Blog.list_posts()
        json(conn, %{data: posts})
      end

      # GET /api/posts/:id
      def show(conn, %{"id" => id}) do
        post = Blog.get_post!(id)
        json(conn, %{data: post})
      end

      # POST /api/posts
      def create(conn, %{"post" => post_params}) do
        case Blog.create_post(post_params) do
          {:ok, post} ->
            conn
            |> put_status(:created)
            |> put_resp_header("location", ~p"/api/posts/\#{post}")
            |> json(%{data: post})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: format_errors(changeset)})
        end
      end

      # PUT/PATCH /api/posts/:id
      def update(conn, %{"id" => id, "post" => post_params}) do
        post = Blog.get_post!(id)

        case Blog.update_post(post, post_params) do
          {:ok, post} ->
            json(conn, %{data: post})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: format_errors(changeset)})
        end
      end

      # DELETE /api/posts/:id
      def delete(conn, %{"id" => id}) do
        post = Blog.get_post!(id)
        Blog.delete_post(post)
        send_resp(conn, :no_content, "")
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(selected_resource: "posts")
     |> assign(resources: @resources)
     |> assign(routes: @routes)
     |> assign(show_nested: false)
     |> assign(nested_parent: nil)
     |> assign(highlighted_action: nil)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">API Resource Routes & Controllers</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Pick a resource name and see all the routes Phoenix generates for an API.
        Unlike browser routes, API resources <strong>exclude</strong> <code>:new</code> and <code>:edit</code>
        because those are HTML form pages.
      </p>

      <!-- Resource Picker -->
      <div>
        <h3 class="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">Choose a Resource</h3>
        <div class="flex flex-wrap gap-2">
          <%= for {name, _meta} <- @resources do %>
            <button
              phx-click="select_resource"
              phx-value-name={name}
              phx-target={@myself}
              class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer text-sm",
                if(@selected_resource == name,
                  do: "bg-rose-600 text-white shadow-md",
                  else: "bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-rose-100 dark:hover:bg-rose-900/30 hover:text-rose-700 dark:hover:text-rose-300")
              ]}
            >
              /{name}
            </button>
          <% end %>
        </div>
      </div>

      <!-- Router Code -->
      <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
        <div class="text-gray-500 mb-1"># router.ex</div>
        <div class="text-blue-400">scope <span class="text-green-400">"/api"</span>, MyAppWeb.Api <span class="text-gray-500">do</span></div>
        <div class="text-blue-400 ml-4">pipe_through <span class="text-yellow-400">:api</span></div>
        <div class="text-white ml-4 mt-1">
          resources <span class="text-green-400">"/{@selected_resource}"</span>,
          <span class="text-yellow-300">{Map.get(@resources, @selected_resource).schema}Controller</span>,
          <span class="text-rose-400">except: [:new, :edit]</span>
        </div>
        <div class="text-gray-500 ml-0">end</div>
      </div>

      <!-- Generated Routes Table -->
      <div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Generated Routes</h3>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b-2 border-rose-200 dark:border-rose-800">
                <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">HTTP Method</th>
                <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">Path</th>
                <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">Controller Action</th>
                <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">Purpose</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <%= for route <- @routes do %>
                <tr
                  phx-click="highlight_action"
                  phx-value-action={route.action}
                  phx-target={@myself}
                  class={["cursor-pointer transition-colors",
                    if(@highlighted_action == Atom.to_string(route.action),
                      do: "bg-rose-50 dark:bg-rose-900/20",
                      else: "hover:bg-gray-50 dark:hover:bg-gray-800/50")
                  ]}
                >
                  <td class="py-3 px-3">
                    <span class={["inline-block px-2 py-0.5 rounded text-xs font-bold",
                      method_color(route.method)
                    ]}>
                      {route.method}
                    </span>
                  </td>
                  <td class="py-3 px-3 font-mono text-gray-900 dark:text-white">
                    /api/{@selected_resource}{route.path_suffix}
                  </td>
                  <td class="py-3 px-3 font-mono text-rose-600 dark:text-rose-400">
                    {Map.get(@resources, @selected_resource).schema}Controller.{route.action}
                  </td>
                  <td class="py-3 px-3 text-gray-600 dark:text-gray-400">{route.desc}</td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Excluded Routes -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">Excluded Routes (browser-only)</h4>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
          <div class="flex items-center gap-2">
            <span class="text-rose-500 font-bold">X</span>
            <code class="text-gray-700 dark:text-gray-300">GET /api/{@selected_resource}/new</code>
            <span class="text-gray-500">- renders a "new" form</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-rose-500 font-bold">X</span>
            <code class="text-gray-700 dark:text-gray-300">GET /api/{@selected_resource}/:id/edit</code>
            <span class="text-gray-500">- renders an "edit" form</span>
          </div>
        </div>
        <p class="text-sm text-rose-700 dark:text-rose-400 mt-2">
          API clients build their own forms. The server only needs endpoints that accept and return JSON data.
        </p>
      </div>

      <!-- Controller Action Detail -->
      <%= if @highlighted_action do %>
        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
          <div class="text-gray-400 mb-2"># {Map.get(@resources, @selected_resource).schema}Controller.{@highlighted_action}/2</div>
          <pre class="text-green-400 whitespace-pre-wrap"><%= controller_code(@selected_resource, @highlighted_action, @resources) %></pre>
        </div>
      <% end %>

      <!-- Nested Resources Toggle -->
      <div>
        <button
          phx-click="toggle_nested"
          phx-target={@myself}
          class="px-4 py-2 bg-rose-100 dark:bg-rose-900/30 text-rose-700 dark:text-rose-300 rounded-lg font-medium hover:bg-rose-200 dark:hover:bg-rose-900/50 transition-colors cursor-pointer text-sm"
        >
          <%= if @show_nested, do: "Hide Nested Routes", else: "Show Nested Routes Example" %>
        </button>
      </div>

      <%= if @show_nested do %>
        <div class="space-y-3">
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
            <div class="text-gray-500"># Nested resources for parent-child relationships</div>
            <div class="text-blue-400">resources <span class="text-green-400">"/{@selected_resource}"</span>, {Map.get(@resources, @selected_resource).schema}Controller, <span class="text-rose-400">except: [:new, :edit]</span> <span class="text-gray-500">do</span></div>
            <div class="text-white ml-4">resources <span class="text-green-400">"/comments"</span>, <span class="text-yellow-300">CommentController</span>, <span class="text-rose-400">except: [:new, :edit]</span></div>
            <div class="text-gray-500">end</div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b-2 border-rose-200 dark:border-rose-800">
                  <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">Method</th>
                  <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">Nested Path</th>
                  <th class="text-left py-2 px-3 text-gray-600 dark:text-gray-400">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr>
                  <td class="py-2 px-3"><span class="px-2 py-0.5 rounded text-xs font-bold bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300">GET</span></td>
                  <td class="py-2 px-3 font-mono text-gray-900 dark:text-white">/api/{@selected_resource}/:post_id/comments</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">CommentController.index</td>
                </tr>
                <tr>
                  <td class="py-2 px-3"><span class="px-2 py-0.5 rounded text-xs font-bold bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300">GET</span></td>
                  <td class="py-2 px-3 font-mono text-gray-900 dark:text-white">/api/{@selected_resource}/:post_id/comments/:id</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">CommentController.show</td>
                </tr>
                <tr>
                  <td class="py-2 px-3"><span class="px-2 py-0.5 rounded text-xs font-bold bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300">POST</span></td>
                  <td class="py-2 px-3 font-mono text-gray-900 dark:text-white">/api/{@selected_resource}/:post_id/comments</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">CommentController.create</td>
                </tr>
                <tr>
                  <td class="py-2 px-3"><span class="px-2 py-0.5 rounded text-xs font-bold bg-amber-100 text-amber-800 dark:bg-amber-900/50 dark:text-amber-300">PUT</span></td>
                  <td class="py-2 px-3 font-mono text-gray-900 dark:text-white">/api/{@selected_resource}/:post_id/comments/:id</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">CommentController.update</td>
                </tr>
                <tr>
                  <td class="py-2 px-3"><span class="px-2 py-0.5 rounded text-xs font-bold bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-300">DELETE</span></td>
                  <td class="py-2 px-3 font-mono text-gray-900 dark:text-white">/api/{@selected_resource}/:post_id/comments/:id</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">CommentController.delete</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp method_color(method) do
    case method do
      "GET" -> "bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300"
      "POST" -> "bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300"
      "PUT/PATCH" -> "bg-amber-100 text-amber-800 dark:bg-amber-900/50 dark:text-amber-300"
      "DELETE" -> "bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-300"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900/50 dark:text-gray-300"
    end
  end

  defp controller_code(resource, action, resources) do
    meta = Map.get(resources, resource)
    s = meta.singular
    _schema = meta.schema
    ctx = meta.context

    case action do
      "index" ->
        """
        def index(conn, _params) do
          #{resource} = #{ctx}.list_#{resource}()
          json(conn, %{data: #{resource}})
        end
        """

      "show" ->
        """
        def show(conn, %{"id" => id}) do
          #{s} = #{ctx}.get_#{s}!(id)
          json(conn, %{data: #{s}})
        end
        """

      "create" ->
        """
        def create(conn, %{"#{s}" => #{s}_params}) do
          case #{ctx}.create_#{s}(#{s}_params) do
            {:ok, #{s}} ->
              conn
              |> put_status(:created)
              |> json(%{data: #{s}})

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: format_errors(changeset)})
          end
        end
        """

      "update" ->
        """
        def update(conn, %{"id" => id, "#{s}" => #{s}_params}) do
          #{s} = #{ctx}.get_#{s}!(id)

          case #{ctx}.update_#{s}(#{s}, #{s}_params) do
            {:ok, #{s}} ->
              json(conn, %{data: #{s}})

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: format_errors(changeset)})
          end
        end
        """

      "delete" ->
        """
        def delete(conn, %{"id" => id}) do
          #{s} = #{ctx}.get_#{s}!(id)
          #{ctx}.delete_#{s}(#{s})
          send_resp(conn, :no_content, "")
        end
        """

      _ ->
        "# Select an action to see the code"
    end
    |> String.trim()
  end

  def handle_event("select_resource", %{"name" => name}, socket) do
    {:noreply, assign(socket, selected_resource: name, highlighted_action: nil)}
  end

  def handle_event("highlight_action", %{"action" => action}, socket) do
    new_action = if socket.assigns.highlighted_action == action, do: nil, else: action
    {:noreply, assign(socket, highlighted_action: new_action)}
  end

  def handle_event("toggle_nested", _params, socket) do
    {:noreply, assign(socket, show_nested: !socket.assigns.show_nested)}
  end
end
