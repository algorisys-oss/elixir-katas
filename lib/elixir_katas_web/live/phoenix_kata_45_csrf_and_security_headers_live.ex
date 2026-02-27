defmodule ElixirKatasWeb.PhoenixKata45CsrfAndSecurityHeadersLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # CSRF & Security Headers

    # --- Router pipeline with all security plugs ---
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {Layouts, :root}
      plug :protect_from_forgery        # CSRF protection
      plug :put_secure_browser_headers, %{
        "content-security-policy" =>
          "default-src 'self'; " <>
          "script-src 'self'; " <>
          "style-src 'self' 'unsafe-inline'; " <>
          "img-src 'self' data: https:; " <>
          "connect-src 'self' wss:",
        "permissions-policy" =>
          "camera=(), microphone=(), geolocation=()"
      }
    end

    # --- CSRF Token in forms ---
    # Phoenix forms auto-include _csrf_token hidden field.
    # For AJAX requests, use the meta tag pattern:
    # <meta name="csrf-token" content={get_csrf_token()} />
    # fetch("/api/action", {
    #   method: "POST",
    #   headers: {"x-csrf-token": token}
    # })

    # --- CSP with nonce for inline scripts ---
    defp put_content_security_policy(conn, _opts) do
      nonce = :crypto.strong_rand_bytes(16) |> Base.encode64()
      conn
      |> assign(:csp_nonce, nonce)
      |> put_resp_header("content-security-policy",
           "default-src 'self'; script-src 'self' 'nonce-\#{nonce}'")
    end

    # --- Default Phoenix security headers ---
    # X-Frame-Options: SAMEORIGIN        (clickjacking)
    # X-Content-Type-Options: nosniff    (MIME sniffing)
    # X-XSS-Protection: 1; mode=block
    # X-Download-Options: noopen
    # X-Permitted-Cross-Domain-Policies: none
    # Referrer-Policy: strict-origin-when-cross-origin

    # --- Force HTTPS in production ---
    config :my_app, MyAppWeb.Endpoint,
      force_ssl: [rewrite_on: [:x_forwarded_proto]]

    # --- HSTS header ---
    plug :put_secure_browser_headers, %{
      "strict-transport-security" =>
        "max-age=63072000; includeSubDomains; preload"
    }

    # --- Rate limiting plug ---
    defmodule MyAppWeb.Plugs.RateLimit do
      import Plug.Conn
      def init(opts), do: opts
      def call(conn, opts) do
        max = Keyword.get(opts, :max, 100)
        per = Keyword.get(opts, :per, 60_000)
        ip = conn.remote_ip |> :inet.ntoa() |> to_string()
        case Hammer.check_rate("rate_limit:\#{ip}", per, max) do
          {:allow, _count} -> conn
          {:deny, _limit} -> conn |> put_status(429) |> halt()
        end
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "csrf")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">CSRF &amp; Security Headers</h2>
      <p class="text-gray-600 dark:text-gray-300">
        protect_from_forgery, Content Security Policy, secure headers, and OWASP basics — the defense layers of a Phoenix application.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "csp", "headers", "owasp", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-400 border-b-2 border-red-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["csrf", "forgery", "token"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-red-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <p class="text-sm font-semibold text-red-700 dark:text-red-300 mb-1">CSRF Attack</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Tricks logged-in users into submitting forms on malicious sites.</p>
            </div>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">CSRF Token</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Secret value in forms — server rejects requests without it.</p>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">Phoenix Built-in</p>
              <p class="text-sm text-gray-600 dark:text-gray-300"><code>plug :protect_from_forgery</code> handles this automatically.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- CSP -->
      <%= if @active_tab == "csp" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Content Security Policy (CSP) prevents XSS attacks by telling browsers which sources of content are trusted.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{csp_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">CSP Directives</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>default-src</strong>: fallback for all resource types</li>
                <li><strong>script-src</strong>: where JS can be loaded from</li>
                <li><strong>style-src</strong>: CSS sources</li>
                <li><strong>img-src</strong>: image sources</li>
                <li><strong>connect-src</strong>: XHR/WebSocket targets</li>
                <li><strong>frame-src</strong>: iframes</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Phoenix CSP + Nonce</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{csp_nonce_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Security Headers -->
      <%= if @active_tab == "headers" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>put_secure_browser_headers</code> sets several important HTTP headers automatically.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{headers_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-2">Default Phoenix Headers</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><code>x-frame-options: SAMEORIGIN</code> (clickjacking)</li>
                <li><code>x-content-type-options: nosniff</code> (MIME sniff)</li>
                <li><code>x-xss-protection: 1; mode=block</code></li>
                <li><code>x-download-options: noopen</code></li>
                <li><code>x-permitted-cross-domain-policies: none</code></li>
                <li><code>cross-origin-window-policy: deny</code></li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Custom Headers</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{custom_headers_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- OWASP -->
      <%= if @active_tab == "owasp" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            OWASP Top 10 and how Phoenix addresses each threat.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{owasp_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <p class="text-sm font-semibold text-red-700 dark:text-red-300 mb-2">Force HTTPS (Production)</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{force_ssl_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">HSTS Header</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{hsts_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Security Configuration</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("overview"), do: "CSRF Overview"
  defp tab_label("csp"), do: "Content Security Policy"
  defp tab_label("headers"), do: "Security Headers"
  defp tab_label("owasp"), do: "OWASP Basics"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("csrf"), do: "What is CSRF?"
  defp topic_label("forgery"), do: "protect_from_forgery"
  defp topic_label("token"), do: "CSRF Tokens"

  defp overview_code("csrf") do
    """
    # Cross-Site Request Forgery (CSRF) attack:
    #
    # 1. Victim is logged in to bank.com
    # 2. Victim visits evil.com
    # 3. evil.com has a hidden form that POSTs to bank.com/transfer
    # 4. Browser auto-includes the bank.com session cookie
    # 5. Bank processes the transfer as if the user requested it!
    #
    # CSRF only works for state-changing requests (POST/PUT/DELETE)
    # that rely on cookies for authentication.
    #
    # JSON APIs using Bearer tokens are NOT vulnerable to CSRF
    # (browsers won't auto-add Authorization headers).
    #
    # Solution: require a secret token in every form that
    # the attacker cannot know.\
    """
    |> String.trim()
  end

  defp overview_code("forgery") do
    """
    # Phoenix's :protect_from_forgery plug:
    # - Generates a unique CSRF token per session
    # - Embeds it in forms (as _csrf_token field)
    # - Verifies it on every POST/PUT/PATCH/DELETE request
    # - Rejects requests where the token is missing or wrong

    # In router (already included in :browser pipeline):
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {Layouts, :root}
      plug :protect_from_forgery   # <-- this one!
      plug :put_secure_browser_headers
    end

    # Phoenix forms auto-include the token:
    # <.form for={@changeset} action={~p"/users"}>
    #   <!-- Hidden field _csrf_token is added automatically -->
    #   <.input field={@changeset[:email]} type="email" />
    #   <.button>Submit</.button>
    # </.form>\
    """
    |> String.trim()
  end

  defp overview_code("token") do
    """
    # Getting the CSRF token manually:
    Phoenix.Controller.get_csrf_token()
    # => "ZHVtbXkgdG9rZW4..."

    # Add to non-Phoenix forms manually:
    # <form method="POST" action="/transfer">
    #   <input type="hidden"
    #          name="_csrf_token"
    #          value={Phoenix.Controller.get_csrf_token()} />
    #   <button type="submit">Transfer</button>
    # </form>

    # For AJAX/fetch requests, use the meta tag pattern:
    # <!-- In layout: -->
    # <meta name="csrf-token"
    #       content={Phoenix.Controller.get_csrf_token()} />

    # <!-- In JS: -->
    # const token = document.querySelector('[name="csrf-token"]')
    #               .getAttribute("content");
    # fetch("/api/action", {
    #   method: "POST",
    #   headers: {"x-csrf-token": token}
    # })

    # Phoenix checks X-CSRF-Token header for AJAX requests.\
    """
    |> String.trim()
  end

  defp csp_code do
    """
    # Content Security Policy prevents XSS by restricting
    # which resources the browser is allowed to load.

    # Basic CSP for Phoenix app:
    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; " <>
        "script-src 'self' 'nonce-NONCE'; " <>
        "style-src 'self' 'unsafe-inline'; " <>
        "img-src 'self' data: https:; " <>
        "font-src 'self'; " <>
        "connect-src 'self' wss://yourapp.com"
    }

    # Directives explained:
    # default-src 'self'     -> only from same origin by default
    # script-src 'self'      -> only scripts from same origin
    # 'nonce-...'            -> allow specific inline scripts
    # 'unsafe-inline'        -> allow inline styles (avoid if possible)
    # img-src data:          -> allow data: URI images (base64)
    # connect-src wss://     -> allow WebSocket connections

    # Test CSP with report-only mode first:
    "content-security-policy-report-only: default-src 'self'; ..."\
    """
    |> String.trim()
  end

  defp csp_nonce_code do
    """
    # Generate a nonce per-request for inline scripts:
    plug :put_content_security_policy

    defp put_content_security_policy(conn, _opts) do
      nonce = :crypto.strong_rand_bytes(16) |> Base.encode64()

      conn
      |> assign(:csp_nonce, nonce)
      |> put_resp_header(
           "content-security-policy",
           "default-src 'self'; " <>
           "script-src 'self' 'nonce-\#{nonce}'"
         )
    end

    # In layout template:
    # <script nonce={@csp_nonce}>
    #   // inline JS is allowed with the nonce
    # </script>

    # Phoenix LiveView uses a nonce internally
    # for its bundled scripts.\
    """
    |> String.trim()
  end

  defp headers_code do
    """
    # put_secure_browser_headers/2 adds these by default:
    # (from Plug.Conn.put_secure_browser_headers)

    # X-Frame-Options: SAMEORIGIN
    #   -> Prevents your page from being embedded in iframes
    #      on other domains (clickjacking protection)

    # X-Content-Type-Options: nosniff
    #   -> Browser won't guess MIME type; honors Content-Type
    #      (prevents "MIME sniffing" attacks)

    # X-XSS-Protection: 1; mode=block
    #   -> Legacy IE/Chrome XSS filter (modern browsers use CSP)

    # X-Download-Options: noopen
    #   -> IE: don't allow direct file execution on download

    # X-Permitted-Cross-Domain-Policies: none
    #   -> Prevents Flash/PDF plugins from cross-domain requests

    # Referrer-Policy: strict-origin-when-cross-origin
    #   -> Controls Referer header sent to other sites

    # In Phoenix router:
    pipeline :browser do
      plug :put_secure_browser_headers   # all the above!
    end\
    """
    |> String.trim()
  end

  defp custom_headers_code do
    """
    # Add custom headers via put_secure_browser_headers map:
    plug :put_secure_browser_headers, %{
      "content-security-policy" => "default-src 'self'",
      "permissions-policy" =>
        "camera=(), microphone=(), geolocation=()",
      "referrer-policy" => "no-referrer"
    }

    # Or add headers manually in a plug:
    def set_headers(conn, _opts) do
      conn
      |> put_resp_header("strict-transport-security",
           "max-age=31536000; includeSubDomains")
      |> put_resp_header("referrer-policy",
           "strict-origin-when-cross-origin")
      |> put_resp_header("permissions-policy",
           "geolocation=(), camera=()")
    end\
    """
    |> String.trim()
  end

  defp owasp_code do
    """
    # OWASP Top 10 — Phoenix's built-in defenses:

    # A01: Broken Access Control
    #   -> Use Authorization plugs + scope queries
    #   -> Never trust user-supplied IDs without ownership check

    # A02: Cryptographic Failures
    #   -> Phoenix uses strong signing keys (secret_key_base)
    #   -> Use Bcrypt/Argon2 for passwords (not MD5/SHA1)

    # A03: Injection (SQL, XSS)
    #   -> Ecto parameterizes all queries (no SQL injection)
    #   -> HEEx escapes all output by default (no XSS)
    #   -> Only raw/3 renders unescaped — use with extreme care

    # A04: Insecure Design
    #   -> Use gen.auth for authentication (don't roll your own)

    # A05: Security Misconfiguration
    #   -> Set secret_key_base from environment, never hardcode
    #   -> Force HTTPS in production

    # A07: Identification & Authentication Failures
    #   -> rate-limit login attempts (use Plug.RateLimit or Hammer)
    #   -> configure_session(renew: true) on login
    #   -> Use email confirmation + strong passwords\
    """
    |> String.trim()
  end

  defp force_ssl_code do
    """
    # config/prod.exs:
    config :my_app, MyAppWeb.Endpoint,
      force_ssl: [rewrite_on: [:x_forwarded_proto]]

    # This adds the ForceSSL plug that:
    # 1. Checks X-Forwarded-Proto header
    # 2. Redirects HTTP -> HTTPS with 301
    # 3. Adds Strict-Transport-Security header\
    """
    |> String.trim()
  end

  defp hsts_code do
    """
    # HSTS (HTTP Strict Transport Security):
    # Tells browsers to ONLY connect via HTTPS for N seconds.

    # Phoenix sets this when force_ssl is configured:
    Strict-Transport-Security: max-age=31536000

    # Custom HSTS (longer, with subdomains):
    plug :put_secure_browser_headers, %{
      "strict-transport-security" =>
        "max-age=63072000; includeSubDomains; preload"
    }

    # 63072000 seconds = 2 years (recommended by OWASP)
    # includeSubDomains: applies to all subdomains
    # preload: submit to browser preload lists\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Comprehensive security configuration for Phoenix:

    # router.ex
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {Layouts, :root}
      plug :protect_from_forgery        # CSRF protection
      plug :put_secure_browser_headers, %{
        "content-security-policy" =>
          "default-src 'self'; " <>
          "script-src 'self'; " <>
          "style-src 'self' 'unsafe-inline'; " <>
          "img-src 'self' data: https:; " <>
          "connect-src 'self' wss:",
        "permissions-policy" =>
          "camera=(), microphone=(), geolocation=()"
      }
      plug MyAppWeb.Plugs.RateLimit, max: 100, per: 60_000
    end

    # endpoint.ex — add force_ssl in prod:
    # config :my_app, MyAppWeb.Endpoint,
    #   force_ssl: [rewrite_on: [:x_forwarded_proto]]

    # Login rate limiting:
    defmodule MyAppWeb.Plugs.RateLimit do
      import Plug.Conn
      def init(opts), do: opts
      def call(conn, opts) do
        max = Keyword.get(opts, :max, 100)
        per = Keyword.get(opts, :per, 60_000)
        ip = conn.remote_ip |> :inet.ntoa() |> to_string()
        key = "rate_limit:\#{ip}"

        case Hammer.check_rate(key, per, max) do
          {:allow, _count} ->
            conn
          {:deny, _limit} ->
            conn
            |> put_status(429)
            |> halt()
        end
      end
    end\
    """
    |> String.trim()
  end
end
