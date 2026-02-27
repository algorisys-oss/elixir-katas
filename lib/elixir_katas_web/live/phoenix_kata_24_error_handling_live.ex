defmodule ElixirKatasWeb.PhoenixKata24ErrorHandlingLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # 1. Fallback Controller — centralized error handling
    defmodule MyAppWeb.FallbackController do
      use MyAppWeb, :controller

      def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("422.json", changeset: changeset)
      end

      def call(conn, {:error, :not_found}) do
        conn
        |> put_status(:not_found)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("404.json")
      end

      def call(conn, {:error, :unauthorized}) do
        conn
        |> put_status(:unauthorized)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("401.json")
      end
    end

    # 2. Controller using action_fallback + with
    defmodule MyAppWeb.API.ProductController do
      use MyAppWeb, :controller
      action_fallback MyAppWeb.FallbackController

      def show(conn, %{"id" => id}) do
        with {:ok, product} <- Catalog.fetch_product(id) do
          render(conn, :show, product: product)
        end
      end

      def create(conn, %{"product" => params}) do
        with {:ok, product} <- Catalog.create_product(params) do
          conn |> put_status(:created) |> render(:show, product: product)
        end
      end
    end

    # 3. Error JSON view
    defmodule MyAppWeb.ErrorJSON do
      def render("422.json", %{changeset: changeset}) do
        errors = Ecto.Changeset.traverse_errors(changeset,
          fn {msg, _} -> msg end)
        %{errors: errors}
      end

      def render(template, _assigns) do
        %{errors: %{detail:
          Phoenix.Controller.status_message_from_template(template)}}
      end
    end

    # 4. Custom exceptions with HTTP status
    defmodule MyApp.NotFoundError do
      defexception message: "not found", plug_status: 404
    end
    """
    |> String.trim()
  end

  @exception_map [
    %{exception: "Ecto.NoResultsError", status: 404, desc: "Record not found in DB"},
    %{exception: "Phoenix.Router.NoRouteError", status: 404, desc: "No matching route"},
    %{exception: "Ecto.ChangeError", status: 422, desc: "Invalid changeset data"},
    %{exception: "Any unhandled exception", status: 500, desc: "Internal server error"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "auto",
       selected_approach: "bang",
       selected_fallback: "changeset"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Error Handling</h2>
      <p class="text-gray-600 dark:text-gray-300">
        How Phoenix converts exceptions to HTTP errors, custom error pages, and the action_fallback pattern.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["auto", "fallback", "views", "code"]}
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

      <!-- Auto error conversion -->
      <%= if @active_tab == "auto" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix automatically converts exceptions to HTTP error responses.
          </p>

          <!-- Exception → Status table -->
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="text-left text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-2 pr-4">Exception</th>
                  <th class="py-2 pr-4">Status</th>
                  <th class="py-2">Description</th>
                </tr>
              </thead>
              <tbody>
                <%= for ex <- exception_map() do %>
                  <tr class="border-b border-gray-100 dark:border-gray-800">
                    <td class="py-2 pr-4 font-mono text-sm text-red-600 dark:text-red-400">{ex.exception}</td>
                    <td class="py-2 pr-4">
                      <span class={["px-2 py-0.5 rounded text-xs font-bold",
                        status_color(ex.status)]}>{ex.status}</span>
                    </td>
                    <td class="py-2 text-gray-500 dark:text-gray-400">{ex.desc}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <!-- Approach selector -->
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Error Handling Approaches</h4>
          <div class="flex flex-wrap gap-2">
            <button :for={approach <- ["bang", "case", "with", "rescue"]}
              phx-click="select_approach"
              phx-target={@myself}
              phx-value-approach={approach}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_approach == approach,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {approach_label(approach)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{approach_code(@selected_approach)}</div>
        </div>
      <% end %>

      <!-- Action Fallback -->
      <%= if @active_tab == "fallback" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>action_fallback</code> centralizes error handling. Controllers return error tuples, the fallback handles them.
          </p>

          <!-- Flow diagram -->
          <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <div class="flex items-center gap-2 text-sm font-mono flex-wrap">
              <span class="px-2 py-1 rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300">Controller action</span>
              <span class="text-gray-400">→ returns</span>
              <span class="px-2 py-1 rounded bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300">error tuple</span>
              <span class="text-gray-400">→ handled by</span>
              <span class="px-2 py-1 rounded bg-amber-100 dark:bg-amber-900 text-amber-700 dark:text-amber-300">FallbackController</span>
              <span class="text-gray-400">→</span>
              <span class="px-2 py-1 rounded bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300">Error response</span>
            </div>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div>
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Controller (with fallback)</h4>
              <div class="bg-gray-900 rounded-lg p-4 font-mono text-xs text-green-400 overflow-x-auto whitespace-pre">{fallback_controller_code()}</div>
            </div>
            <div>
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Fallback Controller</h4>
              <div class="bg-gray-900 rounded-lg p-4 font-mono text-xs text-green-400 overflow-x-auto whitespace-pre">{fallback_code()}</div>
            </div>
          </div>

          <!-- Error type selector -->
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Fallback Handlers</h4>
          <div class="flex flex-wrap gap-2">
            <button :for={fb <- ["changeset", "not_found", "unauthorized", "forbidden"]}
              phx-click="select_fallback"
              phx-target={@myself}
              phx-value-fallback={fb}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_fallback == fb,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {fallback_label(fb)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{fallback_handler_code(@selected_fallback)}</div>
        </div>
      <% end %>

      <!-- Error views -->
      <%= if @active_tab == "views" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Error views render the actual error pages. Separate modules for HTML and JSON.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">ErrorHTML</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{error_html_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">ErrorJSON</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{error_json_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Custom Exceptions</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{custom_exception_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Config</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{error_config_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Error Handling Setup</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_approach", %{"approach" => approach}, socket) do
    {:noreply, assign(socket, selected_approach: approach)}
  end

  def handle_event("select_fallback", %{"fallback" => fb}, socket) do
    {:noreply, assign(socket, selected_fallback: fb)}
  end

  defp tab_label("auto"), do: "Auto Errors"
  defp tab_label("fallback"), do: "Action Fallback"
  defp tab_label("views"), do: "Error Views"
  defp tab_label("code"), do: "Source Code"

  defp exception_map, do: @exception_map

  defp status_color(404), do: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400"
  defp status_color(422), do: "bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400"
  defp status_color(500), do: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"

  defp approach_label("bang"), do: "Bang! (auto 404)"
  defp approach_label("case"), do: "Case match"
  defp approach_label("with"), do: "With + fallback"
  defp approach_label("rescue"), do: "Rescue"

  defp approach_code("bang") do
    """
    # get_product! raises Ecto.NoResultsError → auto 404
    def show(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      render(conn, :show, product: product)
    end

    # If product doesn't exist:
    # → Ecto.NoResultsError is raised
    # → Phoenix catches it
    # → Returns 404 with ErrorHTML.render("404.html")\
    """
    |> String.trim()
  end

  defp approach_code("case") do
    """
    # Handle not-found explicitly with case:
    def show(conn, %{"id" => id}) do
      case Catalog.get_product(id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> put_view(MyAppWeb.ErrorHTML)
          |> render("404.html")

        product ->
          render(conn, :show, product: product)
      end
    end\
    """
    |> String.trim()
  end

  defp approach_code("with") do
    """
    # with + action_fallback — cleanest pattern:
    action_fallback MyAppWeb.FallbackController

    def show(conn, %{"id" => id}) do
      with {:ok, product} <- Catalog.fetch_product(id) do
        render(conn, :show, product: product)
      end
      # If fetch_product returns {:error, :not_found}
      # → FallbackController.call(conn, {:error, :not_found})
    end

    def create(conn, %{"product" => params}) do
      with {:ok, product} <- Catalog.create_product(params) do
        conn |> put_status(:created) |> render(:show, product: product)
      end
      # If create returns {:error, changeset}
      # → FallbackController.call(conn, {:error, changeset})
    end\
    """
    |> String.trim()
  end

  defp approach_code("rescue") do
    """
    # rescue — use sparingly, prefer action_fallback:
    def show(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      render(conn, :show, product: product)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> put_view(MyAppWeb.ErrorHTML)
        |> render("404.html")

      Ecto.Query.CastError ->
        conn
        |> put_status(:bad_request)
        |> put_view(MyAppWeb.ErrorHTML)
        |> render("400.html")
    end\
    """
    |> String.trim()
  end

  defp fallback_controller_code do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      # All errors delegated to fallback:
      action_fallback MyAppWeb.FallbackController

      def show(conn, %{"id" => id}) do
        with {:ok, product} <- Catalog.fetch_product(id) do
          render(conn, :show, product: product)
        end
      end

      def create(conn, %{"product" => params}) do
        with {:ok, product} <- Catalog.create_product(params) do
          conn
          |> put_status(:created)
          |> render(:show, product: product)
        end
      end
    end\
    """
    |> String.trim()
  end

  defp fallback_code do
    """
    defmodule MyAppWeb.FallbackController do
      use MyAppWeb, :controller

      def call(conn, {:error, %Ecto.Changeset{} = cs}) do
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("422.json", changeset: cs)
      end

      def call(conn, {:error, :not_found}) do
        conn
        |> put_status(:not_found)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("404.json")
      end

      def call(conn, {:error, :unauthorized}) do
        conn
        |> put_status(:unauthorized)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("401.json")
      end
    end\
    """
    |> String.trim()
  end

  defp fallback_label("changeset"), do: "Changeset (422)"
  defp fallback_label("not_found"), do: "Not Found (404)"
  defp fallback_label("unauthorized"), do: "Unauthorized (401)"
  defp fallback_label("forbidden"), do: "Forbidden (403)"

  defp fallback_handler_code("changeset") do
    """
    # {:error, %Ecto.Changeset{}} → 422 Unprocessable Entity
    def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
      conn
      |> put_status(:unprocessable_entity)
      |> put_view(json: MyAppWeb.ErrorJSON)
      |> render("422.json", changeset: changeset)
    end

    # Response:
    # {"errors": {"name": ["can't be blank"], "price": ["must be > 0"]}}\
    """
    |> String.trim()
  end

  defp fallback_handler_code("not_found") do
    """
    # {:error, :not_found} → 404 Not Found
    def call(conn, {:error, :not_found}) do
      conn
      |> put_status(:not_found)
      |> put_view(json: MyAppWeb.ErrorJSON)
      |> render("404.json")
    end

    # Response:
    # {"errors": {"detail": "Not Found"}}\
    """
    |> String.trim()
  end

  defp fallback_handler_code("unauthorized") do
    """
    # {:error, :unauthorized} → 401 Unauthorized
    def call(conn, {:error, :unauthorized}) do
      conn
      |> put_status(:unauthorized)
      |> put_view(json: MyAppWeb.ErrorJSON)
      |> render("401.json")
    end

    # Response:
    # {"errors": {"detail": "Unauthorized"}}\
    """
    |> String.trim()
  end

  defp fallback_handler_code("forbidden") do
    """
    # {:error, :forbidden} → 403 Forbidden
    def call(conn, {:error, :forbidden}) do
      conn
      |> put_status(:forbidden)
      |> put_view(json: MyAppWeb.ErrorJSON)
      |> render("403.json")
    end

    # Response:
    # {"errors": {"detail": "Forbidden"}}\
    """
    |> String.trim()
  end

  defp error_html_code do
    """
    defmodule MyAppWeb.ErrorHTML do
      use MyAppWeb, :html

      embed_templates "error_html/*"

      def render("404.html", _assigns) do
        "Page Not Found"
      end

      def render("500.html", _assigns) do
        "Internal Server Error"
      end

      def render(template, _assigns) do
        Phoenix.Controller
          .status_message_from_template(template)
      end
    end\
    """
    |> String.trim()
  end

  defp error_json_code do
    """
    defmodule MyAppWeb.ErrorJSON do
      def render("422.json", %{changeset: cs}) do
        %{errors: format_errors(cs)}
      end

      def render(template, _assigns) do
        %{errors: %{
          detail:
            Phoenix.Controller
              .status_message_from_template(template)
        }}
      end

      defp format_errors(changeset) do
        Ecto.Changeset.traverse_errors(
          changeset,
          fn {msg, _} -> msg end
        )
      end
    end\
    """
    |> String.trim()
  end

  defp custom_exception_code do
    """
    # Define exceptions with HTTP status:
    defmodule MyApp.NotFoundError do
      defexception message: "not found",
                   plug_status: 404
    end

    defmodule MyApp.ForbiddenError do
      defexception message: "access denied",
                   plug_status: 403
    end

    # Usage:
    def show(conn, %{"id" => id}) do
      case Catalog.get_product(id) do
        nil -> raise MyApp.NotFoundError
        product -> render(conn, :show, product: product)
      end
    end\
    """
    |> String.trim()
  end

  defp error_config_code do
    """
    # config/config.exs:
    config :my_app, MyAppWeb.Endpoint,
      render_errors: [
        formats: [
          html: MyAppWeb.ErrorHTML,
          json: MyAppWeb.ErrorJSON
        ],
        layout: false
      ]

    # config/dev.exs:
    config :my_app, MyAppWeb.Endpoint,
      debug_errors: true
      # Shows detailed error pages in dev
      # Set false in prod for custom pages\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # 1. Fallback Controller
    defmodule MyAppWeb.FallbackController do
      use MyAppWeb, :controller

      def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("422.json", changeset: changeset)
      end

      def call(conn, {:error, :not_found}) do
        conn
        |> put_status(:not_found)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("404.json")
      end

      def call(conn, {:error, :unauthorized}) do
        conn
        |> put_status(:unauthorized)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render("401.json")
      end
    end

    # 2. Controller using fallback
    defmodule MyAppWeb.API.ProductController do
      use MyAppWeb, :controller
      action_fallback MyAppWeb.FallbackController

      def index(conn, _params) do
        products = Catalog.list_products()
        render(conn, :index, products: products)
      end

      def show(conn, %{"id" => id}) do
        with {:ok, product} <- Catalog.fetch_product(id) do
          render(conn, :show, product: product)
        end
      end

      def create(conn, %{"product" => params}) do
        with {:ok, product} <- Catalog.create_product(params) do
          conn
          |> put_status(:created)
          |> render(:show, product: product)
        end
      end
    end

    # 3. Error JSON view
    defmodule MyAppWeb.ErrorJSON do
      def render("422.json", %{changeset: changeset}) do
        errors = Ecto.Changeset.traverse_errors(changeset,
          fn {msg, _} -> msg end)
        %{errors: errors}
      end

      def render(template, _assigns) do
        %{errors: %{detail:
          Phoenix.Controller.status_message_from_template(template)}}
      end
    end\
    """
    |> String.trim()
  end
end
