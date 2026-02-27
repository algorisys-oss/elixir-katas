defmodule ElixirKatasWeb.PhoenixKata19VerifiedRoutesLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Verified Routes — compile-time checked paths with ~p sigil
    # Typos become compiler errors, not runtime 404s!

    # Setup (auto-generated in lib/my_app_web.ex):
    defp html_helpers do
      quote do
        use Phoenix.VerifiedRoutes,
          endpoint: MyAppWeb.Endpoint,
          router: MyAppWeb.Router,
          statics: MyAppWeb.static_paths()
      end
    end

    # Basic usage:
    ~p"/products"                         # => "/products"
    ~p"/products/\#{product}"              # => "/products/42"
    ~p"/users/\#{user}/posts"              # => "/users/5/posts"
    ~p"/products?\#{%{page: 2, sort: "name"}}"  # => "/products?page=2&sort=name"

    # In controllers:
    def create(conn, %{"product" => params}) do
      case Catalog.create_product(params) do
        {:ok, product} ->
          conn
          |> put_flash(:info, "Created!")
          |> redirect(to: ~p"/products/\#{product}")

        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end

    # In templates (HEEx):
    <.link navigate={~p"/products"}>Products</.link>
    <.link navigate={~p"/products/\#{@product}"}>View</.link>
    <.link navigate={~p"/products/\#{@product}/edit"}>Edit</.link>

    <.form for={@changeset} action={~p"/products"}>
      ...
    </.form>

    # In LiveView:
    def handle_event("view", %{"id" => id}, socket) do
      {:noreply, push_navigate(socket, to: ~p"/products/\#{id}")}
    end

    # Static assets (cache-busting in prod):
    <link href={~p"/assets/app.css"} rel="stylesheet" />
    <script src={~p"/assets/app.js"}></script>
    # Dev:  "/assets/app.css"
    # Prod: "/assets/app-d3adb33f.css"

    # Typo? Compile error, not runtime 404:
    # ~p"/prodcuts/\#{id}"
    # => ** (CompileError) no route path matches "/prodcuts/*"

    # Migrating from old path helpers:
    # product_path(conn, :index)    → ~p"/products"
    # product_path(conn, :show, 42) → ~p"/products/\#{product}"
    """
    |> String.trim()
  end

  @examples [
    %{id: "basic", label: "Basic", path: "/products", route: "get \"/products\", ProductController, :index", result: "/products"},
    %{id: "with_param", label: "With Param", path: "/products/42", route: "get \"/products/:id\", ProductController, :show", result: "/products/42"},
    %{id: "nested", label: "Nested", path: "/users/5/posts", route: "resources \"/users\" do resources \"/posts\" end", result: "/users/5/posts"},
    %{id: "query", label: "Query Params", path: "/products?page=2&sort=name", route: "get \"/products\", ProductController, :index", result: "/products?page=2&sort=name"},
    %{id: "static", label: "Static Asset", path: "/assets/app.css", route: "(static file)", result: "/assets/app-ABC123.css"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "compare",
       selected_example: "basic",
       test_path: "/products/42",
       test_valid: true
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Verified Routes</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Compile-time checked paths with the <code>~p</code> sigil. Typos become compiler errors, not runtime 404s.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["compare", "examples", "usage", "code"]}
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

      <!-- Compare: String vs Verified -->
      <%= if @active_tab == "compare" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Compare string-based paths (old) vs verified routes (new). See what gets caught at compile time.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- String paths (old) -->
            <div class="p-4 rounded-lg border-2 border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/10">
              <div class="flex items-center gap-2 mb-3">
                <span class="w-3 h-3 rounded-full bg-red-500"></span>
                <h4 class="font-semibold text-red-700 dark:text-red-300">String Paths (risky)</h4>
              </div>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{string_paths_code()}</div>
              <div class="mt-3 space-y-1">
                <p class="text-xs text-red-600 dark:text-red-400 flex items-center gap-1">
                  <span>x</span> Typos compile fine
                </p>
                <p class="text-xs text-red-600 dark:text-red-400 flex items-center gap-1">
                  <span>x</span> Wrong param count compiles fine
                </p>
                <p class="text-xs text-red-600 dark:text-red-400 flex items-center gap-1">
                  <span>x</span> Discovered only at runtime
                </p>
              </div>
            </div>

            <!-- Verified routes (new) -->
            <div class="p-4 rounded-lg border-2 border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/10">
              <div class="flex items-center gap-2 mb-3">
                <span class="w-3 h-3 rounded-full bg-green-500"></span>
                <h4 class="font-semibold text-green-700 dark:text-green-300">Verified Routes (~p)</h4>
              </div>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{verified_paths_code()}</div>
              <div class="mt-3 space-y-1">
                <p class="text-xs text-green-600 dark:text-green-400 flex items-center gap-1">
                  <span>+</span> Typos caught at compile time
                </p>
                <p class="text-xs text-green-600 dark:text-green-400 flex items-center gap-1">
                  <span>+</span> Param count verified
                </p>
                <p class="text-xs text-green-600 dark:text-green-400 flex items-center gap-1">
                  <span>+</span> Zero runtime overhead
                </p>
              </div>
            </div>
          </div>

          <!-- Compile error example -->
          <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
            <h4 class="font-semibold text-red-700 dark:text-red-300 mb-2">What a compile error looks like</h4>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-red-400 whitespace-pre">{compile_error_example()}</div>
          </div>
        </div>
      <% end %>

      <!-- Interactive examples -->
      <%= if @active_tab == "examples" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Click an example to see how <code>~p</code> works for different route types.
          </p>

          <!-- Example buttons -->
          <div class="flex flex-wrap gap-2">
            <%= for ex <- examples() do %>
              <button
                phx-click="select_example"
                phx-target={@myself}
                phx-value-id={ex.id}
                class={["px-3 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors border",
                  if(@selected_example == ex.id,
                    do: "bg-teal-50 dark:bg-teal-900/30 border-teal-400 text-teal-700 dark:text-teal-300",
                    else: "border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:border-gray-300")]}
              >
                {ex.label}
              </button>
            <% end %>
          </div>

          <!-- Example detail -->
          <% ex = Enum.find(examples(), &(&1.id == @selected_example)) %>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase mb-1">Route Definition</p>
              <p class="font-mono text-xs text-gray-800 dark:text-gray-200">{ex.route}</p>
            </div>
            <div class="p-3 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-xs font-semibold text-purple-600 dark:text-purple-400 uppercase mb-1">~p Expression</p>
              <p class="font-mono text-xs text-gray-800 dark:text-gray-200">~p"{ex.path}"</p>
            </div>
            <div class="p-3 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-xs font-semibold text-green-600 dark:text-green-400 uppercase mb-1">Runtime Result</p>
              <p class="font-mono text-xs text-gray-800 dark:text-gray-200">"{ex.result}"</p>
            </div>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{example_code(@selected_example)}</div>
        </div>
      <% end %>

      <!-- Usage patterns -->
      <%= if @active_tab == "usage" do %>
        <div class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">In Controllers</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{controller_usage_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">In Templates (HEEx)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{template_usage_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">In LiveView</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{liveview_usage_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Static Assets</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{static_usage_code()}</div>
            </div>
          </div>

          <!-- Migration from path helpers -->
          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <h4 class="font-semibold text-amber-700 dark:text-amber-300 mb-2">Migrating from Path Helpers</h4>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{migration_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Setup & Complete Usage</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_example", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_example: id)}
  end

  defp tab_label("compare"), do: "String vs ~p"
  defp tab_label("examples"), do: "Examples"
  defp tab_label("usage"), do: "Usage"
  defp tab_label("code"), do: "Source Code"

  defp examples, do: @examples

  defp string_paths_code do
    """
    # String paths — NO compile-time checks
    redirect(conn, to: "/prodcuts/\#{id}")
    #                    ^^^^^^^^ typo!
    #                    Compiles fine...
    #                    404 at runtime!

    <a href="/users/\#{user.id}/posst">
    #                          ^^^^^ typo!
    #                          Discovered by users\
    """
    |> String.trim()
  end

  defp verified_paths_code do
    """
    # Verified routes — compile-time checked
    redirect(conn, to: ~p"/products/\#{product}")
    #                    ↑ checked against router!

    <.link navigate={~p"/users/\#{@user}/posts"}>
    #                  ↑ path must exist in router

    # Typo? → Compile error, not runtime 404\
    """
    |> String.trim()
  end

  defp compile_error_example do
    """
    ** (CompileError) lib/my_app_web/controllers/product_controller.ex:15
      no route path for MyAppWeb.Router matches "/prodcuts/*"

      Available routes:
        /products
        /products/:id
        /products/:id/edit
        /users
        /users/:id\
    """
    |> String.trim()
  end

  defp example_code("basic") do
    """
    # Route: get "/products", ProductController, :index

    # In controller:
    redirect(conn, to: ~p"/products")

    # In template:
    <.link navigate={~p"/products"}>All Products</.link>

    # Result: "/products"\
    """
    |> String.trim()
  end

  defp example_code("with_param") do
    """
    # Route: get "/products/:id", ProductController, :show

    # In controller:
    redirect(conn, to: ~p"/products/\#{product}")

    # In template:
    <.link navigate={~p"/products/\#{@product}"}>View</.link>

    # Result: "/products/42"\
    """
    |> String.trim()
  end

  defp example_code("nested") do
    """
    # Route: resources "/users" do resources "/posts" end

    # In controller:
    redirect(conn, to: ~p"/users/\#{user}/posts")

    # In template:
    <.link navigate={~p"/users/\#{@user}/posts"}>
      Posts by \#{@user.name}
    </.link>

    # Result: "/users/5/posts"\
    """
    |> String.trim()
  end

  defp example_code("query") do
    """
    # Add query params with a map:
    ~p"/products?\#{%{page: 2, sort: "name"}}"
    # → "/products?page=2&sort=name"

    # With path param + query params:
    ~p"/products/\#{product}?\#{%{tab: "reviews"}}"
    # → "/products/42?tab=reviews"\
    """
    |> String.trim()
  end

  defp example_code("static") do
    """
    # Static assets get cache-busting hashes in prod:
    ~p"/assets/app.css"
    # Dev:  "/assets/app.css"
    # Prod: "/assets/app-ABC123.css"

    <link rel="stylesheet" href={~p"/assets/app.css"} />
    <script src={~p"/assets/app.js"}></script>
    <img src={~p"/images/logo.png"} />\
    """
    |> String.trim()
  end

  defp controller_usage_code do
    """
    def create(conn, %{"product" => params}) do
      case Catalog.create_product(params) do
        {:ok, product} ->
          conn
          |> put_flash(:info, "Created!")
          |> redirect(to: ~p"/products/\#{product}")

        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp template_usage_code do
    """
    <%# Navigation links %>
    <.link navigate={~p"/products"}>Products</.link>
    <.link navigate={~p"/products/\#{@product}"}>View</.link>
    <.link navigate={~p"/products/\#{@product}/edit"}>Edit</.link>

    <%# Forms %>
    <.form for={@changeset} action={~p"/products"}>
      ...
    </.form>\
    """
    |> String.trim()
  end

  defp liveview_usage_code do
    """
    def handle_event("view", %{"id" => id}, socket) do
      {:noreply,
       push_navigate(socket,
         to: ~p"/products/\#{id}")}
    end

    def handle_event("search", params, socket) do
      {:noreply,
       push_patch(socket,
         to: ~p"/products?\#{params}")}\
    end\
    """
    |> String.trim()
  end

  defp static_usage_code do
    """
    <%# CSS & JS with cache busting %>
    <link href={~p"/assets/app.css"} rel="stylesheet" />
    <script src={~p"/assets/app.js"}></script>

    <%# Images %>
    <img src={~p"/images/logo.png"} alt="Logo" />

    <%# In prod, becomes: %>
    <%# /assets/app-d3adb33f.css %>\
    """
    |> String.trim()
  end

  defp migration_code do
    """
    # Old (deprecated):            # New (verified):
    product_path(conn, :index)   → ~p"/products"
    product_path(conn, :show, 42)→ ~p"/products/\#{product}"
    product_path(conn, :show, 42,
      tab: "reviews")            → ~p"/products/\#{product}?\#{%{tab: "reviews"}}"\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # 1. Setup in lib/my_app_web.ex (auto-generated):
    defp html_helpers do
      quote do
        use Phoenix.VerifiedRoutes,
          endpoint: MyAppWeb.Endpoint,
          router: MyAppWeb.Router,
          statics: MyAppWeb.static_paths()
      end
    end

    # 2. Router defines the routes:
    scope "/", MyAppWeb do
      pipe_through :browser

      get "/", PageController, :home
      resources "/products", ProductController
      resources "/users", UserController do
        resources "/posts", PostController
      end
    end

    # 3. Use ~p everywhere:

    # Controller:
    redirect(conn, to: ~p"/products/\#{product}")

    # Template:
    <.link navigate={~p"/products"}>All Products</.link>
    <.link navigate={~p"/products/\#{@product}"}>View</.link>

    # LiveView:
    push_navigate(socket, to: ~p"/products/\#{id}")

    # Static assets:
    <link href={~p"/assets/app.css"} rel="stylesheet" />

    # Query params:
    ~p"/products?\#{%{page: 1, sort: "name"}}"\
    """
    |> String.trim()
  end
end
