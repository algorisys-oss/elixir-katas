defmodule ElixirKatasWeb.PhoenixKata32PlugConnDeepDiveLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Plug.Conn — the connection struct and its key functions

    import Plug.Conn

    # --- Reading request data ---
    conn.method           # "GET", "POST", etc.
    conn.request_path     # "/users/1"
    conn.query_string     # "page=2&sort=name"
    conn.params           # %{"id" => "1", "page" => "2"}
    conn.host             # "example.com"
    conn.port             # 443
    conn.scheme           # :https
    conn.remote_ip        # {1, 2, 3, 4}
    conn.req_headers      # [{"accept", "html"}, ...]
    get_req_header(conn, "authorization")  # list

    # --- Assigns (app data, visible in templates) ---
    assign(conn, :current_user, user)
    conn.assigns.current_user
    conn.assigns[:key]    # nil if missing

    # --- Private (framework data, NOT in templates) ---
    put_private(conn, :my_lib, %{version: "2.0"})
    conn.private.phoenix_action

    # --- Response headers ---
    put_resp_header(conn, "x-request-id", "abc123")
    delete_resp_header(conn, "x-old")
    put_resp_content_type(conn, "application/json")

    # --- Sending responses ---
    send_resp(conn, 200, "body")
    put_status(conn, :created)     # 201

    # --- Halting the pipeline ---
    # halt/1 sets conn.halted = true — no further plugs run
    def require_auth(conn, _opts) do
      if conn.assigns[:current_user] do
        conn
      else
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
      end
    end

    # --- Session ---
    get_session(conn, :user_id)
    put_session(conn, :user_id, 42)
    delete_session(conn, :user_id)
    clear_session(conn)

    # --- Hooks ---
    register_before_send(conn, fn conn ->
      # runs before bytes are written
      conn
    end)
    """
    |> String.trim()
  end

  @conn_fields [
    %{name: "method", type: "string", example: "\"GET\"", desc: "HTTP method"},
    %{name: "host", type: "string", example: "\"example.com\"", desc: "Request host"},
    %{name: "port", type: "integer", example: "443", desc: "Request port"},
    %{name: "scheme", type: "atom", example: ":https", desc: "Protocol scheme"},
    %{name: "request_path", type: "string", example: "\"/users/1\"", desc: "URL path"},
    %{name: "query_string", type: "string", example: "\"page=2\"", desc: "Query string"},
    %{name: "params", type: "map", example: "%{\"id\" => \"1\"}", desc: "Merged params"},
    %{name: "req_headers", type: "list", example: "[{\"accept\", \"html\"}]", desc: "Request headers"},
    %{name: "resp_headers", type: "list", example: "[{\"content-type\", \"html\"}]", desc: "Response headers"},
    %{name: "status", type: "integer | nil", example: "200", desc: "HTTP response status"},
    %{name: "assigns", type: "map", example: "%{current_user: user}", desc: "Request-scoped data"},
    %{name: "private", type: "map", example: "%{phoenix_action: :show}", desc: "Framework-internal data"},
    %{name: "halted", type: "boolean", example: "false", desc: "Whether pipeline is halted"},
    %{name: "state", type: "atom", example: ":unset", desc: "Response state"},
    %{name: "remote_ip", type: "tuple", example: "{127, 0, 0, 1}", desc: "Client IP address"}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "fields",
       selected_field: 0,
       selected_topic: "assigns"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Plug.Conn Deep Dive</h2>
      <p class="text-gray-600 dark:text-gray-300">
        The connection struct: assigns, private, halting, response headers, and the full request/response lifecycle.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["fields", "assigns", "headers", "halting", "code"]}
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

      <!-- Fields explorer -->
      <%= if @active_tab == "fields" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Click any field to see its type, example, and how to use it.
          </p>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- Field list -->
            <div class="space-y-1 overflow-y-auto max-h-96">
              <%= for {field, idx} <- Enum.with_index(conn_fields()) do %>
                <button
                  phx-click="select_field"
                  phx-target={@myself}
                  phx-value-idx={to_string(idx)}
                  class={["flex items-center gap-3 w-full p-2 rounded-lg border text-left transition-all cursor-pointer text-xs",
                    if(@selected_field == idx,
                      do: "border-teal-400 bg-teal-50 dark:bg-teal-900/20 ring-1 ring-teal-300",
                      else: "border-gray-200 dark:border-gray-700 hover:border-gray-300")]}
                >
                  <span class="font-mono font-semibold text-teal-600 dark:text-teal-400 w-28 flex-shrink-0">{field.name}</span>
                  <span class="text-purple-600 dark:text-purple-400 w-20 flex-shrink-0">{field.type}</span>
                  <span class="text-gray-500 truncate">{field.desc}</span>
                </button>
              <% end %>
            </div>

            <!-- Field detail -->
            <% field = Enum.at(conn_fields(), @selected_field) %>
            <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 space-y-3">
              <div>
                <span class="font-mono font-bold text-lg text-teal-600 dark:text-teal-400">conn.{field.name}</span>
                <span class="ml-2 text-sm text-purple-600 dark:text-purple-400">{field.type}</span>
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-300">{field.desc}</p>
              <div>
                <p class="text-xs text-gray-500 mb-1">Example value:</p>
                <div class="bg-gray-900 rounded p-2 font-mono text-xs text-green-400">{field.example}</div>
              </div>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{field_usage_code(field.name)}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Assigns vs Private -->
      <%= if @active_tab == "assigns" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["assigns", "private", "difference"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {String.capitalize(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{assigns_code(@selected_topic)}</div>
        </div>
      <% end %>

      <!-- Response headers -->
      <%= if @active_tab == "headers" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Reading request headers and setting response headers.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Reading Request Headers</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{req_headers_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Setting Response Headers</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{resp_headers_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Security Headers</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{security_headers_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Content-Type</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{content_type_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Halting -->
      <%= if @active_tab == "halting" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Halting the pipeline stops all further plugs from running. Essential for auth, redirects, and error responses.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{halting_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <p class="text-sm font-semibold text-red-700 dark:text-red-300 mb-2">Redirect + Halt</p>
              <div class="bg-gray-900 rounded p-2 font-mono text-xs text-green-400 whitespace-pre">{redirect_halt_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Send Response + Halt</p>
              <div class="bg-gray-900 rounded p-2 font-mono text-xs text-green-400 whitespace-pre">{send_resp_halt_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Conn State</p>
              <div class="bg-gray-900 rounded p-2 font-mono text-xs text-green-400 whitespace-pre">{conn_state_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Plug.Conn Cheat Sheet</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab, selected_field: 0)}
  end

  def handle_event("select_field", %{"idx" => idx}, socket) do
    {:noreply, assign(socket, selected_field: String.to_integer(idx))}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("fields"), do: "Conn Fields"
  defp tab_label("assigns"), do: "Assigns vs Private"
  defp tab_label("headers"), do: "Headers"
  defp tab_label("halting"), do: "Halting"
  defp tab_label("code"), do: "Source Code"

  defp conn_fields, do: @conn_fields

  defp field_usage_code("method") do
    """
    # Read the HTTP method:
    conn.method  # => "GET", "POST", "PUT", etc.

    # Pattern match:
    case conn.method do
      "GET"  -> handle_get(conn)
      "POST" -> handle_post(conn)
    end\
    """
    |> String.trim()
  end

  defp field_usage_code("assigns") do
    """
    # Read assigns:
    conn.assigns.current_user
    conn.assigns[:current_user]  # nil if missing

    # Set assigns:
    Plug.Conn.assign(conn, :locale, "en")

    # In templates: @current_user, @locale\
    """
    |> String.trim()
  end

  defp field_usage_code("private") do
    """
    # Read private:
    conn.private[:phoenix_action]
    conn.private.phoenix_controller

    # Set private (use for library/framework data):
    Plug.Conn.put_private(conn, :my_lib_data, value)\
    """
    |> String.trim()
  end

  defp field_usage_code("halted") do
    """
    # Check if halted:
    conn.halted  # => false (normally)

    # Halt the pipeline:
    Plug.Conn.halt(conn)
    # conn.halted => true
    # No more plugs will run!\
    """
    |> String.trim()
  end

  defp field_usage_code("status") do
    """
    # Status is nil before response is sent
    conn.status  # => nil

    # After send_resp or render:
    conn.status  # => 200, 404, 301, etc.

    # Set status manually:
    Plug.Conn.put_status(conn, 201)\
    """
    |> String.trim()
  end

  defp field_usage_code("req_headers") do
    """
    # req_headers is a list of {name, value} tuples
    # Header names are lowercased:
    conn.req_headers
    # => [{"accept", "text/html"}, {"host", "example.com"}]

    # Get a specific header:
    Plug.Conn.get_req_header(conn, "authorization")
    # => ["Bearer token123"] or []\
    """
    |> String.trim()
  end

  defp field_usage_code("resp_headers") do
    """
    # resp_headers are set by put_resp_header/3:
    conn = Plug.Conn.put_resp_header(conn,
      "x-request-id", "abc123")

    # Delete a header:
    conn = Plug.Conn.delete_resp_header(conn, "x-old-header")

    # Read (list of {name, value}):
    conn.resp_headers\
    """
    |> String.trim()
  end

  defp field_usage_code("params") do
    """
    # params combines path params, query params, body params:
    conn.params
    # => %{"id" => "1", "page" => "2", "q" => "search"}

    # Path: /users/:id => params["id"]
    # Query: ?page=2  => params["page"]
    # Body (form/JSON): params["name"]\
    """
    |> String.trim()
  end

  defp field_usage_code("remote_ip") do
    """
    # Remote IP as a tuple:
    conn.remote_ip
    # => {127, 0, 0, 1}  (localhost)
    # => {93, 184, 216, 34}  (example.com)

    # Convert to string:
    :inet.ntoa(conn.remote_ip) |> to_string()
    # => "127.0.0.1"\
    """
    |> String.trim()
  end

  defp field_usage_code("state") do
    """
    # Response state lifecycle:
    # :unset     — no response set yet
    # :set       — put_resp/send_resp called
    # :chunked   — chunked transfer encoding
    # :sent      — response fully sent
    # :upgraded  — upgraded to WebSocket/etc.

    conn.state  # => :unset (before controller)\
    """
    |> String.trim()
  end

  defp field_usage_code(_) do
    """
    # Access this field:
    conn.field_name

    # Use Plug.Conn functions to modify:
    # (direct struct modification is discouraged)\
    """
    |> String.trim()
  end

  defp assigns_code("assigns") do
    """
    # conn.assigns — application data for this request
    # Visible in templates and controllers

    import Plug.Conn

    # Setting assigns:
    conn = assign(conn, :current_user, user)
    conn = assign(conn, :locale, "en")

    # Reading assigns:
    user = conn.assigns.current_user
    locale = conn.assigns[:locale]  # nil if not set

    # In templates (HEEx):
    # @current_user, @locale

    # merge_assigns/2 (Plug >= 1.14):
    conn = merge_assigns(conn, user: user, locale: "en")\
    """
    |> String.trim()
  end

  defp assigns_code("private") do
    """
    # conn.private — framework/library internal data
    # NOT intended for application code

    import Plug.Conn

    # Phoenix stores its state in private:
    conn.private.phoenix_action     # => :show
    conn.private.phoenix_controller # => MyAppWeb.UserController
    conn.private.phoenix_format     # => "html"
    conn.private.phoenix_view       # => MyAppWeb.UserHTML

    # Setting private data (use for library code only):
    conn = put_private(conn, :my_lib, %{version: "2.0"})

    # Reading back:
    conn.private[:my_lib]  # => %{version: "2.0"}\
    """
    |> String.trim()
  end

  defp assigns_code("difference") do
    """
    # KEY DIFFERENCE:
    # assigns — user/application data, available in templates
    # private — internal framework data, not for templates

    # CORRECT usage:
    assign(conn, :current_user, user)   # app data
    put_private(conn, :rate_limit, 42)  # lib data

    # Phoenix.Controller.render/3 passes assigns to template:
    # @current_user works in template because it's in assigns

    # You CANNOT use @private_key in templates
    # private is NOT exposed to HEEx templates\
    """
    |> String.trim()
  end

  defp req_headers_code do
    """
    import Plug.Conn

    # Get a specific header (always returns a list):
    get_req_header(conn, "authorization")
    # => ["Bearer token"] or []

    get_req_header(conn, "accept")
    # => ["text/html,application/xhtml+xml"]

    # First value or nil:
    conn
    |> get_req_header("x-forwarded-for")
    |> List.first()
    # => "1.2.3.4" or nil

    # All headers (lowercase names):
    conn.req_headers
    # => [{"host", "example.com"}, ...]\
    """
    |> String.trim()
  end

  defp resp_headers_code do
    """
    import Plug.Conn

    # Add a response header:
    conn = put_resp_header(conn, "x-request-id", "abc123")

    # Append (keeps existing values):
    conn = prepend_resp_headers(conn,
      [{"x-custom", "value"}])

    # Delete:
    conn = delete_resp_header(conn, "x-powered-by")

    # Merge headers map:
    conn = merge_resp_headers(conn, %{
      "cache-control" => "no-store",
      "x-frame-options" => "DENY"
    })\
    """
    |> String.trim()
  end

  defp security_headers_code do
    """
    # Phoenix sets these via :put_secure_browser_headers:
    "x-content-type-options"  => "nosniff"
    "x-download-options"      => "noopen"
    "x-frame-options"         => "SAMEORIGIN"
    "x-permitted-cross-domain-policies" => "none"
    "x-xss-protection"        => "1; mode=block"
    "cross-origin-window-policy" => "deny"

    # Custom content security policy:
    conn = put_resp_header(conn,
      "content-security-policy",
      "default-src 'self'; script-src 'self' 'nonce-\#{nonce}'")\
    """
    |> String.trim()
  end

  defp content_type_code do
    """
    import Plug.Conn

    # Set content type for response:
    conn = put_resp_content_type(conn, "application/json")
    conn = put_resp_content_type(conn, "text/plain")

    # Phoenix sets content type automatically based on format:
    # :html => "text/html; charset=utf-8"
    # :json => "application/json; charset=utf-8"

    # Read request content type:
    conn.req_headers
    |> List.keyfind("content-type", 0)
    # => {"content-type", "application/json"}\
    """
    |> String.trim()
  end

  defp halting_code do
    """
    import Plug.Conn

    # halt/1 sets conn.halted = true
    # No subsequent plugs in the pipeline will run

    def require_auth(conn, _opts) do
      if conn.assigns[:current_user] do
        conn  # continue pipeline
      else
        conn
        |> put_flash_message(:error, "Please log in")
        |> redirect_to_login()
        |> halt()   # <-- STOP HERE
      end
    end

    # IMPORTANT: halt/1 only stops the plug pipeline.
    # You must ALSO send a response (or redirect) before halting,
    # otherwise the connection will be left open!

    # Wrong (no response sent):
    conn |> halt()

    # Correct:
    conn |> send_resp(401, "Unauthorized") |> halt()
    conn |> redirect(to: "/login") |> halt()\
    """
    |> String.trim()
  end

  defp redirect_halt_code do
    """
    import Plug.Conn
    import Phoenix.Controller

    def require_login(conn, _) do
      if conn.assigns[:current_user] do
        conn
      else
        conn
        |> put_flash(:error, "Log in first")
        |> redirect(to: "/login")
        |> halt()
      end
    end\
    """
    |> String.trim()
  end

  defp send_resp_halt_code do
    """
    import Plug.Conn

    def check_api_key(conn, _) do
      case get_req_header(conn, "x-api-key") do
        [key] when key != "" ->
          conn  # valid

        _ ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(401,
               ~s({"error":"Invalid key"}))
          |> halt()
      end
    end\
    """
    |> String.trim()
  end

  defp conn_state_code do
    """
    # conn.state tracks response lifecycle:
    :unset    # initial state
    :set      # send_resp/put_resp called
    :chunked  # chunked transfer
    :sent     # response written to socket
    :upgraded # protocol upgrade (WebSocket)

    # Check before sending:
    if conn.state == :unset do
      send_resp(conn, 200, "OK")
    end

    # conn.halted vs conn.state:
    # halted  — plug pipeline stopped
    # state   — response has been sent\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Plug.Conn function reference

    import Plug.Conn

    # --- Reading request data ---
    conn.method           # "GET", "POST", etc.
    conn.request_path     # "/users/1"
    conn.query_string     # "page=2&sort=name"
    conn.params           # %{"id" => "1", "page" => "2"}
    conn.host             # "example.com"
    conn.port             # 443
    conn.scheme           # :https
    conn.remote_ip        # {1, 2, 3, 4}
    conn.req_headers      # [{"accept", "html"}, ...]
    get_req_header(conn, "authorization")  # list

    # --- Assigns ---
    assign(conn, :key, value)
    merge_assigns(conn, key: value)
    conn.assigns.key
    conn.assigns[:key]    # nil if missing

    # --- Private ---
    put_private(conn, :key, value)
    conn.private[:key]
    conn.private.phoenix_action

    # --- Response headers ---
    put_resp_header(conn, "x-id", "123")
    delete_resp_header(conn, "x-old")
    put_resp_content_type(conn, "application/json")
    get_resp_header(conn, "content-type")

    # --- Sending responses ---
    send_resp(conn, 200, "body")
    send_resp(conn, 404, "Not Found")
    put_status(conn, :created)     # 201

    # --- Session ---
    get_session(conn, :user_id)
    put_session(conn, :user_id, 42)
    delete_session(conn, :user_id)
    clear_session(conn)

    # --- Pipeline control ---
    halt(conn)               # stop pipeline
    conn.halted              # => true/false
    conn.state               # :unset/:set/:sent

    # --- Hooks ---
    register_before_send(conn, fn conn ->
      # runs before bytes are written
      conn
    end)\
    """
    |> String.trim()
  end
end
