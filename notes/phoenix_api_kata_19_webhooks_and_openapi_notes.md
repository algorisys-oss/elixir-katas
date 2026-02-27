# Kata 19: Webhooks & OpenAPI

## Core Concepts

**Webhooks** are HTTP callbacks -- when an event happens in one system, it sends a POST request to a URL registered by another system. They enable real-time, event-driven integrations without polling.

**OpenAPI** (formerly Swagger) is a specification for describing REST APIs. It defines endpoints, request/response schemas, authentication methods, and more in a machine-readable format (YAML or JSON).

---

## Receiving Webhooks

### Webhook Controller

```elixir
defmodule MyAppWeb.WebhookController do
  use MyAppWeb, :controller

  @webhook_secret Application.compile_env(:my_app, :webhook_secret)

  def handle(conn, params) do
    with {:ok, body, conn} <- read_body(conn),
         :ok <- verify_signature(conn, body) do
      event = params["event"]
      payload = params["data"]

      # Process asynchronously -- respond immediately
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

    expected =
      :crypto.mac(:hmac, :sha256, @webhook_secret, body)
      |> Base.encode16(case: :lower)

    if Plug.Crypto.secure_compare(signature, expected) do
      :ok
    else
      {:error, :invalid_signature}
    end
  end
end
```

### Router Setup

```elixir
# In router.ex -- webhook routes skip CSRF and standard auth
scope "/webhooks", MyAppWeb do
  pipe_through :api  # no :browser pipeline, no CSRF

  post "/stripe", WebhookController, :handle
  post "/github", WebhookController, :handle
end
```

---

## Signature Verification (HMAC-SHA256)

Webhook signatures prove the request came from the expected sender:

1. The sender computes `HMAC-SHA256(shared_secret, request_body)`
2. The sender includes this as the `X-Webhook-Signature` header
3. Your server recomputes the HMAC with your copy of the secret
4. If they match, the request is authentic

**Critical:** Use `Plug.Crypto.secure_compare/2` for timing-safe comparison. Regular `==` is vulnerable to timing attacks.

---

## Sending Webhooks

```elixir
defmodule MyApp.Webhooks.Sender do
  def send_event(event, payload) do
    endpoints = MyApp.Webhooks.list_endpoints_for_event(event)

    Enum.each(endpoints, fn endpoint ->
      body = Jason.encode!(%{
        event: event,
        data: payload,
        timestamp: DateTime.utc_now()
      })

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
```

### Retry with Exponential Backoff

Use Oban for reliable delivery:

```elixir
defmodule MyApp.Workers.WebhookDelivery do
  use Oban.Worker, queue: :webhooks, max_attempts: 5

  @impl true
  def perform(%{args: %{"endpoint_id" => id, "event" => event, "payload" => payload}}) do
    endpoint = MyApp.Webhooks.get_endpoint!(id)
    body = Jason.encode!(%{event: event, data: payload})
    signature = sign(body, endpoint.secret)

    case Req.post(endpoint.url, body: body, headers: [{"x-webhook-signature", signature}]) do
      {:ok, %{status: status}} when status in 200..299 -> :ok
      {:ok, resp} -> {:error, "HTTP #{resp.status}"}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

---

## OpenAPI with Phoenix

### OpenApiSpex

```elixir
# mix.exs
defp deps do
  [{:open_api_spex, "~> 3.18"}]
end
```

### Define Schemas

```elixir
defmodule MyApp.Schemas.Post do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Post",
    type: :object,
    required: [:title],
    properties: %{
      id: %Schema{type: :integer, readOnly: true},
      title: %Schema{type: :string, minLength: 1},
      body: %Schema{type: :string},
      inserted_at: %Schema{type: :string, format: :"date-time"}
    }
  })
end
```

### Annotate Controllers

```elixir
defmodule MyAppWeb.Api.PostController do
  use MyAppWeb, :controller
  use OpenApiSpex.ControllerSpecs

  tags ["Posts"]
  security [%{"bearerAuth" => []}]

  operation :index,
    summary: "List all posts",
    parameters: [
      page: [in: :query, type: :integer, description: "Page number"]
    ],
    responses: [
      ok: {"Post list", "application/json", MyApp.Schemas.PostList}
    ]

  def index(conn, params) do
    # ...
  end
end
```

### Serve the Spec

```elixir
# In router.ex
scope "/api" do
  pipe_through :api

  get "/openapi", OpenApiSpex.Plug.RenderSpec, []
end

# For Swagger UI:
scope "/swaggerui" do
  pipe_through :browser
  get "/", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
end
```

---

## Best Practices

### Webhooks
1. **Always verify signatures** -- never trust unverified webhooks
2. **Respond immediately** (200) and process asynchronously
3. **Implement idempotency** -- use event IDs to deduplicate
4. **Store raw payloads** for debugging and replay
5. **Use Oban** for reliable delivery with retries
6. **Log delivery attempts** for troubleshooting

### OpenAPI
1. **Keep schemas in sync with Ecto schemas** -- or generate from them
2. **Use `$ref`** for reusable components
3. **Document error responses** (401, 403, 404, 422)
4. **Version your API** in the spec
5. **Validate requests against the spec** with `OpenApiSpex.Plug.CastAndValidate`

---

## Common Pitfalls

- **Not using `read_body/1` before parsing**: If you verify the signature against the raw body but Phoenix already parsed params, the body may be consumed. Use a custom body reader plug.
- **Trusting webhook payloads without verification**: Treat unverified webhooks as potentially malicious.
- **Synchronous webhook processing**: If processing takes too long, the sender may time out and retry, causing duplicate processing.
- **OpenAPI spec drift**: The spec gets out of date with the actual API. Code-first approach (OpenApiSpex) prevents this.
- **Missing webhook event types**: Document which events you send and which you accept.
