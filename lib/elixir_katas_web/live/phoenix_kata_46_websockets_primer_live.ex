defmodule ElixirKatasWeb.PhoenixKata46WebsocketsPrimerLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # WebSockets Primer — Protocol & Phoenix Integration

    # --- The Upgrade Handshake (RFC 6455) ---
    # CLIENT REQUEST:
    # GET /socket/websocket HTTP/1.1
    # Host: example.com
    # Upgrade: websocket
    # Connection: Upgrade
    # Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    # Sec-WebSocket-Version: 13
    #
    # SERVER RESPONSE:
    # HTTP/1.1 101 Switching Protocols
    # Upgrade: websocket
    # Connection: Upgrade
    # Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    #
    # After this: pure WebSocket frames, no more HTTP.

    # --- Phoenix Endpoint socket configuration ---
    # For LiveView:
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    # For Channels:
    socket "/socket", MyAppWeb.UserSocket,
      websocket: true,
      longpoll: false

    # --- WebSocket frame structure ---
    # Byte 0: FIN bit + opcode (text=1, binary=2, ping=9, close=8)
    # Byte 1: MASK bit + payload length
    # Client->Server: MUST be masked
    # Server->Client: MUST NOT be masked

    # --- Phoenix channel message format ---
    # [join_ref, ref, topic, event, payload]
    # ["1", "1", "room:lobby", "phx_join", {}]
    # [null, "2", "room:lobby", "new_msg", {"body": "Hi!"}]

    # --- JavaScript client (phoenix.js) ---
    # import {Socket} from "phoenix"
    #
    # const socket = new Socket("/socket", {
    #   params: {token: window.userToken}
    # })
    # socket.connect()
    #
    # const channel = socket.channel("room:lobby", {})
    # channel.join()
    #   .receive("ok", resp => console.log("Joined!", resp))
    #   .receive("error", resp => console.log("Error", resp))
    #
    # channel.push("new_msg", {body: "Hello!"})
    # channel.on("new_msg", msg => console.log("Got:", msg))

    # --- Why WebSockets over HTTP? ---
    # HTTP: stateless, half-duplex, ~500 bytes overhead per request
    # WS:   stateful, full-duplex, ~2-14 bytes per frame
    # Each WS connection = one Elixir process (~2KB)
    # A single Phoenix server can handle 2M+ connections
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "why")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">WebSockets Primer</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Why WebSockets, the upgrade handshake, full-duplex vs HTTP — understanding the protocol that powers Phoenix Channels and LiveView.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "handshake", "protocol", "vshttp", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-sky-50 dark:bg-sky-900/30 text-sky-700 dark:text-sky-400 border-b-2 border-sky-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["why", "history", "usecases"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-sky-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">HTTP: Request-Response</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Client asks, server answers. Connection closes after each response.</p>
            </div>
            <div class="p-4 rounded-lg bg-sky-50 dark:bg-sky-900/20 border border-sky-200 dark:border-sky-800">
              <p class="text-sm font-semibold text-sky-700 dark:text-sky-300 mb-1">WebSocket: Persistent</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">One connection stays open. Either side can send data at any time.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Full-Duplex</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Server can push data without client asking — real-time!</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Handshake -->
      <%= if @active_tab == "handshake" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            WebSocket starts as an HTTP request and upgrades to a persistent TCP connection via the Upgrade handshake.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{handshake_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Handshake Steps</p>
              <ol class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>1. Client sends HTTP GET with Upgrade: websocket</li>
                <li>2. Includes Sec-WebSocket-Key (random base64)</li>
                <li>3. Server responds 101 Switching Protocols</li>
                <li>4. Server returns Sec-WebSocket-Accept (derived key)</li>
                <li>5. Connection is now a WebSocket — no more HTTP!</li>
              </ol>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">In Phoenix (Cowboy)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{phoenix_ws_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Protocol -->
      <%= if @active_tab == "protocol" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            After the handshake, data is sent as WebSocket frames — a lightweight binary protocol.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{protocol_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Frame Types</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>Text frame</strong>: UTF-8 encoded text (JSON)</li>
                <li><strong>Binary frame</strong>: arbitrary binary data</li>
                <li><strong>Ping/Pong</strong>: keepalive heartbeat</li>
                <li><strong>Close frame</strong>: graceful shutdown</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Phoenix on Top</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">
                Phoenix Channels add a higher-level protocol on top of WebSockets: topics, events, and payloads encoded as JSON arrays or Erlang binary.
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- vs HTTP -->
      <%= if @active_tab == "vshttp" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            When to use WebSockets vs HTTP — both have their place.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{comparison_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-sky-50 dark:bg-sky-900/20 border border-sky-200 dark:border-sky-800">
              <p class="text-sm font-semibold text-sky-700 dark:text-sky-300 mb-2">Use WebSockets for:</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>- Chat / messaging</li>
                <li>- Live dashboards / monitoring</li>
                <li>- Collaborative editing</li>
                <li>- Gaming</li>
                <li>- Notifications</li>
                <li>- LiveView (real-time UI updates)</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600">
              <p class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Stick with HTTP for:</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>- REST APIs</li>
                <li>- File uploads</li>
                <li>- Simple page navigation</li>
                <li>- Search engines / crawlers</li>
                <li>- Caching (HTTP has Cache-Control)</li>
                <li>- One-off requests with no ongoing state</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">WebSocket in Browser (JS) + Phoenix</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("overview"), do: "Overview"
  defp tab_label("handshake"), do: "Upgrade Handshake"
  defp tab_label("protocol"), do: "WS Protocol"
  defp tab_label("vshttp"), do: "WS vs HTTP"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("why"), do: "Why WebSockets?"
  defp topic_label("history"), do: "History"
  defp topic_label("usecases"), do: "Use Cases"

  defp overview_code("why") do
    """
    # The problem with HTTP for real-time:
    #
    # Option 1: Short Polling
    # - Client asks "anything new?" every N seconds
    # - Wastes server resources, high latency
    # setInterval(() => fetch('/messages'), 1000)
    #
    # Option 2: Long Polling
    # - Server holds request open until new data arrives
    # - Better, but complex and inefficient
    #
    # Option 3: Server-Sent Events (SSE)
    # - Server can push, but client CANNOT send
    # - One-directional only
    #
    # Option 4: WebSockets (RFC 6455, 2011)
    # - Single persistent connection
    # - BOTH sides can send at any time
    # - Low overhead (~2 bytes per frame header)
    # - Same firewall/proxy compatibility as HTTP\
    """
    |> String.trim()
  end

  defp overview_code("history") do
    """
    # Timeline:
    # 2009: WebSockets proposed
    # 2011: RFC 6455 standardized
    # 2012: Supported in all major browsers
    # 2015: Phoenix Channels built on WebSockets
    # 2018: Phoenix LiveView uses WebSockets for UI
    #
    # Before WebSockets, Comet techniques:
    # - AJAX polling
    # - Long polling
    # - Forever frames (IE hack)
    # - Flash sockets
    #
    # WebSockets replaced all of these by providing
    # a proper, standardized protocol.\
    """
    |> String.trim()
  end

  defp overview_code("usecases") do
    """
    # Real-world WebSocket use cases:
    #
    # 1. Chat applications (WhatsApp Web, Slack)
    # 2. Live sports scores / stock tickers
    # 3. Collaborative editors (Google Docs)
    # 4. Online gaming (multiplayer)
    # 5. DevOps dashboards (Grafana)
    # 6. Notifications (GitHub, Twitter)
    # 7. Phoenix LiveView (real-time DOM diffs)
    # 8. Phoenix Channels (pub/sub messaging)
    #
    # In Elixir/Phoenix:
    # - Each WebSocket connection = one Elixir process
    # - A single Phoenix server can handle 2M+ connections
    # - BEAM processes are cheap (~2KB each)
    # - No threads needed — actor model handles concurrency\
    """
    |> String.trim()
  end

  defp handshake_code do
    """
    # WebSocket Upgrade Handshake (RFC 6455):
    #
    # CLIENT REQUEST:
    GET /socket/websocket HTTP/1.1
    Host: example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Sec-WebSocket-Version: 13
    Sec-WebSocket-Protocol: phoenix
    Origin: http://example.com

    # SERVER RESPONSE:
    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: phoenix

    # After this: no more HTTP. Pure WebSocket frames.
    # The TCP connection remains open indefinitely.

    # Sec-WebSocket-Accept is computed as:
    # base64(sha1(key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))\
    """
    |> String.trim()
  end

  defp phoenix_ws_code do
    """
    # Phoenix Endpoint mounts a WebSocket at /live:
    # (for LiveView)
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    # And at /socket for Channels:
    socket "/socket", MyAppWeb.UserSocket,
      websocket: true,
      longpoll: false

    # Cowboy (the HTTP server) handles the upgrade:
    # HTTP/1.1 request arrives -> Cowboy sees Upgrade header
    # -> calls Phoenix socket handler
    # -> Phoenix initializes the socket process
    # -> Returns 101, connection is now WebSocket\
    """
    |> String.trim()
  end

  defp protocol_code do
    """
    # WebSocket frame structure:
    #
    # Byte 0: FIN bit + opcode (text=1, binary=2, ping=9, pong=10, close=8)
    # Byte 1: MASK bit + payload length
    # (2-8 more bytes for extended length if needed)
    # (4 bytes masking key if MASK=1)
    # Payload...
    #
    # Client->Server frames MUST be masked (MASK=1)
    # Server->Client frames MUST NOT be masked
    #
    # Phoenix encodes channel messages as JSON:
    # [join_ref, ref, topic, event, payload]
    # Example:
    # [null, "1", "room:lobby", "phx_join", {}]
    # [null, "2", "room:lobby", "new_msg", {"body": "Hi!"}]
    #
    # Or as Erlang binary (more efficient with :erlpack):
    # Binary encoded version of the same structure\
    """
    |> String.trim()
  end

  defp comparison_code do
    """
    # HTTP vs WebSocket comparison:
    #
    # HTTP:
    # - Stateless: each request is independent
    # - Half-duplex: client requests, server responds
    # - Headers on every request (~500 bytes overhead)
    # - Connection closes after response (HTTP/1.1 keep-alive helps)
    # - Easy to cache (Cache-Control, ETags)
    # - Works great for REST APIs, pages, files
    #
    # WebSocket:
    # - Stateful: persistent connection with state
    # - Full-duplex: both sides send independently
    # - Tiny frame overhead (~2-14 bytes)
    # - Connection stays open for the session lifetime
    # - No caching mechanism
    # - Works great for real-time, bidirectional communication
    #
    # HTTP/2 and HTTP/3 reduce many HTTP limitations,
    # but WebSockets still win for true bidirectional streaming.\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Browser JavaScript WebSocket API:
    const ws = new WebSocket("wss://example.com/socket/websocket");

    ws.onopen = () => {
      console.log("Connected!");
      // Join a Phoenix channel:
      const joinMsg = JSON.stringify(
        [null, "1", "room:lobby", "phx_join", {}]
      );
      ws.send(joinMsg);
    };

    ws.onmessage = (event) => {
      const [joinRef, ref, topic, eventName, payload] =
        JSON.parse(event.data);
      console.log("Event:", eventName, payload);
    };

    ws.onclose = (event) => {
      console.log("Disconnected:", event.code, event.reason);
      // Reconnect after delay...
    };

    ws.onerror = (error) => {
      console.error("WebSocket error:", error);
    };

    // Send a message:
    ws.send(JSON.stringify(
      [null, "2", "room:lobby", "new_msg", {body: "Hello!"}]
    ));

    // Close gracefully:
    ws.close(1000, "Normal closure");

    # Phoenix JavaScript client (phoenix.js) wraps this:
    import {Socket} from "phoenix"

    const socket = new Socket("/socket", {
      params: {token: window.userToken}
    })
    socket.connect()

    const channel = socket.channel("room:lobby", {})
    channel.join()
      .receive("ok", resp => console.log("Joined!", resp))
      .receive("error", resp => console.log("Error", resp))

    channel.push("new_msg", {body: "Hello!"})
    channel.on("new_msg", msg => console.log("Got:", msg))\
    """
    |> String.trim()
  end
end
