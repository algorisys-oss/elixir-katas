defmodule ElixirKatasWeb.PhoenixKata26LayoutsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Two-layer layout system: root (HTML shell) + app (page chrome)

    # layouts/root.html.heex — the HTML document shell
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title>{assigns[:page_title] || "MyApp"}</.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static src={~p"/assets/app.js"}></script>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>

    # layouts/app.html.heex — navigation + footer wrapper
    <header>
      <nav>
        <.link navigate={~p"/"}>Home</.link>
        <.link navigate={~p"/products"}>Products</.link>
      </nav>
    </header>
    <main>
      <.flash_group flash={@flash} />
      {@inner_content}
    </main>
    <footer>&copy; 2024 MyApp</footer>

    # Layouts module — auto-loads .heex files:
    defmodule MyAppWeb.Layouts do
      use MyAppWeb, :html
      embed_templates "layouts/*"
    end

    # Setting layouts:

    # In router pipeline:
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}

    # In controller — per action:
    conn |> put_layout(html: {MyAppWeb.Layouts, :admin}) |> render(:index)

    # In LiveView — via live_session:
    live_session :admin, layout: {MyAppWeb.Layouts, :admin} do
      live "/admin", AdminLive
    end

    # No layout (root only):
    conn |> put_layout(false) |> render(:embed)
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "layers",
       selected_layout: "root"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Layouts</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Two-layer layout system: root (HTML shell) and app (page chrome with nav, footer).
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["layers", "layouts", "setting", "code"]}
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

      <!-- Layer diagram -->
      <%= if @active_tab == "layers" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Content nests inside layouts like Russian dolls. Each layer adds structure.
          </p>

          <!-- Nested boxes diagram -->
          <div class="p-4 rounded-lg border-2 border-blue-400 bg-blue-50 dark:bg-blue-900/10">
            <p class="text-xs font-bold text-blue-600 dark:text-blue-400 mb-2">root.html.heex — HTML document</p>
            <div class="p-4 rounded-lg border-2 border-purple-400 bg-purple-50 dark:bg-purple-900/10 ml-4">
              <p class="text-xs font-bold text-purple-600 dark:text-purple-400 mb-2">app.html.heex — Navigation, footer</p>
              <div class="p-4 rounded-lg border-2 border-green-400 bg-green-50 dark:bg-green-900/10 ml-4">
                <p class="text-xs font-bold text-green-600 dark:text-green-400 mb-1">Page template</p>
                <p class="text-xs text-gray-500">Your controller/LiveView content</p>
              </div>
              <p class="text-xs text-purple-500 mt-2 font-mono">@inner_content = page template</p>
            </div>
            <p class="text-xs text-blue-500 mt-2 font-mono">@inner_content = app layout + page</p>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{layer_flow_code()}</div>
        </div>
      <% end %>

      <!-- Layout files -->
      <%= if @active_tab == "layouts" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Click a layout to see its code. Each serves a different purpose.
          </p>

          <div class="flex flex-wrap gap-2">
            <button :for={layout <- ["root", "app", "admin", "auth"]}
              phx-click="select_layout"
              phx-target={@myself}
              phx-value-layout={layout}
              class={["px-3 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors border",
                if(@selected_layout == layout,
                  do: "bg-teal-50 dark:bg-teal-900/30 border-teal-400 text-teal-700 dark:text-teal-300",
                  else: "border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:border-gray-300")]}
            >
              {layout}.html.heex
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{layout_code(@selected_layout)}</div>
        </div>
      <% end %>

      <!-- Setting layouts -->
      <%= if @active_tab == "setting" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            How to set layouts in routers, controllers, and LiveView.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">In Router (pipeline)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{router_layout_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">In Controller</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{controller_layout_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">In LiveView</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{liveview_layout_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">No Layout</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{no_layout_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Layouts Module</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_layout", %{"layout" => layout}, socket) do
    {:noreply, assign(socket, selected_layout: layout)}
  end

  defp tab_label("layers"), do: "How It Works"
  defp tab_label("layouts"), do: "Layout Files"
  defp tab_label("setting"), do: "Setting Layouts"
  defp tab_label("code"), do: "Source Code"

  defp layer_flow_code do
    """
    # Request → root layout wraps app layout wraps page:

    root.html.heex:
      <html>
        <head>CSS, JS, meta tags</head>
        <body>
          {@inner_content}   ← app layout inserted here
        </body>
      </html>

    app.html.heex:
      <nav>Navigation</nav>
      <main>
        <.flash_group flash={@flash} />
        {@inner_content}   ← page template inserted here
      </main>
      <footer>Footer</footer>

    page template:
      <h1>My Page</h1>
      <p>Content here</p>\
    """
    |> String.trim()
  end

  defp layout_code("root") do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title>
          {assigns[:page_title] || "MyApp"}
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static src={~p"/assets/app.js"}></script>
      </head>
      <body class="antialiased">
        {@inner_content}
      </body>
    </html>\
    """
    |> String.trim()
  end

  defp layout_code("app") do
    """
    <header class="bg-white shadow">
      <nav class="container mx-auto px-4 py-3 flex items-center gap-6">
        <.link navigate={~p"/"} class="font-bold text-lg">MyApp</.link>
        <.link navigate={~p"/products"}>Products</.link>
        <.link navigate={~p"/about"}>About</.link>

        <div class="ml-auto">
          <%= if @current_user do %>
            <span>{@current_user.email}</span>
            <.link href={~p"/logout"} method="delete">Log out</.link>
          <% else %>
            <.link navigate={~p"/login"}>Log in</.link>
          <% end %>
        </div>
      </nav>
    </header>

    <main class="container mx-auto px-4 py-8">
      <.flash_group flash={@flash} />
      {@inner_content}
    </main>

    <footer class="border-t mt-12 py-6 text-center text-gray-500">
      &copy; 2024 MyApp
    </footer>\
    """
    |> String.trim()
  end

  defp layout_code("admin") do
    """
    <div class="flex h-screen">
      <%# Sidebar %>
      <aside class="w-64 bg-gray-900 text-white p-4">
        <h2 class="text-lg font-bold mb-6">Admin Panel</h2>
        <nav class="space-y-2">
          <.link navigate={~p"/admin"} class="block px-3 py-2 rounded hover:bg-gray-800">
            Dashboard
          </.link>
          <.link navigate={~p"/admin/users"} class="block px-3 py-2 rounded hover:bg-gray-800">
            Users
          </.link>
          <.link navigate={~p"/admin/products"} class="block px-3 py-2 rounded hover:bg-gray-800">
            Products
          </.link>
        </nav>
      </aside>

      <%# Main content %>
      <div class="flex-1 overflow-auto">
        <header class="bg-white shadow px-6 py-4">
          <h1 class="text-xl font-semibold">{@page_title}</h1>
        </header>
        <main class="p-6">
          <.flash_group flash={@flash} />
          {@inner_content}
        </main>
      </div>
    </div>\
    """
    |> String.trim()
  end

  defp layout_code("auth") do
    """
    <%# Minimal layout for login/register pages %>
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="w-full max-w-md">
        <h1 class="text-2xl font-bold text-center mb-8">MyApp</h1>

        <div class="bg-white rounded-lg shadow-lg p-8">
          <.flash_group flash={@flash} />
          {@inner_content}
        </div>

        <p class="text-center mt-4 text-gray-500 text-sm">
          <.link navigate={~p"/"}>Back to home</.link>
        </p>
      </div>
    </div>\
    """
    |> String.trim()
  end

  defp router_layout_code do
    """
    # Root layout set in pipeline:
    pipeline :browser do
      plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    end

    # Different root layout:
    pipeline :admin do
      plug :put_root_layout, html: {MyAppWeb.Layouts, :admin_root}
    end\
    """
    |> String.trim()
  end

  defp controller_layout_code do
    """
    # Set app layout for one action:
    def index(conn, _params) do
      conn
      |> put_layout(html: {MyAppWeb.Layouts, :admin})
      |> render(:index)
    end

    # Set for all actions in controller:
    plug :put_layout, html: {MyAppWeb.Layouts, :admin}\
    """
    |> String.trim()
  end

  defp liveview_layout_code do
    """
    # In router — set layout for live_session:
    live_session :admin,
      layout: {MyAppWeb.Layouts, :admin} do
      live "/admin", AdminLive
      live "/admin/users", Admin.UsersLive
    end

    # Or in the LiveView module:
    use MyAppWeb, :live_view,
      layout: {MyAppWeb.Layouts, :admin}\
    """
    |> String.trim()
  end

  defp no_layout_code do
    """
    # No app layout (root only):
    def embed(conn, _params) do
      conn
      |> put_layout(false)
      |> render(:embed)
    end

    # Useful for:
    # - Embeddable widgets
    # - Email templates
    # - Print-friendly pages\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyAppWeb.Layouts do
      use MyAppWeb, :html

      # Auto-loads all .heex files from layouts/ directory:
      embed_templates "layouts/*"

      # Files:
      # layouts/root.html.heex  → Layouts.root/1
      # layouts/app.html.heex   → Layouts.app/1
      # layouts/admin.html.heex → Layouts.admin/1
      # layouts/auth.html.heex  → Layouts.auth/1

      # Or define as function components:
      # def custom(assigns) do
      #   ~H\"\"\"
      #   <main>{@inner_content}</main>
      #   \"\"\"
      # end
    end

    # In router:
    scope "/", MyAppWeb do
      pipe_through :browser  # Uses :root + :app layout

      get "/", PageController, :home
      resources "/products", ProductController
    end

    scope "/admin", MyAppWeb.Admin do
      pipe_through [:browser, :require_admin]

      live_session :admin, layout: {MyAppWeb.Layouts, :admin} do
        live "/", DashboardLive
        live "/users", UsersLive
      end
    end\
    """
    |> String.trim()
  end
end
