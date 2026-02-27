defmodule ElixirKatasWeb.PhoenixKata08CowboyAndRanchLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Cowboy Handler: called for each HTTP request
    defmodule MyHandler do
      def init(req, state) do
        method = :cowboy_req.method(req)
        path = :cowboy_req.path(req)

        {status, body} =
          case {method, path} do
            {"GET", "/"} ->
              {200, "<h1>Welcome!</h1>"}
            {"GET", "/about"} ->
              {200, "<h1>About Us</h1>"}
            _ ->
              {404, "<h1>Not Found</h1>"}
          end

        req = :cowboy_req.reply(status, %{
          "content-type" => "text/html"
        }, body, req)

        {:ok, req, state}
      end
    end

    # Cowboy Dispatch Rules: map URL patterns to handlers
    dispatch = :cowboy_router.compile([
      {:_, [                                # Match any hostname
        {"/", PageHandler, []},             # Exact match: /
        {"/about", PageHandler, []},        # Exact match: /about
        {"/api/[...]", ApiHandler, []},     # Prefix match: /api/*
        {:_, NotFoundHandler, []}           # Catch-all: everything else
      ]}
    ])

    # Start the server with dispatch rules
    :cowboy.start_clear(:my_http_listener,
      [port: 4000],                         # Ranch options (TCP)
      %{env: %{dispatch: dispatch}}         # Cowboy options (HTTP)
    )

    # Phoenix startup chain:
    # 1. mix phx.server → starts application supervisor
    # 2. Phoenix.Endpoint.start_link() → initializes endpoint
    # 3. Plug.Cowboy.http(Endpoint, [], port: 4000) → tells Cowboy to start
    # 4. :cowboy.start_clear(:http, ...) → Cowboy starts Ranch listener
    # 5. Ranch listens on port 4000 → 100 acceptors ready

    # config/dev.exs → flows through Phoenix → Plug.Cowboy → :cowboy → :ranch
    config :my_app, MyAppWeb.Endpoint,
      http: [port: 4000],       # → Ranch: listen on port 4000
      debug_errors: true,       # → Cowboy: show error details
      check_origin: false       # → Cowboy: WebSocket origin check
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "architecture",
       handler_path: "/",
       handler_result: nil
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Cowboy & Ranch</h2>
      <p class="text-gray-600 dark:text-gray-300">
        The HTTP server and TCP connection pool under Phoenix. Explore how requests flow from TCP to your code.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["architecture", "handler", "dispatch", "phoenix"]}
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

      <!-- Architecture tab -->
      <%= if @active_tab == "architecture" do %>
        <div class="space-y-6">
          <!-- Stack visualization -->
          <div class="max-w-xl mx-auto space-y-0">
            <.stack_layer label="Your Phoenix App" detail="Controllers, LiveView, Channels" color="bg-amber-100 dark:bg-amber-900/30 border-amber-300 dark:border-amber-700" />
            <.stack_arrow />
            <.stack_layer label="Phoenix Framework" detail="Routing, MVC, real-time" color="bg-orange-100 dark:bg-orange-900/30 border-orange-300 dark:border-orange-700" />
            <.stack_arrow />
            <.stack_layer label="Plug" detail="HTTP middleware specification" color="bg-purple-100 dark:bg-purple-900/30 border-purple-300 dark:border-purple-700" />
            <.stack_arrow />
            <.stack_layer label="Cowboy" detail="HTTP parser, dispatches to handlers, WebSocket support" color="bg-teal-100 dark:bg-teal-900/30 border-teal-300 dark:border-teal-700" active={true} />
            <.stack_arrow />
            <.stack_layer label="Ranch" detail="TCP connection pool — 100 acceptors, supervised workers" color="bg-blue-100 dark:bg-blue-900/30 border-blue-300 dark:border-blue-700" active={true} />
            <.stack_arrow />
            <.stack_layer label=":gen_tcp / BEAM VM" detail="Raw TCP sockets (Kata 06)" color="bg-gray-100 dark:bg-gray-800 border-gray-300 dark:border-gray-600" />
          </div>

          <!-- Ranch vs our server comparison -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Our Kata 06 Server</h4>
              <ul class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li class="flex items-center gap-2"><span class="text-red-500">x</span> 1 acceptor (single loop)</li>
                <li class="flex items-center gap-2"><span class="text-red-500">x</span> No supervision</li>
                <li class="flex items-center gap-2"><span class="text-red-500">x</span> No connection limits</li>
                <li class="flex items-center gap-2"><span class="text-red-500">x</span> TCP only</li>
                <li class="flex items-center gap-2"><span class="text-red-500">x</span> Crash = connection lost</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-teal-200 dark:border-teal-700 bg-teal-50 dark:bg-teal-900/20">
              <h4 class="font-semibold text-teal-700 dark:text-teal-300 mb-3">Ranch + Cowboy</h4>
              <ul class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li class="flex items-center gap-2"><span class="text-green-500">+</span> 100 acceptors (configurable pool)</li>
                <li class="flex items-center gap-2"><span class="text-green-500">+</span> Full OTP supervision tree</li>
                <li class="flex items-center gap-2"><span class="text-green-500">+</span> Connection limits & backpressure</li>
                <li class="flex items-center gap-2"><span class="text-green-500">+</span> TCP + TLS</li>
                <li class="flex items-center gap-2"><span class="text-green-500">+</span> Crash = restart & recover</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Handler tab -->
      <%= if @active_tab == "handler" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            In pure Cowboy (without Phoenix/Plug), you write handler modules. Try different paths to see how a Cowboy handler dispatches.
          </p>

          <div class="flex gap-2 items-end">
            <div class="flex-1">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Request Path</label>
              <div class="flex gap-2">
                <span class="px-3 py-2 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 rounded-lg text-sm font-mono font-bold">GET</span>
                <input
                  type="text"
                  phx-change="update_handler_path"
                  phx-target={@myself}
                  name="path"
                  value={@handler_path}
                  class="flex-1 rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm font-mono"
                  placeholder="/"
                />
              </div>
            </div>
            <button phx-click="run_handler" phx-target={@myself}
              class="px-4 py-2 rounded-lg font-medium bg-teal-600 hover:bg-teal-700 text-white transition-colors cursor-pointer">
              Dispatch
            </button>
          </div>

          <!-- Quick path buttons -->
          <div class="flex flex-wrap gap-2">
            <button :for={path <- ["/", "/about", "/api/users", "/api/products/42", "/unknown"]}
              phx-click="set_handler_path"
              phx-target={@myself}
              phx-value-path={path}
              class="px-3 py-1 text-xs rounded-full bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 font-mono cursor-pointer">
              {path}
            </button>
          </div>

          <%= if @handler_result do %>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
              <pre class="text-gray-500 mb-2"># Cowboy dispatch for: GET {@handler_path}</pre>
              <pre class={["whitespace-pre", handler_result_color(@handler_result.status)]}>{@handler_result.output}</pre>
            </div>
          <% end %>

          <!-- Handler source code -->
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{handler_source_code()}</div>
        </div>
      <% end %>

      <!-- Dispatch tab -->
      <%= if @active_tab == "dispatch" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Cowboy uses dispatch rules to map URL patterns to handler modules. This is similar to Phoenix's router but lower-level.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{dispatch_source_code()}</div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Cowboy Dispatch vs Phoenix Router</p>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <p class="font-mono text-xs text-gray-500 mb-1">Cowboy dispatch:</p>
                <pre class="text-amber-800 dark:text-amber-200 font-mono text-xs whitespace-pre">{cowboy_dispatch_example()}</pre>
              </div>
              <div>
                <p class="font-mono text-xs text-gray-500 mb-1">Phoenix router:</p>
                <pre class="text-amber-800 dark:text-amber-200 font-mono text-xs whitespace-pre">{phoenix_router_example()}</pre>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Phoenix integration tab -->
      <%= if @active_tab == "phoenix" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix uses Cowboy through Plug. Here's the chain of calls when you run <code>mix phx.server</code>.
          </p>

          <!-- Startup chain -->
          <div class="space-y-0 max-w-lg mx-auto">
            <.chain_step num="1" title="mix phx.server" detail="Starts the application supervisor" />
            <.chain_arrow />
            <.chain_step num="2" title="Phoenix.Endpoint.start_link()" detail="Initializes the Endpoint" />
            <.chain_arrow />
            <.chain_step num="3" title="Plug.Cowboy.http(Endpoint, [], port: 4000)" detail="Plug tells Cowboy to start" />
            <.chain_arrow />
            <.chain_step num="4" title=":cowboy.start_clear(:http, ...)" detail="Cowboy starts Ranch listener" />
            <.chain_arrow />
            <.chain_step num="5" title="Ranch listens on port 4000" detail="100 acceptors ready for connections" />
          </div>

          <!-- Config mapping -->
          <div class="mt-6">
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Config to Cowboy Mapping</h4>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{config_mapping_code()}</div>
          </div>

          <!-- WebSocket note -->
          <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
            <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-2">WebSocket Support</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Cowboy also handles WebSocket connections for LiveView and Channels.
              When a browser sends an HTTP Upgrade request, Cowboy switches the
              connection from HTTP to WebSocket framing — enabling real-time
              communication without new HTTP requests.
            </p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :detail, :string, required: true
  attr :color, :string, required: true
  attr :active, :boolean, default: false

  defp stack_layer(assigns) do
    ~H"""
    <div class={["p-3 rounded-lg border-2 text-center transition-all", @color,
      if(@active, do: "ring-2 ring-teal-400 ring-offset-1", else: "")]}>
      <p class="font-semibold text-sm text-gray-800 dark:text-gray-200">{@label}</p>
      <p class="text-xs text-gray-500 dark:text-gray-400">{@detail}</p>
    </div>
    """
  end

  defp stack_arrow(assigns) do
    ~H"""
    <div class="text-center text-gray-400 text-sm py-0.5">↑</div>
    """
  end

  attr :num, :string, required: true
  attr :title, :string, required: true
  attr :detail, :string, required: true

  defp chain_step(assigns) do
    ~H"""
    <div class="flex items-start gap-3 p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
      <span class="w-6 h-6 rounded-full bg-teal-500 text-white flex items-center justify-center text-xs flex-shrink-0">{@num}</span>
      <div>
        <p class="font-mono text-sm font-semibold text-gray-800 dark:text-gray-200">{@title}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{@detail}</p>
      </div>
    </div>
    """
  end

  defp chain_arrow(assigns) do
    ~H"""
    <div class="text-center text-gray-400 text-sm py-0.5 ml-3">↓</div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("update_handler_path", %{"path" => path}, socket) do
    {:noreply, assign(socket, handler_path: path)}
  end

  def handle_event("set_handler_path", %{"path" => path}, socket) do
    result = simulate_handler("GET", path)
    {:noreply, assign(socket, handler_path: path, handler_result: result)}
  end

  def handle_event("run_handler", _, socket) do
    result = simulate_handler("GET", socket.assigns.handler_path)
    {:noreply, assign(socket, handler_result: result)}
  end

  defp simulate_handler(method, path) do
    {status, body, handler} =
      case {method, path} do
        {"GET", "/"} ->
          {200, "<h1>Welcome!</h1>", "PageHandler"}

        {"GET", "/about"} ->
          {200, "<h1>About Us</h1>", "PageHandler"}

        {"GET", "/api/" <> rest} ->
          {200, "{\"resource\": \"#{rest}\"}", "ApiHandler"}

        _ ->
          {404, "<h1>Not Found</h1>", "NotFoundHandler"}
      end

    output = """
    # Matched handler: #{handler}
    # Calling #{handler}.init(req, state)

    :cowboy_req.reply(#{status}, %{
      "content-type" => "#{if status == 200 && String.starts_with?(path, "/api/"), do: "application/json", else: "text/html"}"
    }, "#{body}", req)

    # Response: #{status} #{reason_phrase(status)}
    # Body: #{body}\
    """

    %{status: status, output: String.trim(output)}
  end

  defp reason_phrase(200), do: "OK"
  defp reason_phrase(404), do: "Not Found"
  defp reason_phrase(_), do: "Unknown"

  defp handler_result_color(200), do: "text-green-400"
  defp handler_result_color(404), do: "text-red-400"
  defp handler_result_color(_), do: "text-yellow-300"

  defp tab_label("architecture"), do: "Architecture"
  defp tab_label("handler"), do: "Handler Demo"
  defp tab_label("dispatch"), do: "Dispatch Rules"
  defp tab_label("phoenix"), do: "Phoenix Integration"

  defp handler_source_code do
    """
    defmodule MyHandler do
      # Cowboy calls init/2 for each request
      def init(req, state) do
        method = :cowboy_req.method(req)
        path = :cowboy_req.path(req)

        {status, body} =
          case {method, path} do
            {"GET", "/"} ->
              {200, "<h1>Welcome!</h1>"}
            {"GET", "/about"} ->
              {200, "<h1>About Us</h1>"}
            _ ->
              {404, "<h1>Not Found</h1>"}
          end

        req = :cowboy_req.reply(status, %{
          "content-type" => "text/html"
        }, body, req)

        {:ok, req, state}
      end
    end\
    """
    |> String.trim()
  end

  defp dispatch_source_code do
    """
    # Cowboy dispatch rules map URL patterns to handler modules
    dispatch = :cowboy_router.compile([
      {:_, [                                # Match any hostname
        {"/", PageHandler, []},             # Exact match: /
        {"/about", PageHandler, []},        # Exact match: /about
        {"/api/[...]", ApiHandler, []},     # Prefix match: /api/*
        {:_, NotFoundHandler, []}           # Catch-all: everything else
      ]}
    ])

    # Start the server with these dispatch rules
    :cowboy.start_clear(:my_http_listener,
      [port: 4000],                         # Ranch options (TCP)
      %{env: %{dispatch: dispatch}}         # Cowboy options (HTTP)
    )\
    """
    |> String.trim()
  end

  defp cowboy_dispatch_example do
    """
    {"/products/:id", ProductHandler, []}
    {"/api/[...]", ApiHandler, []}
    {:_, NotFoundHandler, []}\
    """
    |> String.trim()
  end

  defp phoenix_router_example do
    """
    get "/products/:id", ProductController, :show
    scope "/api" do
      resources "/users", UserController
    end\
    """
    |> String.trim()
  end

  defp config_mapping_code do
    """
    # config/dev.exs
    config :my_app, MyAppWeb.Endpoint,
      http: [port: 4000],       # → Ranch: listen on port 4000
      debug_errors: true,       # → Cowboy: show error details
      check_origin: false       # → Cowboy: WebSocket origin check

    # These options flow through:
    # Phoenix.Endpoint → Plug.Cowboy → :cowboy → :ranch\
    """
    |> String.trim()
  end
end
