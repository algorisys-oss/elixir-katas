# Kata 08: API Keys

## API Keys vs Tokens

| Aspect        | API Key                     | Bearer Token (JWT)             |
|---------------|-----------------------------|--------------------------------|
| Identifies    | The **application**         | The **user**                   |
| Purpose       | Rate limiting, billing      | Authentication, authorization  |
| Lifespan      | Long-lived (months/years)   | Short-lived (minutes/hours)    |
| Revocation    | Delete from database        | Wait for expiry or use denylist |
| Rotation      | Issue new key, deprecate old | Refresh token flow             |
| In header     | `X-API-Key: ak_...`        | `Authorization: Bearer eyJ...` |

Many APIs use both: an API key for the calling application plus a Bearer token for the user session.

---

## Sending API Keys

### 1. Custom Header (Recommended)

```
X-API-Key: ak_prod_abc123def456
```

```elixir
defp extract_key(conn) do
  case get_req_header(conn, "x-api-key") do
    [key | _] -> {:ok, key}
    [] -> {:error, :missing_key}
  end
end
```

**Why recommended?**
- Not logged in URL/query strings
- Not cached by browsers or proxies
- Clear separation from auth tokens

### 2. Query Parameter (Avoid)

```
GET /api/users?api_key=ak_prod_abc123def456
```

**Problems:**
- Appears in server logs, browser history, referrer headers
- Can be cached by CDNs and proxies
- Only use for quick testing or webhook callbacks

### 3. Bearer Token Style

```
Authorization: Bearer ak_prod_abc123def456
```

Works but conflates app identification with user authentication. Better to keep them separate.

---

## Generating Secure API Keys

```elixir
defmodule MyApp.ApiKeys do
  @doc "Generate a cryptographically secure API key with prefix"
  def generate(prefix \\ "ak") do
    random = :crypto.strong_rand_bytes(24)
    encoded = Base.url_encode64(random, padding: false)
    "#{prefix}_#{encoded}"
  end
end
```

### Key Format Best Practices

```
ak_prod_Xk9mP2qR7vLwN3tF8bYj...
│  │     └─ random bytes (base64url)
│  └─ environment prefix
└─ type prefix
```

- **Prefix**: Makes keys recognizable (`ak_` = API key, `sk_` = secret key)
- **Environment**: `prod_`, `stg_`, `test_` helps prevent accidental misuse
- **Random part**: At least 24 bytes (192 bits) of randomness from `:crypto.strong_rand_bytes/1`
- **No padding**: Use `padding: false` in Base64 encoding for cleaner URLs

### Storing Keys Securely

```elixir
# Store a HASH of the key, not the key itself
defmodule MyApp.ApiKeys do
  def create_key(attrs) do
    key = generate()
    hash = :crypto.hash(:sha256, key)

    %ApiKey{}
    |> ApiKey.changeset(Map.merge(attrs, %{
      key_prefix: String.slice(key, 0, 12),  # for display
      key_hash: hash                           # for lookup
    }))
    |> Repo.insert()
    |> case do
      {:ok, api_key} -> {:ok, api_key, key}  # return raw key once
      error -> error
    end
  end

  def verify_key(raw_key) do
    hash = :crypto.hash(:sha256, raw_key)
    Repo.get_by(ApiKey, key_hash: hash)
  end
end
```

---

## Key Rotation

Rotation lets you replace keys without downtime:

```elixir
# 1. Generate a new key
{:ok, api_key, new_raw_key} = ApiKeys.create_key(%{
  app_id: app.id,
  name: "Production Key v2"
})

# 2. Client starts using new key

# 3. Monitor: is the old key still being used?
old_key = Repo.get!(ApiKey, old_key_id)
if old_key.last_used_at < DateTime.add(DateTime.utc_now(), -7, :day) do
  # Old key unused for 7 days — safe to revoke
  ApiKeys.revoke(old_key)
end
```

### Graceful Rotation Pattern

1. Generate new key
2. Both old and new keys work simultaneously
3. Deploy client with new key
4. Monitor old key usage
5. Revoke old key after grace period

---

## Per-Key Rate Limiting

Each API key can have its own rate limit:

```elixir
defmodule MyApp.RateLimiter do
  @doc "Check and increment the request count for an API key"
  def check_and_increment(api_key_id, limit) do
    key = "rate:#{api_key_id}:#{current_window()}"

    case MyApp.Cache.get(key) do
      nil ->
        MyApp.Cache.put(key, 1, ttl: 60_000)  # 1 minute window
        {:ok, limit - 1}

      count when count < limit ->
        MyApp.Cache.increment(key)
        {:ok, limit - count - 1}

      _count ->
        {:error, :rate_limited}
    end
  end

  defp current_window do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> then(&div(DateTime.to_unix(&1), 60))  # 1-minute windows
  end
end
```

### Rate Limit Headers

Always include rate limit information in responses:

```elixir
conn
|> put_resp_header("x-rate-limit-limit", to_string(api_key.rate_limit))
|> put_resp_header("x-rate-limit-remaining", to_string(remaining))
|> put_resp_header("x-rate-limit-reset", to_string(reset_time))
```

---

## API Key Plug

```elixir
defmodule MyAppWeb.Plugs.VerifyApiKey do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, raw_key} <- extract_key(conn),
         %ApiKey{status: :active} = api_key <- ApiKeys.verify_key(raw_key),
         {:ok, remaining} <- RateLimiter.check_and_increment(api_key.id, api_key.rate_limit) do
      conn
      |> assign(:api_key, api_key)
      |> put_resp_header("x-rate-limit-remaining", to_string(remaining))
    else
      {:error, :missing_key} ->
        conn |> put_status(401) |> json_error("API key required") |> halt()
      {:error, :rate_limited} ->
        conn |> put_status(429) |> put_resp_header("retry-after", "60")
        |> json_error("Rate limit exceeded") |> halt()
      %ApiKey{status: :revoked} ->
        conn |> put_status(401) |> json_error("API key revoked") |> halt()
      nil ->
        conn |> put_status(401) |> json_error("Invalid API key") |> halt()
    end
  end

  defp extract_key(conn) do
    case get_req_header(conn, "x-api-key") do
      [key | _] -> {:ok, key}
      [] -> {:error, :missing_key}
    end
  end

  defp json_error(conn, msg) do
    Phoenix.Controller.json(conn, %{errors: %{detail: msg}})
  end
end
```

---

## Testing API Keys

```elixir
defmodule MyAppWeb.Plugs.VerifyApiKeyTest do
  use MyAppWeb.ConnCase

  test "allows request with valid API key" do
    {api_key, raw_key} = create_api_key()

    conn =
      build_conn()
      |> put_req_header("x-api-key", raw_key)
      |> VerifyApiKey.call([])

    assert conn.assigns.api_key.id == api_key.id
    refute conn.halted
  end

  test "rejects request without API key" do
    conn = build_conn() |> VerifyApiKey.call([])
    assert conn.status == 401
    assert conn.halted
  end

  test "rejects revoked key" do
    {_api_key, raw_key} = create_api_key(status: :revoked)

    conn =
      build_conn()
      |> put_req_header("x-api-key", raw_key)
      |> VerifyApiKey.call([])

    assert conn.status == 401
  end
end
```
