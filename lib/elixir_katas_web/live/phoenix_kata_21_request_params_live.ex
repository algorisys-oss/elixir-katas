defmodule ElixirKatasWeb.PhoenixKata21RequestParamsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      # Optional params with defaults
      def index(conn, params) do
        opts = [
          page: to_int(params["page"], 1),
          per_page: to_int(params["per_page"], 20),
          sort: params["sort"] || "inserted_at",
          category: params["category"]
        ]
        products = Catalog.list_products(opts)
        render(conn, :index, products: products, opts: opts)
      end

      # Required path param — MatchError if missing
      def show(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        render(conn, :show, product: product)
      end

      # Nested form params
      def create(conn, %{"product" => product_params}) do
        case Catalog.create_product(product_params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Created!")
            |> redirect(to: ~p"/products/\#{product}")
          {:error, changeset} ->
            render(conn, :new, changeset: changeset)
        end
      end

      # Match on specific values — dispatch different behaviors
      def export(conn, %{"format" => "csv"}) do
        csv = Catalog.products_to_csv()
        send_download(conn, {:binary, csv}, filename: "products.csv")
      end

      def export(conn, %{"format" => "json"}) do
        products = Catalog.list_products()
        json(conn, %{products: products})
      end

      def export(conn, _params) do
        render(conn, :export_options)
      end

      # Extract specific keys AND keep the full map
      def update(conn, %{"id" => id, "product" => product_params} = params) do
        redirect_to = params["redirect_to"] || "/products"
        product = Catalog.get_product!(id)
        Catalog.update_product(product, product_params)
        redirect(conn, to: redirect_to)
      end

      defp to_int(nil, default), do: default
      defp to_int(str, default) do
        case Integer.parse(str) do
          {n, ""} -> n
          _ -> default
        end
      end
    end
    """
    |> String.trim()
  end

  @param_sources [
    %{id: "path", label: "Path Params", example: "/users/42", result: ~s(%{"id" => "42"}), color: "blue"},
    %{id: "query", label: "Query Params", example: "?page=2&sort=name", result: ~s(%{"page" => "2", "sort" => "name"}), color: "purple"},
    %{id: "body", label: "Body Params", example: "user[name]=Alice", result: ~s(%{"user" => %{"name" => "Alice"}}), color: "green"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "sources",
       selected_pattern: "required",
       test_params: ~s(%{"id" => "42", "format" => "json", "page" => "2"}),
       match_result: nil
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Request Params & Pattern Matching</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Extract params from URLs, query strings, and form data using Elixir's pattern matching.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["sources", "patterns", "nested", "code"]}
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

      <!-- Param Sources -->
      <%= if @active_tab == "sources" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Params come from three sources and are merged into a single map.
          </p>

          <div class="space-y-3">
            <%= for source <- param_sources() do %>
              <div class={["p-4 rounded-lg border",
                "border-#{source.color}-200 dark:border-#{source.color}-800",
                "bg-#{source.color}-50 dark:bg-#{source.color}-900/20"]}>
                <div class="flex items-center justify-between mb-2">
                  <h4 class={"font-semibold text-#{source.color}-700 dark:text-#{source.color}-300"}>{source.label}</h4>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div>
                    <p class="text-xs text-gray-500 uppercase mb-1">Input</p>
                    <p class="font-mono text-sm text-gray-700 dark:text-gray-300">{source.example}</p>
                  </div>
                  <div>
                    <p class="text-xs text-gray-500 uppercase mb-1">Params</p>
                    <p class="font-mono text-sm text-gray-700 dark:text-gray-300">{source.result}</p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Merge diagram -->
          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">All Three Merge Into One Map</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{merged_params_code()}</div>
          </div>

          <div class="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
            <p class="text-sm text-red-700 dark:text-red-300">
              <strong>All params are strings!</strong> Even numeric path params like <code>:id</code>
              arrive as <code>"42"</code> not <code>42</code>. Always convert: <code>String.to_integer(id)</code>
            </p>
          </div>
        </div>
      <% end %>

      <!-- Pattern matching -->
      <%= if @active_tab == "patterns" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Different ways to pattern match params in controller function heads.
          </p>

          <div class="flex flex-wrap gap-2">
            <button :for={pattern <- ["required", "multiple", "values", "keep_all", "optional", "guard"]}
              phx-click="select_pattern"
              phx-target={@myself}
              phx-value-pattern={pattern}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_pattern == pattern,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {pattern_label(pattern)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{pattern_code(@selected_pattern)}</div>

          <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <p class="text-sm text-gray-600 dark:text-gray-300">{pattern_explanation(@selected_pattern)}</p>
          </div>
        </div>
      <% end %>

      <!-- Nested params -->
      <%= if @active_tab == "nested" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            HTML forms send nested params. See how form field names map to Elixir maps.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">HTML Form</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{form_html_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Resulting Params</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{form_params_code()}</div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Pattern Match Form Data</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{form_match_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Strong Params (via Ecto)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{strong_params_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Controller with All Param Patterns</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_pattern", %{"pattern" => pattern}, socket) do
    {:noreply, assign(socket, selected_pattern: pattern)}
  end

  defp tab_label("sources"), do: "Param Sources"
  defp tab_label("patterns"), do: "Pattern Matching"
  defp tab_label("nested"), do: "Nested Params"
  defp tab_label("code"), do: "Source Code"

  defp param_sources, do: @param_sources

  defp pattern_label("required"), do: "Required"
  defp pattern_label("multiple"), do: "Multiple"
  defp pattern_label("values"), do: "Match Values"
  defp pattern_label("keep_all"), do: "Keep Full Map"
  defp pattern_label("optional"), do: "Optional"
  defp pattern_label("guard"), do: "Guards"

  defp merged_params_code do
    """
    # GET /users/42?tab=posts
    # with route: get "/users/:id", UserController, :show

    def show(conn, params) do
      # params = %{
      #   "id"  => "42",   ← from path
      #   "tab" => "posts" ← from query string
      # }
    end\
    """
    |> String.trim()
  end

  defp pattern_code("required") do
    """
    # Requires "id" — MatchError if missing
    def show(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      render(conn, :show, product: product)
    end

    # If someone calls this without "id" in params:
    # ** (MatchError) no match of right hand side value\
    """
    |> String.trim()
  end

  defp pattern_code("multiple") do
    """
    # Extract multiple params at once:
    def update(conn, %{"id" => id, "product" => product_params}) do
      product = Catalog.get_product!(id)
      Catalog.update_product(product, product_params)
    end

    # Nested resources:
    def index(conn, %{"user_id" => user_id}) do
      posts = Blog.list_posts_for_user(user_id)
      render(conn, :index, posts: posts)
    end\
    """
    |> String.trim()
  end

  defp pattern_code("values") do
    """
    # Match on SPECIFIC VALUES — dispatch different behaviors:

    def export(conn, %{"format" => "csv"}) do
      csv = Products.to_csv()
      send_download(conn, {:binary, csv}, filename: "products.csv")
    end

    def export(conn, %{"format" => "json"}) do
      products = Products.list_all()
      json(conn, %{products: products})
    end

    def export(conn, _params) do
      # Default — no format specified
      render(conn, :export_options)
    end

    # Elixir tries clauses TOP TO BOTTOM — specific first!\
    """
    |> String.trim()
  end

  defp pattern_code("keep_all") do
    """
    # Extract specific keys AND keep the full map:
    def create(conn, %{"product" => product_params} = params) do
      redirect_to = params["redirect_to"] || "/products"
      # product_params = %{"name" => "Widget", "price" => "9.99"}
      # params = the full map including "redirect_to"

      case Catalog.create_product(product_params) do
        {:ok, _product} -> redirect(conn, to: redirect_to)
        {:error, changeset} -> render(conn, :new, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp pattern_code("optional") do
    """
    # Don't pattern match — use Map.get/3 for defaults:
    def index(conn, params) do
      page = Map.get(params, "page", "1") |> String.to_integer()
      per_page = Map.get(params, "per_page", "20") |> String.to_integer()
      sort = params["sort"] || "inserted_at"
      order = params["order"] || "desc"

      products = Catalog.list_products(
        page: page, per_page: per_page,
        sort: sort, order: order
      )
      render(conn, :index, products: products)
    end\
    """
    |> String.trim()
  end

  defp pattern_code("guard") do
    """
    # Combine pattern matching with guard clauses:
    def show(conn, %{"id" => id}) when is_binary(id) do
      case Integer.parse(id) do
        {num, ""} when num > 0 ->
          product = Catalog.get_product!(num)
          render(conn, :show, product: product)
        _ ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Invalid ID"})
      end
    end\
    """
    |> String.trim()
  end

  defp pattern_explanation("required"), do: "Pattern matching on required params crashes with MatchError if the key is missing. This is intentional — it means the route/form is misconfigured."
  defp pattern_explanation("multiple"), do: "Extract multiple keys in one pattern. Useful for nested resource routes (user_id + id) or form submissions (id + form data)."
  defp pattern_explanation("values"), do: "Match on specific values to dispatch different behavior. Elixir tries clauses top-to-bottom — put specific matches first, catch-all last."
  defp pattern_explanation("keep_all"), do: "Use = params to extract specific keys AND keep access to the full params map. Useful when you need both named fields and optional extras."
  defp pattern_explanation("optional"), do: "For optional params with defaults, don't pattern match in the function head. Use Map.get/3 or || to provide defaults in the function body."
  defp pattern_explanation("guard"), do: "Guards add extra conditions beyond pattern matching. Useful for validating param formats before processing."

  defp form_html_code do
    """
    <form action="/users" method="post">
      <input name="user[name]"
             value="Alice" />
      <input name="user[email]"
             value="alice@example.com" />
      <input name="user[address][city]"
             value="NYC" />
      <input name="user[tags][]"
             value="admin" />
      <input name="user[tags][]"
             value="editor" />
    </form>\
    """
    |> String.trim()
  end

  defp form_params_code do
    """
    %{
      "user" => %{
        "name" => "Alice",
        "email" => "alice@example.com",
        "address" => %{
          "city" => "NYC"
        },
        "tags" => ["admin", "editor"]
      }
    }\
    """
    |> String.trim()
  end

  defp form_match_code do
    """
    def create(conn, %{"user" => user_params}) do
      # user_params = %{
      #   "name" => "Alice",
      #   "email" => "alice@example.com",
      #   ...
      # }

      case Accounts.create_user(user_params) do
        {:ok, user} ->
          redirect(conn, to: ~p"/users/\#{user}")
        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp strong_params_code do
    """
    # In Ecto schema/changeset:
    def changeset(user, attrs) do
      user
      |> cast(attrs, [:name, :email])
      #   ↑ Only these fields are permitted
      |> validate_required([:name, :email])
      |> validate_format(:email, ~r/@/)
    end

    # Unpermitted fields are silently ignored
    # No need for Rails-style strong_params\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      # Optional params with defaults
      def index(conn, params) do
        opts = [
          page: to_int(params["page"], 1),
          per_page: to_int(params["per_page"], 20),
          sort: params["sort"] || "inserted_at",
          category: params["category"]
        ]
        products = Catalog.list_products(opts)
        render(conn, :index, products: products, opts: opts)
      end

      # Required path param
      def show(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        render(conn, :show, product: product)
      end

      # Nested form params
      def create(conn, %{"product" => product_params}) do
        case Catalog.create_product(product_params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Created!")
            |> redirect(to: ~p"/products/\#{product}")
          {:error, changeset} ->
            render(conn, :new, changeset: changeset)
        end
      end

      # Match on specific values
      def export(conn, %{"format" => "csv"}) do
        csv = Catalog.products_to_csv()
        send_download(conn, {:binary, csv}, filename: "products.csv")
      end

      def export(conn, %{"format" => "json"}) do
        products = Catalog.list_products()
        json(conn, %{products: products})
      end

      def export(conn, _params) do
        render(conn, :export_options)
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
