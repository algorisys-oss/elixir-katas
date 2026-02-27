defmodule ElixirKatasWeb.PhoenixApiKata08ApiKeysLive do
  use ElixirKatasWeb, :live_component

  @initial_keys [
    %{
      id: "key_1",
      name: "Production App",
      key: "ak_prod_" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false),
      created: "2025-01-15",
      last_used: "2025-02-27",
      requests_today: 4521,
      rate_limit: 10_000,
      status: :active
    },
    %{
      id: "key_2",
      name: "Staging App",
      key: "ak_stg_" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false),
      created: "2025-02-01",
      last_used: "2025-02-26",
      requests_today: 892,
      rate_limit: 5_000,
      status: :active
    },
    %{
      id: "key_3",
      name: "Old Integration",
      key: "ak_old_Xk9mP2qR7vLwN3",
      created: "2024-06-10",
      last_used: "2024-12-01",
      requests_today: 0,
      rate_limit: 1_000,
      status: :revoked
    }
  ]

  @delivery_methods [
    %{id: "header", label: "X-API-Key Header", example: "X-API-Key: ak_prod_abc123...", recommended: true},
    %{id: "query", label: "Query Parameter", example: "/api/users?api_key=ak_prod_abc123...", recommended: false},
    %{id: "bearer", label: "Bearer Token", example: "Authorization: Bearer ak_prod_abc123...", recommended: false}
  ]

  def phoenix_source do
    """
    # API Key Authentication Plug
    #
    # API keys identify the calling application (not a user).
    # They're simpler than JWT — just a lookup in the database.

    defmodule MyAppWeb.Plugs.VerifyApiKey do
      @behaviour Plug
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        with {:ok, key} <- extract_key(conn),
             {:ok, api_key} <- lookup_key(key),
             :ok <- check_rate_limit(api_key) do
          conn
          |> assign(:api_key, api_key)
          |> assign(:rate_limit_remaining, remaining_requests(api_key))
          |> put_resp_header("x-rate-limit-remaining",
               to_string(remaining_requests(api_key)))
        else
          {:error, :missing_key} ->
            conn |> put_status(401) |> json_error("API key required") |> halt()

          {:error, :invalid_key} ->
            conn |> put_status(401) |> json_error("Invalid API key") |> halt()

          {:error, :revoked} ->
            conn |> put_status(401) |> json_error("API key has been revoked") |> halt()

          {:error, :rate_limited} ->
            conn
            |> put_status(429)
            |> put_resp_header("retry-after", "60")
            |> json_error("Rate limit exceeded")
            |> halt()
        end
      end

      # Check X-API-Key header first, then query param
      defp extract_key(conn) do
        case get_req_header(conn, "x-api-key") do
          [key | _] -> {:ok, key}
          [] ->
            case conn.params["api_key"] do
              nil -> {:error, :missing_key}
              key -> {:ok, key}
            end
        end
      end

      defp lookup_key(key) do
        case Repo.get_by(ApiKey, key: key) do
          nil -> {:error, :invalid_key}
          %{status: :revoked} -> {:error, :revoked}
          api_key -> {:ok, api_key}
        end
      end

      defp check_rate_limit(api_key) do
        count = MyApp.RateLimiter.get_count(api_key.id)
        if count < api_key.rate_limit, do: :ok, else: {:error, :rate_limited}
      end

      defp remaining_requests(api_key) do
        max(0, api_key.rate_limit - MyApp.RateLimiter.get_count(api_key.id))
      end

      defp json_error(conn, message) do
        Phoenix.Controller.json(conn, %{errors: %{detail: message}})
      end
    end

    # Generating secure API keys:
    defmodule MyApp.ApiKeys do
      def generate_key(prefix \\\\ "ak") do
        random = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
        prefix <> "_" <> random
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(api_keys: @initial_keys)
     |> assign(delivery_methods: @delivery_methods)
     |> assign(selected_key: nil)
     |> assign(test_key_input: "")
     |> assign(test_method: "header")
     |> assign(test_result: nil)
     |> assign(new_key_name: "")
     |> assign(show_generator: false)
     |> assign(generated_key: nil)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">API Key Management</h2>
      <p class="text-gray-600 dark:text-gray-300">
        API keys identify <strong>applications</strong>, not users. Manage keys, test validation,
        and see how the plug pipeline processes each request.
      </p>

      <!-- API Key Dashboard -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">API Keys</h3>
          <button
            phx-click="toggle_generator"
            phx-target={@myself}
            class="px-4 py-2 text-sm rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-medium transition-colors cursor-pointer"
          >
            + Generate New Key
          </button>
        </div>

        <!-- Key Generator -->
        <%= if @show_generator do %>
          <div class="mb-4 p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <div class="flex items-end gap-3">
              <div class="flex-1">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Key Name</label>
                <input
                  type="text"
                  value={@new_key_name}
                  phx-change="update_key_name"
                  phx-target={@myself}
                  name="name"
                  placeholder="e.g., Mobile App, CI/CD Pipeline..."
                  class="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-900 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-rose-500"
                />
              </div>
              <button
                phx-click="generate_key"
                phx-target={@myself}
                disabled={@new_key_name == ""}
                class={["px-4 py-2 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                  if(@new_key_name == "",
                    do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                    else: "bg-emerald-600 hover:bg-emerald-700 text-white")
                ]}
              >
                Generate
              </button>
            </div>
            <%= if @generated_key do %>
              <div class="mt-3 p-3 rounded bg-gray-900">
                <p class="text-xs text-gray-400 mb-1">Copy this key now &mdash; it won't be shown again!</p>
                <code class="text-emerald-400 font-mono text-sm break-all">{@generated_key}</code>
              </div>
            <% end %>
          </div>
        <% end %>

        <!-- Key List -->
        <div class="space-y-2">
          <%= for key <- @api_keys do %>
            <button
              phx-click="select_key"
              phx-value-id={key.id}
              phx-target={@myself}
              class={["w-full text-left p-4 rounded-lg border-2 transition-all cursor-pointer",
                if(@selected_key && @selected_key.id == key.id,
                  do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                  else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
              ]}
            >
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class={["w-2.5 h-2.5 rounded-full",
                    if(key.status == :active, do: "bg-emerald-500", else: "bg-red-500")
                  ]}></div>
                  <div>
                    <div class="font-semibold text-gray-900 dark:text-white">{key.name}</div>
                    <div class="font-mono text-xs text-gray-500 dark:text-gray-400">
                      {String.slice(key.key, 0, 12)}<span class="text-gray-400">{"••••••••"}</span>
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-sm text-gray-600 dark:text-gray-400">
                    {key.requests_today} / {key.rate_limit} requests
                  </div>
                  <div class={["text-xs",
                    usage_color(key.requests_today, key.rate_limit)
                  ]}>
                    {usage_percent(key.requests_today, key.rate_limit)}% used today
                  </div>
                </div>
              </div>

              <!-- Rate Limit Bar -->
              <div class="mt-2 w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                <div
                  class={["h-1.5 rounded-full transition-all",
                    rate_bar_color(key.requests_today, key.rate_limit)
                  ]}
                  style={"width: #{usage_percent(key.requests_today, key.rate_limit)}%"}
                >
                </div>
              </div>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Selected Key Detail -->
      <%= if @selected_key do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border-2 border-rose-300 dark:border-rose-700">
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{@selected_key.name}</h3>
            <span class={["px-2.5 py-0.5 rounded-full text-xs font-semibold",
              if(@selected_key.status == :active,
                do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400",
                else: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400")
            ]}>
              {if @selected_key.status == :active, do: "Active", else: "Revoked"}
            </span>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
            <div>
              <span class="text-gray-500 dark:text-gray-400">Created</span>
              <div class="font-medium text-gray-900 dark:text-white">{@selected_key.created}</div>
            </div>
            <div>
              <span class="text-gray-500 dark:text-gray-400">Last Used</span>
              <div class="font-medium text-gray-900 dark:text-white">{@selected_key.last_used}</div>
            </div>
            <div>
              <span class="text-gray-500 dark:text-gray-400">Rate Limit</span>
              <div class="font-medium text-gray-900 dark:text-white">{@selected_key.rate_limit}/day</div>
            </div>
            <div>
              <span class="text-gray-500 dark:text-gray-400">Requests Today</span>
              <div class="font-medium text-gray-900 dark:text-white">{@selected_key.requests_today}</div>
            </div>
          </div>

          <div class="mt-3 flex gap-2">
            <%= if @selected_key.status == :active do %>
              <button
                phx-click="revoke_key"
                phx-value-id={@selected_key.id}
                phx-target={@myself}
                class="px-3 py-1.5 text-sm rounded-lg bg-red-600 hover:bg-red-700 text-white transition-colors cursor-pointer"
              >
                Revoke Key
              </button>
            <% end %>
            <button
              phx-click="use_key_for_test"
              phx-value-key={@selected_key.key}
              phx-target={@myself}
              class="px-3 py-1.5 text-sm rounded-lg bg-rose-600 hover:bg-rose-700 text-white transition-colors cursor-pointer"
            >
              Test This Key
            </button>
          </div>
        </div>
      <% end %>

      <!-- Delivery Methods -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">How to Send an API Key</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <%= for method <- @delivery_methods do %>
            <div class={["p-4 rounded-lg border",
              if(method.recommended,
                do: "border-rose-300 dark:border-rose-700 bg-rose-50 dark:bg-rose-900/20",
                else: "border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800")
            ]}>
              <div class="flex items-center gap-2 mb-2">
                <h4 class="font-semibold text-gray-900 dark:text-white">{method.label}</h4>
                <%= if method.recommended do %>
                  <span class="px-1.5 py-0.5 rounded text-xs font-semibold bg-rose-200 dark:bg-rose-800 text-rose-800 dark:text-rose-200">
                    Recommended
                  </span>
                <% end %>
              </div>
              <div class="bg-gray-900 rounded p-2 font-mono text-xs text-rose-400 break-all">
                {method.example}
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Test API Key -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Test Key Validation</h3>
        <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <div class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">API Key</label>
              <input
                type="text"
                value={@test_key_input}
                phx-change="update_test_key"
                phx-target={@myself}
                name="key"
                placeholder="ak_prod_..."
                class="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-900 text-gray-900 dark:text-white font-mono text-sm focus:ring-2 focus:ring-rose-500"
              />
            </div>
            <div class="flex items-end">
              <button
                phx-click="test_key"
                phx-target={@myself}
                class="px-4 py-2 text-sm rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-medium transition-colors cursor-pointer"
              >
                Validate
              </button>
            </div>
          </div>

          <%= if @test_result do %>
            <div class={["mt-3 p-3 rounded-lg border",
              if(@test_result.success,
                do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
                else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
            ]}>
              <div class="flex items-center gap-2 mb-2">
                <%= if @test_result.success do %>
                  <svg class="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                  <span class="font-bold text-emerald-800 dark:text-emerald-300">{@test_result.status}</span>
                <% else %>
                  <svg class="w-5 h-5 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  <span class="font-bold text-red-800 dark:text-red-300">{@test_result.status}</span>
                <% end %>
              </div>
              <div class="bg-gray-900 rounded p-2 font-mono text-sm">
                <pre class={["whitespace-pre-wrap", if(@test_result.success, do: "text-emerald-400", else: "text-red-400")]}><%= @test_result.response %></pre>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">API Keys vs Bearer Tokens</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          <strong>API keys</strong> identify the <em>application</em> (rate limiting, analytics, billing).
          <strong>Bearer tokens</strong> (JWTs, session tokens) identify the <em>user</em> (authentication, authorization).
          Many APIs use both: an API key for the app + a Bearer token for the user.
        </p>
      </div>
    </div>
    """
  end

  defp usage_percent(used, limit) when limit > 0, do: min(100, round(used / limit * 100))
  defp usage_percent(_, _), do: 0

  defp usage_color(used, limit) do
    pct = usage_percent(used, limit)
    cond do
      pct >= 90 -> "text-red-600 dark:text-red-400"
      pct >= 70 -> "text-amber-600 dark:text-amber-400"
      true -> "text-emerald-600 dark:text-emerald-400"
    end
  end

  defp rate_bar_color(used, limit) do
    pct = usage_percent(used, limit)
    cond do
      pct >= 90 -> "bg-red-500"
      pct >= 70 -> "bg-amber-500"
      true -> "bg-emerald-500"
    end
  end

  def handle_event("select_key", %{"id" => id}, socket) do
    key = Enum.find(socket.assigns.api_keys, &(&1.id == id))
    new_key = if socket.assigns.selected_key && socket.assigns.selected_key.id == id, do: nil, else: key
    {:noreply, assign(socket, selected_key: new_key)}
  end

  def handle_event("toggle_generator", _params, socket) do
    {:noreply, assign(socket, show_generator: !socket.assigns.show_generator, generated_key: nil, new_key_name: "")}
  end

  def handle_event("update_key_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, new_key_name: name)}
  end

  def handle_event("generate_key", _params, socket) do
    random = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
    new_key_value = "ak_live_" <> random
    new_key = %{
      id: "key_#{System.unique_integer([:positive])}",
      name: socket.assigns.new_key_name,
      key: new_key_value,
      created: Date.to_string(Date.utc_today()),
      last_used: "never",
      requests_today: 0,
      rate_limit: 5_000,
      status: :active
    }
    {:noreply,
     socket
     |> assign(api_keys: socket.assigns.api_keys ++ [new_key])
     |> assign(generated_key: new_key_value)
     |> assign(new_key_name: "")
    }
  end

  def handle_event("revoke_key", %{"id" => id}, socket) do
    updated_keys = Enum.map(socket.assigns.api_keys, fn key ->
      if key.id == id, do: %{key | status: :revoked}, else: key
    end)
    selected = if socket.assigns.selected_key && socket.assigns.selected_key.id == id do
      Enum.find(updated_keys, &(&1.id == id))
    else
      socket.assigns.selected_key
    end
    {:noreply, assign(socket, api_keys: updated_keys, selected_key: selected)}
  end

  def handle_event("use_key_for_test", %{"key" => key}, socket) do
    {:noreply, assign(socket, test_key_input: key, test_result: nil)}
  end

  def handle_event("update_test_key", %{"key" => key}, socket) do
    {:noreply, assign(socket, test_key_input: key)}
  end

  def handle_event("test_key", _params, socket) do
    key_input = socket.assigns.test_key_input
    matched_key = Enum.find(socket.assigns.api_keys, &(&1.key == key_input))

    result = cond do
      key_input == "" ->
        %{success: false, status: "401 — Missing API Key",
          response: "{\n  \"errors\": {\n    \"detail\": \"API key required\"\n  }\n}"}

      matched_key == nil ->
        %{success: false, status: "401 — Invalid API Key",
          response: "{\n  \"errors\": {\n    \"detail\": \"Invalid API key\"\n  }\n}"}

      matched_key.status == :revoked ->
        %{success: false, status: "401 — Revoked API Key",
          response: "{\n  \"errors\": {\n    \"detail\": \"API key has been revoked\"\n  }\n}"}

      matched_key.requests_today >= matched_key.rate_limit ->
        %{success: false, status: "429 — Rate Limit Exceeded",
          response: "{\n  \"errors\": {\n    \"detail\": \"Rate limit exceeded\"\n  },\n  \"retry_after\": 60\n}"}

      true ->
        remaining = matched_key.rate_limit - matched_key.requests_today - 1
        %{success: true, status: "200 OK — Key Valid",
          response: "HTTP/1.1 200 OK\nX-Rate-Limit-Remaining: #{remaining}\nContent-Type: application/json\n\n{\n  \"data\": { ... }\n}"}
    end

    {:noreply, assign(socket, test_result: result)}
  end
end
