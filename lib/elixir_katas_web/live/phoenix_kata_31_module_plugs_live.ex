defmodule ElixirKatasWeb.PhoenixKata31ModulePlugsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Module plug structure: init/1 (compile time) + call/2 (runtime)
    defmodule MyApp.Plugs.RequestLogger do
      @behaviour Plug
      import Plug.Conn
      require Logger

      @valid_levels [:debug, :info, :warning, :error]

      @impl Plug
      def init(opts) do
        level = Keyword.get(opts, :level, :info)

        unless level in @valid_levels do
          raise ArgumentError,
            "level must be one of: \#{inspect(@valid_levels)}"
        end

        %{
          level: level,
          log_headers: Keyword.get(opts, :log_headers, false),
          filter_paths: Keyword.get(opts, :filter_paths, [])
        }
      end

      @impl Plug
      def call(conn, opts) do
        if should_log?(conn, opts) do
          start = System.monotonic_time(:millisecond)
          log_request(conn, opts)

          register_before_send(conn, fn conn ->
            elapsed = System.monotonic_time(:millisecond) - start
            log_response(conn, elapsed, opts)
            conn
          end)
        else
          conn
        end
      end

      defp should_log?(conn, %{filter_paths: paths}) do
        not Enum.any?(paths, &String.starts_with?(
          conn.request_path, &1))
      end

      defp log_request(conn, %{level: level}) do
        Logger.log(level, "[REQ] \#{conn.method} \#{conn.request_path}")
      end

      defp log_response(conn, elapsed, %{level: level}) do
        Logger.log(level,
          "[RES] \#{conn.method} \#{conn.request_path} " <>
          "=> \#{conn.status} in \#{elapsed}ms")
      end
    end

    # Usage in router:
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug MyApp.Plugs.RequestLogger,
        level: :info,
        log_headers: false,
        filter_paths: ["/health", "/metrics"]
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "structure")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Module Plugs</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Reusable middleware modules with <code>init/1</code> and <code>call/2</code> callbacks, options, and compile-time initialization.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "init", "options", "examples", "code"]}
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
            <button :for={topic <- ["structure", "minimal", "behaviour"]}
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

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">init/1 — Compile Time</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">
                Called once when the plug is loaded. Use it to validate and transform options so <code>call/2</code> is fast.
              </p>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">call/2 — Runtime</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">
                Called on every request. Receives the conn and the result of <code>init/1</code>. Returns a modified conn.
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- init/1 lifecycle -->
      <%= if @active_tab == "init" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>init/1</code> runs at compile time in production (or startup in dev). Use it to precompute expensive work.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{init_lifecycle_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Good uses for init/1</h4>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li class="flex items-start gap-2"><span class="text-green-500 mt-0.5">+</span> Validate required options</li>
                <li class="flex items-start gap-2"><span class="text-green-500 mt-0.5">+</span> Compile regex patterns</li>
                <li class="flex items-start gap-2"><span class="text-green-500 mt-0.5">+</span> Build lookup maps</li>
                <li class="flex items-start gap-2"><span class="text-green-500 mt-0.5">+</span> Convert option types</li>
                <li class="flex items-start gap-2"><span class="text-green-500 mt-0.5">+</span> Set default values</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Avoid in init/1</h4>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li class="flex items-start gap-2"><span class="text-red-500 mt-0.5">-</span> Database queries</li>
                <li class="flex items-start gap-2"><span class="text-red-500 mt-0.5">-</span> HTTP calls</li>
                <li class="flex items-start gap-2"><span class="text-red-500 mt-0.5">-</span> Anything that can fail at startup</li>
                <li class="flex items-start gap-2"><span class="text-red-500 mt-0.5">-</span> Request-specific logic</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Options -->
      <%= if @active_tab == "options" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Module plugs accept options at declaration time. <code>init/1</code> transforms them; <code>call/2</code> uses the result.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Keyword Options</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{keyword_opts_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Map Options</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{map_opts_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 md:col-span-2">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Validated Options with NimbleOptions</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{nimble_opts_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Real-world examples -->
      <%= if @active_tab == "examples" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Common module plug patterns used in real Phoenix applications.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">SetLocale Plug</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{set_locale_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">RateLimit Plug</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{rate_limit_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">RequireRole Plug</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{require_role_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">VerifyAPIKey Plug</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{verify_api_key_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Module Plug: RequestLogger</h4>
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
  defp tab_label("init"), do: "init/1 Lifecycle"
  defp tab_label("options"), do: "Options"
  defp tab_label("examples"), do: "Examples"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("structure"), do: "Structure"
  defp topic_label("minimal"), do: "Minimal Plug"
  defp topic_label("behaviour"), do: "Plug Behaviour"

  defp overview_code("structure") do
    """
    # Module plug structure:
    defmodule MyApp.Plugs.MyPlug do
      @behaviour Plug       # optional but good practice
      import Plug.Conn

      # 1. Called once at compile time (or startup in dev)
      #    Receives the options passed at plug declaration
      #    Returns a value that becomes the opts for call/2
      @impl Plug
      def init(opts) do
        # Validate, transform, and return options
        opts
      end

      # 2. Called on every request
      #    conn   — the current %Plug.Conn{}
      #    opts   — the return value of init/1
      #    return — a (possibly modified) %Plug.Conn{}
      @impl Plug
      def call(conn, opts) do
        # Transform conn
        conn
      end
    end

    # Usage:
    plug MyApp.Plugs.MyPlug
    plug MyApp.Plugs.MyPlug, key: "value"\
    """
    |> String.trim()
  end

  defp overview_code("minimal") do
    """
    # The simplest possible module plug:
    defmodule MyApp.Plugs.Hello do
      def init(opts), do: opts

      def call(conn, _opts) do
        IO.puts("Hello from plug!")
        conn
      end
    end

    # A plug that adds a response header:
    defmodule MyApp.Plugs.AddHeader do
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        put_resp_header(conn, "x-powered-by", "Phoenix")
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("behaviour") do
    """
    # Plug defines a @behaviour with two callbacks:
    # @callback init(opts :: keyword()) :: opts :: any()
    # @callback call(conn :: Plug.Conn.t(), opts :: any())
    #   :: Plug.Conn.t()

    # With @behaviour and @impl for clarity:
    defmodule MyApp.Plugs.StrictPlug do
      @behaviour Plug
      import Plug.Conn

      @impl Plug
      def init(opts) do
        unless Keyword.has_key?(opts, :required_key) do
          raise ArgumentError, "required_key is required"
        end
        opts
      end

      @impl Plug
      def call(conn, opts) do
        value = Keyword.fetch!(opts, :required_key)
        assign(conn, :plug_value, value)
      end
    end\
    """
    |> String.trim()
  end

  defp init_lifecycle_code do
    """
    # init/1 runs AT COMPILE TIME in production:
    defmodule MyApp.Plugs.ContentNegotiation do
      @behaviour Plug

      # init/1: validates and preprocesses options
      # This runs once when the router module is compiled!
      def init(opts) do
        allowed = Keyword.get(opts, :allowed, ["html", "json"])
        # Convert to a MapSet for O(1) lookup at runtime:
        %{allowed: MapSet.new(allowed)}
      end

      # call/2: receives the MapSet, not the original list
      def call(conn, %{allowed: allowed}) do
        [format | _] = Plug.Conn.accepts(conn, MapSet.to_list(allowed))
        Plug.Conn.assign(conn, :format, format)
      end
    end

    # In dev, init/1 runs on every request (modules recompile)
    # In prod, init/1 runs ONCE and the result is stored

    # This means init/1 CAN do expensive work — it only
    # runs once in production:
    def init(opts) do
      pattern = Keyword.fetch!(opts, :pattern)
      # Compile the regex once:
      %{regex: Regex.compile!(pattern)}
    end\
    """
    |> String.trim()
  end

  defp keyword_opts_code do
    """
    defmodule MyApp.Plugs.Timeout do
      def init(opts) do
        # Set defaults, validate types:
        %{
          timeout: Keyword.get(opts, :timeout, 5000),
          action: Keyword.get(opts, :action, :halt)
        }
      end

      def call(conn, %{timeout: t, action: action}) do
        # Use the precomputed map from init/1
        Plug.Conn.assign(conn, :timeout, t)
      end
    end

    # Usage:
    plug MyApp.Plugs.Timeout, timeout: 10_000\
    """
    |> String.trim()
  end

  defp map_opts_code do
    """
    defmodule MyApp.Plugs.CORS do
      def init(opts) when is_list(opts) do
        %{
          origin: Keyword.get(opts, :origin, "*"),
          methods: Keyword.get(opts, :methods,
            ["GET", "POST", "PUT", "DELETE"]),
          headers: Keyword.get(opts, :headers,
            ["Content-Type", "Authorization"])
        }
      end

      def call(conn, %{origin: origin, methods: methods}) do
        conn
        |> Plug.Conn.put_resp_header(
             "access-control-allow-origin", origin)
        |> Plug.Conn.put_resp_header(
             "access-control-allow-methods",
             Enum.join(methods, ", "))
      end
    end\
    """
    |> String.trim()
  end

  defp nimble_opts_code do
    """
    # Using NimbleOptions for declarative validation:
    defmodule MyApp.Plugs.RateLimit do
      @schema NimbleOptions.new!([
        requests: [type: :pos_integer, required: true],
        window:   [type: :pos_integer, default: 60_000],
        key_fn:   [type: {:fun, 1}, default: &RateLimit.default_key/1]
      ])

      def init(opts) do
        NimbleOptions.validate!(opts, @schema)
      end

      def call(conn, opts) do
        key = opts[:key_fn].(conn)
        # ... rate limit logic
        conn
      end

      def default_key(conn), do: conn.remote_ip
    end\
    """
    |> String.trim()
  end

  defp set_locale_code do
    """
    defmodule MyApp.Plugs.SetLocale do
      import Plug.Conn

      @supported_locales ~w(en fr de es)

      def init(opts) do
        %{default: Keyword.get(opts, :default, "en")}
      end

      def call(conn, %{default: default}) do
        locale =
          get_session(conn, :locale) ||
          parse_accept_language(conn) ||
          default

        conn
        |> assign(:locale, locale)
        |> put_session(:locale, locale)
      end

      defp parse_accept_language(conn) do
        conn
        |> get_req_header("accept-language")
        |> List.first("")
        |> String.slice(0, 2)
        |> then(&if &1 in @supported_locales, do: &1)
      end
    end\
    """
    |> String.trim()
  end

  defp rate_limit_code do
    """
    defmodule MyApp.Plugs.RateLimit do
      import Plug.Conn

      def init(opts) do
        %{
          limit: Keyword.get(opts, :limit, 100),
          window: Keyword.get(opts, :window, 60_000)
        }
      end

      def call(conn, %{limit: limit, window: window}) do
        key = "rate_limit:\#{conn.remote_ip}"
        count = MyApp.Cache.incr(key, ttl: window)

        if count > limit do
          conn
          |> put_resp_header("x-ratelimit-limit",
               to_string(limit))
          |> send_resp(429, "Too Many Requests")
          |> halt()
        else
          put_resp_header(conn, "x-ratelimit-remaining",
            to_string(limit - count))
        end
      end
    end

    # Usage:
    plug MyApp.Plugs.RateLimit, limit: 60, window: 60_000\
    """
    |> String.trim()
  end

  defp require_role_code do
    """
    defmodule MyApp.Plugs.RequireRole do
      import Plug.Conn
      import Phoenix.Controller

      def init(opts) do
        role = Keyword.fetch!(opts, :role)
        %{role: role}
      end

      def call(conn, %{role: required_role}) do
        user = conn.assigns[:current_user]

        cond do
          is_nil(user) ->
            conn
            |> redirect(to: "/login")
            |> halt()

          user.role != required_role ->
            conn
            |> put_flash(:error, "Access denied")
            |> redirect(to: "/")
            |> halt()

          true ->
            conn
        end
      end
    end

    # Usage:
    plug MyApp.Plugs.RequireRole, role: :admin\
    """
    |> String.trim()
  end

  defp verify_api_key_code do
    """
    defmodule MyApp.Plugs.VerifyAPIKey do
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        with [api_key] <- get_req_header(conn, "x-api-key"),
             {:ok, client} <- MyApp.APIKeys.verify(api_key) do
          assign(conn, :api_client, client)
        else
          _ ->
            conn
            |> send_resp(401, ~s({"error":"Invalid API key"}))
            |> halt()
        end
      end
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete module plug: structured request logger

    defmodule MyApp.Plugs.RequestLogger do
      @behaviour Plug
      import Plug.Conn
      require Logger

      @valid_levels [:debug, :info, :warning, :error]

      @impl Plug
      def init(opts) do
        level = Keyword.get(opts, :level, :info)

        unless level in @valid_levels do
          raise ArgumentError,
            "level must be one of: \#{inspect(@valid_levels)}"
        end

        %{
          level: level,
          log_headers: Keyword.get(opts, :log_headers, false),
          filter_paths: Keyword.get(opts, :filter_paths, [])
        }
      end

      @impl Plug
      def call(conn, opts) do
        if should_log?(conn, opts) do
          start = System.monotonic_time(:millisecond)
          log_request(conn, opts)

          register_before_send(conn, fn conn ->
            elapsed = System.monotonic_time(:millisecond) - start
            log_response(conn, elapsed, opts)
            conn
          end)
        else
          conn
        end
      end

      defp should_log?(conn, %{filter_paths: paths}) do
        not Enum.any?(paths, &String.starts_with?(
          conn.request_path, &1))
      end

      defp log_request(conn, %{level: level, log_headers: log_headers}) do
        msg = "[REQ] \#{conn.method} \#{conn.request_path}"
        msg = if log_headers do
          headers = Enum.map_join(conn.req_headers, ", ",
            fn {k, v} -> "\#{k}: \#{v}" end)
          msg <> " headers=[\#{headers}]"
        else
          msg
        end
        Logger.log(level, msg)
      end

      defp log_response(conn, elapsed, %{level: level}) do
        Logger.log(level,
          "[RES] \#{conn.method} \#{conn.request_path} " <>
          "=> \#{conn.status} in \#{elapsed}ms")
      end
    end

    # Usage in router:
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug MyApp.Plugs.RequestLogger,
        level: :info,
        log_headers: false,
        filter_paths: ["/health", "/metrics"]
    end\
    """
    |> String.trim()
  end
end
