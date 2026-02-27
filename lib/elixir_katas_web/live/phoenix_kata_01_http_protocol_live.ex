defmodule ElixirKatasWeb.PhoenixKata01HttpProtocolLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # HTTP Request Structure
    # Every HTTP request is plain text with this format:
    #
    #   METHOD PATH HTTP/1.1
    #   Header-Name: Header-Value
    #   \\r\\n
    #   (optional body)

    # Request line examples:
    GET /users HTTP/1.1
    POST /users HTTP/1.1
    DELETE /users/3 HTTP/1.1

    # Common headers:
    Host: example.com
    Accept: text/html
    Content-Type: application/json
    User-Agent: Browser/1.0

    # HTTP Response Structure:
    #   HTTP/1.1 STATUS_CODE REASON
    #   Header-Name: Header-Value
    #   \\r\\n
    #   (body)

    # Common Status Codes:
    # 200 OK            - Success
    # 201 Created       - Resource created (POST)
    # 204 No Content    - Success, no body (DELETE)
    # 301 Moved         - Permanent redirect
    # 304 Not Modified  - Use cached version
    # 400 Bad Request   - Client error
    # 401 Unauthorized  - Not authenticated
    # 404 Not Found     - Resource doesn't exist
    # 500 Server Error  - Something broke on server

    # Example response:
    HTTP/1.1 200 OK
    Content-Type: application/json
    Server: Phoenix/1.8

    [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       method: "GET",
       path: "/users",
       headers: [
         {"Host", "example.com"},
         {"Accept", "text/html"},
         {"User-Agent", "Browser/1.0"}
       ],
       body: "",
       response_status: nil,
       response_headers: [],
       response_body: nil,
       show_raw: false
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">HTTP Request Builder</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Build an HTTP request and see the raw text that gets sent over the wire.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Request Builder -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-amber-700 dark:text-amber-400">Request</h3>

          <div class="flex gap-2">
            <select
              phx-change="set_method"
              phx-target={@myself}
              name="method"
              class="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 font-mono"
            >
              <%= for m <- ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"] do %>
                <option value={m} selected={m == @method}>{m}</option>
              <% end %>
            </select>
            <input
              type="text"
              value={@path}
              phx-change="set_path"
              phx-target={@myself}
              name="path"
              class="flex-1 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 font-mono"
              placeholder="/path"
            />
          </div>

          <div class="space-y-2">
            <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Headers</h4>
            <%= for {name, value} <- @headers do %>
              <div class="flex gap-2 items-center text-sm font-mono">
                <span class="text-amber-600 dark:text-amber-400 font-semibold">{name}:</span>
                <span class="text-gray-700 dark:text-gray-300">{value}</span>
              </div>
            <% end %>
          </div>

          <%= if @method in ["POST", "PUT", "PATCH"] do %>
            <div>
              <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Body</h4>
              <textarea
                phx-change="set_body"
                phx-target={@myself}
                name="body"
                rows="3"
                class="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 font-mono text-sm"
                placeholder={"name=John&email=john@example.com"}
              >{@body}</textarea>
            </div>
          <% end %>

          <button
            phx-click="send_request"
            phx-target={@myself}
            class="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-lg font-medium transition-colors cursor-pointer"
          >
            Send Request
          </button>
        </div>

        <!-- Raw HTTP View -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-amber-700 dark:text-amber-400">Raw HTTP</h3>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 whitespace-pre overflow-x-auto">
            <div class="text-yellow-300">{@method} {@path} HTTP/1.1</div>
            <%= for {name, value} <- @headers do %>
              <div><span class="text-cyan-300">{name}</span>: {value}</div>
            <% end %>
            <%= if @method in ["POST", "PUT", "PATCH"] do %>
              <div class="text-cyan-300">Content-Length: {byte_size(@body)}</div>
            <% end %>
            <div class="text-gray-600">&#8203;</div>
            <%= if @body != "" do %>
              <div class="text-white">{@body}</div>
            <% end %>
          </div>

          <%= if @response_status do %>
            <h3 class="text-lg font-semibold text-emerald-700 dark:text-emerald-400">Response</h3>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 whitespace-pre overflow-x-auto">
              <div class="text-yellow-300">HTTP/1.1 {@response_status}</div>
              <%= for {name, value} <- @response_headers do %>
                <div><span class="text-cyan-300">{name}</span>: {value}</div>
              <% end %>
              <div class="text-gray-600">&#8203;</div>
              <div class="text-white">{@response_body}</div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Status Code Reference -->
      <div class="mt-8">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Common Status Codes</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div class="p-3 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
            <span class="font-mono font-bold text-emerald-700 dark:text-emerald-400">200</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">OK</span>
          </div>
          <div class="p-3 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
            <span class="font-mono font-bold text-emerald-700 dark:text-emerald-400">201</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">Created</span>
          </div>
          <div class="p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <span class="font-mono font-bold text-blue-700 dark:text-blue-400">301</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">Moved</span>
          </div>
          <div class="p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <span class="font-mono font-bold text-blue-700 dark:text-blue-400">304</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">Not Modified</span>
          </div>
          <div class="p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <span class="font-mono font-bold text-amber-700 dark:text-amber-400">400</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">Bad Request</span>
          </div>
          <div class="p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <span class="font-mono font-bold text-amber-700 dark:text-amber-400">401</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">Unauthorized</span>
          </div>
          <div class="p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <span class="font-mono font-bold text-amber-700 dark:text-amber-400">404</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">Not Found</span>
          </div>
          <div class="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
            <span class="font-mono font-bold text-red-700 dark:text-red-400">500</span>
            <span class="text-sm text-gray-600 dark:text-gray-300 ml-1">Server Error</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("set_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, method: method)}
  end

  def handle_event("set_path", %{"path" => path}, socket) do
    {:noreply, assign(socket, path: path)}
  end

  def handle_event("set_body", %{"body" => body}, socket) do
    {:noreply, assign(socket, body: body)}
  end

  def handle_event("send_request", _, socket) do
    {status, headers, body} = simulate_response(socket.assigns.method, socket.assigns.path)

    {:noreply,
     assign(socket,
       response_status: status,
       response_headers: headers,
       response_body: body
     )}
  end

  defp simulate_response("GET", "/users") do
    {"200 OK",
     [{"Content-Type", "application/json"}, {"Server", "Phoenix/1.8"}],
     ~s([{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}])}
  end

  defp simulate_response("POST", _path) do
    {"201 Created",
     [{"Content-Type", "application/json"}, {"Location", "/users/3"}],
     ~s({"id": 3, "message": "Resource created"})}
  end

  defp simulate_response("DELETE", _path) do
    {"204 No Content",
     [{"Server", "Phoenix/1.8"}],
     ""}
  end

  defp simulate_response("PUT", _path) do
    {"200 OK",
     [{"Content-Type", "application/json"}],
     ~s({"message": "Resource updated"})}
  end

  defp simulate_response("PATCH", _path) do
    {"200 OK",
     [{"Content-Type", "application/json"}],
     ~s({"message": "Resource partially updated"})}
  end

  defp simulate_response(_method, "/404") do
    {"404 Not Found",
     [{"Content-Type", "text/html"}],
     "<h1>Not Found</h1>"}
  end

  defp simulate_response(_method, _path) do
    {"200 OK",
     [{"Content-Type", "text/html"}, {"Server", "Phoenix/1.8"}],
     "<h1>Welcome</h1><p>Hello from the server!</p>"}
  end
end
