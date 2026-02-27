# Kata 15: Rate Limiting

## Core Concept

Rate limiting controls how many requests a client can make to your API within a time window. It protects your server from abuse, ensures fair usage, and prevents a single client from monopolizing resources.

The most common algorithm is the **token bucket**: each client gets a bucket of N tokens per time window. Each request consumes one token. When the bucket is empty, requests are rejected with `429 Too Many Requests`.

---

## Hammer: Elixir Rate Limiter

Hammer is the go-to rate limiting library for Elixir. It supports pluggable backends (ETS, Mnesia, Redis).

### Installation

```elixir
# mix.exs
defp deps do
  [
    {:hammer, "~> 6.1"},
    {:hammer_backend_mnesia, "~> 0.6"}
  ]
end

# config/config.exs
config :hammer,
  backend: {Hammer.Backend.Mnesia, [expiry_ms: 60_000 * 60]}
```

### Basic Usage

```elixir
case Hammer.check_rate("user:#{user_id}", 60_000, 100) do
  {:allow, count} ->
    # count is how many requests have been made in this window
    remaining = 100 - count
    # proceed...

  {:deny, _limit} ->
    # rate limit exceeded
    # return 429
end
```

---

## Rate Limit Plug

```elixir
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

  def call(conn, %{limit: limit, window_ms: window_ms, by: by}) do
    key = build_key(conn, by)

    case Hammer.check_rate(key, window_ms, limit) do
      {:allow, count} ->
        remaining = limit - count

        conn
        |> put_resp_header("x-ratelimit-limit", to_string(limit))
        |> put_resp_header("x-ratelimit-remaining", to_string(remaining))
        |> put_resp_header("x-ratelimit-reset", to_string(div(window_ms, 1000)))

      {:deny, _limit} ->
        conn
        |> put_status(429)
        |> put_resp_header("retry-after", to_string(div(window_ms, 1000)))
        |> Phoenix.Controller.json(%{errors: %{detail: "Rate limit exceeded"}})
        |> halt()
    end
  end

  defp build_key(conn, :ip) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    "rate:ip:#{ip}"
  end

  defp build_key(conn, :api_key) do
    "rate:key:#{conn.assigns[:api_key_id] || "anon"}"
  end
end
```

---

## Rate Limit Headers

Always include these headers in API responses:

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Maximum requests allowed in the window |
| `X-RateLimit-Remaining` | Requests remaining in current window |
| `X-RateLimit-Reset` | Seconds until the window resets |
| `Retry-After` | Only on 429 responses -- when to retry |

---

## Per-IP vs Per-API-Key

### Per-IP Address
- Simple, works without authentication
- Good for public endpoints
- Problem: users behind NAT/VPN share a bucket
- Easy to bypass with rotating IPs

### Per-API Key
- Fair per-consumer limiting
- Supports per-plan rate limits (free: 100/min, pro: 1000/min)
- Tracks usage per application
- Requires authentication first

### Hybrid Approach
Use per-IP for unauthenticated endpoints and per-API-key for authenticated ones:

```elixir
pipeline :public_rate_limit do
  plug MyAppWeb.Plugs.RateLimit, limit: 30, window_ms: 60_000, by: :ip
end

pipeline :auth_rate_limit do
  plug MyAppWeb.Plugs.RateLimit, limit: 100, window_ms: 60_000, by: :api_key
end
```

---

## Best Practices

1. **Always return rate limit headers** so clients can self-throttle
2. **Use different limits for different endpoints** -- reads vs writes
3. **Include `Retry-After` on 429 responses**
4. **Use Redis backend in production** for distributed rate limiting across nodes
5. **Log rate limit hits** for monitoring and abuse detection
6. **Consider sliding windows** instead of fixed windows to prevent burst at window boundaries

---

## Common Pitfalls

- **Fixed window boundary burst**: A client can make 100 requests at 0:59 and 100 more at 1:00. Use sliding windows to mitigate.
- **Not rate limiting error responses**: Failed requests should still count against the limit.
- **Forgetting distributed systems**: ETS-based rate limiting doesn't work across multiple nodes. Use Redis or Mnesia.
- **Too aggressive limits**: Start generous, tighten based on actual usage data.
- **No differentiation**: Apply stricter limits to write endpoints than read endpoints.
