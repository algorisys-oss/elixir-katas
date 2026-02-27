defmodule ElixirKatasWeb.PhoenixKata10PlugRouterLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Plug.Router: A Mini Web App Without Phoenix
    defmodule MyApp.Router do
      use Plug.Router

      # Plugs run before routing
      plug Plug.Logger
      plug Plug.Parsers,
        parsers: [:urlencoded, :json],
        json_decoder: Jason

      plug :match     # Find matching route
      plug :dispatch  # Execute route handler

      get "/" do
        send_resp(conn, 200, "Welcome!")
      end

      get "/hello/:name" do
        send_resp(conn, 200, "Hello, \#{name}!")
      end

      get "/users" do
        users = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]
        json_resp(conn, 200, users)
      end

      get "/users/:id" do
        user = find_user(String.to_integer(id))
        if user, do: json_resp(conn, 200, user),
                 else: json_resp(conn, 404, %{error: "Not found"})
      end

      post "/users" do
        name = conn.body_params["name"]
        json_resp(conn, 201, %{id: 3, name: name})
      end

      # Catch-all (must be last!)
      match _ do
        send_resp(conn, 404, "Not Found")
      end

      defp json_resp(conn, status, data) do
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, Jason.encode!(data))
      end
    end

    # Starting the server:
    children = [
      {Plug.Cowboy,
        scheme: :http,
        plug: MyApp.Router,
        options: [port: 4001]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)

    # Forwarding to sub-routers:
    defmodule MyApp.MainRouter do
      use Plug.Router
      plug :match
      plug :dispatch

      forward "/api", to: MyApp.ApiRouter
      forward "/admin", to: MyApp.AdminRouter

      get "/" do
        send_resp(conn, 200, "Main site")
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       method: "GET",
       path: "/",
       response: nil,
       active_tab: "demo"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Plug Router</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Build a mini web app without Phoenix using Plug.Router. Test routes and see how routing works.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["demo", "code", "comparison"]}
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

      <!-- Route tester -->
      <%= if @active_tab == "demo" do %>
        <div class="space-y-4">
          <div class="flex gap-2 items-end">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Method</label>
              <select
                phx-change="update_method"
                phx-target={@myself}
                name="method"
                class="rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm font-mono"
              >
                <option :for={m <- ["GET", "POST", "PUT", "DELETE"]} value={m} selected={@method == m}>{m}</option>
              </select>
            </div>
            <div class="flex-1">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Path</label>
              <input
                type="text"
                phx-change="update_path"
                phx-target={@myself}
                name="path"
                value={@path}
                class="w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm font-mono"
                placeholder="/"
              />
            </div>
            <button phx-click="send_request" phx-target={@myself}
              class="px-4 py-2 rounded-lg font-medium bg-teal-600 hover:bg-teal-700 text-white transition-colors cursor-pointer">
              Send
            </button>
          </div>

          <!-- Quick route buttons -->
          <div class="flex flex-wrap gap-2">
            <button :for={route <- sample_routes()}
              phx-click="quick_route"
              phx-target={@myself}
              phx-value-method={route.method}
              phx-value-path={route.path}
              class="px-3 py-1 text-xs rounded-full bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 font-mono cursor-pointer">
              {route.method} {route.path}
            </button>
          </div>

          <!-- Response -->
          <%= if @response do %>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto space-y-2">
              <div class="flex items-center gap-2">
                <span class={["px-2 py-0.5 rounded text-xs font-bold",
                  status_color(@response.status)]}>
                  {@response.status}
                </span>
                <span class="text-gray-400">{@response.reason}</span>
              </div>
              <div class="text-gray-500 text-xs">
                <span :for={header <- @response.headers} class="block">{header}</span>
              </div>
              <pre class={["whitespace-pre-wrap mt-2", if(@response.status < 400, do: "text-green-400", else: "text-red-400")]}>{@response.body}</pre>

              <!-- Route match info -->
              <div class="mt-3 pt-3 border-t border-gray-700">
                <p class="text-gray-500 text-xs">Matched route:</p>
                <pre class="text-yellow-300 text-xs">{@response.matched_route}</pre>
              </div>
            </div>
          <% end %>

          <!-- Routes table -->
          <div class="mt-4">
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Defined Routes</h4>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="border-b border-gray-200 dark:border-gray-700">
                    <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Method</th>
                    <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Path</th>
                    <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Response</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={route <- defined_routes()} class="border-b border-gray-100 dark:border-gray-800">
                    <td class="py-2 px-3">
                      <span class={["px-2 py-0.5 rounded text-xs font-bold", method_color(route.method)]}>
                        {route.method}
                      </span>
                    </td>
                    <td class="py-2 px-3 font-mono text-sm text-gray-600 dark:text-gray-400">{route.path}</td>
                    <td class="py-2 px-3 text-gray-500 text-sm">{route.description}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Source code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            A complete Plug.Router application — no Phoenix needed. Just Plug + Cowboy.
          </p>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{router_source_code()}</div>

          <h4 class="font-semibold text-gray-700 dark:text-gray-300 mt-6 mb-3">Starting the Server</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{startup_code()}</div>

          <h4 class="font-semibold text-gray-700 dark:text-gray-300 mt-6 mb-3">Forwarding to Sub-Routers</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{forward_code()}</div>
        </div>
      <% end %>

      <!-- Comparison -->
      <%= if @active_tab == "comparison" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Plug.Router is minimal by design. Phoenix.Router adds pipelines, named routes, and the full Phoenix ecosystem.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-rose-600 dark:text-rose-400 mb-3">Plug.Router</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre mb-3">{plug_router_example()}</div>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-400">
                <li>+ Minimal, lightweight</li>
                <li>+ Easy to understand</li>
                <li>+ Good for microservices</li>
                <li>- No pipelines</li>
                <li>- No named routes</li>
                <li>- No LiveView/Channels</li>
              </ul>
            </div>

            <div class="p-4 rounded-lg border border-teal-200 dark:border-teal-700 bg-teal-50 dark:bg-teal-900/20">
              <h4 class="font-semibold text-teal-600 dark:text-teal-400 mb-3">Phoenix.Router</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre mb-3">{phoenix_router_example()}</div>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-400">
                <li>+ Pipelines (middleware groups)</li>
                <li>+ Named routes & verified routes</li>
                <li>+ LiveView & Channels</li>
                <li>+ Scoping & nesting</li>
                <li>+ Code generation</li>
                <li>+ Error handling</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("update_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, method: method)}
  end

  def handle_event("update_path", %{"path" => path}, socket) do
    {:noreply, assign(socket, path: path)}
  end

  def handle_event("send_request", _, socket) do
    response = simulate_route(socket.assigns.method, socket.assigns.path)
    {:noreply, assign(socket, response: response)}
  end

  def handle_event("quick_route", %{"method" => method, "path" => path}, socket) do
    response = simulate_route(method, path)
    {:noreply, assign(socket, method: method, path: path, response: response)}
  end

  defp simulate_route("GET", "/") do
    %{status: 200, reason: "OK", body: "Welcome to the Plug.Router app!",
      headers: ["Content-Type: text/html"],
      matched_route: "get \"/\" do ... end"}
  end

  defp simulate_route("GET", "/hello/" <> name) when name != "" do
    %{status: 200, reason: "OK", body: "Hello, #{name}!",
      headers: ["Content-Type: text/html"],
      matched_route: "get \"/hello/:name\" do ... end\n# name = \"#{name}\""}
  end

  defp simulate_route("GET", "/users") do
    %{status: 200, reason: "OK",
      body: "[{\"id\": 1, \"name\": \"Alice\"}, {\"id\": 2, \"name\": \"Bob\"}]",
      headers: ["Content-Type: application/json"],
      matched_route: "get \"/users\" do ... end"}
  end

  defp simulate_route("GET", "/users/" <> id) do
    case Integer.parse(id) do
      {n, ""} when n in [1, 2] ->
        name = if n == 1, do: "Alice", else: "Bob"
        %{status: 200, reason: "OK",
          body: "{\"id\": #{n}, \"name\": \"#{name}\"}",
          headers: ["Content-Type: application/json"],
          matched_route: "get \"/users/:id\" do ... end\n# id = \"#{id}\""}

      _ ->
        %{status: 404, reason: "Not Found",
          body: "{\"error\": \"User not found\"}",
          headers: ["Content-Type: application/json"],
          matched_route: "get \"/users/:id\" do ... end\n# id = \"#{id}\" (no match)"}
    end
  end

  defp simulate_route("POST", "/api/echo") do
    %{status: 200, reason: "OK",
      body: "(echoed request body)",
      headers: ["Content-Type: text/plain"],
      matched_route: "post \"/api/echo\" do ... end"}
  end

  defp simulate_route("POST", "/users") do
    %{status: 201, reason: "Created",
      body: "{\"id\": 3, \"name\": \"(from body)\"}",
      headers: ["Content-Type: application/json"],
      matched_route: "post \"/users\" do ... end"}
  end

  defp simulate_route(method, path) do
    %{status: 404, reason: "Not Found",
      body: "Not Found",
      headers: ["Content-Type: text/plain"],
      matched_route: "match _ do ... end\n# No route for #{method} #{path}"}
  end

  defp sample_routes do
    [
      %{method: "GET", path: "/"},
      %{method: "GET", path: "/hello/World"},
      %{method: "GET", path: "/users"},
      %{method: "GET", path: "/users/1"},
      %{method: "POST", path: "/users"},
      %{method: "POST", path: "/api/echo"},
      %{method: "GET", path: "/nonexistent"}
    ]
  end

  defp defined_routes do
    [
      %{method: "GET", path: "/", description: "Welcome page"},
      %{method: "GET", path: "/hello/:name", description: "Greeting with path param"},
      %{method: "GET", path: "/users", description: "List all users (JSON)"},
      %{method: "GET", path: "/users/:id", description: "Get user by ID (JSON)"},
      %{method: "POST", path: "/users", description: "Create a user (JSON)"},
      %{method: "POST", path: "/api/echo", description: "Echo request body"},
      %{method: "ANY", path: "_", description: "Catch-all → 404"}
    ]
  end

  defp status_color(status) when status < 300, do: "bg-green-600 text-white"
  defp status_color(status) when status < 400, do: "bg-yellow-600 text-white"
  defp status_color(_), do: "bg-red-600 text-white"

  defp method_color("GET"), do: "bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300"
  defp method_color("POST"), do: "bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300"
  defp method_color("PUT"), do: "bg-amber-100 dark:bg-amber-900 text-amber-700 dark:text-amber-300"
  defp method_color("DELETE"), do: "bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300"
  defp method_color(_), do: "bg-gray-100 dark:bg-gray-900 text-gray-700 dark:text-gray-300"

  defp tab_label("demo"), do: "Route Tester"
  defp tab_label("code"), do: "Source Code"
  defp tab_label("comparison"), do: "vs Phoenix Router"

  defp router_source_code do
    """
    defmodule MyApp.Router do
      use Plug.Router

      # Plugs run before routing
      plug Plug.Logger
      plug Plug.Parsers,
        parsers: [:urlencoded, :json],
        json_decoder: Jason

      plug :match     # Find matching route
      plug :dispatch  # Execute route handler

      get "/" do
        send_resp(conn, 200, "Welcome!")
      end

      get "/hello/:name" do
        send_resp(conn, 200, "Hello, \#{name}!")
      end

      get "/users" do
        users = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]
        json_resp(conn, 200, users)
      end

      get "/users/:id" do
        user = find_user(String.to_integer(id))
        if user, do: json_resp(conn, 200, user),
                 else: json_resp(conn, 404, %{error: "Not found"})
      end

      post "/users" do
        name = conn.body_params["name"]
        json_resp(conn, 201, %{id: 3, name: name})
      end

      post "/api/echo" do
        {:ok, body, conn} = read_body(conn)
        send_resp(conn, 200, body)
      end

      # Catch-all (must be last!)
      match _ do
        send_resp(conn, 404, "Not Found")
      end

      defp json_resp(conn, status, data) do
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, Jason.encode!(data))
      end
    end\
    """
    |> String.trim()
  end

  defp startup_code do
    """
    # In your application.ex:
    children = [
      {Plug.Cowboy,
        scheme: :http,
        plug: MyApp.Router,
        options: [port: 4001]}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one)\
    """
    |> String.trim()
  end

  defp forward_code do
    """
    defmodule MyApp.Router do
      use Plug.Router
      plug :match
      plug :dispatch

      # Forward all /api/* requests to ApiRouter
      forward "/api", to: MyApp.ApiRouter

      # Forward all /admin/* requests to AdminRouter
      forward "/admin", to: MyApp.AdminRouter

      get "/" do
        send_resp(conn, 200, "Main site")
      end
    end

    defmodule MyApp.ApiRouter do
      use Plug.Router
      plug :match
      plug :dispatch

      # Handles GET /api/users
      get "/users" do
        send_resp(conn, 200, "API users")
      end
    end\
    """
    |> String.trim()
  end

  defp plug_router_example do
    """
    get "/users/:id" do
      user = find_user(id)
      send_resp(conn, 200, user)
    end\
    """
    |> String.trim()
  end

  defp phoenix_router_example do
    """
    scope "/", MyAppWeb do
      pipe_through :browser
      get "/users/:id",
        UserController, :show
    end\
    """
    |> String.trim()
  end
end
