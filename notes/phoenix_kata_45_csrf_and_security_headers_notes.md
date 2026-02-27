# Kata 45: CSRF & Security Headers

## What is CSRF?

**Cross-Site Request Forgery (CSRF)** tricks a logged-in user into submitting a request to a site they did not intend to:

```
1. Victim is logged in to bank.com (session cookie is set)
2. Victim visits evil.com
3. evil.com contains a hidden form that POSTs to bank.com/transfer
4. Browser automatically sends the bank.com session cookie with the request
5. Bank processes the transfer as if the user requested it!
```

CSRF only works when:
- Authentication uses cookies (automatically sent by the browser)
- The server does not verify that the request originated from its own pages

**JSON APIs using `Authorization: Bearer <token>` headers are NOT vulnerable** to CSRF because browsers never auto-add custom headers on cross-origin requests.

---

## Phoenix's CSRF Protection

The `protect_from_forgery` plug is included in the `:browser` pipeline by default:

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {Layouts, :root}
  plug :protect_from_forgery   # <-- CSRF protection
  plug :put_secure_browser_headers
end
```

**How it works:**
1. Generates a unique CSRF token per session
2. Embeds it in all forms as a hidden `_csrf_token` field (done automatically by `<.form>`)
3. On every POST/PUT/PATCH/DELETE request, verifies that the token is present and correct
4. Rejects requests where the token is missing or does not match

Phoenix forms automatically include the token:

```html
<!-- The <.form> component generates this hidden input: -->
<input type="hidden" name="_csrf_token" value="ZHVtbXkgdG9rZW4...">
```

---

## Using CSRF Tokens Manually

Sometimes you need the token outside of Phoenix forms:

```elixir
# Get the current CSRF token:
Phoenix.Controller.get_csrf_token()
# => "ZHVtbXkgdG9rZW4..."
```

### In non-Phoenix HTML forms:

```html
<form method="POST" action="/transfer">
  <input type="hidden" name="_csrf_token"
         value={Phoenix.Controller.get_csrf_token()} />
  <button type="submit">Transfer</button>
</form>
```

### In AJAX/fetch requests:

```html
<!-- In the layout, add a meta tag: -->
<meta name="csrf-token" content={get_csrf_token()} />
```

```javascript
// In JavaScript, read the meta tag and send as header:
const token = document.querySelector('meta[name="csrf-token"]')
              .getAttribute("content");

fetch("/api/action", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "x-csrf-token": token
  },
  body: JSON.stringify({amount: 100})
});
```

Phoenix checks both `_csrf_token` (form body field) and `x-csrf-token` (HTTP header) for the token.

---

## Security Headers

`put_secure_browser_headers/2` adds several important HTTP response headers automatically:

| Header | Default Value | Purpose |
|--------|---------------|---------|
| `x-frame-options` | `SAMEORIGIN` | Prevents clickjacking via iframes |
| `x-content-type-options` | `nosniff` | Prevents MIME-type sniffing attacks |
| `x-xss-protection` | `1; mode=block` | Legacy IE/Chrome XSS filter |
| `x-download-options` | `noopen` | Prevents IE from auto-executing downloads |
| `x-permitted-cross-domain-policies` | `none` | Blocks Flash/PDF cross-domain requests |
| `referrer-policy` | `strict-origin-when-cross-origin` | Controls Referer header sent to other sites |
| `cross-origin-window-policy` | `deny` | Prevents cross-origin window access |

These are set in the router pipeline:

```elixir
pipeline :browser do
  # ... other plugs
  plug :put_secure_browser_headers   # sets all the above!
end
```

---

## Custom Security Headers

Add or override headers via the map argument:

```elixir
plug :put_secure_browser_headers, %{
  "content-security-policy" => "default-src 'self'",
  "permissions-policy" => "camera=(), microphone=(), geolocation=()",
  "referrer-policy" => "no-referrer"
}
```

Or add headers manually in a custom plug:

```elixir
def set_security_headers(conn, _opts) do
  conn
  |> put_resp_header("strict-transport-security",
       "max-age=31536000; includeSubDomains")
  |> put_resp_header("permissions-policy",
       "camera=(), microphone=(), geolocation=()")
end
```

---

## Content Security Policy (CSP)

CSP is an HTTP header that tells the browser which sources of content are trusted. It is the strongest defense against XSS attacks:

```elixir
plug :put_secure_browser_headers, %{
  "content-security-policy" =>
    "default-src 'self'; " <>
    "script-src 'self'; " <>
    "style-src 'self' 'unsafe-inline'; " <>
    "img-src 'self' data: https:; " <>
    "font-src 'self'; " <>
    "connect-src 'self' wss://myapp.com"
}
```

### CSP Directives

| Directive | Purpose | Example |
|-----------|---------|---------|
| `default-src` | Fallback for all resource types | `'self'` |
| `script-src` | Where JavaScript can load from | `'self' 'nonce-abc123'` |
| `style-src` | Where CSS can load from | `'self' 'unsafe-inline'` |
| `img-src` | Where images can load from | `'self' data: https:` |
| `font-src` | Where fonts can load from | `'self' https://fonts.gstatic.com` |
| `connect-src` | Where XHR/WebSocket can connect | `'self' wss://myapp.com` |
| `frame-src` | Where iframes can load from | `'none'` |
| `object-src` | Where plugins (Flash) can load from | `'none'` |

