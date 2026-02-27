defmodule ElixirKatasWeb.PhoenixApiKata06BearerTokenAuthLive do
  use ElixirKatasWeb, :live_component

  @valid_token "sk_live_abc123def456"
  @plug_steps [
    %{id: "receive", label: "Receive Request", icon: "1"},
    %{id: "extract", label: "Extract Header", icon: "2"},
    %{id: "validate", label: "Validate Token", icon: "3"},
    %{id: "assign_or_halt", label: "Assign or Halt", icon: "4"},
    %{id: "response", label: "Response", icon: "5"}
  ]

  def phoenix_source do
    """
    # Bearer Token Authentication Plug
    #
    # A module plug that extracts and validates Bearer tokens
    # from the Authorization header. It follows the plug contract:
    # init/1 (compile-time options) and call/2 (runtime).

    defmodule MyAppWeb.Plugs.VerifyApiToken do
      @behaviour Plug
      import Plug.Conn

      # init/1 runs at compile time — configure options here
      def init(opts), do: opts

      # call/2 runs for every request in the pipeline
      def call(conn, _opts) do
        with {:ok, token} <- extract_token(conn),
             {:ok, user}  <- verify_token(token) do
          # Token valid — assign the user and continue
          assign(conn, :current_user, user)
        else
          {:error, reason} ->
            # Token invalid — halt the pipeline with 401
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.json(%{
              errors: %{detail: auth_error_message(reason)}
            })
            |> halt()
        end
      end

      # Extract "Bearer <token>" from the Authorization header
      defp extract_token(conn) do
        case get_req_header(conn, "authorization") do
          ["Bearer " <> token] -> {:ok, String.trim(token)}
          [_other]             -> {:error, :invalid_format}
          []                   -> {:error, :missing_token}
        end
      end

      # Look up the token (DB, cache, or decode a JWT)
      defp verify_token(token) do
        case MyApp.Auth.find_user_by_token(token) do
          nil  -> {:error, :invalid_token}
          user -> {:ok, user}
        end
      end

      defp auth_error_message(:missing_token), do: "Missing Authorization header"
      defp auth_error_message(:invalid_format), do: "Authorization header must use Bearer scheme"
      defp auth_error_message(:invalid_token), do: "Token is invalid or expired"
    end

    # Using the plug in your router:
    defmodule MyAppWeb.Router do
      pipeline :api_auth do
        plug MyAppWeb.Plugs.VerifyApiToken
      end

      scope "/api", MyAppWeb.Api do
        pipe_through [:api, :api_auth]

        resources "/users", UserController
        resources "/posts", PostController
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(token_input: "")
     |> assign(auth_result: nil)
     |> assign(current_step: 0)
     |> assign(plug_steps: @plug_steps)
     |> assign(conn_state: nil)
     |> assign(show_valid_token: false)
     |> assign(valid_token: @valid_token)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Bearer Token Authentication</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Simulate a token auth flow through the plug pipeline. Enter a token and watch each step
        of the <code>VerifyApiToken</code> plug process the request.
      </p>

      <!-- Token Input Section -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Authorization Header</h3>

        <div class="flex items-center gap-2 mb-3">
          <span class="text-sm font-mono text-gray-500 dark:text-gray-400 whitespace-nowrap">Authorization: Bearer</span>
          <input
            type="text"
            value={@token_input}
            phx-change="update_token"
            phx-target={@myself}
            name="token"
            placeholder="paste your token here..."
            class="flex-1 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-900 text-gray-900 dark:text-white font-mono text-sm focus:ring-2 focus:ring-rose-500 focus:border-rose-500"
          />
        </div>

        <!-- Quick Action Buttons -->
        <div class="flex flex-wrap gap-2">
          <button
            phx-click="try_valid_token"
            phx-target={@myself}
            class="px-4 py-2 text-sm rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-medium transition-colors cursor-pointer"
          >
            Try with valid token
          </button>
          <button
            phx-click="try_no_token"
            phx-target={@myself}
            class="px-4 py-2 text-sm rounded-lg bg-red-600 hover:bg-red-700 text-white font-medium transition-colors cursor-pointer"
          >
            Try without token
          </button>
          <button
            phx-click="try_bad_format"
            phx-target={@myself}
            class="px-4 py-2 text-sm rounded-lg bg-amber-600 hover:bg-amber-700 text-white font-medium transition-colors cursor-pointer"
          >
            Try bad format (Basic)
          </button>
          <button
            phx-click="try_invalid_token"
            phx-target={@myself}
            class="px-4 py-2 text-sm rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-medium transition-colors cursor-pointer"
          >
            Try expired token
          </button>
        </div>

        <%= if @show_valid_token do %>
          <div class="mt-3 p-2 rounded bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
            <p class="text-xs text-emerald-700 dark:text-emerald-400 font-mono">
              Valid token: {@valid_token}
            </p>
          </div>
        <% end %>
      </div>

      <!-- Plug Pipeline Visualization -->
      <%= if @auth_result do %>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              Plug Pipeline
            </h3>
            <div class="flex gap-2">
              <button
                phx-click="reset_pipeline"
                phx-target={@myself}
                class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
              >
                Reset
              </button>
              <button
                phx-click="next_step"
                phx-target={@myself}
                disabled={@current_step >= length(@auth_result.steps)}
                class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                  if(@current_step >= length(@auth_result.steps),
                    do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                    else: "bg-rose-600 hover:bg-rose-700 text-white")
                ]}
              >
                <%= if @current_step == 0, do: "Start Flow", else: "Next Step" %>
              </button>
            </div>
          </div>

          <!-- Steps -->
          <div class="space-y-3">
            <%= for {step, i} <- Enum.with_index(@auth_result.steps) do %>
              <div class={["flex items-start gap-4 p-4 rounded-lg transition-all duration-300",
                cond do
                  i < @current_step -> "bg-gray-50 dark:bg-gray-800 opacity-100"
                  i == @current_step -> "bg-rose-50 dark:bg-rose-900/20 border-2 border-rose-300 dark:border-rose-700 shadow-md"
                  true -> "bg-gray-50 dark:bg-gray-800 opacity-30"
                end
              ]}>
                <!-- Step Number -->
                <div class={["flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                  cond do
                    i < @current_step && step.status == :ok -> "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400"
                    i < @current_step && step.status == :error -> "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
                    i == @current_step -> "bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400"
                    true -> "bg-gray-200 dark:bg-gray-700 text-gray-400"
                  end
                ]}>
                  <%= if i < @current_step do %>
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

                <!-- Step Content -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-0.5">
                    <span class="text-xs font-semibold uppercase tracking-wide text-rose-600 dark:text-rose-400">
                      {step.label}
                    </span>
                  </div>
                  <div class="font-mono text-sm text-gray-900 dark:text-white">{step.code}</div>
                  <%= if i <= @current_step do %>
                    <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">{step.detail}</div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Conn State Display -->
          <%= if @current_step > 0 do %>
            <div class="mt-4 p-4 bg-gray-900 rounded-lg">
              <div class="text-gray-400 font-mono text-sm mb-2"># Plug.Conn state after step {@current_step}:</div>
              <pre class="text-rose-400 font-mono text-sm whitespace-pre-wrap"><%= conn_state_at(@auth_result, @current_step) %></pre>
            </div>
          <% end %>

          <!-- Final Result -->
          <%= if @current_step >= length(@auth_result.steps) do %>
            <div class={["mt-4 p-4 rounded-lg border-2",
              if(@auth_result.success,
                do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
                else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
            ]}>
              <div class="flex items-center gap-2 mb-2">
                <%= if @auth_result.success do %>
                  <svg class="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span class="font-bold text-emerald-800 dark:text-emerald-300">200 OK &mdash; Request Authorized</span>
                <% else %>
                  <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span class="font-bold text-red-800 dark:text-red-300">401 Unauthorized &mdash; Request Rejected</span>
                <% end %>
              </div>
              <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm">
                <pre class={["whitespace-pre-wrap", if(@auth_result.success, do: "text-emerald-400", else: "text-red-400")]}><%= @auth_result.response %></pre>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Architecture Overview -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Module Plug Pattern</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">1. init/1</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Runs at <strong>compile time</strong>. Returns options that are passed to <code>call/2</code>.
              Use this to pre-compute or validate config.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">2. call/2</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Runs at <strong>request time</strong>. Receives the conn and init options.
              Must return a <code>Plug.Conn</code>. Can modify, assign, or halt.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">3. halt/1</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Stops the plug pipeline. No further plugs or controller actions run.
              The response is sent immediately from this plug.
            </p>
          </div>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">The Bearer Token Flow</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          The client sends <code>Authorization: Bearer &lt;token&gt;</code>. The plug extracts the token,
          validates it against the database or signing key, and either assigns the user to the conn
          (allowing the request to proceed) or halts with a 401 response. This pattern keeps
          authentication logic out of controllers entirely.
        </p>
      </div>
    </div>
    """
  end

  defp conn_state_at(auth_result, step) do
    Enum.at(auth_result.conn_states, step - 1, "")
  end

  @valid_token_val @valid_token

  defp simulate_auth("") do
    simulate_missing()
  end

  defp simulate_auth(token) do
    if token == @valid_token_val do
      simulate_valid(token)
    else
      simulate_invalid(token)
    end
  end

  defp simulate_missing do
    %{
      success: false,
      steps: [
        %{label: "Receive", code: "GET /api/users", detail: "Incoming request — no Authorization header", status: :ok},
        %{label: "Extract", code: "get_req_header(conn, \"authorization\")", detail: "Returns [] — no header found", status: :error},
        %{label: "Halt", code: "conn |> put_status(:unauthorized) |> halt()", detail: "Pipeline stopped. 401 response sent.", status: :error}
      ],
      conn_states: [
        "%Plug.Conn{\n  req_headers: [...],\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  req_headers: [],  # no authorization header\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  status: 401,\n  halted: true,\n  resp_body: \"{\\\"errors\\\":{\\\"detail\\\":\\\"Missing Authorization header\\\"}}\"\n}"
      ],
      response: "HTTP/1.1 401 Unauthorized\nContent-Type: application/json\n\n{\n  \"errors\": {\n    \"detail\": \"Missing Authorization header\"\n  }\n}"
    }
  end

  defp simulate_bad_format do
    %{
      success: false,
      steps: [
        %{label: "Receive", code: "GET /api/users", detail: "Incoming request with Authorization header", status: :ok},
        %{label: "Extract", code: "get_req_header(conn, \"authorization\")", detail: "Found header but format is \"Basic ...\" not \"Bearer ...\"", status: :error},
        %{label: "Halt", code: "conn |> put_status(:unauthorized) |> halt()", detail: "Pipeline stopped. Must use Bearer scheme.", status: :error}
      ],
      conn_states: [
        "%Plug.Conn{\n  req_headers: [{\"authorization\", \"Basic dXNlcjpwYXNz\"}],\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  # Header found but wrong format\n  # Expected: \"Bearer <token>\"\n  # Got: \"Basic dXNlcjpwYXNz\"\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  status: 401,\n  halted: true,\n  resp_body: \"{\\\"errors\\\":{\\\"detail\\\":\\\"Authorization header must use Bearer scheme\\\"}}\"\n}"
      ],
      response: "HTTP/1.1 401 Unauthorized\nContent-Type: application/json\n\n{\n  \"errors\": {\n    \"detail\": \"Authorization header must use Bearer scheme\"\n  }\n}"
    }
  end

  defp simulate_invalid(token) do
    %{
      success: false,
      steps: [
        %{label: "Receive", code: "GET /api/users", detail: "Incoming request with Bearer token", status: :ok},
        %{label: "Extract", code: "get_req_header(conn, \"authorization\")", detail: "Found \"Bearer #{token}\" — extracted token", status: :ok},
        %{label: "Validate", code: "MyApp.Auth.find_user_by_token(token)", detail: "Token not found in database — invalid or expired", status: :error},
        %{label: "Halt", code: "conn |> put_status(:unauthorized) |> halt()", detail: "Pipeline stopped. Invalid token.", status: :error}
      ],
      conn_states: [
        "%Plug.Conn{\n  req_headers: [{\"authorization\", \"Bearer #{token}\"}],\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  # Token extracted: \"#{token}\"\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  # Token lookup failed — no matching user\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  status: 401,\n  halted: true,\n  resp_body: \"{\\\"errors\\\":{\\\"detail\\\":\\\"Token is invalid or expired\\\"}}\"\n}"
      ],
      response: "HTTP/1.1 401 Unauthorized\nContent-Type: application/json\n\n{\n  \"errors\": {\n    \"detail\": \"Token is invalid or expired\"\n  }\n}"
    }
  end

  defp simulate_valid(token) do
    %{
      success: true,
      steps: [
        %{label: "Receive", code: "GET /api/users", detail: "Incoming request with Bearer token", status: :ok},
        %{label: "Extract", code: "get_req_header(conn, \"authorization\")", detail: "Found \"Bearer #{token}\" — extracted token", status: :ok},
        %{label: "Validate", code: "MyApp.Auth.find_user_by_token(token)", detail: "Token valid! Found user: Alice (id: 42)", status: :ok},
        %{label: "Assign", code: "assign(conn, :current_user, user)", detail: "User assigned to conn — pipeline continues to controller", status: :ok}
      ],
      conn_states: [
        "%Plug.Conn{\n  req_headers: [{\"authorization\", \"Bearer #{token}\"}],\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  # Token extracted: \"#{token}\"\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  # User found: %User{id: 42, name: \"Alice\", role: \"admin\"}\n  status: nil,\n  halted: false\n}",
        "%Plug.Conn{\n  assigns: %{current_user: %User{id: 42, name: \"Alice\", role: \"admin\"}},\n  status: nil,\n  halted: false\n}"
      ],
      response: "HTTP/1.1 200 OK\nContent-Type: application/json\n\n{\n  \"data\": {\n    \"id\": 42,\n    \"name\": \"Alice\",\n    \"email\": \"alice@example.com\",\n    \"role\": \"admin\"\n  }\n}"
    }
  end

  def handle_event("update_token", %{"token" => token}, socket) do
    {:noreply, assign(socket, token_input: token)}
  end

  def handle_event("try_valid_token", _params, socket) do
    result = simulate_auth(@valid_token)
    {:noreply, assign(socket, token_input: @valid_token, auth_result: result, current_step: 0, show_valid_token: true)}
  end

  def handle_event("try_no_token", _params, socket) do
    result = simulate_missing()
    {:noreply, assign(socket, token_input: "", auth_result: result, current_step: 0, show_valid_token: false)}
  end

  def handle_event("try_bad_format", _params, socket) do
    result = simulate_bad_format()
    {:noreply, assign(socket, token_input: "Basic dXNlcjpwYXNz", auth_result: result, current_step: 0, show_valid_token: false)}
  end

  def handle_event("try_invalid_token", _params, socket) do
    token = "sk_expired_xyz789"
    result = simulate_auth(token)
    {:noreply, assign(socket, token_input: token, auth_result: result, current_step: 0, show_valid_token: false)}
  end

  def handle_event("next_step", _params, socket) do
    max = length(socket.assigns.auth_result.steps)
    new_step = min(socket.assigns.current_step + 1, max)
    {:noreply, assign(socket, current_step: new_step)}
  end

  def handle_event("reset_pipeline", _params, socket) do
    {:noreply, assign(socket, current_step: 0)}
  end
end
