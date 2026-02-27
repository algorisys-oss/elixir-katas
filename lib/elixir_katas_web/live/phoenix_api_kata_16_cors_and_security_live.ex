defmodule ElixirKatasWeb.PhoenixApiKata16CorsAndSecurityLive do
  use ElixirKatasWeb, :live_component

  @security_headers [
    %{name: "Content-Security-Policy", value: "default-src 'self'", desc: "Controls which resources the browser can load"},
    %{name: "X-Frame-Options", value: "DENY", desc: "Prevents your page from being embedded in an iframe"},
    %{name: "X-Content-Type-Options", value: "nosniff", desc: "Prevents MIME-type sniffing attacks"},
    %{name: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains", desc: "Forces HTTPS for all future requests"},
    %{name: "X-XSS-Protection", value: "1; mode=block", desc: "Legacy XSS filter (modern browsers use CSP instead)"},
    %{name: "Referrer-Policy", value: "strict-origin-when-cross-origin", desc: "Controls how much referrer info is sent"}
  ]

  @default_cors %{
    allowed_origins: ["https://myapp.com", "https://admin.myapp.com"],
    allowed_methods: ["GET", "POST", "PUT", "DELETE"],
    allowed_headers: ["Authorization", "Content-Type", "X-API-Key"],
    max_age: 3600,
    credentials: true
  }

  def phoenix_source do
    """
    # CORS & Security Headers
    #
    # CORS (Cross-Origin Resource Sharing) controls which domains
    # can call your API from a browser. Security headers protect
    # against common web attacks.

    # 1. Add cors_plug to mix.exs
    defp deps do
      [{:cors_plug, "~> 3.0"}]
    end

    # 2. Configure CORS in endpoint or router
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      # CORS plug — runs before the router
      plug CORSPlug,
        origin: ["https://myapp.com", "https://admin.myapp.com"],
        methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        headers: ["Authorization", "Content-Type", "X-API-Key"],
        max_age: 3600,
        credentials: true
    end

    # 3. Or build your own CORS plug:
    defmodule MyAppWeb.Plugs.CORS do
      @behaviour Plug
      import Plug.Conn

      @allowed_origins ["https://myapp.com", "https://admin.myapp.com"]

      def init(opts), do: opts

      def call(conn, _opts) do
        origin = get_req_header(conn, "origin") |> List.first()

        if origin in @allowed_origins do
          conn
          |> put_resp_header("access-control-allow-origin", origin)
          |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
          |> put_resp_header("access-control-allow-headers", "Authorization, Content-Type, X-API-Key")
          |> put_resp_header("access-control-max-age", "3600")
          |> put_resp_header("access-control-allow-credentials", "true")
          |> handle_preflight()
        else
          conn
        end
      end

      defp handle_preflight(%{method: "OPTIONS"} = conn) do
        conn |> send_resp(204, "") |> halt()
      end
      defp handle_preflight(conn), do: conn
    end

    # 4. Security headers plug
    defmodule MyAppWeb.Plugs.SecurityHeaders do
      @behaviour Plug
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        conn
        |> put_resp_header("content-security-policy", "default-src 'self'")
        |> put_resp_header("x-frame-options", "DENY")
        |> put_resp_header("x-content-type-options", "nosniff")
        |> put_resp_header("strict-transport-security", "max-age=31536000; includeSubDomains")
        |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
      end
    end

    # 5. Add to endpoint
    defmodule MyAppWeb.Endpoint do
      plug MyAppWeb.Plugs.SecurityHeaders
      plug MyAppWeb.Plugs.CORS
      plug MyAppWeb.Router
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(cors_config: @default_cors)
     |> assign(security_headers: @security_headers)
     |> assign(test_origin: "https://myapp.com")
     |> assign(test_method: "GET")
     |> assign(preflight_result: nil)
     |> assign(flow_step: 0)
     |> assign(active_section: "cors")
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">CORS & Security Headers</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Explore how CORS preflight requests work and which security headers protect your API.
        Configure allowed origins and watch the browser-server negotiation.
      </p>

      <!-- Section Toggle -->
      <div class="flex gap-3">
        <button
          phx-click="set_section"
          phx-value-section="cors"
          phx-target={@myself}
          class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
            if(@active_section == "cors",
              do: "border-rose-500 bg-rose-600 text-white",
              else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
          ]}
        >
          CORS Flow
        </button>
        <button
          phx-click="set_section"
          phx-value-section="security"
          phx-target={@myself}
          class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
            if(@active_section == "security",
              do: "border-rose-500 bg-rose-600 text-white",
              else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
          ]}
        >
          Security Headers
        </button>
      </div>

      <!-- CORS Section -->
      <%= if @active_section == "cors" do %>
        <!-- CORS Configuration -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">CORS Configuration</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Allowed Origins</label>
              <div class="space-y-1">
                <%= for origin <- @cors_config.allowed_origins do %>
                  <div class="flex items-center gap-2">
                    <span class="px-2 py-1 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 rounded text-sm font-mono">{origin}</span>
                  </div>
                <% end %>
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Allowed Methods</label>
              <div class="flex flex-wrap gap-1">
                <%= for method <- @cors_config.allowed_methods do %>
                  <span class="px-2 py-0.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 rounded text-xs font-mono font-bold">{method}</span>
                <% end %>
              </div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 mt-3">Allowed Headers</label>
              <div class="flex flex-wrap gap-1">
                <%= for header <- @cors_config.allowed_headers do %>
                  <span class="px-2 py-0.5 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400 rounded text-xs font-mono">{header}</span>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <!-- Test a Request -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Simulate a Cross-Origin Request</h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Origin (the requesting domain)</label>
              <div class="space-y-2">
                <%= for origin <- ["https://myapp.com", "https://admin.myapp.com", "https://evil-site.com", "https://localhost:3000"] do %>
                  <button
                    phx-click="set_origin"
                    phx-value-origin={origin}
                    phx-target={@myself}
                    class={["w-full text-left px-3 py-2 rounded-lg border-2 text-sm font-mono transition-all cursor-pointer",
                      if(@test_origin == origin,
                        do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20",
                        else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 bg-white dark:bg-gray-800")
                    ]}
                  >
                    {origin}
                    <%= if origin in @cors_config.allowed_origins do %>
                      <span class="ml-2 px-1.5 py-0.5 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded text-xs">allowed</span>
                    <% else %>
                      <span class="ml-2 px-1.5 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded text-xs">blocked</span>
                    <% end %>
                  </button>
                <% end %>
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">HTTP Method</label>
              <div class="space-y-2">
                <%= for method <- ["GET", "POST", "PUT", "DELETE", "PATCH"] do %>
                  <button
                    phx-click="set_method"
                    phx-value-method={method}
                    phx-target={@myself}
                    class={["w-full text-left px-3 py-2 rounded-lg border-2 text-sm font-mono transition-all cursor-pointer",
                      if(@test_method == method,
                        do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20",
                        else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 bg-white dark:bg-gray-800")
                    ]}
                  >
                    {method}
                    <%= if method in @cors_config.allowed_methods do %>
                      <span class="ml-2 px-1.5 py-0.5 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded text-xs">allowed</span>
                    <% else %>
                      <span class="ml-2 px-1.5 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded text-xs">blocked</span>
                    <% end %>
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <button
            phx-click="test_cors"
            phx-target={@myself}
            class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer"
          >
            Send Preflight Request (OPTIONS)
          </button>
        </div>

        <!-- Preflight Flow -->
        <%= if @preflight_result do %>
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Preflight Flow</h3>
              <div class="flex gap-2">
                <button
                  phx-click="reset_flow"
                  phx-target={@myself}
                  class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
                >
                  Reset
                </button>
                <button
                  phx-click="next_flow_step"
                  phx-target={@myself}
                  disabled={@flow_step >= length(@preflight_result.steps)}
                  class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                    if(@flow_step >= length(@preflight_result.steps),
                      do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                      else: "bg-rose-600 hover:bg-rose-700 text-white")
                  ]}
                >
                  <%= if @flow_step == 0, do: "Start Flow", else: "Next Step" %>
                </button>
              </div>
            </div>

            <div class="space-y-3">
              <%= for {step, i} <- Enum.with_index(@preflight_result.steps) do %>
                <div class={["flex items-start gap-4 p-4 rounded-lg transition-all duration-300",
                  cond do
                    i < @flow_step -> "bg-gray-50 dark:bg-gray-800 opacity-100"
                    i == @flow_step -> "bg-rose-50 dark:bg-rose-900/20 border-2 border-rose-300 dark:border-rose-700 shadow-md"
                    true -> "bg-gray-50 dark:bg-gray-800 opacity-30"
                  end
                ]}>
                  <div class={["flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                    cond do
                      i < @flow_step && step.status == :ok -> "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400"
                      i < @flow_step && step.status == :error -> "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
                      true -> "bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400"
                    end
                  ]}>
                    <%= if i < @flow_step do %>
                      <%= if step.status == :ok do %>
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                      <% else %>
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      <% end %>
                    <% else %>
                      {i + 1}
                    <% end %>
                  </div>
                  <div class="flex-1 min-w-0">
                    <span class="text-xs font-semibold uppercase tracking-wide text-rose-600 dark:text-rose-400">{step.label}</span>
                    <div class="font-mono text-sm text-gray-900 dark:text-white whitespace-pre-wrap">{step.code}</div>
                    <%= if i <= @flow_step do %>
                      <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">{step.detail}</div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Final Result -->
            <%= if @flow_step >= length(@preflight_result.steps) do %>
              <div class={["mt-4 p-4 rounded-lg border-2",
                if(@preflight_result.allowed,
                  do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
                  else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
              ]}>
                <div class="flex items-center gap-2 mb-2">
                  <%= if @preflight_result.allowed do %>
                    <svg class="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                    <span class="font-bold text-emerald-800 dark:text-emerald-300">CORS Allowed -- Browser will send the actual request</span>
                  <% else %>
                    <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                    </svg>
                    <span class="font-bold text-red-800 dark:text-red-300">CORS Blocked -- Browser will reject the request</span>
                  <% end %>
                </div>
                <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm">
                  <pre class={["whitespace-pre-wrap", if(@preflight_result.allowed, do: "text-emerald-400", else: "text-red-400")]}>{@preflight_result.response}</pre>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <!-- How CORS Works -->
        <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
          <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">When Does Preflight Happen?</h4>
          <p class="text-sm text-rose-700 dark:text-rose-400">
            <strong>Simple requests</strong> (GET/POST with standard headers) skip preflight.
            <strong>Preflighted requests</strong> (PUT/DELETE, custom headers, JSON Content-Type) trigger
            an OPTIONS request first. The browser checks the response headers before sending the real request.
            CORS is enforced by the <em>browser</em>, not the server -- server-to-server calls ignore CORS entirely.
          </p>
        </div>
      <% end %>

      <!-- Security Headers Section -->
      <%= if @active_section == "security" do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Security Response Headers</h3>
          <p class="text-sm text-gray-600 dark:text-gray-300 mb-4">
            These headers should be set on every response to protect against common web attacks.
          </p>
          <div class="space-y-3">
            <%= for header <- @security_headers do %>
              <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-900/50 border border-gray-200 dark:border-gray-700">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1">
                    <div class="font-mono text-sm font-semibold text-rose-700 dark:text-rose-400">{header.name}</div>
                    <div class="font-mono text-xs text-gray-600 dark:text-gray-400 mt-0.5">{header.value}</div>
                    <p class="text-sm text-gray-600 dark:text-gray-300 mt-1">{header.desc}</p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Example Response -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Example Response with All Headers</h3>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
            <div class="text-emerald-400">{"HTTP/1.1 200 OK"}</div>
            <div class="text-gray-400">{"Content-Type: application/json"}</div>
            <%= for header <- @security_headers do %>
              <div class="text-blue-400">{header.name}: <span class="text-white">{header.value}</span></div>
            <% end %>
            <div class="text-purple-400 mt-1">{"Access-Control-Allow-Origin: https://myapp.com"}</div>
            <div class="text-purple-400">{"Access-Control-Allow-Methods: GET, POST, PUT, DELETE"}</div>
          </div>
        </div>

        <!-- Key Insight -->
        <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
          <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Defense in Depth</h4>
          <p class="text-sm text-rose-700 dark:text-rose-400">
            Security headers are a <strong>defense-in-depth</strong> strategy. No single header prevents all attacks,
            but together they significantly reduce your API's attack surface. Set them at the Endpoint level
            so every response includes them, including error responses.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("set_section", %{"section" => section}, socket) do
    {:noreply, assign(socket, active_section: section)}
  end

  def handle_event("set_origin", %{"origin" => origin}, socket) do
    {:noreply, assign(socket, test_origin: origin, preflight_result: nil, flow_step: 0)}
  end

  def handle_event("set_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, test_method: method, preflight_result: nil, flow_step: 0)}
  end

  def handle_event("test_cors", _params, socket) do
    result = build_preflight_result(socket.assigns.test_origin, socket.assigns.test_method, socket.assigns.cors_config)
    {:noreply, assign(socket, preflight_result: result, flow_step: 0)}
  end

  def handle_event("next_flow_step", _params, socket) do
    max = length(socket.assigns.preflight_result.steps)
    new_step = min(socket.assigns.flow_step + 1, max)
    {:noreply, assign(socket, flow_step: new_step)}
  end

  def handle_event("reset_flow", _params, socket) do
    {:noreply, assign(socket, flow_step: 0)}
  end

  defp build_preflight_result(origin, method, cors_config) do
    origin_allowed = origin in cors_config.allowed_origins
    method_allowed = method in cors_config.allowed_methods

    needs_preflight = method in ["PUT", "DELETE", "PATCH"]

    steps = [
      %{
        label: "Browser",
        code: "fetch(\"https://api.myapp.com/posts\", {\n  method: \"#{method}\",\n  headers: { \"Origin\": \"#{origin}\" }\n})",
        detail: "JavaScript on #{origin} initiates a cross-origin request.",
        status: :ok
      }
    ]

    steps =
      if needs_preflight do
        steps ++
          [
            %{
              label: "Preflight",
              code: "OPTIONS /api/posts HTTP/1.1\nOrigin: #{origin}\nAccess-Control-Request-Method: #{method}\nAccess-Control-Request-Headers: Content-Type",
              detail: "#{method} is not a simple method -- browser sends an OPTIONS preflight first.",
              status: :ok
            }
          ]
      else
        steps ++
          [
            %{
              label: "Simple Request",
              code: "#{method} /api/posts HTTP/1.1\nOrigin: #{origin}",
              detail: "#{method} is a simple method -- no preflight needed, browser sends the request directly.",
              status: :ok
            }
          ]
      end

    steps =
      steps ++
        [
          %{
            label: "Origin Check",
            code: "origin = get_req_header(conn, \"origin\")\norigin in @allowed_origins",
            detail:
              if(origin_allowed,
                do: "Origin \"#{origin}\" IS in the allowed origins list.",
                else: "Origin \"#{origin}\" is NOT in the allowed origins list."
              ),
            status: if(origin_allowed, do: :ok, else: :error)
          }
        ]

    if origin_allowed do
      steps =
        steps ++
          [
            %{
              label: "Method Check",
              code: "\"#{method}\" in @allowed_methods",
              detail:
                if(method_allowed,
                  do: "Method #{method} IS in the allowed methods list.",
                  else: "Method #{method} is NOT in the allowed methods list."
                ),
              status: if(method_allowed, do: :ok, else: :error)
            }
          ]

      if method_allowed do
        steps =
          steps ++
            [
              %{
                label: "Response Headers",
                code: "Access-Control-Allow-Origin: #{origin}\nAccess-Control-Allow-Methods: #{Enum.join(cors_config.allowed_methods, ", ")}\nAccess-Control-Max-Age: #{cors_config.max_age}",
                detail: "Server responds with CORS headers. Browser proceeds with the actual request.",
                status: :ok
              }
            ]

        %{
          allowed: true,
          steps: steps,
          response: "HTTP/1.1 204 No Content\nAccess-Control-Allow-Origin: #{origin}\nAccess-Control-Allow-Methods: #{Enum.join(cors_config.allowed_methods, ", ")}\nAccess-Control-Allow-Headers: #{Enum.join(cors_config.allowed_headers, ", ")}\nAccess-Control-Max-Age: #{cors_config.max_age}\nAccess-Control-Allow-Credentials: true"
        }
      else
        %{
          allowed: false,
          steps: steps,
          response: "CORS Error: Method #{method} is not allowed.\nThe browser will block the response.\n\nConsole: Access to fetch at 'https://api.myapp.com/posts'\nfrom origin '#{origin}' has been blocked by CORS policy:\nMethod #{method} is not allowed."
        }
      end
    else
      %{
        allowed: false,
        steps: steps,
        response: "CORS Error: Origin #{origin} is not allowed.\nThe browser will block the response.\n\nConsole: Access to fetch at 'https://api.myapp.com/posts'\nfrom origin '#{origin}' has been blocked by CORS policy:\nNo 'Access-Control-Allow-Origin' header is present."
      }
    end
  end
end
