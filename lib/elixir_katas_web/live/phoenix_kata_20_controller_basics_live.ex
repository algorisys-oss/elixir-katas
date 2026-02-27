defmodule ElixirKatasWeb.PhoenixKata20ControllerBasicsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Controllers handle HTTP requests
    # Each action receives conn and params, returns a response

    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      def index(conn, params) do
        page = to_int(params["page"], 1)
        products = Catalog.list_products(page: page)
        render(conn, :index, products: products, page: page)
      end

      def show(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        render(conn, :show, product: product)
      end

      def new(conn, _params) do
        changeset = Catalog.change_product(%Product{})
        render(conn, :new, changeset: changeset)
      end

      def create(conn, %{"product" => params}) do
        case Catalog.create_product(params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product created!")
            |> redirect(to: ~p"/products/\#{product}")

          {:error, changeset} ->
            render(conn, :new, changeset: changeset)
        end
      end

      def delete(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        {:ok, _} = Catalog.delete_product(product)

        conn
        |> put_flash(:info, "Deleted!")
        |> redirect(to: ~p"/products")
      end

      defp to_int(nil, default), do: default
      defp to_int(str, default) do
        case Integer.parse(str) do
          {n, ""} -> n
          _ -> default
        end
      end
    end

    # Response types:
    render(conn, :index, products: products)  # HTML template
    json(conn, %{data: products})             # JSON response
    text(conn, "OK")                          # Plain text
    html(conn, "<h1>Hello!</h1>")             # Raw HTML
    redirect(conn, to: ~p"/products")         # 302 redirect
    send_resp(conn, 204, "")                  # Custom status

    # The conn struct — request fields:
    conn.method        # "GET"
    conn.request_path  # "/products/42"
    conn.params        # %{"id" => "42", "tab" => "reviews"}

    # Modifying conn:
    conn
    |> put_status(:created)
    |> put_resp_header("x-req", "abc")
    |> assign(:key, value)
    |> put_flash(:info, "Done!")
    |> put_session(:user_id, 42)

    # Common status codes:
    # 200 :ok             201 :created          204 :no_content
    # 301 :moved_permanently  302 :found
    # 400 :bad_request    401 :unauthorized      403 :forbidden
    # 404 :not_found      422 :unprocessable_entity
    """
    |> String.trim()
  end

  @response_types [
    %{id: "render", label: "render", desc: "HTML template", status: 200, content_type: "text/html"},
    %{id: "json", label: "json", desc: "JSON response", status: 200, content_type: "application/json"},
    %{id: "text", label: "text", desc: "Plain text", status: 200, content_type: "text/plain"},
    %{id: "html", label: "html", desc: "Raw HTML string", status: 200, content_type: "text/html"},
    %{id: "redirect", label: "redirect", desc: "302 redirect", status: 302, content_type: "text/html"},
    %{id: "send_resp", label: "send_resp", desc: "Custom status", status: 204, content_type: "text/plain"}
  ]

  @status_codes [
    %{code: 200, atom: ":ok", desc: "Success"},
    %{code: 201, atom: ":created", desc: "Resource created"},
    %{code: 204, atom: ":no_content", desc: "Success, no body"},
    %{code: 301, atom: ":moved_permanently", desc: "Permanent redirect"},
    %{code: 302, atom: ":found", desc: "Temporary redirect"},
    %{code: 400, atom: ":bad_request", desc: "Malformed request"},
    %{code: 401, atom: ":unauthorized", desc: "Not authenticated"},
    %{code: 403, atom: ":forbidden", desc: "Not authorized"},
    %{code: 404, atom: ":not_found", desc: "Resource not found"},
    %{code: 422, atom: ":unprocessable_entity", desc: "Validation failed"},
    %{code: 500, atom: ":internal_server_error", desc: "Server error"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "actions",
       selected_response: "render",
       selected_action: "index"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Controller Basics</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Controllers handle HTTP requests. Each action receives <code>conn</code> and <code>params</code>, then returns a response.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["actions", "responses", "conn", "code"]}
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

      <!-- Actions -->
      <%= if @active_tab == "actions" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Click an action to see its implementation. Each follows REST conventions.
          </p>

          <div class="flex flex-wrap gap-2">
            <button :for={action <- ["index", "show", "new", "create", "edit", "update", "delete"]}
              phx-click="select_action"
              phx-target={@myself}
              phx-value-action={action}
              class={["px-3 py-2 rounded-lg text-xs font-mono font-semibold cursor-pointer transition-colors",
                if(@selected_action == action,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {action}
            </button>
          </div>

          <!-- Action detail -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div class="p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase mb-1">HTTP Method</p>
              <p class="font-mono text-sm font-bold text-gray-800 dark:text-gray-200">{action_method(@selected_action)}</p>
            </div>
            <div class="p-3 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-xs font-semibold text-purple-600 dark:text-purple-400 uppercase mb-1">Path</p>
              <p class="font-mono text-sm text-gray-800 dark:text-gray-200">{action_path(@selected_action)}</p>
            </div>
            <div class="p-3 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-xs font-semibold text-green-600 dark:text-green-400 uppercase mb-1">Purpose</p>
              <p class="text-sm text-gray-800 dark:text-gray-200">{action_purpose(@selected_action)}</p>
            </div>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{action_code(@selected_action)}</div>
        </div>
      <% end %>

      <!-- Response types -->
      <%= if @active_tab == "responses" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Controllers can return different response types. Click one to see the code.
          </p>

          <div class="flex flex-wrap gap-2">
            <%= for resp <- response_types() do %>
              <button
                phx-click="select_response"
                phx-target={@myself}
                phx-value-id={resp.id}
                class={["px-3 py-2 rounded-lg text-sm font-mono font-medium cursor-pointer transition-colors border",
                  if(@selected_response == resp.id,
                    do: "bg-teal-50 dark:bg-teal-900/30 border-teal-400 text-teal-700 dark:text-teal-300",
                    else: "border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:border-gray-300")]}
              >
                {resp.label}
              </button>
            <% end %>
          </div>

          <% resp = Enum.find(response_types(), &(&1.id == @selected_response)) %>
          <div class="grid grid-cols-3 gap-3">
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-center">
              <p class="text-xs text-gray-500 uppercase mb-1">Status</p>
              <p class="font-mono font-bold text-lg text-gray-800 dark:text-gray-200">{resp.status}</p>
            </div>
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-center">
              <p class="text-xs text-gray-500 uppercase mb-1">Content-Type</p>
              <p class="font-mono text-sm text-gray-800 dark:text-gray-200">{resp.content_type}</p>
            </div>
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-center">
              <p class="text-xs text-gray-500 uppercase mb-1">Function</p>
              <p class="font-mono text-sm font-bold text-teal-600 dark:text-teal-400">{resp.label}/2</p>
            </div>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{response_code(@selected_response)}</div>

          <!-- Status codes reference -->
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Common Status Codes</h4>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="text-left text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-2 pr-4">Code</th>
                  <th class="py-2 pr-4">Atom</th>
                  <th class="py-2">Description</th>
                </tr>
              </thead>
              <tbody>
                <%= for sc <- status_codes() do %>
                  <tr class="border-b border-gray-100 dark:border-gray-800">
                    <td class="py-1.5 pr-4 font-mono font-bold text-gray-700 dark:text-gray-300">{sc.code}</td>
                    <td class="py-1.5 pr-4 font-mono text-blue-600 dark:text-blue-400">{sc.atom}</td>
                    <td class="py-1.5 text-gray-500 dark:text-gray-400">{sc.desc}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>

      <!-- The conn struct -->
      <%= if @active_tab == "conn" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>%Plug.Conn{}</code> carries everything about the request and response through the pipeline.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20">
              <h4 class="font-semibold text-blue-700 dark:text-blue-300 mb-2">Request Fields</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{conn_request_fields()}</div>
            </div>
            <div class="p-4 rounded-lg border border-purple-200 dark:border-purple-800 bg-purple-50 dark:bg-purple-900/20">
              <h4 class="font-semibold text-purple-700 dark:text-purple-300 mb-2">Response Fields</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{conn_response_fields()}</div>
            </div>
            <div class="p-4 rounded-lg border border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/20">
              <h4 class="font-semibold text-green-700 dark:text-green-300 mb-2">Assigns</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{conn_assigns_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/20">
              <h4 class="font-semibold text-amber-700 dark:text-amber-300 mb-2">Modifying conn</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{conn_modify_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Controller Example</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_controller_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_action", %{"action" => action}, socket) do
    {:noreply, assign(socket, selected_action: action)}
  end

  def handle_event("select_response", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_response: id)}
  end

  defp tab_label("actions"), do: "Actions"
  defp tab_label("responses"), do: "Responses"
  defp tab_label("conn"), do: "The Conn"
  defp tab_label("code"), do: "Source Code"

  defp response_types, do: @response_types
  defp status_codes, do: @status_codes

  defp action_method("index"), do: "GET"
  defp action_method("show"), do: "GET"
  defp action_method("new"), do: "GET"
  defp action_method("create"), do: "POST"
  defp action_method("edit"), do: "GET"
  defp action_method("update"), do: "PUT / PATCH"
  defp action_method("delete"), do: "DELETE"

  defp action_path("index"), do: "/products"
  defp action_path("show"), do: "/products/:id"
  defp action_path("new"), do: "/products/new"
  defp action_path("create"), do: "/products"
  defp action_path("edit"), do: "/products/:id/edit"
  defp action_path("update"), do: "/products/:id"
  defp action_path("delete"), do: "/products/:id"

  defp action_purpose("index"), do: "List all products"
  defp action_purpose("show"), do: "Show one product"
  defp action_purpose("new"), do: "Show create form"
  defp action_purpose("create"), do: "Save new product"
  defp action_purpose("edit"), do: "Show edit form"
  defp action_purpose("update"), do: "Save changes"
  defp action_purpose("delete"), do: "Remove product"

  defp action_code("index") do
    """
    def index(conn, _params) do
      products = Catalog.list_products()
      render(conn, :index, products: products)
    end\
    """
    |> String.trim()
  end

  defp action_code("show") do
    """
    def show(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      render(conn, :show, product: product)
    end\
    """
    |> String.trim()
  end

  defp action_code("new") do
    """
    def new(conn, _params) do
      changeset = Catalog.change_product(%Product{})
      render(conn, :new, changeset: changeset)
    end\
    """
    |> String.trim()
  end

  defp action_code("create") do
    """
    def create(conn, %{"product" => product_params}) do
      case Catalog.create_product(product_params) do
        {:ok, product} ->
          conn
          |> put_flash(:info, "Product created!")
          |> redirect(to: ~p"/products/\#{product}")

        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp action_code("edit") do
    """
    def edit(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      changeset = Catalog.change_product(product)
      render(conn, :edit, product: product, changeset: changeset)
    end\
    """
    |> String.trim()
  end

  defp action_code("update") do
    """
    def update(conn, %{"id" => id, "product" => params}) do
      product = Catalog.get_product!(id)

      case Catalog.update_product(product, params) do
        {:ok, product} ->
          conn
          |> put_flash(:info, "Updated!")
          |> redirect(to: ~p"/products/\#{product}")

        {:error, changeset} ->
          render(conn, :edit, product: product, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp action_code("delete") do
    """
    def delete(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      {:ok, _} = Catalog.delete_product(product)

      conn
      |> put_flash(:info, "Deleted!")
      |> redirect(to: ~p"/products")
    end\
    """
    |> String.trim()
  end

  defp response_code("render") do
    """
    def index(conn, _params) do
      products = Catalog.list_products()
      render(conn, :index, products: products)
      # Looks up ProductHTML.index template
      # Returns 200 with rendered HTML
    end\
    """
    |> String.trim()
  end

  defp response_code("json") do
    """
    def index(conn, _params) do
      products = Catalog.list_products()
      json(conn, %{data: products, count: length(products)})
      # Returns 200 with JSON body
      # Content-Type: application/json
    end\
    """
    |> String.trim()
  end

  defp response_code("text") do
    """
    def health(conn, _params) do
      text(conn, "OK")
      # Returns 200 with plain text
      # Content-Type: text/plain
    end\
    """
    |> String.trim()
  end

  defp response_code("html") do
    """
    def inline(conn, _params) do
      html(conn, "<h1>Hello!</h1><p>Raw HTML string</p>")
      # Returns 200 with raw HTML
      # No template needed
    end\
    """
    |> String.trim()
  end

  defp response_code("redirect") do
    """
    def create(conn, %{"product" => params}) do
      {:ok, product} = Catalog.create_product(params)

      conn
      |> put_flash(:info, "Created!")
      |> redirect(to: ~p"/products/\#{product}")
      # Returns 302 redirect
      # Browser follows Location header
    end\
    """
    |> String.trim()
  end

  defp response_code("send_resp") do
    """
    def delete(conn, %{"id" => id}) do
      Catalog.delete_product!(id)
      send_resp(conn, 204, "")
      # Returns 204 No Content
      # Custom status code + body
    end\
    """
    |> String.trim()
  end

  defp conn_request_fields do
    """
    conn.method        # "GET"
    conn.request_path  # "/products/42"
    conn.path_info     # ["products", "42"]
    conn.query_string  # "tab=reviews"
    conn.params        # %{"id" => "42", "tab" => "reviews"}
    conn.host          # "localhost"
    conn.port          # 4000
    conn.scheme        # :http
    conn.remote_ip     # {127, 0, 0, 1}\
    """
    |> String.trim()
  end

  defp conn_response_fields do
    """
    conn.status        # 200 (set by render/json/etc)
    conn.resp_body     # "<html>..." (set by render)
    conn.resp_headers  # [{"content-type", "text/html"}]
    conn.state         # :unset → :set → :sent
    conn.halted        # true if halt() was called\
    """
    |> String.trim()
  end

  defp conn_assigns_code do
    """
    # Plugs set assigns:
    conn = assign(conn, :current_user, user)

    # Access in controller:
    conn.assigns.current_user
    conn.assigns[:current_user]

    # Access in template:
    @current_user\
    """
    |> String.trim()
  end

  defp conn_modify_code do
    """
    conn
    |> put_status(:created)        # Set status
    |> put_resp_header("x-req", "abc") # Add header
    |> put_resp_content_type("application/json")
    |> assign(:key, value)         # Set assign
    |> put_flash(:info, "Done!")   # Flash message
    |> put_session(:user_id, 42)   # Session data
    |> json(%{ok: true})           # Send response\
    """
    |> String.trim()
  end

  defp full_controller_code do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      def index(conn, params) do
        page = to_int(params["page"], 1)
        products = Catalog.list_products(page: page)
        render(conn, :index, products: products, page: page)
      end

      def show(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        render(conn, :show, product: product)
      end

      def new(conn, _params) do
        changeset = Catalog.change_product(%Product{})
        render(conn, :new, changeset: changeset)
      end

      def create(conn, %{"product" => params}) do
        case Catalog.create_product(params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product created!")
            |> redirect(to: ~p"/products/\#{product}")

          {:error, changeset} ->
            render(conn, :new, changeset: changeset)
        end
      end

      def delete(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        {:ok, _} = Catalog.delete_product(product)

        conn
        |> put_flash(:info, "Deleted!")
        |> redirect(to: ~p"/products")
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