### Testing CSP with Report-Only

Before enforcing CSP, test it in report-only mode:

```http
Content-Security-Policy-Report-Only: default-src 'self'; script-src 'self'
```

This logs violations to the browser console without actually blocking anything. Once you are confident there are no false positives, switch to the enforcing header.

---

## CSP Nonce for Inline Scripts

If you need inline scripts (common with LiveView), use a per-request nonce:

```elixir
# Custom plug to generate a nonce:
def put_csp_nonce(conn, _opts) do
  nonce = :crypto.strong_rand_bytes(16) |> Base.encode64()

  conn
  |> assign(:csp_nonce, nonce)
  |> put_resp_header(
       "content-security-policy",
       "default-src 'self'; script-src 'self' 'nonce-#{nonce}'"
     )
end
```

In the layout template:

```html
<script nonce={@csp_nonce}>
  // This inline script is allowed because it has the correct nonce
  console.log("Hello from inline script");
</script>
```

Phoenix LiveView uses a nonce internally for its scripts.

---

## Force HTTPS

Always enforce HTTPS in production:

```elixir
# config/prod.exs or config/runtime.exs:
config :my_app, MyAppWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]]
```

This adds the `Plug.SSL` plug which checks `X-Forwarded-Proto`, redirects HTTP to HTTPS with a 301, and adds the `Strict-Transport-Security` header.

---

## HSTS (HTTP Strict Transport Security)

```http
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
```

HSTS tells browsers to **only** connect via HTTPS for the specified duration. Once a browser receives this header:
- All future requests to the domain use HTTPS automatically
- Even if the user types `http://` in the address bar
- Even if a link points to `http://`

```elixir
plug :put_secure_browser_headers, %{
  "strict-transport-security" =>
    "max-age=63072000; includeSubDomains; preload"
}
```

- `63072000` seconds = 2 years (recommended by OWASP)
- `includeSubDomains` — applies HSTS to all subdomains
- `preload` — allows submission to browser preload lists (Chrome, Firefox ship with a list of HSTS domains)

---

## OWASP Top 10 and Phoenix

The OWASP Top 10 is a standard list of the most critical web application security risks. Here is how Phoenix addresses each:

| OWASP Risk | Phoenix Defense |
|------------|-----------------|
| **A01: Broken Access Control** | Authorization plugs + scope queries (Kata 44) |
| **A02: Cryptographic Failures** | `secret_key_base` for signing, Bcrypt/Argon2 for passwords |
| **A03: Injection (SQL)** | Ecto parameterized queries — automatic |
| **A03: Injection (XSS)** | HEEx auto-escapes all output — automatic |
| **A04: Insecure Design** | Use `gen.auth`, do not build auth from scratch |
| **A05: Security Misconfiguration** | `runtime.exs` + environment variables for secrets |
| **A07: Auth Failures** | Rate-limit logins, `configure_session(renew: true)` |

### Ecto Prevents SQL Injection

```elixir
# SAFE: Ecto parameterizes the query automatically
from u in User, where: u.email == ^email

# DANGEROUS: string interpolation in fragment — never do this
from u in User, where: fragment("email = '#{email}'")
```

### HEEx Prevents XSS

```html
<!-- SAFE: auto-escaped by HEEx -->
<p>{@user_input}</p>
<!-- If user_input is "<script>alert('xss')</script>", it renders as text -->

<!-- DANGEROUS: only use raw/1 with trusted HTML you generated yourself -->
<p>{raw(@trusted_html)}</p>
```

---

## Rate Limiting

Protect login, registration, and password reset endpoints from brute-force attacks:

```elixir
defmodule MyAppWeb.Plugs.RateLimit do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    max = Keyword.get(opts, :max, 100)
    per = Keyword.get(opts, :per, 60_000)   # milliseconds
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    key = "rate_limit:#{ip}:#{conn.request_path}"

    case Hammer.check_rate(key, per, max) do
      {:allow, _count} ->
        conn
      {:deny, _limit} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(429, "Too many requests. Please try again later.")
        |> halt()
    end
  end
end
```

Usage in the router:

```elixir
# Apply to login route:
scope "/", MyAppWeb do
  pipe_through [:browser, MyAppWeb.Plugs.RateLimit]
  post "/users/log_in", UserSessionController, :create
end
```

Add `{:hammer, "~> 6.0"}` to your `mix.exs` dependencies.

---

## Key Takeaways

1. **CSRF protection** is automatic via `protect_from_forgery` — never remove it from the browser pipeline
2. **Security headers** are set automatically by `put_secure_browser_headers` — they protect against clickjacking, MIME sniffing, and more
3. **CSP** is the strongest XSS defense — start with `report-only` mode before enforcing
4. **Force HTTPS** in production with `force_ssl: [rewrite_on: [:x_forwarded_proto]]`
5. **Ecto** prevents SQL injection automatically via parameterized queries
6. **HEEx** prevents XSS automatically via output escaping — avoid `raw/1` with user input
7. Add **rate limiting** to login, registration, and password reset endpoints
8. Never commit **secrets** to version control — use `runtime.exs` and environment variables
9. **HSTS** ensures browsers always use HTTPS — set `max-age` to at least 1 year in production
