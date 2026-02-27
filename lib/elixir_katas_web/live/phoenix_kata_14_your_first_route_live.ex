defmodule ElixirKatasWeb.PhoenixKata14YourFirstRouteLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Router — maps URLs to controllers
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      scope "/", MyAppWeb do
        pipe_through :browser

        get "/", PageController, :home
        get "/about", PageController, :about
        get "/products", ProductController, :index
        post "/products", ProductController, :create
        get "/products/:id", ProductController, :show
      end

      scope "/api", MyAppWeb do
        pipe_through :api

        get "/users", UserController, :index
        post "/users", UserController, :create
      end
    end

    # 4 files to create a new route:

    # 1. Add the route (router.ex)
    scope "/", MyAppWeb do
      pipe_through :browser
      get "/hello", HelloController, :index
    end

    # 2. Create the controller
    defmodule MyAppWeb.HelloController do
      use MyAppWeb, :controller

      def index(conn, _params) do
        render(conn, :index)
      end
    end

    # 3. Create the view module
    defmodule MyAppWeb.HelloHTML do
      use MyAppWeb, :html
      embed_templates "hello_html/*"
    end

    # 4. Create the template (hello_html/index.html.heex)
    <h1>Hello, Phoenix!</h1>
    <p>This is my first route.</p>

    # LiveView routes — no controller needed!
    scope "/", MyAppWeb do
      pipe_through :browser
      live "/dashboard", DashboardLive
      live "/products/:id", ProductLive.Show
    end
    """
    |> String.trim()
  end

  @routes [
    %{method: "GET", path: "/", controller: "PageController", action: ":home", pipeline: ":browser"},
    %{method: "GET", path: "/about", controller: "PageController", action: ":about", pipeline: ":browser"},
    %{method: "GET", path: "/products", controller: "ProductController", action: ":index", pipeline: ":browser"},
    %{method: "POST", path: "/products", controller: "ProductController", action: ":create", pipeline: ":browser"},
    %{method: "GET", path: "/products/:id", controller: "ProductController", action: ":show", pipeline: ":browser"},
    %{method: "GET", path: "/api/users", controller: "UserController", action: ":index", pipeline: ":api"},
    %{method: "POST", path: "/api/users", controller: "UserController", action: ":create", pipeline: ":api"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "routes",
       selected_route: nil,
       test_method: "GET",
       test_path: "/"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Your First Route</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Routes map URLs to code. Try matching requests to routes and see the full request flow.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["routes", "tester", "walkthrough", "code"]}
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

      <!-- Route table -->
      <%= if @active_tab == "routes" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            These are the routes defined in our sample router. Click one to see the full request flow.
          </p>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-200 dark:border-gray-700">
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Method</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Path</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Controller</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Action</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Pipeline</th>
                </tr>
              </thead>
              <tbody>
                <%= for {route, idx} <- Enum.with_index(routes()) do %>
                  <tr
                    phx-click="select_route"
                    phx-target={@myself}
                    phx-value-idx={to_string(idx)}
                    class={["border-b border-gray-100 dark:border-gray-800 cursor-pointer transition-colors",
                      if(@selected_route == idx, do: "bg-teal-50 dark:bg-teal-900/20", else: "hover:bg-gray-50 dark:hover:bg-gray-800")]}
                  >
                    <td class="py-2 px-3">
                      <span class={["px-2 py-0.5 rounded text-xs font-bold", method_color(route.method)]}>
                        {route.method}
                      </span>
                    </td>
                    <td class="py-2 px-3 font-mono text-gray-600 dark:text-gray-400">{route.path}</td>
                    <td class="py-2 px-3 font-mono text-teal-600 dark:text-teal-400">{route.controller}</td>
                    <td class="py-2 px-3 font-mono text-purple-600 dark:text-purple-400">{route.action}</td>
                    <td class="py-2 px-3">
                      <span class="px-2 py-0.5 rounded text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400">
                        {route.pipeline}
                      </span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <!-- Request flow for selected route -->
          <%= if @selected_route do %>
            <% route = Enum.at(routes(), @selected_route) %>
            <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
              <p class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                Request flow for: <span class="font-mono text-teal-600">{route.method} {route.path}</span>
              </p>
              <div class="flex flex-wrap items-center gap-2 text-xs font-mono">
                <span class="px-2 py-1 rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300">Endpoint</span>
                <span class="text-gray-400">→</span>
                <span class="px-2 py-1 rounded bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300">Router</span>
                <span class="text-gray-400">→</span>
                <span class="px-2 py-1 rounded bg-amber-100 dark:bg-amber-900 text-amber-700 dark:text-amber-300">{route.pipeline}</span>
                <span class="text-gray-400">→</span>
                <span class="px-2 py-1 rounded bg-teal-100 dark:bg-teal-900 text-teal-700 dark:text-teal-300">{route.controller}.{String.replace(route.action, ":", "")}/2</span>
                <span class="text-gray-400">→</span>
                <span class="px-2 py-1 rounded bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300">Response</span>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Route tester -->
      <%= if @active_tab == "tester" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Type a method and path to see which route matches.
          </p>

          <div class="flex gap-2 items-end">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Method</label>
              <select phx-change="update_test_method" phx-target={@myself} name="method"
                class="rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm font-mono">
                <option :for={m <- ["GET", "POST", "PUT", "PATCH", "DELETE"]} value={m} selected={@test_method == m}>{m}</option>
              </select>
            </div>
            <div class="flex-1">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Path</label>
              <input type="text" phx-change="update_test_path" phx-target={@myself} name="path" value={@test_path}
                class="w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm font-mono" />
            </div>
            <button phx-click="test_route" phx-target={@myself}
              class="px-4 py-2 rounded-lg font-medium bg-teal-600 hover:bg-teal-700 text-white transition-colors cursor-pointer">
              Match
            </button>
          </div>

          <!-- Quick paths -->
          <div class="flex flex-wrap gap-2">
            <button :for={path <- ["/", "/about", "/products", "/products/42", "/api/users", "/nonexistent"]}
              phx-click="quick_test"
              phx-target={@myself}
              phx-value-path={path}
              class="px-3 py-1 text-xs rounded-full bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 font-mono cursor-pointer">
              {path}
            </button>
          </div>

          <% match = find_matching_route(@test_method, @test_path) %>
          <div class={["p-4 rounded-lg border",
            if(match, do: "border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/20", else: "border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20")]}>
            <%= if match do %>
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">Match found!</p>
              <pre class="font-mono text-xs text-green-800 dark:text-green-200 whitespace-pre">{format_match(match, @test_path)}</pre>
            <% else %>
              <p class="text-sm font-semibold text-red-700 dark:text-red-300">No matching route</p>
              <p class="text-xs text-red-600 dark:text-red-400 mt-1">This would return a 404 error. Add a route for this path in router.ex.</p>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Step-by-step walkthrough -->
      <%= if @active_tab == "walkthrough" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The 4 files needed to create a new route from scratch.
          </p>

          <div class="space-y-4">
            <.walkthrough_step num="1" title="Add the route" file="router.ex" code={walkthrough_router()} />
            <.walkthrough_step num="2" title="Create the controller" file="hello_controller.ex" code={walkthrough_controller()} />
            <.walkthrough_step num="3" title="Create the view module" file="hello_html.ex" code={walkthrough_view()} />
            <.walkthrough_step num="4" title="Create the template" file="hello_html/index.html.heex" code={walkthrough_template()} />
          </div>
        </div>
      <% end %>

      <!-- Router source code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Sample Router</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{router_source()}</div>

          <h4 class="font-semibold text-gray-700 dark:text-gray-300 mt-6">LiveView Routes</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{liveview_routes()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :num, :string, required: true
  attr :title, :string, required: true
  attr :file, :string, required: true
  attr :code, :string, required: true

  defp walkthrough_step(assigns) do
    ~H"""
    <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
      <div class="flex items-center gap-2 mb-2">
        <span class="w-6 h-6 rounded-full bg-teal-500 text-white flex items-center justify-center text-xs">{@num}</span>
        <span class="font-semibold text-gray-800 dark:text-gray-200">{@title}</span>
        <span class="ml-auto font-mono text-xs text-gray-500">{@file}</span>
      </div>
      <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 overflow-x-auto whitespace-pre">{@code}</div>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_route", %{"idx" => idx}, socket) do
    {:noreply, assign(socket, selected_route: String.to_integer(idx))}
  end

  def handle_event("update_test_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, test_method: method)}
  end

  def handle_event("update_test_path", %{"path" => path}, socket) do
    {:noreply, assign(socket, test_path: path)}
  end

  def handle_event("test_route", _, socket) do
    {:noreply, socket}
  end

  def handle_event("quick_test", %{"path" => path}, socket) do
    {:noreply, assign(socket, test_path: path, test_method: "GET")}
  end

  defp routes, do: @routes

  defp tab_label("routes"), do: "Route Table"
  defp tab_label("tester"), do: "Route Tester"
  defp tab_label("walkthrough"), do: "Walkthrough"
  defp tab_label("code"), do: "Source Code"

  defp method_color("GET"), do: "bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300"
  defp method_color("POST"), do: "bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300"
  defp method_color("PUT"), do: "bg-amber-100 dark:bg-amber-900 text-amber-700 dark:text-amber-300"
  defp method_color("PATCH"), do: "bg-amber-100 dark:bg-amber-900 text-amber-700 dark:text-amber-300"
  defp method_color("DELETE"), do: "bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300"
  defp method_color(_), do: "bg-gray-100 dark:bg-gray-900 text-gray-700 dark:text-gray-300"

  defp find_matching_route(method, path) do
    Enum.find(routes(), fn route ->
      route.method == method && path_matches?(route.path, path)
    end)
  end

  defp path_matches?(pattern, path) do
    pattern_parts = String.split(pattern, "/")
    path_parts = String.split(path, "/")

    if length(pattern_parts) != length(path_parts) do
      false
    else
      Enum.zip(pattern_parts, path_parts)
      |> Enum.all?(fn {p, v} ->
        String.starts_with?(p, ":") || p == v
      end)
    end
  end

  defp format_match(route, path) do
    params =
      Enum.zip(String.split(route.path, "/"), String.split(path, "/"))
      |> Enum.filter(fn {p, _} -> String.starts_with?(p, ":") end)
      |> Enum.map(fn {p, v} -> "  #{String.replace(p, ":", "")} = \"#{v}\"" end)
      |> Enum.join("\n")

    params_section = if params != "", do: "\nParams:\n#{params}", else: ""

    "Route:      #{route.method} #{route.path}\nController:  #{route.controller}\nAction:      #{route.action}\nPipeline:    #{route.pipeline}#{params_section}"
  end

  defp walkthrough_router do
    """
    # router.ex
    scope "/", MyAppWeb do
      pipe_through :browser
      get "/hello", HelloController, :index
    end\
    """
    |> String.trim()
  end

  defp walkthrough_controller do
    """
    defmodule MyAppWeb.HelloController do
      use MyAppWeb, :controller

      def index(conn, _params) do
        render(conn, :index)
      end
    end\
    """
    |> String.trim()
  end

  defp walkthrough_view do
    """
    defmodule MyAppWeb.HelloHTML do
      use MyAppWeb, :html
      embed_templates "hello_html/*"
    end\
    """
    |> String.trim()
  end

  defp walkthrough_template do
    """
    <h1>Hello, Phoenix!</h1>
    <p>This is my first route.</p>\
    """
    |> String.trim()
  end

  defp router_source do
    """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :api do
        plug :accepts, ["json"]
      end

      scope "/", MyAppWeb do
        pipe_through :browser

        get "/", PageController, :home
        get "/about", PageController, :about
        get "/products", ProductController, :index
        post "/products", ProductController, :create
        get "/products/:id", ProductController, :show
      end

      scope "/api", MyAppWeb do
        pipe_through :api

        get "/users", UserController, :index
        post "/users", UserController, :create
      end
    end\
    """
    |> String.trim()
  end

  defp liveview_routes do
    """
    # LiveView routes — no controller needed!
    scope "/", MyAppWeb do
      pipe_through :browser

      live "/dashboard", DashboardLive
      live "/products/:id", ProductLive.Show
    end\
    """
    |> String.trim()
  end
end
