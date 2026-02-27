defmodule ElixirKatasWeb.PhoenixKata30FunctionPlugsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Function plug signature: def my_plug(conn, opts) -> conn

    defmodule MyAppWeb.Router do
      use MyAppWeb, :router
      import Plug.Conn

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :put_locale          # custom function plug
        plug :add_request_id      # custom function plug
      end

      # Function plug — reads locale from session
      defp put_locale(conn, _opts) do
        locale = get_session(conn, :locale) || "en"
        assign(conn, :locale, locale)
      end

      # Function plug — generates a request ID
      defp add_request_id(conn, _opts) do
        id = :crypto.strong_rand_bytes(8) |> Base.encode16()
        conn
        |> assign(:request_id, id)
        |> put_resp_header("x-request-id", id)
      end
    end

    # Controller-level function plugs with guards:
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      # Only runs for specific actions:
      plug :load_product when action in [:show, :edit, :update, :delete]
      plug :verify_owner when action in [:edit, :update, :delete]

      def show(conn, _params) do
        render(conn, :show, product: conn.assigns.product)
      end

      defp load_product(conn, _opts) do
        product = Catalog.get_product!(conn.params["id"])
        Plug.Conn.assign(conn, :product, product)
      end

      defp verify_owner(conn, _opts) do
        if conn.assigns.product.user_id == conn.assigns.current_user.id do
          conn
        else
          conn
          |> put_flash(:error, "Not authorized")
          |> redirect(to: ~p"/products")
          |> halt()
        end
      end
    end

    # Request timing with register_before_send:
    def log_request(conn, _opts) do
      start = System.monotonic_time(:millisecond)

      Plug.Conn.register_before_send(conn, fn conn ->
        duration = System.monotonic_time(:millisecond) - start
        Logger.info("\#{conn.method} \#{conn.request_path} => \#{conn.status} in \#{duration}ms")
        conn
      end)
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "inline")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Function Plugs</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Inline request transformations using plain functions: adding assigns, logging, and modifying the conn.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "assigns", "logging", "pipeline", "code"]}
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

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["inline", "named", "signature"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">What is a Function Plug?</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              A function plug is any function that takes a <code>%Plug.Conn{}</code> and options,
              and returns a <code>%Plug.Conn{}</code>. Used with <code>plug :function_name</code>
              in a router pipeline or controller.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Adding Assigns -->
      <%= if @active_tab == "assigns" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Function plugs commonly add data to <code>conn.assigns</code> for use in templates and controllers.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Simple Assign</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{simple_assign_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Multiple Assigns</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{multiple_assigns_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Conditional Assign</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{conditional_assign_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Using in Template</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{template_assign_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Logging -->
      <%= if @active_tab == "logging" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Function plugs are ideal for request logging, metrics, and debugging without touching controllers.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{logging_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Request Timing</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{timing_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Before/After Hook Pattern</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{before_after_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- In pipelines -->
      <%= if @active_tab == "pipeline" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Function plugs integrate into router pipelines and controller plugs using <code>plug :name</code>.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{pipeline_usage_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-purple-200 dark:border-purple-800 bg-purple-50 dark:bg-purple-900/20">
              <h4 class="font-semibold text-purple-700 dark:text-purple-300 mb-2">With Options</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{plug_with_opts_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-teal-200 dark:border-teal-800 bg-teal-50 dark:bg-teal-900/20">
              <h4 class="font-semibold text-teal-700 dark:text-teal-300 mb-2">Controller Plug</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{controller_plug_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Function vs Module Plug</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Use <strong>function plugs</strong> for simple, stateless transformations defined in the same module.
              Use <strong>module plugs</strong> when you need initialization logic (<code>init/1</code>), reuse across many modules, or complex state.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Function Plug Examples</h4>
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
  defp tab_label("assigns"), do: "Assigns"
  defp tab_label("logging"), do: "Logging"
  defp tab_label("pipeline"), do: "In Pipelines"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("inline"), do: "Inline Plug"
  defp topic_label("named"), do: "Named Function"
  defp topic_label("signature"), do: "Signature"

  defp overview_code("inline") do
    """
    # Simplest function plug — defined inline in router:
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :add_locale   # <-- our function plug
    end

    # The function lives in the same module
    # (or imported into it):
    def add_locale(conn, _opts) do
      locale = get_req_header(conn, "accept-language")
                |> List.first()
                |> parse_locale()
      assign(conn, :locale, locale || "en")
    end

    # Now @locale is available in every template!\
    """
    |> String.trim()
  end

  defp overview_code("named") do
    """
    # Named function plugs are defined with def/defp:
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :log_request      # function plug
        plug :add_request_id   # function plug
      end

      # These functions must be accessible in this scope:
      defp log_request(conn, _opts) do
        IO.puts("Request: \#{conn.method} \#{conn.request_path}")
        conn
      end

      defp add_request_id(conn, _opts) do
        id = :crypto.strong_rand_bytes(8) |> Base.encode16()
        Plug.Conn.assign(conn, :request_id, id)
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("signature") do
    """
    # A function plug MUST have this signature:
    def my_plug(conn, opts)

    # conn  — the %Plug.Conn{} struct
    # opts  — options passed via: plug :my_plug, opts
    # return — a (possibly modified) %Plug.Conn{}

    # Examples:
    def no_opts(conn, _opts), do: conn

    def with_opts(conn, opts) do
      level = Keyword.get(opts, :level, :info)
      Logger.log(level, "Path: \#{conn.request_path}")
      conn
    end

    # Used as:
    plug :no_opts
    plug :with_opts, level: :debug\
    """
    |> String.trim()
  end

  defp simple_assign_code do
    """
    # Assign a single value to conn:
    def put_locale(conn, _opts) do
      Plug.Conn.assign(conn, :locale, "en")
    end

    # In templates: @locale => "en"
    # In controllers:
    #   conn.assigns.locale => "en"\
    """
    |> String.trim()
  end

  defp multiple_assigns_code do
    """
    # Assign multiple values using Plug.Conn.merge_assigns/2:
    import Plug.Conn

    def put_app_context(conn, _opts) do
      conn
      |> assign(:app_name, "MyApp")
      |> assign(:app_version, "1.0.0")
      |> assign(:env, Mix.env())
    end

    # Or using merge_assigns (Plug >= 1.14):
    def put_app_context(conn, _opts) do
      merge_assigns(conn,
        app_name: "MyApp",
        app_version: "1.0.0",
        env: Mix.env()
      )
    end\
    """
    |> String.trim()
  end

  defp conditional_assign_code do
    """
    # Only modify conn under certain conditions:
    def maybe_put_user_locale(conn, _opts) do
      case get_session(conn, :locale) do
        nil ->
          # Fall back to Accept-Language header
          locale =
            conn
            |> get_req_header("accept-language")
            |> List.first("en")
            |> String.slice(0, 2)

          assign(conn, :locale, locale)

        saved_locale ->
          assign(conn, :locale, saved_locale)
      end
    end\
    """
    |> String.trim()
  end

  defp template_assign_code do
    """
    <%# Assigns set by plugs are available in all
        templates rendered during that request: %>

    <%# In app.html.heex: %>
    <html lang={@locale}>

    <%# In any template: %>
    <p>Version: {@app_version}</p>

    <%# In controllers — read from conn.assigns: %>
    def index(conn, _params) do
      locale = conn.assigns.locale
      products = Catalog.list_products(locale: locale)
      render(conn, :index, products: products)
    end\
    """
    |> String.trim()
  end

  defp logging_code do
    """
    import Plug.Conn
    require Logger

    # Basic request logger:
    def log_request(conn, _opts) do
      start = System.monotonic_time(:millisecond)

      Plug.Conn.register_before_send(conn, fn conn ->
        stop = System.monotonic_time(:millisecond)
        diff = stop - start

        Logger.info(
          "\#{conn.method} \#{conn.request_path} => " <>
          "\#{conn.status} in \#{diff}ms"
        )

        conn
      end)
    end

    # register_before_send/2 runs a callback right before
    # the response is sent — perfect for logging status codes.\
    """
    |> String.trim()
  end

  defp timing_code do
    """
    # Store start time in conn private:
    def start_timer(conn, _opts) do
      put_private(conn, :start_time,
        System.monotonic_time(:microsecond))
    end

    # Read it later in a response plug:
    def log_duration(conn, _opts) do
      t0 = conn.private[:start_time]
      t1 = System.monotonic_time(:microsecond)
      ms = Float.round((t1 - t0) / 1000, 2)
      Logger.debug("Response time: \#{ms}ms")
      conn
    end\
    """
    |> String.trim()
  end

  defp before_after_code do
    """
    # register_before_send runs AFTER controller
    # but BEFORE the response bytes are written:
    def track_request(conn, _opts) do
      # "Before" logic (runs now):
      conn = assign(conn, :request_start, DateTime.utc_now())

      # "After" logic (runs when response is ready):
      register_before_send(conn, fn conn ->
        duration_ms =
          DateTime.diff(DateTime.utc_now(),
                        conn.assigns.request_start, :millisecond)

        MyApp.Metrics.record(conn.request_path, duration_ms)
        conn
      end)
    end\
    """
    |> String.trim()
  end

  defp pipeline_usage_code do
    """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug :put_locale          # <-- custom function plug
        plug :log_request         # <-- another function plug
      end

      # These function plugs must be defined or imported:
      defp put_locale(conn, _opts) do
        Plug.Conn.assign(conn, :locale,
          get_session(conn, :locale) || "en")
      end

      defp log_request(conn, _opts) do
        require Logger
        Logger.debug("GET \#{conn.request_path}")
        conn
      end
    end\
    """
    |> String.trim()
  end

  defp plug_with_opts_code do
    """
    # Pass options to a function plug:
    pipeline :browser do
      plug :check_header, header: "x-api-version"
    end

    defp check_header(conn, opts) do
      header = Keyword.fetch!(opts, :header)
      case Plug.Conn.get_req_header(conn, header) do
        [] ->
          conn |> Plug.Conn.assign(:api_version, "v1")
        [version | _] ->
          conn |> Plug.Conn.assign(:api_version, version)
      end
    end\
    """
    |> String.trim()
  end

  defp controller_plug_code do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      # Plug only runs for specific actions:
      plug :load_product when action in [:show, :edit, :update, :delete]
      plug :verify_owner when action in [:edit, :update, :delete]

      defp load_product(conn, _opts) do
        id = conn.params["id"]
        product = Catalog.get_product!(id)
        Plug.Conn.assign(conn, :product, product)
      end

      defp verify_owner(conn, _opts) do
        product = conn.assigns.product
        user = conn.assigns.current_user

        if product.user_id == user.id do
          conn
        else
          conn
          |> put_flash(:error, "Not authorized")
          |> redirect(to: ~p"/products")
          |> halt()
        end
      end
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Full example: function plugs in a Phoenix router and controller

    defmodule MyAppWeb.Router do
      use MyAppWeb, :router
      import Plug.Conn
      require Logger

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug :put_locale          # custom: reads locale from session
        plug :add_request_id      # custom: generates a request ID
      end

      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
        resources "/products", ProductController
      end

      # --- Function plug definitions ---

      defp put_locale(conn, _opts) do
        locale = get_session(conn, :locale) || "en"
        assign(conn, :locale, locale)
      end

      defp add_request_id(conn, _opts) do
        id = :crypto.strong_rand_bytes(8) |> Base.encode16()
        conn
        |> assign(:request_id, id)
        |> put_resp_header("x-request-id", id)
      end
    end

    # Controller-level function plugs:
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller
      import Plug.Conn

      # Run for all write actions
      plug :ensure_product_loaded when action in [:show, :edit, :update, :delete]

      def index(conn, _params) do
        products = Catalog.list_products(locale: conn.assigns.locale)
        render(conn, :index, products: products)
      end

      def show(conn, _params) do
        # conn.assigns.product already loaded by plug!
        render(conn, :show)
      end

      defp ensure_product_loaded(conn, _opts) do
        id = conn.params["id"]
        product = Catalog.get_product!(id)
        assign(conn, :product, product)
      end
    end\
    """
    |> String.trim()
  end
end
