defmodule ElixirKatasWeb.PhoenixKata04ClientServerArchitectureLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Client-Server: Journey of a Web Request

    # Step 1: Browser prepares the request
    GET /products HTTP/1.1
    Host: shop.example.com
    Accept: text/html
    Cookie: session_id=abc123

    # Step 2: DNS resolves the domain
    # shop.example.com → DNS → 93.184.216.34

    # Step 3: Server receives the request
    # Cowboy accepts TCP connection on port 443
    # Creates %Plug.Conn{} struct
    # Passes to Phoenix.Endpoint

    # Step 4: Phoenix processes the request
    # Endpoint → Router → :browser pipeline
    conn
    |> fetch_session()
    |> protect_from_forgery()
    |> ProductController.index()

    # Step 5: Database query (if needed)
    # In ProductController:
    products = Shop.list_products()
    # Ecto: SELECT * FROM products

    # Step 6: Server sends the response
    HTTP/1.1 200 OK
    Content-Type: text/html

    <html>...product list...</html>

    # Step 7: Browser renders the page
    # Parses HTML, fetches CSS/JS/images (more HTTP requests!),
    # paints the page on screen.

    # Static content (priv/static/): files served directly, no code runs
    #   → HTML pages, CSS, JavaScript, images, fonts
    #
    # Dynamic content (Controllers, LiveView): generated per request
    #   → User dashboards, API responses, search results, real-time updates
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       step: 0,
       max_steps: 7,
       animation_running: false
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Client-Server Architecture</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Step through the journey of a web request from browser to server and back.
      </p>

      <!-- Step-by-step diagram -->
      <div class="relative bg-gray-50 dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
        <div class="flex flex-wrap justify-between items-start gap-4">
          <!-- Browser -->
          <div class={["flex flex-col items-center p-4 rounded-xl border-2 transition-all duration-300 w-28",
            if(@step in [0, 1, 7], do: "border-amber-500 bg-amber-50 dark:bg-amber-900/20 scale-105", else: "border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700")]}>
            <svg class="w-10 h-10 text-amber-600 dark:text-amber-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
            </svg>
            <span class="text-sm font-semibold">Browser</span>
            <span class="text-xs text-gray-500">(Client)</span>
          </div>

          <!-- DNS -->
          <div class={["flex flex-col items-center p-4 rounded-xl border-2 transition-all duration-300 w-28",
            if(@step == 2, do: "border-blue-500 bg-blue-50 dark:bg-blue-900/20 scale-105", else: "border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700")]}>
            <svg class="w-10 h-10 text-blue-600 dark:text-blue-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path>
            </svg>
            <span class="text-sm font-semibold">DNS</span>
            <span class="text-xs text-gray-500">Lookup</span>
          </div>

          <!-- Web Server -->
          <div class={["flex flex-col items-center p-4 rounded-xl border-2 transition-all duration-300 w-28",
            if(@step in [3, 4, 5], do: "border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20 scale-105", else: "border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700")]}>
            <svg class="w-10 h-10 text-emerald-600 dark:text-emerald-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"></path>
            </svg>
            <span class="text-sm font-semibold">Server</span>
            <span class="text-xs text-gray-500">(Phoenix)</span>
          </div>

          <!-- Database -->
          <div class={["flex flex-col items-center p-4 rounded-xl border-2 transition-all duration-300 w-28",
            if(@step == 5, do: "border-purple-500 bg-purple-50 dark:bg-purple-900/20 scale-105", else: "border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700")]}>
            <svg class="w-10 h-10 text-purple-600 dark:text-purple-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4"></path>
            </svg>
            <span class="text-sm font-semibold">Database</span>
            <span class="text-xs text-gray-500">(PostgreSQL)</span>
          </div>
        </div>

        <!-- Step description -->
        <div class="mt-6 p-4 rounded-lg bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 min-h-[100px]">
          <div class="flex items-center gap-2 mb-2">
            <span class="px-2 py-0.5 rounded-full bg-amber-100 dark:bg-amber-900 text-amber-800 dark:text-amber-200 text-xs font-semibold">
              Step {@step} of {@max_steps}
            </span>
          </div>
          <p class="text-gray-700 dark:text-gray-200 font-medium">{step_title(@step)}</p>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{step_description(@step)}</p>
          <%= if step_code(@step) do %>
            <pre class="mt-3 p-3 bg-gray-900 rounded text-sm font-mono text-green-400 overflow-x-auto">{step_code(@step)}</pre>
          <% end %>
        </div>
      </div>

      <!-- Controls -->
      <div class="flex items-center gap-3">
        <button
          phx-click="prev_step"
          phx-target={@myself}
          disabled={@step == 0}
          class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
            if(@step == 0, do: "bg-gray-200 text-gray-400 cursor-not-allowed", else: "bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300")]}
        >
          Previous
        </button>
        <button
          phx-click="next_step"
          phx-target={@myself}
          disabled={@step == @max_steps}
          class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
            if(@step == @max_steps, do: "bg-gray-200 text-gray-400 cursor-not-allowed", else: "bg-amber-600 hover:bg-amber-700 text-white")]}
        >
          Next
        </button>
        <button
          phx-click="reset_steps"
          phx-target={@myself}
          class="px-4 py-2 rounded-lg font-medium bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 transition-colors cursor-pointer"
        >
          Reset
        </button>
      </div>

      <!-- Static vs Dynamic comparison -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
        <div class="p-5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Static Content</h3>
          <p class="text-sm text-gray-600 dark:text-gray-300 mb-3">
            Files served directly from disk — no code runs, no database queries. Just read and send.
          </p>
          <div class="space-y-2 text-sm font-mono">
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-blue-400"></span> HTML pages
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-pink-400"></span> CSS stylesheets
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-yellow-400"></span> JavaScript files
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-green-400"></span> Images, fonts, videos
            </div>
          </div>
          <p class="text-xs text-gray-500 mt-3">In Phoenix: <code>priv/static/</code></p>
        </div>

        <div class="p-5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Dynamic Content</h3>
          <p class="text-sm text-gray-600 dark:text-gray-300 mb-3">
            Generated on each request by running code — personalized, data-driven, real-time.
          </p>
          <div class="space-y-2 text-sm font-mono">
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-emerald-400"></span> User dashboards
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-purple-400"></span> API responses (JSON)
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-amber-400"></span> Search results
            </div>
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-red-400"></span> Real-time updates
            </div>
          </div>
          <p class="text-xs text-gray-500 mt-3">In Phoenix: Controllers, LiveView</p>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("next_step", _, socket) do
    step = min(socket.assigns.step + 1, socket.assigns.max_steps)
    {:noreply, assign(socket, step: step)}
  end

  def handle_event("prev_step", _, socket) do
    step = max(socket.assigns.step - 1, 0)
    {:noreply, assign(socket, step: step)}
  end

  def handle_event("reset_steps", _, socket) do
    {:noreply, assign(socket, step: 0)}
  end

  defp step_title(0), do: "User types a URL"
  defp step_title(1), do: "Browser prepares the request"
  defp step_title(2), do: "DNS resolves the domain"
  defp step_title(3), do: "Server receives the request"
  defp step_title(4), do: "Phoenix processes the request"
  defp step_title(5), do: "Database query (if needed)"
  defp step_title(6), do: "Server sends the response"
  defp step_title(7), do: "Browser renders the page"

  defp step_description(0), do: "The user enters https://shop.example.com/products in the browser's address bar and hits Enter."
  defp step_description(1), do: "The browser constructs an HTTP GET request with headers (Accept, User-Agent, Cookies) and prepares to send it."
  defp step_description(2), do: "The browser asks a DNS server to translate 'shop.example.com' into an IP address (e.g., 93.184.216.34). This is cached after the first lookup."
  defp step_description(3), do: "The request arrives at the server's IP address on port 443 (HTTPS). Cowboy (the HTTP server) accepts the connection and hands it to Phoenix."
  defp step_description(4), do: "Phoenix runs the request through: Endpoint → Router → Pipeline (plugs) → Controller. Each step transforms the Plug.Conn struct."
  defp step_description(5), do: "The controller calls context functions that use Ecto to query the database. Results are loaded into memory as Elixir structs."
  defp step_description(6), do: "The controller renders a template (HTML) or encodes data (JSON), sets the status code, and sends the response back through the network."
  defp step_description(7), do: "The browser receives HTML, parses it, fetches linked CSS/JS/images (more HTTP requests!), and paints the page on screen."

  defp step_code(0), do: nil
  defp step_code(1), do: "GET /products HTTP/1.1\nHost: shop.example.com\nAccept: text/html\nCookie: session_id=abc123"
  defp step_code(2), do: "shop.example.com → DNS → 93.184.216.34"
  defp step_code(3), do: "# Cowboy accepts TCP connection\n# Creates %Plug.Conn{} struct\n# Passes to Phoenix.Endpoint"
  defp step_code(4), do: "# Endpoint → Router → :browser pipeline\nconn\n|> fetch_session()\n|> protect_from_forgery()\n|> ProductController.index()"
  defp step_code(5), do: "# In ProductController:\nproducts = Shop.list_products()\n# Ecto: SELECT * FROM products"
  defp step_code(6), do: "HTTP/1.1 200 OK\nContent-Type: text/html\n\n<html>...product list...</html>"
  defp step_code(7), do: nil
end
