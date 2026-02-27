defmodule ElixirKatasWeb.PhoenixKata07ParsingHttpByHandLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule HTTPParser do
      def parse(raw) do
        # Split headers from body at the blank line
        [head, body] = String.split(raw, "\\r\\n\\r\\n", parts: 2)
        [request_line | header_lines] = String.split(head, "\\r\\n")

        # Parse request line: "GET /products?page=2 HTTP/1.1"
        [method, full_path, version] = String.split(request_line, " ")

        # Separate path from query string
        {path, query_string} =
          case String.split(full_path, "?", parts: 2) do
            [p, q] -> {p, q}
            [p]    -> {p, ""}
          end

        # Parse headers into a map
        headers =
          header_lines
          |> Enum.map(fn line ->
            [k, v] = String.split(line, ": ", parts: 2)
            {String.downcase(k), v}
          end)
          |> Map.new()

        %{
          method: method,
          path: path,
          query_string: query_string,
          params: URI.decode_query(query_string),
          version: version,
          headers: headers,
          body: body
        }
      end
    end

    # Building an HTTP response
    defmodule HTTPBuilder do
      def response(status, body) do
        reason = %{200 => "OK", 201 => "Created", 404 => "Not Found", 500 => "Internal Server Error"}

        "HTTP/1.1 \#{status} \#{reason[status]}\\r\\n" <>
        "Content-Type: text/html\\r\\n" <>
        "Content-Length: \#{byte_size(body)}\\r\\n" <>
        "Connection: close\\r\\n" <>
        "\\r\\n" <>
        body
      end
    end

    # How parsed data maps to Plug.Conn:
    # conn.method        = "GET"
    # conn.request_path  = "/products"
    # conn.query_string  = "page=2"
    # conn.params        = %{"page" => "2"}
    # conn.req_headers   = [{"host", "shop.example.com"}, ...]
    """
    |> String.trim()
  end

  def mount(socket) do
    default_request = "GET /products?page=2 HTTP/1.1\r\nHost: shop.example.com\r\nAccept: text/html\r\nUser-Agent: Mozilla/5.0\r\nCookie: session=abc123\r\n\r\n"

    {:ok,
     assign(socket,
       raw_request: default_request,
       parsed: parse_http(default_request),
       response_status: "200",
       response_body: "<h1>Hello!</h1>",
       built_response: nil
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Parsing HTTP by Hand</h2>
      <p class="text-gray-600 dark:text-gray-300">
        HTTP is a text-based protocol. Type a raw request to see how it's parsed into structured data.
      </p>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Raw request input -->
        <div class="space-y-3">
          <h3 class="text-lg font-semibold text-teal-700 dark:text-teal-400">Raw HTTP Request</h3>
          <textarea
            phx-change="update_request"
            phx-target={@myself}
            name="raw"
            rows="10"
            class="w-full font-mono text-sm bg-gray-900 text-green-400 rounded-lg p-4 border border-gray-700 focus:border-teal-500 focus:ring-1 focus:ring-teal-500"
            spellcheck="false"
          >{@raw_request}</textarea>
          <p class="text-xs text-gray-500">Edit the raw request text above — the parser updates in real-time.</p>

          <!-- Quick presets -->
          <div class="flex flex-wrap gap-2">
            <button phx-click="preset_get" phx-target={@myself}
              class="px-3 py-1 text-xs rounded-full bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 hover:bg-green-200 dark:hover:bg-green-800 cursor-pointer">
              GET request
            </button>
            <button phx-click="preset_post" phx-target={@myself}
              class="px-3 py-1 text-xs rounded-full bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 hover:bg-blue-200 dark:hover:bg-blue-800 cursor-pointer">
              POST with body
            </button>
            <button phx-click="preset_json" phx-target={@myself}
              class="px-3 py-1 text-xs rounded-full bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300 hover:bg-purple-200 dark:hover:bg-purple-800 cursor-pointer">
              JSON API
            </button>
          </div>
        </div>

        <!-- Parsed output -->
        <div class="space-y-3">
          <h3 class="text-lg font-semibold text-teal-700 dark:text-teal-400">Parsed Result</h3>

          <%= if @parsed.error do %>
            <div class="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
              <p class="text-red-600 dark:text-red-400 text-sm font-medium">{@parsed.error}</p>
            </div>
          <% else %>
            <!-- Request line -->
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
              <p class="text-xs font-semibold text-gray-500 uppercase mb-2">Request Line</p>
              <div class="flex flex-wrap gap-2">
                <span class="px-2 py-1 rounded bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 font-mono text-sm">
                  {@parsed.method}
                </span>
                <span class="px-2 py-1 rounded bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 font-mono text-sm">
                  {@parsed.path}
                </span>
                <span class="px-2 py-1 rounded bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 font-mono text-sm">
                  {@parsed.version}
                </span>
              </div>
            </div>

            <!-- Query params -->
            <%= if @parsed.params != %{} do %>
              <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                <p class="text-xs font-semibold text-gray-500 uppercase mb-2">Query Parameters</p>
                <div class="space-y-1">
                  <%= for {key, val} <- @parsed.params do %>
                    <div class="flex gap-2 font-mono text-sm">
                      <span class="text-amber-600 dark:text-amber-400">{key}</span>
                      <span class="text-gray-400">=</span>
                      <span class="text-cyan-600 dark:text-cyan-400">{val}</span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <!-- Headers -->
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
              <p class="text-xs font-semibold text-gray-500 uppercase mb-2">Headers</p>
              <div class="space-y-1">
                <%= for {key, val} <- @parsed.headers do %>
                  <div class="flex gap-2 font-mono text-sm">
                    <span class="text-pink-600 dark:text-pink-400">{key}:</span>
                    <span class="text-gray-700 dark:text-gray-300">{val}</span>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Body -->
            <%= if @parsed.body != "" do %>
              <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                <p class="text-xs font-semibold text-gray-500 uppercase mb-2">Body</p>
                <pre class="font-mono text-sm text-gray-700 dark:text-gray-300 whitespace-pre-wrap">{@parsed.body}</pre>
              </div>
            <% end %>

            <!-- Plug.Conn mapping -->
            <div class="p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase mb-2">In Phoenix (Plug.Conn)</p>
              <pre class="font-mono text-xs text-amber-800 dark:text-amber-200 whitespace-pre">{format_conn_mapping(@parsed)}</pre>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Response builder -->
      <div class="mt-8 space-y-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Build an HTTP Response</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Status Code</label>
            <select
              phx-change="update_response"
              phx-target={@myself}
              name="status"
              class="w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm"
            >
              <option value="200" selected={@response_status == "200"}>200 OK</option>
              <option value="201" selected={@response_status == "201"}>201 Created</option>
              <option value="301" selected={@response_status == "301"}>301 Moved Permanently</option>
              <option value="400" selected={@response_status == "400"}>400 Bad Request</option>
              <option value="404" selected={@response_status == "404"}>404 Not Found</option>
              <option value="500" selected={@response_status == "500"}>500 Internal Server Error</option>
            </select>
          </div>
          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Response Body</label>
            <input
              type="text"
              phx-change="update_response"
              phx-target={@myself}
              name="body"
              value={@response_body}
              class="w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 text-sm font-mono"
            />
          </div>
        </div>
        <button phx-click="build_response" phx-target={@myself}
          class="px-4 py-2 rounded-lg font-medium bg-teal-600 hover:bg-teal-700 text-white transition-colors cursor-pointer">
          Build Response
        </button>

        <%= if @built_response do %>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
            <pre class="text-pink-300 whitespace-pre">{@built_response}</pre>
          </div>
        <% end %>
      </div>

      <!-- Parser code -->
      <div class="mt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Parser Source Code</h3>
        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{parser_source_code()}</div>
      </div>
    </div>
    """
  end

  def handle_event("update_request", %{"raw" => raw}, socket) do
    {:noreply, assign(socket, raw_request: raw, parsed: parse_http(raw))}
  end

  def handle_event("update_response", params, socket) do
    status = params["status"] || socket.assigns.response_status
    body = params["body"] || socket.assigns.response_body
    {:noreply, assign(socket, response_status: status, response_body: body)}
  end

  def handle_event("build_response", _, socket) do
    status = String.to_integer(socket.assigns.response_status)
    body = socket.assigns.response_body
    response = build_http_response(status, body)
    {:noreply, assign(socket, built_response: response)}
  end

  def handle_event("preset_get", _, socket) do
    raw = "GET /products?page=2 HTTP/1.1\r\nHost: shop.example.com\r\nAccept: text/html\r\nUser-Agent: Mozilla/5.0\r\nCookie: session=abc123\r\n\r\n"
    {:noreply, assign(socket, raw_request: raw, parsed: parse_http(raw))}
  end

  def handle_event("preset_post", _, socket) do
    raw = "POST /login HTTP/1.1\r\nHost: example.com\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 29\r\n\r\nemail=alice@ex.com&pass=secret"
    {:noreply, assign(socket, raw_request: raw, parsed: parse_http(raw))}
  end

  def handle_event("preset_json", _, socket) do
    raw = "POST /api/users HTTP/1.1\r\nHost: api.example.com\r\nContent-Type: application/json\r\nAccept: application/json\r\nAuthorization: Bearer eyJhbGciOi...\r\n\r\n{\"name\": \"Alice\", \"email\": \"alice@example.com\"}"
    {:noreply, assign(socket, raw_request: raw, parsed: parse_http(raw))}
  end

  defp parse_http(raw) do
    try do
      case String.split(raw, "\r\n\r\n", parts: 2) do
        [head, body] ->
          [request_line | header_lines] = String.split(head, "\r\n")

          case String.split(request_line, " ") do
            [method, full_path, version] ->
              {path, query_string} =
                case String.split(full_path, "?", parts: 2) do
                  [p, q] -> {p, q}
                  [p] -> {p, ""}
                end

              headers =
                header_lines
                |> Enum.reject(&(&1 == ""))
                |> Enum.map(fn line ->
                  case String.split(line, ": ", parts: 2) do
                    [k, v] -> {String.downcase(k), v}
                    [k] -> {String.downcase(k), ""}
                  end
                end)

              %{
                method: method,
                path: path,
                query_string: query_string,
                params: URI.decode_query(query_string),
                version: version,
                headers: headers,
                body: body,
                error: nil
              }

            _ ->
              %{error: "Invalid request line — expected: METHOD PATH VERSION"}
          end

        _ ->
          %{error: "Missing blank line (\\r\\n\\r\\n) between headers and body"}
      end
    rescue
      _ -> %{error: "Could not parse request — check the format"}
    end
  end

  defp build_http_response(status, body) do
    reason =
      case status do
        200 -> "OK"
        201 -> "Created"
        301 -> "Moved Permanently"
        400 -> "Bad Request"
        404 -> "Not Found"
        500 -> "Internal Server Error"
        _ -> "Unknown"
      end

    header_lines = [
      "Content-Type: text/html",
      "Content-Length: #{byte_size(body)}",
      "Connection: close"
    ]

    "HTTP/1.1 #{status} #{reason}\r\n#{Enum.join(header_lines, "\r\n")}\r\n\r\n#{body}"
  end

  defp format_conn_mapping(parsed) do
    params_str =
      parsed.params
      |> Enum.map(fn {k, v} -> "  \"#{k}\" => \"#{v}\"" end)
      |> Enum.join(",\n")

    headers_str =
      parsed.headers
      |> Enum.map(fn {k, v} -> "  {\"#{k}\", \"#{v}\"}" end)
      |> Enum.join(",\n")

    "conn.method        = \"#{parsed.method}\"\nconn.request_path  = \"#{parsed.path}\"\nconn.query_string  = \"#{parsed.query_string}\"\nconn.params        = %{\n#{params_str}\n}\nconn.req_headers   = [\n#{headers_str}\n]"
  end

  defp parser_source_code do
    """
    defmodule HTTPParser do
      def parse(raw) do
        [head, body] = String.split(raw, "\\r\\n\\r\\n", parts: 2)
        [request_line | header_lines] = String.split(head, "\\r\\n")
        [method, full_path, version] = String.split(request_line, " ")

        {path, query_string} =
          case String.split(full_path, "?", parts: 2) do
            [p, q] -> {p, q}
            [p]    -> {p, ""}
          end

        headers =
          header_lines
          |> Enum.map(fn line ->
            [k, v] = String.split(line, ": ", parts: 2)
            {String.downcase(k), v}
          end)
          |> Map.new()

        %{
          method: method,
          path: path,
          query_string: query_string,
          params: URI.decode_query(query_string),
          version: version,
          headers: headers,
          body: body
        }
      end
    end\
    """
    |> String.trim()
  end
end
