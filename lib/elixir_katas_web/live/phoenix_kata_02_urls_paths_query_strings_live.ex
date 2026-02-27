defmodule ElixirKatasWeb.PhoenixKata02UrlsPathsQueryStringsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # URL Anatomy
    # https://shop.example.com:8080/products/shoes?color=red&size=10#reviews
    #
    # scheme: "https"
    # host:   "shop.example.com"
    # port:   8080
    # path:   "/products/shoes"
    # query:  "color=red&size=10"
    # fragment: "reviews"  (never sent to server)

    # Parsing URLs in Elixir
    uri = URI.parse("https://shop.example.com:8080/products/shoes?color=red&size=10#reviews")

    uri.scheme    #=> "https"
    uri.host      #=> "shop.example.com"
    uri.port      #=> 8080
    uri.path      #=> "/products/shoes"
    uri.query     #=> "color=red&size=10"
    uri.fragment  #=> "reviews"

    # Breaking down the path into segments
    path_segments = String.split("/products/shoes", "/", trim: true)
    #=> ["products", "shoes"]

    # Decoding query parameters
    params = URI.decode_query("color=red&size=10")
    #=> %{"color" => "red", "size" => "10"}

    # How it maps to Plug.Conn in Phoenix:
    %Plug.Conn{
      scheme: :https,
      host: "shop.example.com",
      port: 8080,
      request_path: "/products/shoes",
      path_info: ["products", "shoes"],
      query_string: "color=red&size=10",
      params: %{"color" => "red", "size" => "10"}
    }
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       url: "https://shop.example.com:8080/products/shoes?color=red&size=10&sort=price#reviews",
       parsed: nil
     )}
  end

  def update(assigns, socket) do
    socket = assign(socket, id: assigns.id)
    socket = if socket.assigns.parsed == nil, do: parse_url(socket), else: socket
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">URL Anatomy Explorer</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Enter any URL to see it broken down into its component parts.
      </p>

      <div>
        <input
          type="text"
          value={@url}
          phx-change="update_url"
          phx-target={@myself}
          name="url"
          phx-debounce="300"
          class="w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 font-mono text-sm"
          placeholder="https://example.com/path?key=value#fragment"
        />
      </div>

      <%= if @parsed do %>
        <!-- Color-coded URL -->
        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
          <span class="text-pink-400">{@parsed.scheme}</span><span class="text-gray-500">://</span><span class="text-yellow-300">{@parsed.host}</span><%= if @parsed.port do %><span class="text-gray-500">:</span><span class="text-orange-400">{@parsed.port}</span><% end %><span class="text-green-400">{@parsed.path}</span><%= if @parsed.query != "" do %><span class="text-gray-500">?</span><span class="text-cyan-400">{@parsed.query}</span><% end %><%= if @parsed.fragment do %><span class="text-gray-500">#</span><span class="text-purple-400">{@parsed.fragment}</span><% end %>
        </div>

        <!-- Parts breakdown -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="p-4 rounded-lg border border-pink-200 dark:border-pink-800 bg-pink-50 dark:bg-pink-900/20">
            <h4 class="font-semibold text-pink-700 dark:text-pink-400 mb-1">Scheme</h4>
            <code class="text-sm font-mono">{@parsed.scheme}</code>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Protocol (http or https)</p>
          </div>

          <div class="p-4 rounded-lg border border-yellow-200 dark:border-yellow-800 bg-yellow-50 dark:bg-yellow-900/20">
            <h4 class="font-semibold text-yellow-700 dark:text-yellow-400 mb-1">Host</h4>
            <code class="text-sm font-mono">{@parsed.host}</code>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Server domain name</p>
          </div>

          <%= if @parsed.port do %>
            <div class="p-4 rounded-lg border border-orange-200 dark:border-orange-800 bg-orange-50 dark:bg-orange-900/20">
              <h4 class="font-semibold text-orange-700 dark:text-orange-400 mb-1">Port</h4>
              <code class="text-sm font-mono">{@parsed.port}</code>
              <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Network port (default: 80 for HTTP, 443 for HTTPS)</p>
            </div>
          <% end %>

          <div class="p-4 rounded-lg border border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/20">
            <h4 class="font-semibold text-green-700 dark:text-green-400 mb-1">Path</h4>
            <code class="text-sm font-mono">{@parsed.path}</code>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Resource location on the server</p>
            <%= if @parsed.path_segments != [] do %>
              <div class="mt-2 flex flex-wrap gap-1">
                <%= for seg <- @parsed.path_segments do %>
                  <span class="px-2 py-0.5 bg-green-200 dark:bg-green-800 rounded text-xs font-mono">{seg}</span>
                <% end %>
              </div>
            <% end %>
          </div>

          <%= if @parsed.query != "" do %>
            <div class="p-4 rounded-lg border border-cyan-200 dark:border-cyan-800 bg-cyan-50 dark:bg-cyan-900/20">
              <h4 class="font-semibold text-cyan-700 dark:text-cyan-400 mb-1">Query String</h4>
              <code class="text-sm font-mono">{@parsed.query}</code>
              <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Key-value parameters</p>
              <div class="mt-2 space-y-1">
                <%= for {k, v} <- @parsed.query_params do %>
                  <div class="text-xs font-mono">
                    <span class="text-cyan-700 dark:text-cyan-400 font-semibold">{k}</span>
                    <span class="text-gray-500"> = </span>
                    <span class="text-gray-800 dark:text-gray-200">{v}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <%= if @parsed.fragment do %>
            <div class="p-4 rounded-lg border border-purple-200 dark:border-purple-800 bg-purple-50 dark:bg-purple-900/20">
              <h4 class="font-semibold text-purple-700 dark:text-purple-400 mb-1">Fragment</h4>
              <code class="text-sm font-mono">{@parsed.fragment}</code>
              <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Client-side anchor (never sent to server)</p>
            </div>
          <% end %>
        </div>

        <!-- Phoenix mapping -->
        <div class="mt-4 p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
          <h4 class="font-semibold text-amber-700 dark:text-amber-400 mb-2">In Phoenix (Plug.Conn)</h4>
          <pre class="text-sm font-mono text-gray-800 dark:text-gray-200 overflow-x-auto">{format_conn(@parsed)}</pre>
        </div>
      <% end %>

      <!-- Quick examples -->
      <div class="mt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Try These URLs</h3>
        <div class="flex flex-wrap gap-2">
          <%= for example <- example_urls() do %>
            <button
              phx-click="try_url"
              phx-target={@myself}
              phx-value-url={example}
              class="px-3 py-1.5 text-xs font-mono bg-gray-100 dark:bg-gray-700 hover:bg-amber-100 dark:hover:bg-amber-900/30 rounded-lg border border-gray-200 dark:border-gray-600 transition-colors cursor-pointer truncate max-w-xs"
            >
              {example}
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update_url", %{"url" => url}, socket) do
    socket = socket |> assign(:url, url) |> parse_url()
    {:noreply, socket}
  end

  def handle_event("try_url", %{"url" => url}, socket) do
    socket = socket |> assign(:url, url) |> parse_url()
    {:noreply, socket}
  end

  defp parse_url(socket) do
    url = socket.assigns.url

    try do
      uri = URI.parse(url)

      path = uri.path || "/"
      segments = path |> String.split("/", trim: true)

      query = uri.query || ""
      query_params =
        if query != "" do
          URI.decode_query(query) |> Enum.to_list()
        else
          []
        end

      port =
        case uri.port do
          80 when uri.scheme == "http" -> nil
          443 when uri.scheme == "https" -> nil
          p -> p
        end

      assign(socket, :parsed, %{
        scheme: uri.scheme || "https",
        host: uri.host || "example.com",
        port: port,
        path: path,
        path_segments: segments,
        query: query,
        query_params: query_params,
        fragment: uri.fragment
      })
    rescue
      _ -> assign(socket, :parsed, nil)
    end
  end

  defp format_conn(parsed) do
    port_line = if parsed.port, do: "\n  port: #{parsed.port},", else: ""

    "%Plug.Conn{\n" <>
      "  scheme: :#{parsed.scheme},\n" <>
      "  host: \"#{parsed.host}\"," <>
      port_line <> "\n" <>
      "  request_path: \"#{parsed.path}\",\n" <>
      "  path_info: #{inspect(parsed.path_segments)},\n" <>
      "  query_string: \"#{parsed.query}\",\n" <>
      "  params: #{inspect(Map.new(parsed.query_params))}\n" <>
      "}"
  end

  defp example_urls do
    [
      "https://example.com/",
      "http://localhost:4000/users/42",
      "https://api.github.com/repos/elixir-lang/elixir/issues?state=open&per_page=5",
      "https://shop.example.com/products?category=books&sort=price&order=asc#results",
      "https://en.wikipedia.org/wiki/Elixir_(programming_language)"
    ]
  end
end
