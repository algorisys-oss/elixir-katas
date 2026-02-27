defmodule ElixirKatasWeb.PhoenixKata09PlugBasicsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Plug: The Specification for Composable HTTP Middleware

    # Every plug takes a conn and returns a conn:
    conn
    |> put_status(200)
    |> put_resp_header("content-type", "text/html")
    |> assign(:user, user)
    |> send_resp(200, "<h1>Hello</h1>")

    # === FUNCTION PLUG ===
    # Any function that takes (conn, opts) and returns conn
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      plug :require_auth
      plug :load_product when action in [:show, :edit]

      def show(conn, _params) do
        render(conn, :show)
      end

      defp require_auth(conn, _opts) do
        if conn.assigns[:current_user] do
          conn
        else
          conn
          |> put_status(401)
          |> put_view(ErrorHTML)
          |> render(:"401")
          |> halt()  # STOP the pipeline
        end
      end

      defp load_product(conn, _opts) do
        product = Products.get!(conn.params["id"])
        assign(conn, :product, product)
      end
    end

    # === MODULE PLUG ===
    # Implements init/1 (compile-time) and call/2 (per-request)
    defmodule MyAppWeb.Plugs.RequestLogger do
      @behaviour Plug
      import Plug.Conn
      require Logger

      def init(opts) do                            # Called ONCE at compile time
        Keyword.get(opts, :log_level, :info)
      end

      def call(conn, log_level) do                 # Called for EVERY request
        start = System.monotonic_time()

        register_before_send(conn, fn conn ->
          duration = System.monotonic_time() - start
          ms = System.convert_time_unit(duration, :native, :millisecond)
          Logger.log(log_level, "\#{conn.method} \#{conn.request_path} -> \#{conn.status} (\#{ms}ms)")
          conn
        end)
      end
    end

    # Usage: plug MyAppWeb.Plugs.RequestLogger, log_level: :debug

    # Phoenix is just plugs all the way down:
    # Phoenix.Endpoint → Plug.Static → Plug.RequestId → Plug.Parsers
    # → Plug.Session → Phoenix.Router → Pipeline plugs → YOUR CODE!
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "conn",
       pipeline_step: 0,
       pipeline_halted: false,
       conn_state: initial_conn_state(),
       plug_type: "function"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Plug Basics</h2>
      <p class="text-gray-600 dark:text-gray-300">
        The specification for composable modules between Cowboy and Phoenix. Every request passes through a chain of plugs.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["conn", "pipeline", "types", "helpers"]}
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

      <!-- Plug.Conn explorer -->
      <%= if @active_tab == "conn" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>%Plug.Conn{}</code> is the central data structure — it holds everything about the request and response.
          </p>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- Request fields -->
            <div class="p-4 rounded-lg border border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20">
              <h4 class="font-semibold text-blue-700 dark:text-blue-300 mb-3">Request Fields (read these)</h4>
              <pre class="font-mono text-sm text-blue-800 dark:text-blue-200 whitespace-pre">{conn_request_fields()}</pre>
            </div>

            <!-- Response & state fields -->
            <div class="space-y-4">
              <div class="p-4 rounded-lg border border-pink-200 dark:border-pink-800 bg-pink-50 dark:bg-pink-900/20">
                <h4 class="font-semibold text-pink-700 dark:text-pink-300 mb-3">Response Fields (write these)</h4>
                <pre class="font-mono text-sm text-pink-800 dark:text-pink-200 whitespace-pre">{conn_response_fields()}</pre>
              </div>

              <div class="p-4 rounded-lg border border-purple-200 dark:border-purple-800 bg-purple-50 dark:bg-purple-900/20">
                <h4 class="font-semibold text-purple-700 dark:text-purple-300 mb-3">State Tracking</h4>
                <pre class="font-mono text-sm text-purple-800 dark:text-purple-200 whitespace-pre">{conn_state_fields()}</pre>
              </div>
            </div>
          </div>

          <!-- Key principle -->
          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Immutable Transformation</p>
            <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">
              Conn is a struct — every function returns a <strong>new</strong> conn. That's why Phoenix uses the pipe operator:
            </p>
            <pre class="font-mono text-xs text-amber-800 dark:text-amber-200 whitespace-pre">{pipe_example()}</pre>
          </div>
        </div>
      <% end %>

      <!-- Pipeline simulator -->
      <%= if @active_tab == "pipeline" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Step through a plug pipeline to see how each plug transforms the conn. Watch what happens when a plug halts.
          </p>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Pipeline steps -->
            <div class="space-y-2">
              <.pipeline_step
                :for={{plug, idx} <- Enum.with_index(pipeline_plugs())}
                plug={plug}
                idx={idx}
                current_step={@pipeline_step}
                halted={@pipeline_halted}
              />
            </div>

            <!-- Conn state -->
            <div class="p-4 rounded-lg bg-gray-900 font-mono text-sm overflow-x-auto">
              <p class="text-gray-500 mb-2"># conn after step {@pipeline_step}</p>
              <pre class="text-green-400 whitespace-pre">{format_conn_state(@conn_state)}</pre>
            </div>
          </div>

          <!-- Controls -->
          <div class="flex items-center gap-3">
            <button phx-click="pipeline_next" phx-target={@myself}
              disabled={@pipeline_step >= length(pipeline_plugs()) || @pipeline_halted}
              class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
                if(@pipeline_step >= length(pipeline_plugs()) || @pipeline_halted,
                  do: "bg-gray-200 text-gray-400 cursor-not-allowed",
                  else: "bg-teal-600 hover:bg-teal-700 text-white")]}>
              Next Plug
            </button>
            <button phx-click="pipeline_reset" phx-target={@myself}
              class="px-4 py-2 rounded-lg font-medium bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 transition-colors cursor-pointer">
              Reset
            </button>
            <span class="text-sm text-gray-500">
              <%= if @pipeline_halted do %>
                <span class="text-red-500 font-semibold">Pipeline HALTED — remaining plugs skipped</span>
              <% else %>
                Step {@pipeline_step} of {length(pipeline_plugs())}
              <% end %>
            </span>
          </div>
        </div>
      <% end %>

      <!-- Plug types -->
      <%= if @active_tab == "types" do %>
        <div class="space-y-4">
          <div class="flex gap-2 mb-4">
            <button phx-click="set_plug_type" phx-target={@myself} phx-value-type="function"
              class={["px-4 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors",
                if(@plug_type == "function", do: "bg-teal-600 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300")]}>
              Function Plug
            </button>
            <button phx-click="set_plug_type" phx-target={@myself} phx-value-type="module"
              class={["px-4 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors",
                if(@plug_type == "module", do: "bg-teal-600 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300")]}>
              Module Plug
            </button>
          </div>

          <%= if @plug_type == "function" do %>
            <div class="space-y-3">
              <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                <p class="text-sm text-gray-600 dark:text-gray-300 mb-3">
                  A function plug is any function that takes <code>(conn, opts)</code> and returns a <code>conn</code>.
                  Used inside controllers with <code>plug :function_name</code>.
                </p>
                <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{function_plug_code()}</div>
              </div>
            </div>
          <% else %>
            <div class="space-y-3">
              <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                <p class="text-sm text-gray-600 dark:text-gray-300 mb-3">
                  A module plug implements <code>init/1</code> (compile-time setup) and <code>call/2</code> (per-request).
                  Used across the app in routers and endpoints.
                </p>
                <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{module_plug_code()}</div>
              </div>

              <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
                <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">init/1 vs call/2</p>
                <p class="text-sm text-gray-600 dark:text-gray-300">
                  <code>init/1</code> runs <strong>once</strong> at compile time — do expensive setup here.
                  <code>call/2</code> runs for <strong>every request</strong> — keep it fast. The result of <code>init/1</code> is passed as the second argument to <code>call/2</code>.
                </p>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Helpers reference -->
      <%= if @active_tab == "helpers" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Common <code>Plug.Conn</code> functions used in controllers and plugs.
          </p>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-200 dark:border-gray-700">
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Function</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Purpose</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Example</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={helper <- conn_helpers()} class="border-b border-gray-100 dark:border-gray-800">
                  <td class="py-2 px-3 font-mono text-teal-600 dark:text-teal-400 text-xs">{helper.name}</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">{helper.purpose}</td>
                  <td class="py-2 px-3 font-mono text-xs text-gray-500">{helper.example}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Phoenix's plug stack -->
          <div class="mt-6">
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-3">Phoenix's Internal Plug Stack</h4>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{phoenix_plug_stack()}</div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :plug, :map, required: true
  attr :idx, :integer, required: true
  attr :current_step, :integer, required: true
  attr :halted, :boolean, required: true

  defp pipeline_step(assigns) do
    ~H"""
    <div class={["flex items-start gap-3 p-3 rounded-lg border transition-all",
      cond do
        @halted && @idx >= @current_step -> "border-red-200 dark:border-red-800 bg-red-50/50 dark:bg-red-900/10 opacity-40"
        @idx < @current_step -> "border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/20"
        @idx == @current_step -> "border-teal-300 dark:border-teal-700 bg-teal-50 dark:bg-teal-900/20 ring-2 ring-teal-400"
        true -> "border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 opacity-50"
      end]}>
      <span class={["w-6 h-6 rounded-full flex items-center justify-center text-xs text-white flex-shrink-0",
        cond do
          @halted && @idx >= @current_step -> "bg-red-400"
          @idx < @current_step -> "bg-green-500"
          @idx == @current_step -> "bg-teal-500"
          true -> "bg-gray-400"
        end]}>
        <%= if @idx < @current_step do %>✓<% else %>{@idx + 1}<% end %>
      </span>
      <div>
        <p class="font-mono text-sm font-semibold text-gray-800 dark:text-gray-200">{@plug.name}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{@plug.description}</p>
      </div>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("set_plug_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, plug_type: type)}
  end

  def handle_event("pipeline_next", _, socket) do
    step = socket.assigns.pipeline_step
    plugs = pipeline_plugs()

    if step < length(plugs) do
      plug = Enum.at(plugs, step)
      {conn_state, halted} = apply_plug_step(socket.assigns.conn_state, plug)
      {:noreply, assign(socket, pipeline_step: step + 1, conn_state: conn_state, pipeline_halted: halted)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("pipeline_reset", _, socket) do
    {:noreply,
     assign(socket,
       pipeline_step: 0,
       pipeline_halted: false,
       conn_state: initial_conn_state()
     )}
  end

  defp tab_label("conn"), do: "Plug.Conn"
  defp tab_label("pipeline"), do: "Pipeline Simulator"
  defp tab_label("types"), do: "Plug Types"
  defp tab_label("helpers"), do: "Helpers"

  defp initial_conn_state do
    %{
      method: "GET",
      path: "/dashboard",
      status: nil,
      state: ":unset",
      halted: false,
      assigns: %{},
      session: %{},
      resp_headers: ["content-type: text/html"]
    }
  end

  defp pipeline_plugs do
    [
      %{name: "plug :fetch_session", description: "Load session data from encrypted cookie", key: :fetch_session},
      %{name: "plug :fetch_flash", description: "Load flash messages", key: :fetch_flash},
      %{name: "plug :protect_from_forgery", description: "Verify CSRF token", key: :csrf},
      %{name: "plug :require_auth", description: "Check if user is logged in (HALTS if not!)", key: :require_auth},
      %{name: "plug :load_user", description: "Fetch user from database", key: :load_user},
      %{name: "Controller.index/2", description: "Your action — renders the response", key: :action}
    ]
  end

  defp apply_plug_step(conn, %{key: :fetch_session}) do
    conn = %{conn | session: %{"user_id" => "42"}}
    {conn, false}
  end

  defp apply_plug_step(conn, %{key: :fetch_flash}) do
    conn = %{conn | assigns: Map.put(conn.assigns, :flash, %{})}
    {conn, false}
  end

  defp apply_plug_step(conn, %{key: :csrf}) do
    conn = %{conn | resp_headers: conn.resp_headers ++ ["x-csrf-token: abc..."]}
    {conn, false}
  end

  defp apply_plug_step(conn, %{key: :require_auth}) do
    # Simulate: user IS logged in, so pipeline continues
    # Change session to empty to demo halting
    if conn.session["user_id"] do
      {conn, false}
    else
      conn = %{conn | status: 401, state: ":sent", halted: true}
      {conn, true}
    end
  end

  defp apply_plug_step(conn, %{key: :load_user}) do
    conn = %{conn | assigns: Map.put(conn.assigns, :current_user, "Alice (id: 42)")}
    {conn, false}
  end

  defp apply_plug_step(conn, %{key: :action}) do
    conn = %{conn | status: 200, state: ":sent", resp_headers: conn.resp_headers ++ ["content-length: 1234"]}
    conn = %{conn | assigns: Map.put(conn.assigns, :page_title, "Dashboard")}
    {conn, false}
  end

  defp format_conn_state(conn) do
    assigns_str =
      conn.assigns
      |> Enum.map(fn {k, v} -> "    #{k}: #{inspect(v)}" end)
      |> Enum.join(",\n")

    session_str =
      conn.session
      |> Enum.map(fn {k, v} -> "    \"#{k}\" => \"#{v}\"" end)
      |> Enum.join(",\n")

    headers_str =
      conn.resp_headers
      |> Enum.map(fn h -> "    \"#{h}\"" end)
      |> Enum.join(",\n")

    "%Plug.Conn{\n  method: \"#{conn.method}\",\n  request_path: \"#{conn.path}\",\n  status: #{inspect(conn.status)},\n  state: #{conn.state},\n  halted: #{conn.halted},\n  assigns: %{\n#{assigns_str}\n  },\n  session: %{\n#{session_str}\n  },\n  resp_headers: [\n#{headers_str}\n  ]\n}"
  end

  defp conn_request_fields do
    """
    method:       "GET"
    request_path: "/products"
    query_string: "page=2"
    host:         "localhost"
    port:         4000
    params:       %{"page" => "2"}
    req_headers:  [{"accept", "text/html"}, ...]
    remote_ip:    {127, 0, 0, 1}\
    """
    |> String.trim()
  end

  defp conn_response_fields do
    """
    status:       nil → 200
    resp_headers: [{"content-type", ...}]
    resp_body:    nil → "<h1>Hello</h1>"\
    """
    |> String.trim()
  end

  defp conn_state_fields do
    """
    state:   :unset → :set → :sent
    halted:  false
    assigns: %{current_user: ...}\
    """
    |> String.trim()
  end

  defp pipe_example do
    "conn\n|> put_status(200)\n|> put_resp_header(\"content-type\", \"text/html\")\n|> assign(:user, user)\n|> send_resp(200, \"<h1>Hello</h1>\")"
  end

  defp function_plug_code do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      # Register function plugs
      plug :require_auth
      plug :load_product when action in [:show, :edit]

      def show(conn, _params) do
        # conn.assigns.product is already loaded!
        render(conn, :show)
      end

      # Function plug: (conn, opts) -> conn
      defp require_auth(conn, _opts) do
        if conn.assigns[:current_user] do
          conn  # Continue
        else
          conn
          |> put_status(401)
          |> put_view(ErrorHTML)
          |> render(:"401")
          |> halt()  # STOP pipeline
        end
      end

      defp load_product(conn, _opts) do
        product = Products.get!(conn.params["id"])
        assign(conn, :product, product)
      end
    end\
    """
    |> String.trim()
  end

  defp module_plug_code do
    """
    defmodule MyAppWeb.Plugs.RequestLogger do
      @behaviour Plug
      import Plug.Conn
      require Logger

      # Called ONCE at compile time
      def init(opts) do
        Keyword.get(opts, :log_level, :info)
      end

      # Called for EVERY request
      def call(conn, log_level) do
        start = System.monotonic_time()

        register_before_send(conn, fn conn ->
          duration = System.monotonic_time() - start
          ms = System.convert_time_unit(duration, :native, :millisecond)
          Logger.log(log_level, "\#{conn.method} \#{conn.request_path} → \#{conn.status} (\#{ms}ms)")
          conn
        end)
      end
    end

    # Usage in router:
    plug MyAppWeb.Plugs.RequestLogger, log_level: :debug\
    """
    |> String.trim()
  end

  defp conn_helpers do
    [
      %{name: "assign/3", purpose: "Store data in assigns", example: "assign(conn, :user, user)"},
      %{name: "put_status/2", purpose: "Set response status code", example: "put_status(conn, 200)"},
      %{name: "put_resp_header/3", purpose: "Add a response header", example: "put_resp_header(conn, \"x-key\", \"val\")"},
      %{name: "send_resp/3", purpose: "Send the response", example: "send_resp(conn, 200, \"OK\")"},
      %{name: "halt/1", purpose: "Stop the plug pipeline", example: "halt(conn)"},
      %{name: "get_session/2", purpose: "Read session data", example: "get_session(conn, :user_id)"},
      %{name: "put_session/3", purpose: "Write session data", example: "put_session(conn, :user_id, 42)"},
      %{name: "fetch_cookies/1", purpose: "Load cookies from request", example: "fetch_cookies(conn)"},
      %{name: "put_resp_cookie/3", purpose: "Set a cookie in response", example: "put_resp_cookie(conn, \"theme\", \"dark\")"},
      %{name: "get_req_header/2", purpose: "Read a request header", example: "get_req_header(conn, \"accept\")"}
    ]
  end

  defp phoenix_plug_stack do
    """
    # Phoenix is just plugs all the way down:

    Phoenix.Endpoint            # Module plug (entry point)
    ├── Plug.Static             # Serves static files
    ├── Plug.RequestId          # Adds X-Request-Id header
    ├── Plug.Telemetry          # Emits timing events
    ├── Plug.Parsers            # Parses request body
    ├── Plug.MethodOverride     # Supports _method param
    ├── Plug.Head               # Converts HEAD to GET
    ├── Plug.Session            # Loads session from cookie
    └── Phoenix.Router          # Routes to controller
         ├── Pipeline plugs     # :browser or :api pipeline
         ├── Controller plugs   # Your controller plugs
         └── Controller.action  # YOUR CODE!\
    """
    |> String.trim()
  end
end
