defmodule ElixirKatasWeb.PhoenixKata17NestedRoutesAndScopesLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Scopes group routes with shared prefixes, modules, and pipelines

    # Public — no auth needed
    scope "/", MyAppWeb do
      pipe_through :browser
      get "/", PageController, :home
      resources "/products", ProductController, only: [:index, :show]
    end

    # Authenticated — logged-in users only
    scope "/", MyAppWeb do
      pipe_through [:browser, :require_auth]
      resources "/orders", OrderController
      resources "/settings", SettingsController, singleton: true
    end

    # Admin — separate module namespace + path prefix
    scope "/admin", MyAppWeb.Admin, as: :admin do
      pipe_through [:browser, :require_admin]
      get "/", DashboardController, :index
      resources "/users", UserController
      resources "/products", ProductController
    end

    # Versioned API — nested scopes
    scope "/api", MyAppWeb.API do
      pipe_through :api

      scope "/v1", V1 do
        resources "/products", ProductController, only: [:index, :show]
      end

      scope "/v2", V2 do
        resources "/products", ProductController
      end
    end

    # Nested resources — full nesting
    resources "/users", UserController do
      resources "/posts", PostController
    end
    # GET /users/:user_id/posts     PostController :index
    # GET /users/:user_id/posts/:id PostController :show

    # Shallow nesting — nest only where parent context needed
    resources "/users", UserController do
      resources "/posts", PostController, only: [:index, :new, :create]
    end
    resources "/posts", PostController, only: [:show, :edit, :update, :delete]

    # Controller with nested route params
    defmodule MyAppWeb.PostController do
      use MyAppWeb, :controller

      def index(conn, %{"user_id" => user_id}) do
        user = Accounts.get_user!(user_id)
        posts = Blog.list_posts_for_user(user)
        render(conn, :index, user: user, posts: posts)
      end

      def show(conn, %{"id" => id}) do
        post = Blog.get_post!(id)
        render(conn, :show, post: post)
      end
    end
    """
    |> String.trim()
  end

  @scope_examples [
    %{id: "public", label: "Public", prefix: "/", module: "MyAppWeb", pipeline: ":browser"},
    %{id: "auth", label: "Authenticated", prefix: "/", module: "MyAppWeb", pipeline: "[:browser, :require_auth]"},
    %{id: "admin", label: "Admin", prefix: "/admin", module: "MyAppWeb.Admin", pipeline: "[:browser, :require_admin]"},
    %{id: "api_v1", label: "API v1", prefix: "/api/v1", module: "MyAppWeb.API.V1", pipeline: ":api"},
    %{id: "api_v2", label: "API v2", prefix: "/api/v2", module: "MyAppWeb.API.V2", pipeline: ":api"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "scopes",
       selected_scope: "public",
       nesting_mode: "full"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Nested Routes & Scopes</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Organize routes into logical groups with shared prefixes, modules, and middleware.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["scopes", "nesting", "real_world", "code"]}
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

      <!-- Scopes -->
      <%= if @active_tab == "scopes" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Scopes group routes with shared path prefixes, module prefixes, and pipelines.
            Click a scope to see what it generates.
          </p>

          <!-- Scope selector -->
          <div class="flex flex-wrap gap-2">
            <%= for scope <- scope_examples() do %>
              <button
                phx-click="select_scope"
                phx-target={@myself}
                phx-value-scope={scope.id}
                class={["px-3 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors border",
                  if(@selected_scope == scope.id,
                    do: "bg-teal-50 dark:bg-teal-900/30 border-teal-400 text-teal-700 dark:text-teal-300",
                    else: "border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:border-gray-300")]}
              >
                {scope.label}
              </button>
            <% end %>
          </div>

          <!-- Scope detail -->
          <% scope = Enum.find(scope_examples(), &(&1.id == @selected_scope)) %>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase mb-1">Path Prefix</p>
              <p class="font-mono text-sm text-gray-800 dark:text-gray-200">{scope.prefix}</p>
            </div>
            <div class="p-3 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-xs font-semibold text-purple-600 dark:text-purple-400 uppercase mb-1">Module Prefix</p>
              <p class="font-mono text-sm text-gray-800 dark:text-gray-200">{scope.module}</p>
            </div>
            <div class="p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase mb-1">Pipeline</p>
              <p class="font-mono text-sm text-gray-800 dark:text-gray-200">{scope.pipeline}</p>
            </div>
          </div>

          <!-- Generated code -->
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{scope_code(@selected_scope)}</div>

          <!-- Generated routes -->
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Generated Routes</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{scope_routes(@selected_scope)}</div>
        </div>
      <% end %>

      <!-- Nested resources -->
      <%= if @active_tab == "nesting" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Resources can be nested inside other resources. Compare full vs shallow nesting.
          </p>

          <div class="flex gap-2">
            <button :for={{mode, label} <- [{"full", "Full Nesting"}, {"shallow", "Shallow Nesting"}]}
              phx-click="set_nesting"
              phx-target={@myself}
              phx-value-mode={mode}
              class={["px-4 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors",
                if(@nesting_mode == mode,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")]}
            >
              {label}
            </button>
          </div>

          <!-- Router code -->
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{nesting_code(@nesting_mode)}</div>

          <!-- Generated routes -->
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Generated Routes</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{nesting_routes(@nesting_mode)}</div>

          <!-- Controller code -->
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Controller</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{nesting_controller(@nesting_mode)}</div>

          <%= if @nesting_mode == "shallow" do %>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Why shallow nesting?</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">
                Deep URLs like <code>/users/5/posts/42/comments/7</code> are hard to read and bookmark.
                Only nest routes that <em>need</em> the parent context (index, new, create).
                Individual resources (show, edit, update, delete) can stand alone.
              </p>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Real-world patterns -->
      <%= if @active_tab == "real_world" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            A production router typically has multiple scope groups with different access levels.
          </p>

          <div class="space-y-3">
            <div class="p-4 rounded-lg border border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/20">
              <h4 class="font-semibold text-green-700 dark:text-green-300 mb-2">Public Routes</h4>
              <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">No authentication needed. Read-only access.</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{public_scope_code()}</div>
            </div>

            <div class="p-4 rounded-lg border border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20">
              <h4 class="font-semibold text-blue-700 dark:text-blue-300 mb-2">Authenticated Routes</h4>
              <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">Logged-in users only. Full CRUD.</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{auth_scope_code()}</div>
            </div>

            <div class="p-4 rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20">
              <h4 class="font-semibold text-red-700 dark:text-red-300 mb-2">Admin Routes</h4>
              <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">Admin role required. Separate module namespace.</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{admin_scope_code()}</div>
            </div>

            <div class="p-4 rounded-lg border border-purple-200 dark:border-purple-800 bg-purple-50 dark:bg-purple-900/20">
              <h4 class="font-semibold text-purple-700 dark:text-purple-300 mb-2">API Routes</h4>
              <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">JSON responses, versioned API.</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{api_scope_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Router Example</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_router_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_scope", %{"scope" => scope}, socket) do
    {:noreply, assign(socket, selected_scope: scope)}
  end

  def handle_event("set_nesting", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, nesting_mode: mode)}
  end

  defp tab_label("scopes"), do: "Scopes"
  defp tab_label("nesting"), do: "Nested Resources"
  defp tab_label("real_world"), do: "Real World"
  defp tab_label("code"), do: "Source Code"

  defp scope_examples, do: @scope_examples

  defp scope_code("public") do
    """
    scope "/", MyAppWeb do
      pipe_through :browser

      get "/", PageController, :home
      resources "/products", ProductController, only: [:index, :show]
      resources "/blog", BlogController, only: [:index, :show]
    end\
    """
    |> String.trim()
  end

  defp scope_code("auth") do
    """
    scope "/", MyAppWeb do
      pipe_through [:browser, :require_auth]

      resources "/orders", OrderController
      resources "/cart", CartController, singleton: true
      resources "/settings", SettingsController, singleton: true
    end\
    """
    |> String.trim()
  end

  defp scope_code("admin") do
    """
    scope "/admin", MyAppWeb.Admin, as: :admin do
      pipe_through [:browser, :require_admin]

      get "/", DashboardController, :index
      resources "/users", UserController
      resources "/products", ProductController
    end\
    """
    |> String.trim()
  end

  defp scope_code("api_v1") do
    """
    scope "/api", MyAppWeb.API do
      pipe_through :api

      scope "/v1", V1 do
        resources "/products", ProductController, only: [:index, :show]
        resources "/users", UserController, only: [:index, :show]
      end
    end\
    """
    |> String.trim()
  end

  defp scope_code("api_v2") do
    """
    scope "/api", MyAppWeb.API do
      pipe_through :api

      scope "/v2", V2 do
        resources "/products", ProductController
        resources "/users", UserController
      end
    end\
    """
    |> String.trim()
  end

  defp scope_routes("public") do
    """
    GET  /                  PageController     :home
    GET  /products          ProductController  :index
    GET  /products/:id      ProductController  :show
    GET  /blog              BlogController     :index
    GET  /blog/:id          BlogController     :show\
    """
    |> String.trim()
  end

  defp scope_routes("auth") do
    """
    GET    /orders            OrderController    :index
    GET    /orders/new        OrderController    :new
    POST   /orders            OrderController    :create
    GET    /orders/:id        OrderController    :show
    GET    /orders/:id/edit   OrderController    :edit
    PUT    /orders/:id        OrderController    :update
    DELETE /orders/:id        OrderController    :delete
    GET    /cart              CartController     :show
    GET    /settings          SettingsController :show
    GET    /settings/edit     SettingsController :edit
    PUT    /settings          SettingsController :update\
    """
    |> String.trim()
  end

  defp scope_routes("admin") do
    """
    GET    /admin             Admin.DashboardController :index
    GET    /admin/users       Admin.UserController      :index
    GET    /admin/users/new   Admin.UserController      :new
    POST   /admin/users       Admin.UserController      :create
    GET    /admin/users/:id   Admin.UserController      :show
    ...
    GET    /admin/products       Admin.ProductController :index
    ...\
    """
    |> String.trim()
  end

  defp scope_routes("api_v1") do
    """
    GET  /api/v1/products      API.V1.ProductController :index
    GET  /api/v1/products/:id  API.V1.ProductController :show
    GET  /api/v1/users         API.V1.UserController    :index
    GET  /api/v1/users/:id     API.V1.UserController    :show\
    """
    |> String.trim()
  end

  defp scope_routes("api_v2") do
    """
    GET    /api/v2/products          API.V2.ProductController :index
    GET    /api/v2/products/new      API.V2.ProductController :new
    POST   /api/v2/products          API.V2.ProductController :create
    GET    /api/v2/products/:id      API.V2.ProductController :show
    ...
    GET    /api/v2/users             API.V2.UserController    :index
    ...\
    """
    |> String.trim()
  end

  defp nesting_code("full") do
    """
    # Full nesting — all child routes under parent
    resources "/users", UserController do
      resources "/posts", PostController
    end\
    """
    |> String.trim()
  end

  defp nesting_code("shallow") do
    """
    # Shallow nesting — only nest where parent context needed
    resources "/users", UserController do
      resources "/posts", PostController, only: [:index, :new, :create]
    end

    # Individual posts don't need /users/:user_id prefix
    resources "/posts", PostController, only: [:show, :edit, :update, :delete]\
    """
    |> String.trim()
  end

  defp nesting_routes("full") do
    """
    # Parent routes:
    GET    /users                        UserController :index
    GET    /users/:id                    UserController :show
    ...

    # Nested child routes:
    GET    /users/:user_id/posts         PostController :index
    GET    /users/:user_id/posts/new     PostController :new
    POST   /users/:user_id/posts         PostController :create
    GET    /users/:user_id/posts/:id     PostController :show
    GET    /users/:user_id/posts/:id/edit PostController :edit
    PUT    /users/:user_id/posts/:id     PostController :update
    DELETE /users/:user_id/posts/:id     PostController :delete\
    """
    |> String.trim()
  end

  defp nesting_routes("shallow") do
    """
    # Nested (needs parent context):
    GET    /users/:user_id/posts         PostController :index
    GET    /users/:user_id/posts/new     PostController :new
    POST   /users/:user_id/posts         PostController :create

    # Flat (standalone):
    GET    /posts/:id                    PostController :show
    GET    /posts/:id/edit               PostController :edit
    PUT    /posts/:id                    PostController :update
    DELETE /posts/:id                    PostController :delete\
    """
    |> String.trim()
  end

  defp nesting_controller("full") do
    """
    defmodule MyAppWeb.PostController do
      use MyAppWeb, :controller

      # Always has :user_id from nested route
      def index(conn, %{"user_id" => user_id}) do
        user = Accounts.get_user!(user_id)
        posts = Blog.list_posts_for_user(user)
        render(conn, :index, user: user, posts: posts)
      end

      def show(conn, %{"user_id" => user_id, "id" => id}) do
        user = Accounts.get_user!(user_id)
        post = Blog.get_post!(id)
        render(conn, :show, user: user, post: post)
      end
    end\
    """
    |> String.trim()
  end

  defp nesting_controller("shallow") do
    """
    defmodule MyAppWeb.PostController do
      use MyAppWeb, :controller

      # Nested route — has :user_id
      def index(conn, %{"user_id" => user_id}) do
        user = Accounts.get_user!(user_id)
        posts = Blog.list_posts_for_user(user)
        render(conn, :index, user: user, posts: posts)
      end

      # Flat route — only has :id
      def show(conn, %{"id" => id}) do
        post = Blog.get_post!(id)
        render(conn, :show, post: post)
      end
    end\
    """
    |> String.trim()
  end

  defp public_scope_code do
    """
    scope "/", MyAppWeb do
      pipe_through :browser

      get "/", PageController, :home
      resources "/products", ProductController, only: [:index, :show]
    end\
    """
    |> String.trim()
  end

  defp auth_scope_code do
    """
    scope "/", MyAppWeb do
      pipe_through [:browser, :require_auth]

      resources "/orders", OrderController
      resources "/settings", SettingsController, singleton: true
    end\
    """
    |> String.trim()
  end

  defp admin_scope_code do
    """
    scope "/admin", MyAppWeb.Admin, as: :admin do
      pipe_through [:browser, :require_admin]

      get "/", DashboardController, :index
      resources "/users", UserController
      resources "/products", ProductController
    end\
    """
    |> String.trim()
  end

  defp api_scope_code do
    """
    scope "/api", MyAppWeb.API do
      pipe_through :api

      scope "/v1", V1 do
        resources "/products", ProductController, only: [:index, :show]
      end
    end\
    """
    |> String.trim()
  end

  defp full_router_code do
    """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      pipeline :require_auth do
        plug MyAppWeb.Plugs.RequireAuth
      end

      pipeline :require_admin do
        plug MyAppWeb.Plugs.RequireAuth
        plug MyAppWeb.Plugs.RequireAdmin
      end

      # Public
      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
        resources "/products", ProductController, only: [:index, :show]
      end

      # Authenticated
      scope "/", MyAppWeb do
        pipe_through [:browser, :require_auth]
        resources "/orders", OrderController
        resources "/settings", SettingsController, singleton: true
      end

      # Admin (note: as: :admin for unique path helpers)
      scope "/admin", MyAppWeb.Admin, as: :admin do
        pipe_through [:browser, :require_admin]
        get "/", DashboardController, :index
        resources "/users", UserController
        resources "/products", ProductController
      end

      # API v1
      scope "/api", MyAppWeb.API do
        pipe_through :api
        scope "/v1", V1 do
          resources "/products", ProductController, only: [:index, :show]
        end
      end
    end\
    """
    |> String.trim()
  end
end
