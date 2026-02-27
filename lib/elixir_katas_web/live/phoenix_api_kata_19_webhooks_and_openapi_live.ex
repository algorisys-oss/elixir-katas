defmodule ElixirKatasWeb.PhoenixApiKata19WebhooksAndOpenapiLive do
  use ElixirKatasWeb, :live_component

  @webhook_events [
    %{id: "payment_completed", name: "payment.completed", payload_preview: "amount, currency, customer_id"},
    %{id: "user_created", name: "user.created", payload_preview: "id, email, name, plan"},
    %{id: "order_shipped", name: "order.shipped", payload_preview: "order_id, tracking_number, carrier"},
    %{id: "subscription_cancelled", name: "subscription.cancelled", payload_preview: "sub_id, reason, effective_date"}
  ]

  @openapi_sections [
    %{id: "info", name: "Info & Servers", description: "API metadata, version, base URLs"},
    %{id: "paths", name: "Paths & Operations", description: "Endpoints, methods, parameters"},
    %{id: "schemas", name: "Schemas & Components", description: "Data models, request/response bodies"},
    %{id: "security", name: "Security Schemes", description: "Auth methods (Bearer, API Key, OAuth2)"}
  ]

  def phoenix_source do
    """
    # Webhooks & OpenAPI with Phoenix
    #
    # Webhooks: your server receives HTTP POST callbacks from external services.
    # OpenAPI: a spec that describes your API's endpoints, schemas, and auth.

    # === WEBHOOKS ===

    # 1. Webhook Controller — receive and verify incoming webhooks
    defmodule MyAppWeb.WebhookController do
      use MyAppWeb, :controller

      @webhook_secret Application.compile_env(:my_app, :webhook_secret)

      def handle(conn, params) do
        with {:ok, body, conn} <- read_body(conn),
             :ok <- verify_signature(conn, body) do
          event = params["event"]
          payload = params["data"]

          # Process asynchronously
          MyApp.Webhooks.process_async(event, payload)

          json(conn, %{status: "received"})
        else
          {:error, :invalid_signature} ->
            conn
            |> put_status(401)
            |> json(%{error: "Invalid webhook signature"})
        end
      end

      defp verify_signature(conn, body) do
        [signature] = get_req_header(conn, "x-webhook-signature")
        expected = :crypto.mac(:hmac, :sha256, @webhook_secret, body)
                   |> Base.encode16(case: :lower)

        if Plug.Crypto.secure_compare(signature, expected) do
          :ok
        else
          {:error, :invalid_signature}
        end
      end
    end

    # 2. Sending Webhooks to subscribers
    defmodule MyApp.Webhooks.Sender do
      @doc "Send a webhook event to all registered endpoints"
      def send_event(event, payload) do
        endpoints = MyApp.Webhooks.list_endpoints_for_event(event)

        Enum.each(endpoints, fn endpoint ->
          body = Jason.encode!(%{event: event, data: payload, timestamp: DateTime.utc_now()})
          signature = sign(body, endpoint.secret)

          Req.post(endpoint.url,
            body: body,
            headers: [
              {"content-type", "application/json"},
              {"x-webhook-signature", signature}
            ]
          )
        end)
      end

      defp sign(body, secret) do
        :crypto.mac(:hmac, :sha256, secret, body)
        |> Base.encode16(case: :lower)
      end
    end

    # === OPENAPI ===

    # 3. Using OpenApiSpex to generate specs from controllers
    defmodule MyAppWeb.Api.PostController do
      use MyAppWeb, :controller
      use OpenApiSpex.ControllerSpecs

      tags ["Posts"]
      security [%{"bearerAuth" => []}]

      operation :index,
        summary: "List all posts",
        responses: [
          ok: {"Post list", "application/json", MyApp.Schemas.PostList}
        ]

      def index(conn, _params) do
        posts = MyApp.Posts.list_posts()
        render(conn, :index, posts: posts)
      end

      operation :create,
        summary: "Create a post",
        request_body: {"Post params", "application/json", MyApp.Schemas.PostParams},
        responses: [
          created: {"Created post", "application/json", MyApp.Schemas.Post},
          unprocessable_entity: {"Validation errors", "application/json", MyApp.Schemas.ErrorResponse}
        ]

      def create(conn, %{"post" => params}) do
        # ...
      end
    end

    # 4. Define schemas
    defmodule MyApp.Schemas.Post do
      require OpenApiSpex
      alias OpenApiSpex.Schema

      OpenApiSpex.schema(%{
        title: "Post",
        type: :object,
        required: [:title],
        properties: %{
          id: %Schema{type: :integer},
          title: %Schema{type: :string, minLength: 1},
          body: %Schema{type: :string},
          inserted_at: %Schema{type: :string, format: :"date-time"}
        }
      })
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(active_tab: "receiving")
     |> assign(webhook_events: @webhook_events)
     |> assign(selected_event: nil)
     |> assign(signature_valid: nil)
     |> assign(flow_step: 0)
     |> assign(flow_steps: [])
     |> assign(openapi_sections: @openapi_sections)
     |> assign(selected_openapi_section: nil)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Webhooks & OpenAPI</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Explore webhook receiving/sending patterns and OpenAPI spec generation for Phoenix APIs.
      </p>

      <!-- Tab Toggle -->
      <div class="flex gap-3">
        <button
          phx-click="set_tab"
          phx-value-tab="receiving"
          phx-target={@myself}
          class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
            if(@active_tab == "receiving",
              do: "border-rose-500 bg-rose-600 text-white",
              else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
          ]}
        >
          Receiving Webhooks
        </button>
        <button
          phx-click="set_tab"
          phx-value-tab="sending"
          phx-target={@myself}
          class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
            if(@active_tab == "sending",
              do: "border-rose-500 bg-rose-600 text-white",
              else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
          ]}
        >
          Sending Webhooks
        </button>
        <button
          phx-click="set_tab"
          phx-value-tab="openapi"
          phx-target={@myself}
          class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
            if(@active_tab == "openapi",
              do: "border-rose-500 bg-rose-600 text-white",
              else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
          ]}
        >
          OpenAPI Spec
        </button>
      </div>

      <!-- Receiving Webhooks Tab -->
      <%= if @active_tab == "receiving" do %>
        <!-- Event Selector -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Incoming Webhook Event</h3>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <%= for event <- @webhook_events do %>
              <button
                phx-click="select_event"
                phx-value-id={event.id}
                phx-target={@myself}
                class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
                  if(@selected_event && @selected_event.id == event.id,
                    do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                    else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
                ]}
              >
                <div class="font-mono text-sm font-semibold text-rose-600 dark:text-rose-400">{event.name}</div>
                <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">Payload: {event.payload_preview}</div>
              </button>
            <% end %>
          </div>
        </div>

        <!-- Webhook Flow -->
        <%= if @selected_event do %>
          <!-- Signature Verification -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Signature Verification (HMAC-SHA256)</h3>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm mb-4">
              <div class="text-gray-400">{"# Incoming webhook request:"}</div>
              <div class="text-blue-400">POST /webhooks/{@selected_event.name}</div>
              <div class="text-purple-400">X-Webhook-Signature: <span class="text-white">a3f2b8c1d4e5...</span></div>
              <div class="text-gray-400">{"Content-Type: application/json"}</div>
              <div class="text-gray-400 mt-2">{"# Verification:"}</div>
              <div class="text-emerald-400">expected = HMAC-SHA256(secret, request_body)</div>
              <div class="text-emerald-400">secure_compare(signature_header, expected)</div>
            </div>

            <div class="flex gap-3">
              <button
                phx-click="verify_signature"
                phx-value-valid="true"
                phx-target={@myself}
                class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer"
              >
                Simulate Valid Signature
              </button>
              <button
                phx-click="verify_signature"
                phx-value-valid="false"
                phx-target={@myself}
                class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer"
              >
                Simulate Invalid Signature
              </button>
            </div>
          </div>

          <!-- Flow Visualization -->
          <%= if @signature_valid != nil do %>
            <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Webhook Processing Flow</h3>
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
                    disabled={@flow_step >= length(@flow_steps)}
                    class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                      if(@flow_step >= length(@flow_steps),
                        do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                        else: "bg-rose-600 hover:bg-rose-700 text-white")
                    ]}
                  >
                    <%= if @flow_step == 0, do: "Start Flow", else: "Next Step" %>
                  </button>
                </div>
              </div>

              <div class="space-y-3">
                <%= for {step, i} <- Enum.with_index(@flow_steps) do %>
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
              <%= if @flow_step >= length(@flow_steps) do %>
                <div class={["mt-4 p-4 rounded-lg border-2",
                  if(@signature_valid,
                    do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
                    else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
                ]}>
                  <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm">
                    <pre class={["whitespace-pre-wrap", if(@signature_valid, do: "text-emerald-400", else: "text-red-400")]}><%= if @signature_valid do %>{"HTTP/1.1 200 OK\nContent-Type: application/json\n\n{\"status\": \"received\"}"}<% else %>{"HTTP/1.1 401 Unauthorized\nContent-Type: application/json\n\n{\"error\": \"Invalid webhook signature\"}"}<% end %></pre>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>

          <!-- Best Practices -->
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Webhook Best Practices</h4>
            <ul class="text-sm text-rose-700 dark:text-rose-400 space-y-1">
              <li>1. Always verify signatures using <code>Plug.Crypto.secure_compare/2</code> (timing-safe)</li>
              <li>2. Process asynchronously -- respond 200 immediately, then handle in a background job</li>
              <li>3. Implement idempotency -- webhooks may be sent more than once</li>
              <li>4. Store the raw payload for debugging and replay</li>
            </ul>
          </div>
        <% end %>
      <% end %>

      <!-- Sending Webhooks Tab -->
      <%= if @active_tab == "sending" do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Sending Webhooks to Subscribers</h3>
          <p class="text-gray-600 dark:text-gray-300 mb-4">
            When an event occurs in your system, you send a POST to each registered webhook endpoint.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
              <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">1. Event Occurs</h4>
              <p class="text-sm text-rose-700 dark:text-rose-400">
                Something happens in your app (payment, signup, etc.).
                The context module calls <code>Webhooks.send_event/2</code>.
              </p>
            </div>
            <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
              <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">2. Build & Sign</h4>
              <p class="text-sm text-rose-700 dark:text-rose-400">
                JSON-encode the payload with event name and timestamp.
                Sign with HMAC-SHA256 using the endpoint's secret.
              </p>
            </div>
            <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
              <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">3. Deliver</h4>
              <p class="text-sm text-rose-700 dark:text-rose-400">
                POST to each subscriber's URL with signature header.
                Retry on failure with exponential backoff.
              </p>
            </div>
          </div>

          <!-- Example Payload -->
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
            <div class="text-gray-400">{"# Outgoing webhook POST:"}</div>
            <div class="text-blue-400">POST https://customer.example.com/webhooks</div>
            <div class="text-purple-400">Content-Type: application/json</div>
            <div class="text-purple-400">X-Webhook-Signature: hmac_sha256_hex</div>
            <div class="text-gray-400 mt-2">{"# Body:"}</div>
            <pre class="text-emerald-400 whitespace-pre-wrap">{"{\n  \"event\": \"payment.completed\",\n  \"data\": {\n    \"amount\": 9900,\n    \"currency\": \"usd\",\n    \"customer_id\": \"cus_abc123\"\n  },\n  \"timestamp\": \"2025-01-15T10:30:00Z\"\n}"}</pre>
          </div>
        </div>

        <!-- Retry Strategy -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Retry Strategy (Exponential Backoff)</h3>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-200 dark:border-gray-700">
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Attempt</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Delay</th>
                  <th class="text-left py-2 px-3 font-semibold text-gray-700 dark:text-gray-300">Cumulative</th>
                </tr>
              </thead>
              <tbody>
                <tr class="border-b border-gray-100 dark:border-gray-800">
                  <td class="py-2 px-3 text-gray-900 dark:text-white">1</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">immediate</td>
                  <td class="py-2 px-3 text-gray-500">0s</td>
                </tr>
                <tr class="border-b border-gray-100 dark:border-gray-800">
                  <td class="py-2 px-3 text-gray-900 dark:text-white">2</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">1 minute</td>
                  <td class="py-2 px-3 text-gray-500">1m</td>
                </tr>
                <tr class="border-b border-gray-100 dark:border-gray-800">
                  <td class="py-2 px-3 text-gray-900 dark:text-white">3</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">5 minutes</td>
                  <td class="py-2 px-3 text-gray-500">6m</td>
                </tr>
                <tr class="border-b border-gray-100 dark:border-gray-800">
                  <td class="py-2 px-3 text-gray-900 dark:text-white">4</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">30 minutes</td>
                  <td class="py-2 px-3 text-gray-500">36m</td>
                </tr>
                <tr>
                  <td class="py-2 px-3 text-gray-900 dark:text-white">5</td>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">2 hours</td>
                  <td class="py-2 px-3 text-gray-500">2h 36m</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
          <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Use Oban for Webhook Delivery</h4>
          <p class="text-sm text-rose-700 dark:text-rose-400">
            Use <code>Oban</code> for reliable webhook delivery. It handles retries, backoff, and dead-lettering.
            Enqueue a webhook job instead of sending inline, so your API response is not blocked by delivery.
          </p>
        </div>
      <% end %>

      <!-- OpenAPI Tab -->
      <%= if @active_tab == "openapi" do %>
        <!-- Section Selector -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">OpenAPI Spec Structure</h3>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <%= for section <- @openapi_sections do %>
              <button
                phx-click="select_openapi_section"
                phx-value-id={section.id}
                phx-target={@myself}
                class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
                  if(@selected_openapi_section && @selected_openapi_section.id == section.id,
                    do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                    else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
                ]}
              >
                <div class="font-semibold text-sm text-gray-900 dark:text-white">{section.name}</div>
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{section.description}</p>
              </button>
            <% end %>
          </div>
        </div>

        <!-- Selected Section Detail -->
        <%= if @selected_openapi_section do %>
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">{@selected_openapi_section.name}</h3>
            <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
              <pre class="text-sm text-gray-100 whitespace-pre-wrap">{openapi_section_code(@selected_openapi_section.id)}</pre>
            </div>
          </div>
        <% end %>

        <!-- Phoenix + OpenApiSpex -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Phoenix + OpenApiSpex</h3>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
              <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">1. Define Schemas</h4>
              <p class="text-sm text-rose-700 dark:text-rose-400">
                Create schema modules using <code>OpenApiSpex.schema/1</code>.
                These define your request/response data models.
              </p>
            </div>
            <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
              <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">2. Annotate Controllers</h4>
              <p class="text-sm text-rose-700 dark:text-rose-400">
                Use <code>operation/2</code> macros in controllers to describe
                each endpoint's parameters, request body, and responses.
              </p>
            </div>
            <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
              <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">3. Serve the Spec</h4>
              <p class="text-sm text-rose-700 dark:text-rose-400">
                Mount <code>OpenApiSpex.Plug.RenderSpec</code> at <code>/api/openapi</code>.
                Use SwaggerUI plug for interactive docs.
              </p>
            </div>
          </div>
        </div>

        <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
          <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Spec-First vs Code-First</h4>
          <p class="text-sm text-rose-700 dark:text-rose-400">
            <strong>Spec-first:</strong> Write the OpenAPI YAML/JSON first, then generate code stubs.
            <strong>Code-first:</strong> Annotate Phoenix controllers, generate the spec from code (OpenApiSpex).
            Code-first is more common in Phoenix -- the spec stays in sync with your actual controller code.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab, selected_event: nil, signature_valid: nil, flow_step: 0, flow_steps: [], selected_openapi_section: nil)}
  end

  def handle_event("select_event", %{"id" => id}, socket) do
    event = Enum.find(@webhook_events, &(&1.id == id))
    {:noreply, assign(socket, selected_event: event, signature_valid: nil, flow_step: 0, flow_steps: [])}
  end

  def handle_event("verify_signature", %{"valid" => valid_str}, socket) do
    valid = valid_str == "true"
    steps = build_webhook_flow(socket.assigns.selected_event, valid)
    {:noreply, assign(socket, signature_valid: valid, flow_steps: steps, flow_step: 0)}
  end

  def handle_event("next_flow_step", _params, socket) do
    max = length(socket.assigns.flow_steps)
    new_step = min(socket.assigns.flow_step + 1, max)
    {:noreply, assign(socket, flow_step: new_step)}
  end

  def handle_event("reset_flow", _params, socket) do
    {:noreply, assign(socket, flow_step: 0)}
  end

  def handle_event("select_openapi_section", %{"id" => id}, socket) do
    section = Enum.find(@openapi_sections, &(&1.id == id))
    {:noreply, assign(socket, selected_openapi_section: section)}
  end

  defp build_webhook_flow(event, valid_signature) do
    base_steps = [
      %{
        label: "Incoming POST",
        code: "POST /webhooks/#{event.name}",
        detail: "External service sends a webhook POST to your endpoint.",
        status: :ok
      },
      %{
        label: "Read Body",
        code: "read_body(conn)",
        detail: "Read the raw request body for signature verification.",
        status: :ok
      },
      %{
        label: "Verify Signature",
        code: "HMAC-SHA256(secret, body) == X-Webhook-Signature",
        detail:
          if(valid_signature,
            do: "Signature matches -- webhook is authentic.",
            else: "Signature does NOT match -- webhook may be forged!"
          ),
        status: if(valid_signature, do: :ok, else: :error)
      }
    ]

    if valid_signature do
      base_steps ++
        [
          %{
            label: "Parse Event",
            code: "event = params[\"event\"]  # \"#{event.name}\"",
            detail: "Extract event type and payload from JSON body.",
            status: :ok
          },
          %{
            label: "Process Async",
            code: "Webhooks.process_async(\"#{event.name}\", payload)",
            detail: "Enqueue for background processing (Oban job). Respond immediately.",
            status: :ok
          },
          %{
            label: "Respond 200",
            code: "json(conn, %{status: \"received\"})",
            detail: "Return 200 OK to acknowledge receipt.",
            status: :ok
          }
        ]
    else
      base_steps ++
        [
          %{
            label: "Reject",
            code: "put_status(conn, 401) |> json(%{error: \"Invalid signature\"})",
            detail: "Return 401 Unauthorized. Do NOT process the payload.",
            status: :error
          }
        ]
    end
  end

  defp openapi_section_code("info") do
    """
    openapi: "3.0.3"
    info:
      title: "MyApp API"
      version: "1.0.0"
      description: "A RESTful API built with Phoenix"
      contact:
        email: "api@myapp.com"
    servers:
      - url: "https://api.myapp.com/v1"
        description: "Production"
      - url: "https://staging-api.myapp.com/v1"
        description: "Staging"\
    """
  end

  defp openapi_section_code("paths") do
    """
    paths:
      /posts:
        get:
          summary: "List all posts"
          tags: [Posts]
          parameters:
            - name: page
              in: query
              schema:
                type: integer
                default: 1
          responses:
            200:
              description: "A list of posts"
              content:
                application/json:
                  schema:
                    $ref: "#/components/schemas/PostList"
        post:
          summary: "Create a post"
          tags: [Posts]
          requestBody:
            required: true
            content:
              application/json:
                schema:
                  $ref: "#/components/schemas/PostParams"
          responses:
            201:
              description: "Created"
            422:
              description: "Validation errors"\
    """
  end

  defp openapi_section_code("schemas") do
    """
    components:
      schemas:
        Post:
          type: object
          required: [title]
          properties:
            id:
              type: integer
              readOnly: true
            title:
              type: string
              minLength: 1
            body:
              type: string
            inserted_at:
              type: string
              format: date-time
        PostParams:
          type: object
          required: [title]
          properties:
            title:
              type: string
            body:
              type: string
        PostList:
          type: object
          properties:
            data:
              type: array
              items:
                $ref: "#/components/schemas/Post"\
    """
  end

  defp openapi_section_code("security") do
    """
    components:
      securitySchemes:
        bearerAuth:
          type: http
          scheme: bearer
          bearerFormat: JWT
        apiKeyAuth:
          type: apiKey
          in: header
          name: X-API-Key
        oauth2:
          type: oauth2
          flows:
            authorizationCode:
              authorizationUrl: https://auth.myapp.com/authorize
              tokenUrl: https://auth.myapp.com/token
              scopes:
                read: Read access
                write: Write access
    # Apply globally:
    security:
      - bearerAuth: []\
    """
  end
end
