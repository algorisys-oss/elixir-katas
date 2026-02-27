# Kata 16: CORS & Security Headers

## Core Concept

**CORS** (Cross-Origin Resource Sharing) is a browser security mechanism that controls which domains can call your API from JavaScript. **Security headers** are HTTP response headers that instruct browsers to enable additional protections against common web attacks.

CORS is enforced by the _browser_, not the server. Server-to-server calls (curl, Postman, backend services) ignore CORS entirely.

---

## How CORS Works

### Simple Requests (No Preflight)
GET and POST with standard headers go directly:
```
Browser → GET /api/posts (Origin: https://myapp.com) → Server
Server → 200 OK (Access-Control-Allow-Origin: https://myapp.com) → Browser
```

### Preflighted Requests
PUT, DELETE, PATCH, or custom headers trigger a preflight OPTIONS request first:
```
Browser → OPTIONS /api/posts (Origin, Access-Control-Request-Method: PUT) → Server
Server → 204 (CORS headers) → Browser
Browser → PUT /api/posts (actual request) → Server
Server → 200 OK → Browser
```

---

## CORSPlug Configuration

```elixir
# mix.exs
defp deps do
  [{:cors_plug, "~> 3.0"}]
end

# In your endpoint or router:
plug CORSPlug,
  origin: ["https://myapp.com", "https://admin.myapp.com"],
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  headers: ["Authorization", "Content-Type", "X-API-Key"],
  max_age: 3600,
  credentials: true
```

### Key Options

| Option | Description |
|--------|-------------|
| `origin` | List of allowed origins, or `"*"` for any (not recommended with credentials) |
| `methods` | HTTP methods the client is allowed to use |
| `headers` | Request headers the client is allowed to send |
| `max_age` | How long (seconds) the browser caches the preflight response |
| `credentials` | Whether cookies/auth headers are allowed in cross-origin requests |

---

## Custom CORS Plug

```elixir
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
      |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE")
      |> put_resp_header("access-control-allow-headers", "Authorization, Content-Type")
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
```

---

## Security Headers

| Header | Value | Purpose |
|--------|-------|---------|
| `Content-Security-Policy` | `default-src 'self'` | Controls which resources the browser can load |
| `X-Frame-Options` | `DENY` | Prevents clickjacking via iframes |
| `X-Content-Type-Options` | `nosniff` | Prevents MIME-type sniffing |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Forces HTTPS |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Controls referrer information |
| `X-XSS-Protection` | `1; mode=block` | Legacy XSS filter (CSP is preferred) |

### Security Headers Plug

```elixir
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
```

---

## Best Practices

1. **Never use `origin: "*"` with credentials** -- browsers reject this combination
2. **Validate origins against a whitelist**, not a pattern (avoid regex pitfalls)
3. **Set security headers at the Endpoint level** so every response includes them
4. **Use `max_age` for preflight caching** to reduce OPTIONS request overhead
5. **Don't expose unnecessary headers** in `Access-Control-Expose-Headers`
6. **Test CORS from an actual browser** -- curl won't enforce CORS policies

---

## Common Pitfalls

- **Wildcard with credentials**: `Access-Control-Allow-Origin: *` cannot be used with `Access-Control-Allow-Credentials: true`. The browser will reject the response.
- **Forgetting OPTIONS routes**: Some frameworks don't automatically handle OPTIONS. Phoenix with CORSPlug handles this.
- **CORS on error responses**: Make sure CORS headers are set even on 4xx/5xx responses, otherwise the browser hides the error details.
- **Subdomain confusion**: `https://myapp.com` and `https://www.myapp.com` are different origins.
- **CSP too restrictive**: Start with `Content-Security-Policy-Report-Only` to test before enforcing.
