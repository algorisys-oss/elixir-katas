defmodule ElixirKatasWeb.PhoenixKata22JsonApisLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Router — API pipeline and scopes:
    pipeline :api do
      plug :accepts, ["json"]
    end

    scope "/api", MyAppWeb.API do
      pipe_through :api
      resources "/products", ProductController, only: [:index, :show]
    end

    # Controller — JSON responses:
    defmodule MyAppWeb.API.ProductController do
      use MyAppWeb, :controller

      def index(conn, _params) do
        products = Catalog.list_products()
        render(conn, :index, products: products)
      end

      def show(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        render(conn, :show, product: product)
      end

      def create(conn, %{"product" => params}) do
        case Catalog.create_product(params) do
          {:ok, product} ->
            conn |> put_status(:created) |> render(:show, product: product)
          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity)
                 |> json(%{errors: format_errors(changeset)})
        end
      end

      def delete(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        {:ok, _} = Catalog.delete_product(product)
        send_resp(conn, :no_content, "")
      end

      defp format_errors(changeset) do
        Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
      end
    end

    # JSON View — structured serialization:
    defmodule MyAppWeb.API.ProductJSON do
      def index(%{products: products}) do
        %{data: for(product <- products, do: data(product))}
      end

      def show(%{product: product}) do
        %{data: data(product)}
      end

      defp data(product) do
        %{
          id: product.id,
          name: product.name,
          price: product.price,
          inserted_at: product.inserted_at
        }
      end
    end
    """
    |> String.trim()
  end

  @endpoints [
    %{method: "GET", path: "/api/products", action: "index", status: 200, desc: "List products"},
    %{method: "GET", path: "/api/products/:id", action: "show", status: 200, desc: "Get one product"},
    %{method: "POST", path: "/api/products", action: "create", status: 201, desc: "Create product"},
    %{method: "PUT", path: "/api/products/:id", action: "update", status: 200, desc: "Update product"},
    %{method: "DELETE", path: "/api/products/:id", action: "delete", status: 204, desc: "Delete product"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "endpoints",
       selected_endpoint: "index",
       selected_view_tab: "inline"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">JSON APIs</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Build JSON APIs with Phoenix. No templates, no layouts — just data in, JSON out.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["endpoints", "views", "errors", "code"]}
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

      <!-- Endpoints -->
      <%= if @active_tab == "endpoints" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Click an endpoint to see its controller implementation and response.
          </p>

          <!-- Endpoint table -->
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="text-left text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-2 pr-4">Method</th>
                  <th class="py-2 pr-4">Endpoint</th>
                  <th class="py-2 pr-4">Status</th>
                  <th class="py-2">Description</th>
                </tr>
              </thead>
              <tbody>
                <%= for ep <- endpoints() do %>
                  <tr
                    phx-click="select_endpoint"
                    phx-target={@myself}
                    phx-value-action={ep.action}
                    class={["border-b border-gray-100 dark:border-gray-800 cursor-pointer transition-colors",
                      if(@selected_endpoint == ep.action,
                        do: "bg-teal-50 dark:bg-teal-900/20",
                        else: "hover:bg-gray-50 dark:hover:bg-gray-800")]}
                  >
                    <td class="py-2 pr-4">
                      <span class={["px-2 py-0.5 rounded text-xs font-bold", method_color(ep.method)]}>{ep.method}</span>
                    </td>
                    <td class="py-2 pr-4 font-mono text-gray-700 dark:text-gray-300">{ep.path}</td>
                    <td class="py-2 pr-4 font-mono text-gray-500">{ep.status}</td>
                    <td class="py-2 text-gray-500 dark:text-gray-400">{ep.desc}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <!-- Controller code -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div>
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Controller</h4>
              <div class="bg-gray-900 rounded-lg p-4 font-mono text-xs text-green-400 overflow-x-auto whitespace-pre">{endpoint_controller_code(@selected_endpoint)}</div>
            </div>
            <div>
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Response</h4>
              <div class="bg-gray-900 rounded-lg p-4 font-mono text-xs text-blue-400 overflow-x-auto whitespace-pre">{endpoint_response(@selected_endpoint)}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- JSON Views -->
      <%= if @active_tab == "views" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Two approaches to JSON serialization: inline with <code>json/2</code> or structured with JSON views.
          </p>

          <div class="flex gap-2">
            <button :for={{tab, label} <- [{"inline", "Inline (json/2)"}, {"view", "JSON View Module"}]}
              phx-click="select_view_tab"
              phx-target={@myself}
              phx-value-tab={tab}
              class={["px-4 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors",
                if(@selected_view_tab == tab,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-300")]}
            >
              {label}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{view_code(@selected_view_tab)}</div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">When to use which?</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              <strong>Inline</strong>: Quick prototypes, simple APIs with few endpoints.<br/>
              <strong>JSON Views</strong>: Production APIs where you need consistent serialization across endpoints and want to control exactly which fields are exposed.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Error handling -->
      <%= if @active_tab == "errors" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            APIs need structured error responses. Here are common patterns.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Validation Errors (422)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{validation_error_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Not Found (404)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{not_found_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Unauthorized (401)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{unauthorized_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Changeset Errors</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{changeset_error_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete API Setup</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_api_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_endpoint", %{"action" => action}, socket) do
    {:noreply, assign(socket, selected_endpoint: action)}
  end

  def handle_event("select_view_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, selected_view_tab: tab)}
  end

  defp tab_label("endpoints"), do: "Endpoints"
  defp tab_label("views"), do: "JSON Views"
  defp tab_label("errors"), do: "Error Handling"
  defp tab_label("code"), do: "Source Code"

  defp endpoints, do: @endpoints

  defp method_color("GET"), do: "bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400"
  defp method_color("POST"), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp method_color("PUT"), do: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400"
  defp method_color("DELETE"), do: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"

  defp endpoint_controller_code("index") do
    """
    def index(conn, _params) do
      products = Catalog.list_products()
      json(conn, %{data: products})
    end\
    """
    |> String.trim()
  end

  defp endpoint_controller_code("show") do
    """
    def show(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      json(conn, %{data: product})
    end\
    """
    |> String.trim()
  end

  defp endpoint_controller_code("create") do
    """
    def create(conn, %{"product" => params}) do
      case Catalog.create_product(params) do
        {:ok, product} ->
          conn
          |> put_status(:created)
          |> json(%{data: product})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_errors(changeset)})
      end
    end\
    """
    |> String.trim()
  end

  defp endpoint_controller_code("update") do
    """
    def update(conn, %{"id" => id, "product" => params}) do
      product = Catalog.get_product!(id)

      case Catalog.update_product(product, params) do
        {:ok, product} ->
          json(conn, %{data: product})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_errors(changeset)})
      end
    end\
    """
    |> String.trim()
  end

  defp endpoint_controller_code("delete") do
    """
    def delete(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      {:ok, _} = Catalog.delete_product(product)
      send_resp(conn, :no_content, "")
    end\
    """
    |> String.trim()
  end

  defp endpoint_response("index") do
    """
    HTTP/1.1 200 OK
    Content-Type: application/json

    {
      "data": [
        {"id": 1, "name": "Widget", "price": 9.99},
        {"id": 2, "name": "Gadget", "price": 19.99}
      ]
    }\
    """
    |> String.trim()
  end

  defp endpoint_response("show") do
    """
    HTTP/1.1 200 OK
    Content-Type: application/json

    {
      "data": {
        "id": 42,
        "name": "Widget",
        "price": 9.99,
        "inserted_at": "2024-01-15T10:30:00Z"
      }
    }\
    """
    |> String.trim()
  end

  defp endpoint_response("create") do
    """
    HTTP/1.1 201 Created
    Content-Type: application/json

    {
      "data": {
        "id": 43,
        "name": "New Product",
        "price": 29.99
      }
    }\
    """
    |> String.trim()
  end

  defp endpoint_response("update") do
    """
    HTTP/1.1 200 OK
    Content-Type: application/json

    {
      "data": {
        "id": 42,
        "name": "Updated Widget",
        "price": 14.99
      }
    }\
    """
    |> String.trim()
  end

  defp endpoint_response("delete") do
    """
    HTTP/1.1 204 No Content

    (empty body)\
    """
    |> String.trim()
  end

  defp view_code("inline") do
    """
    # Inline — use json/2 directly in controller:
    def index(conn, _params) do
      products = Catalog.list_products()
      json(conn, %{
        data: Enum.map(products, fn p ->
          %{id: p.id, name: p.name, price: p.price}
        end),
        meta: %{count: length(products)}
      })
    end

    def show(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      json(conn, %{
        data: %{id: product.id, name: product.name, price: product.price}
      })
    end\
    """
    |> String.trim()
  end

  defp view_code("view") do
    """
    # JSON View module — structured serialization:

    # lib/my_app_web/controllers/api/product_json.ex
    defmodule MyAppWeb.API.ProductJSON do
      def index(%{products: products}) do
        %{data: for(product <- products, do: data(product))}
      end

      def show(%{product: product}) do
        %{data: data(product)}
      end

      defp data(product) do
        %{
          id: product.id,
          name: product.name,
          price: product.price,
          inserted_at: product.inserted_at
        }
      end
    end

    # In controller — use render instead of json:
    def index(conn, _params) do
      products = Catalog.list_products()
      render(conn, :index, products: products)
      # → Calls ProductJSON.index(%{products: products})
    end\
    """
    |> String.trim()
  end

  defp validation_error_code do
    """
    # 422 — validation failed
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      errors: %{
        name: ["can't be blank"],
        price: ["must be greater than 0"]
      }
    })\
    """
    |> String.trim()
  end

  defp not_found_code do
    """
    # 404 — resource not found
    def show(conn, %{"id" => id}) do
      case Catalog.get_product(id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Product not found"})
        product ->
          json(conn, %{data: product})
      end
    end\
    """
    |> String.trim()
  end

  defp unauthorized_code do
    """
    # 401 — in auth plug
    def call(conn, _opts) do
      case get_req_header(conn, "authorization") do
        ["Bearer " <> token] ->
          verify_token(conn, token)
        _ ->
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "Missing auth token"})
          |> halt()
      end
    end\
    """
    |> String.trim()
  end

  defp changeset_error_code do
    """
    # Convert changeset errors to JSON:
    defp format_errors(changeset) do
      Ecto.Changeset.traverse_errors(
        changeset,
        fn {msg, opts} ->
          Regex.replace(
            ~r"%{(\\w+)}",
            msg,
            fn _, key ->
              opts
              |> Keyword.get(String.to_existing_atom(key), key)
              |> to_string()
            end
          )
        end
      )
    end\
    """
    |> String.trim()
  end

  defp full_api_code do
    """
    # Router:
    pipeline :api do
      plug :accepts, ["json"]
    end

    pipeline :api_auth do
      plug MyAppWeb.Plugs.VerifyBearerToken
    end

    scope "/api", MyAppWeb.API do
      pipe_through :api

      # Public endpoints
      resources "/products", ProductController, only: [:index, :show]
    end

    scope "/api", MyAppWeb.API do
      pipe_through [:api, :api_auth]

      # Authenticated endpoints
      resources "/products", ProductController, only: [:create, :update, :delete]
      resources "/orders", OrderController, except: [:new, :edit]
    end

    # Controller:
    defmodule MyAppWeb.API.ProductController do
      use MyAppWeb, :controller

      def index(conn, params) do
        products = Catalog.list_products(
          page: to_int(params["page"], 1),
          per_page: to_int(params["per_page"], 20)
        )
        render(conn, :index, products: products)
      end

      def show(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        render(conn, :show, product: product)
      end

      def create(conn, %{"product" => params}) do
        case Catalog.create_product(params) do
          {:ok, product} ->
            conn |> put_status(:created) |> render(:show, product: product)
          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity)
                 |> json(%{errors: format_errors(changeset)})
        end
      end

      def delete(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        {:ok, _} = Catalog.delete_product(product)
        send_resp(conn, :no_content, "")
      end

      defp to_int(nil, d), do: d
      defp to_int(s, d) do
        case Integer.parse(s) do
          {n, ""} -> n
          _ -> d
        end
      end

      defp format_errors(changeset) do
        Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
      end
    end\
    """
    |> String.trim()
  end
end
