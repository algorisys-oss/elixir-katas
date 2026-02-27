defmodule ElixirKatasWeb.PhoenixApiKata15RateLimitingLive do
  use ElixirKatasWeb, :live_component

  @default_limit 10
  @window_seconds 60

  def phoenix_source do
    """
    # Rate Limiting with Hammer
    #
    # Hammer is an Elixir rate-limiter with pluggable backends.
    # It uses a "token bucket" algorithm: each key gets N tokens
    # per time window. Each request consumes one token.

    # 1. Add Hammer to mix.exs
    defp deps do
      [
        {:hammer, "~> 6.1"},
        {:hammer_backend_mnesia, "~> 0.6"}  # or Redis backend
      ]
    end

    # 2. Configure in config/config.exs
    config :hammer,
      backend: {Hammer.Backend.Mnesia, [expiry_ms: 60_000 * 60]}

    # 3. Rate Limiting Plug
    defmodule MyAppWeb.Plugs.RateLimit do
      @behaviour Plug
      import Plug.Conn

      def init(opts) do
        %{
          limit: Keyword.get(opts, :limit, 100),
          window_ms: Keyword.get(opts, :window_ms, 60_000),
          by: Keyword.get(opts, :by, :ip)
        }
      end

      def call(conn, opts) do
        key = rate_limit_key(conn, opts.by)

        case Hammer.check_rate(key, opts.window_ms, opts.limit) do
          {:allow, count} ->
            remaining = opts.limit - count
            reset = div(opts.window_ms, 1000)

            conn
            |> put_resp_header("x-ratelimit-limit", to_string(opts.limit))
            |> put_resp_header("x-ratelimit-remaining", to_string(remaining))
            |> put_resp_header("x-ratelimit-reset", to_string(reset))

          {:deny, _limit} ->
            conn
            |> put_status(429)
            |> put_resp_header("retry-after", to_string(div(opts.window_ms, 1000)))
            |> put_resp_header("x-ratelimit-limit", to_string(opts.limit))
            |> put_resp_header("x-ratelimit-remaining", "0")
            |> Phoenix.Controller.json(%{
              errors: %{detail: "Rate limit exceeded. Try again later."}
            })
            |> halt()
        end
      end

      defp rate_limit_key(conn, :ip) do
        ip = conn.remote_ip |> :inet.ntoa() |> to_string()
        "rate:ip:" <> ip
      end

      defp rate_limit_key(conn, :api_key) do
        key = conn.assigns[:api_key_id] || "anonymous"
        "rate:key:" <> to_string(key)
      end
    end

    # 4. Using in the router
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :rate_limited do
        # 100 requests per minute, keyed by IP
        plug MyAppWeb.Plugs.RateLimit, limit: 100, window_ms: 60_000, by: :ip
      end

      pipeline :strict_rate_limit do
        # 10 requests per minute for write endpoints
        plug MyAppWeb.Plugs.RateLimit, limit: 10, window_ms: 60_000, by: :api_key
      end

      scope "/api", MyAppWeb.Api do
        pipe_through [:api, :rate_limited]
        resources "/posts", PostController, only: [:index, :show]
      end

      scope "/api", MyAppWeb.Api do
        pipe_through [:api, :strict_rate_limit]
        resources "/posts", PostController, only: [:create, :update, :delete]
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(bucket_limit: @default_limit)
     |> assign(bucket_remaining: @default_limit)
     |> assign(bucket_used: 0)
     |> assign(window_seconds: @window_seconds)
     |> assign(rate_mode: "ip")
     |> assign(request_log: [])
     |> assign(is_limited: false)
     |> assign(burst_size: 1)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Rate Limiting</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Simulate API rate limiting with a token bucket. Each request consumes a token.
        When tokens run out, requests get a <code class="text-rose-600 dark:text-rose-400">429 Too Many Requests</code> response.
      </p>

      <!-- Rate Limit Mode Toggle -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Rate Limit Strategy</h3>
        <div class="flex gap-3">
          <button
            phx-click="set_mode"
            phx-value-mode="ip"
            phx-target={@myself}
            class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
              if(@rate_mode == "ip",
                do: "border-rose-500 bg-rose-600 text-white",
                else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
            ]}
          >
            Per-IP Address
          </button>
          <button
            phx-click="set_mode"
            phx-value-mode="api_key"
            phx-target={@myself}
            class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
              if(@rate_mode == "api_key",
                do: "border-rose-500 bg-rose-600 text-white",
                else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
            ]}
          >
            Per-API Key
          </button>
        </div>
        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
          <%= if @rate_mode == "ip" do %>
            Keyed by <code>conn.remote_ip</code> -- all requests from the same IP share one bucket.
            Simple but can penalize users behind NAT/proxies.
          <% else %>
            Keyed by <code>conn.assigns.api_key_id</code> -- each API key gets its own bucket.
            Fairer for multi-tenant APIs, allows per-plan limits.
          <% end %>
        </p>
      </div>

      <!-- Bucket Visualization -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Token Bucket</h3>
          <div class="text-sm text-gray-500 dark:text-gray-400">
            Window: {@window_seconds}s &bull;
            Key: <code class="text-rose-600 dark:text-rose-400"><%= if @rate_mode == "ip", do: "rate:ip:192.168.1.42", else: "rate:key:ak_prod_abc123" %></code>
          </div>
        </div>

        <!-- Visual Bucket -->
        <div class="mb-4">
          <div class="flex items-center justify-between mb-1">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
              {@bucket_remaining} / {@bucket_limit} tokens remaining
            </span>
            <span class={["text-sm font-semibold",
              cond do
                @bucket_remaining == 0 -> "text-red-600 dark:text-red-400"
                @bucket_remaining <= div(@bucket_limit, 4) -> "text-amber-600 dark:text-amber-400"
                true -> "text-emerald-600 dark:text-emerald-400"
              end
            ]}>
              <%= cond do %>
                <% @bucket_remaining == 0 -> %>
                  EXHAUSTED
                <% @bucket_remaining <= div(@bucket_limit, 4) -> %>
                  LOW
                <% true -> %>
                  OK
              <% end %>
            </span>
          </div>
          <div class="w-full h-8 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
            <div
              class={["h-full rounded-full transition-all duration-300",
                cond do
                  @bucket_remaining == 0 -> "bg-red-500"
                  @bucket_remaining <= div(@bucket_limit, 4) -> "bg-amber-500"
                  true -> "bg-emerald-500"
                end
              ]}
              style={"width: #{if @bucket_limit > 0, do: Float.round(@bucket_remaining / @bucket_limit * 100, 1), else: 0}%"}
            />
          </div>

          <!-- Token Dots -->
          <div class="flex flex-wrap gap-1 mt-3">
            <%= for i <- 1..@bucket_limit do %>
              <div class={["w-5 h-5 rounded-full transition-all duration-200 border",
                if(i <= @bucket_remaining,
                  do: "bg-emerald-400 dark:bg-emerald-500 border-emerald-500 dark:border-emerald-400",
                  else: "bg-gray-200 dark:bg-gray-700 border-gray-300 dark:border-gray-600")
              ]} />
            <% end %>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-wrap gap-3 mt-4">
          <button
            phx-click="send_request"
            phx-target={@myself}
            class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer"
          >
            Send 1 Request
          </button>
          <button
            phx-click="send_burst"
            phx-value-count="3"
            phx-target={@myself}
            class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer"
          >
            Burst 3 Requests
          </button>
          <button
            phx-click="send_burst"
            phx-value-count="5"
            phx-target={@myself}
            class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer"
          >
            Burst 5 Requests
          </button>
          <button
            phx-click="reset_bucket"
            phx-target={@myself}
            class="px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg text-sm font-medium hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
          >
            Reset Bucket
          </button>
        </div>
      </div>

      <!-- Response Headers -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Response Headers</h3>
        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
          <div class={[if(@is_limited, do: "text-red-400", else: "text-emerald-400")]}>
            {"HTTP/1.1 "}
            <%= if @is_limited do %>
              {"429 Too Many Requests"}
            <% else %>
              {"200 OK"}
            <% end %>
          </div>
          <div class="text-gray-400">{"Content-Type: application/json"}</div>
          <div class="text-blue-400">{"X-RateLimit-Limit: "}<span class="text-white">{@bucket_limit}</span></div>
          <div class="text-blue-400">{"X-RateLimit-Remaining: "}<span class={[if(@bucket_remaining == 0, do: "text-red-400", else: "text-white")]}>{@bucket_remaining}</span></div>
          <div class="text-blue-400">{"X-RateLimit-Reset: "}<span class="text-white">{@window_seconds}</span></div>
          <%= if @is_limited do %>
            <div class="text-amber-400">{"Retry-After: "}<span class="text-white">{@window_seconds}</span></div>
          <% end %>
        </div>
      </div>

      <!-- Request Log -->
      <%= if length(@request_log) > 0 do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Request Log</h3>
          <div class="space-y-2 max-h-64 overflow-y-auto">
            <%= for {entry, i} <- Enum.with_index(@request_log) do %>
              <div class={["flex items-center gap-3 p-2 rounded-lg text-sm",
                if(entry.allowed,
                  do: "bg-emerald-50 dark:bg-emerald-900/10",
                  else: "bg-red-50 dark:bg-red-900/10")
              ]}>
                <span class="text-gray-400 font-mono text-xs w-6 text-right">{"#"}{length(@request_log) - i}</span>
                <span class={["px-2 py-0.5 rounded text-xs font-bold",
                  if(entry.allowed,
                    do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400",
                    else: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400")
                ]}>
                  {entry.status}
                </span>
                <span class="font-mono text-gray-700 dark:text-gray-300">GET /api/posts</span>
                <span class="text-gray-500 dark:text-gray-400 ml-auto">
                  {entry.remaining}/{@bucket_limit} remaining
                </span>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Comparison: Per-IP vs Per-API-Key -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Per-IP vs Per-API-Key Rate Limiting</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">Per-IP Address</h4>
            <ul class="text-sm text-rose-700 dark:text-rose-400 space-y-1">
              <li>+ Simple, works without authentication</li>
              <li>+ Good for public endpoints</li>
              <li>- Users behind NAT/VPN share a bucket</li>
              <li>- Easy to bypass with rotating IPs</li>
            </ul>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">Per-API Key</h4>
            <ul class="text-sm text-rose-700 dark:text-rose-400 space-y-1">
              <li>+ Fair per-consumer limiting</li>
              <li>+ Supports per-plan rate limits</li>
              <li>+ Tracks usage per application</li>
              <li>- Requires authentication first</li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Always Include Rate Limit Headers</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          Good APIs always return <code>X-RateLimit-Limit</code>, <code>X-RateLimit-Remaining</code>,
          and <code>X-RateLimit-Reset</code> headers so clients can self-throttle.
          When the limit is hit, return <code>429 Too Many Requests</code> with a <code>Retry-After</code> header.
        </p>
      </div>
    </div>
    """
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) do
    {:noreply,
     socket
     |> assign(rate_mode: mode)
     |> assign(bucket_remaining: socket.assigns.bucket_limit)
     |> assign(bucket_used: 0)
     |> assign(request_log: [])
     |> assign(is_limited: false)
    }
  end

  def handle_event("send_request", _params, socket) do
    {:noreply, process_requests(socket, 1)}
  end

  def handle_event("send_burst", %{"count" => count_str}, socket) do
    count = String.to_integer(count_str)
    {:noreply, process_requests(socket, count)}
  end

  def handle_event("reset_bucket", _params, socket) do
    {:noreply,
     socket
     |> assign(bucket_remaining: socket.assigns.bucket_limit)
     |> assign(bucket_used: 0)
     |> assign(request_log: [])
     |> assign(is_limited: false)
    }
  end

  defp process_requests(socket, count) do
    Enum.reduce(1..count, socket, fn _i, acc ->
      remaining = acc.assigns.bucket_remaining

      if remaining > 0 do
        new_remaining = remaining - 1
        entry = %{allowed: true, status: "200", remaining: new_remaining}

        acc
        |> assign(bucket_remaining: new_remaining)
        |> assign(bucket_used: acc.assigns.bucket_used + 1)
        |> assign(is_limited: false)
        |> assign(request_log: [entry | acc.assigns.request_log])
      else
        entry = %{allowed: false, status: "429", remaining: 0}

        acc
        |> assign(is_limited: true)
        |> assign(request_log: [entry | acc.assigns.request_log])
      end
    end)
  end
end
