defmodule ElixirKatasWeb.PhoenixKata05StateOnTheWebLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # State on the Web: HTTP is Stateless
    # The server forgets you after every request.
    # Cookies, sessions, and tokens solve this.

    # === COOKIES ===
    # Small data the server asks the browser to store.
    # Browser sends them back with every subsequent request.

    # Server sets a cookie:
    # Set-Cookie: theme=dark; Path=/; HttpOnly
    #
    # Browser sends it back:
    # GET /dashboard HTTP/1.1
    # Cookie: theme=dark; lang=en; session_id=abc123

    # === SESSIONS ===
    # Server-side storage linked to a cookie.
    # Cookie only contains the session ID — all data stays on server.

    # In your Phoenix controller:
    conn
    |> put_session(:user_id, 42)       # Store in session
    |> get_session(:user_id)           # Read from session

    # Phoenix encrypts the cookie automatically
    # Set-Cookie: _my_app_key=SFMyNTY...encrypted

    # === TOKENS (JWT / Bearer) ===
    # Self-contained credentials in the Authorization header.
    # Server stores nothing — token carries all info.
    #
    # POST /api/login HTTP/1.1
    # → Response: token = "eyJhbGci...signed"
    #
    # GET /api/dashboard HTTP/1.1
    # Authorization: Bearer eyJhbGci...signed
    # → Server verifies signature → knows it's Alice

    # Phoenix uses signed, encrypted cookies for sessions by default.
    # No external session store needed!
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_mechanism: "cookies",
       cookie_jar: %{},
       session_store: %{},
       logged_in: false,
       request_count: 0
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">State on the Web</h2>
      <p class="text-gray-600 dark:text-gray-300">
        HTTP is stateless — the server forgets you after every request. Explore how cookies, sessions, and tokens solve this.
      </p>

      <!-- Mechanism selector -->
      <div class="flex flex-wrap gap-2">
        <%= for {id, label} <- [{"cookies", "Cookies"}, {"sessions", "Sessions"}, {"tokens", "Tokens"}] do %>
          <button
            phx-click="select_mechanism"
            phx-target={@myself}
            phx-value-mechanism={id}
            class={[
              "px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
              if(@active_mechanism == id, do: "bg-amber-600 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600")
            ]}
          >
            {label}
          </button>
        <% end %>
      </div>

      <!-- Stateless problem demo -->
      <div class="p-5 rounded-xl border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/10">
        <h3 class="font-semibold text-red-700 dark:text-red-400 mb-2">The Problem: HTTP is Stateless</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-red-200 dark:border-red-800">
            <span class="text-red-600 dark:text-red-400 font-mono font-bold">Request 1:</span>
            <span class="text-gray-700 dark:text-gray-300"> POST /login</span>
            <p class="text-xs text-gray-500 mt-1">Server: "OK, you're Alice!"</p>
          </div>
          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-red-200 dark:border-red-800">
            <span class="text-red-600 dark:text-red-400 font-mono font-bold">Request 2:</span>
            <span class="text-gray-700 dark:text-gray-300"> GET /dashboard</span>
            <p class="text-xs text-gray-500 mt-1">Server: "Who are you? I have no memory of you."</p>
          </div>
          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-red-200 dark:border-red-800">
            <span class="text-red-600 dark:text-red-400 font-mono font-bold">Problem:</span>
            <p class="text-xs text-gray-500 mt-1">Every request starts from scratch. The server doesn't remember previous requests.</p>
          </div>
        </div>
      </div>

      <!-- Active mechanism detail -->
      <%= case @active_mechanism do %>
        <% "cookies" -> %>
          <.cookie_section myself={@myself} cookie_jar={@cookie_jar} request_count={@request_count} />
        <% "sessions" -> %>
          <.session_section myself={@myself} session_store={@session_store} logged_in={@logged_in} />
        <% "tokens" -> %>
          <.token_section myself={@myself} />
      <% end %>
    </div>
    """
  end

  defp cookie_section(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="p-5 rounded-xl border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/10">
        <h3 class="text-lg font-semibold text-amber-700 dark:text-amber-400 mb-3">Cookies</h3>
        <p class="text-sm text-gray-600 dark:text-gray-300 mb-4">
          Small pieces of data the server asks the browser to store. The browser sends them back with every subsequent request.
        </p>

        <div class="flex flex-wrap gap-2 mb-4">
          <button phx-click="set_cookie" phx-target={@myself} phx-value-key="theme" phx-value-val="dark"
            class="px-3 py-1.5 text-sm bg-amber-600 hover:bg-amber-700 text-white rounded-lg cursor-pointer">
            Set theme=dark
          </button>
          <button phx-click="set_cookie" phx-target={@myself} phx-value-key="lang" phx-value-val="en"
            class="px-3 py-1.5 text-sm bg-amber-600 hover:bg-amber-700 text-white rounded-lg cursor-pointer">
            Set lang=en
          </button>
          <button phx-click="set_cookie" phx-target={@myself} phx-value-key="session_id" phx-value-val="abc123"
            class="px-3 py-1.5 text-sm bg-amber-600 hover:bg-amber-700 text-white rounded-lg cursor-pointer">
            Set session_id=abc123
          </button>
          <button phx-click="send_request_with_cookies" phx-target={@myself}
            class="px-3 py-1.5 text-sm bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg cursor-pointer">
            Send Request
          </button>
        </div>

        <!-- Cookie jar -->
        <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-amber-200 dark:border-amber-700">
          <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Browser Cookie Jar</h4>
          <%= if @cookie_jar == %{} do %>
            <p class="text-sm text-gray-400 italic">No cookies set</p>
          <% else %>
            <div class="space-y-1">
              <%= for {k, v} <- @cookie_jar do %>
                <div class="flex items-center gap-2 text-sm font-mono">
                  <span class="text-amber-600 dark:text-amber-400">{k}</span>
                  <span class="text-gray-500">=</span>
                  <span class="text-gray-700 dark:text-gray-300">{v}</span>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <%= if @request_count > 0 do %>
          <div class="mt-3 p-3 rounded-lg bg-gray-900 font-mono text-sm text-green-400 whitespace-pre overflow-x-auto">{cookie_request_text(@cookie_jar, @request_count)}</div>
        <% end %>
      </div>
    </div>
    """
  end

  defp session_section(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="p-5 rounded-xl border border-emerald-200 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-900/10">
        <h3 class="text-lg font-semibold text-emerald-700 dark:text-emerald-400 mb-3">Sessions</h3>
        <p class="text-sm text-gray-600 dark:text-gray-300 mb-4">
          Server-side storage linked to a cookie. The cookie only contains the session ID — all data stays on the server.
        </p>

        <div class="flex flex-wrap gap-2 mb-4">
          <button phx-click="session_login" phx-target={@myself}
            class={["px-3 py-1.5 text-sm rounded-lg cursor-pointer",
              if(@logged_in, do: "bg-gray-400 text-white cursor-not-allowed", else: "bg-emerald-600 hover:bg-emerald-700 text-white")]}>
            Login as Alice
          </button>
          <button phx-click="session_add_cart" phx-target={@myself}
            class={["px-3 py-1.5 text-sm rounded-lg cursor-pointer",
              if(@logged_in, do: "bg-emerald-600 hover:bg-emerald-700 text-white", else: "bg-gray-400 text-white cursor-not-allowed")]}>
            Add to Cart
          </button>
          <button phx-click="session_logout" phx-target={@myself}
            class="px-3 py-1.5 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg cursor-pointer">
            Logout
          </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-emerald-200 dark:border-emerald-700">
            <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Browser (Cookie)</h4>
            <p class="text-sm font-mono text-gray-600 dark:text-gray-400">
              <%= if @logged_in do %>
                session_id=<span class="text-emerald-600 dark:text-emerald-400">s3cr3t_t0k3n</span>
              <% else %>
                <span class="italic text-gray-400">No session cookie</span>
              <% end %>
            </p>
            <p class="text-xs text-gray-400 mt-1">Only the ID — no sensitive data</p>
          </div>

          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-emerald-200 dark:border-emerald-700">
            <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Server (Session Store)</h4>
            <%= if @session_store == %{} do %>
              <p class="text-sm text-gray-400 italic">Empty</p>
            <% else %>
              <div class="space-y-1">
                <%= for {k, v} <- @session_store do %>
                  <div class="text-sm font-mono">
                    <span class="text-emerald-600 dark:text-emerald-400">{k}:</span>
                    <span class="text-gray-700 dark:text-gray-300"> {v}</span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp token_section(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="p-5 rounded-xl border border-purple-200 dark:border-purple-800 bg-purple-50 dark:bg-purple-900/10">
        <h3 class="text-lg font-semibold text-purple-700 dark:text-purple-400 mb-3">Tokens (JWT / Bearer)</h3>
        <p class="text-sm text-gray-600 dark:text-gray-300 mb-4">
          Self-contained credentials sent in the Authorization header. Common for APIs. The server doesn't need to store anything.
        </p>

        <div class="grid grid-cols-1 gap-4">
          <div class="p-3 rounded-lg bg-gray-900 font-mono text-sm overflow-x-auto">
            <div class="text-yellow-300">POST /api/login HTTP/1.1</div>
            <div class="text-cyan-300">Content-Type: application/json</div>
            <div class="text-gray-600 mt-1"></div>
            <div class="text-green-400 mt-1">Response: token = "eyJhbGci...signed"</div>
          </div>

          <div class="p-3 rounded-lg bg-gray-900 font-mono text-sm overflow-x-auto">
            <div class="text-yellow-300">GET /api/dashboard HTTP/1.1</div>
            <div class="text-cyan-300">Authorization: Bearer eyJhbGci...signed</div>
            <div class="text-gray-600 mt-1"></div>
            <div class="text-green-400 mt-1">Server verifies signature → knows it's Alice</div>
          </div>
        </div>

        <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-purple-200 dark:border-purple-700">
            <h4 class="font-semibold text-purple-700 dark:text-purple-400 mb-1">Stateless</h4>
            <p class="text-xs text-gray-600 dark:text-gray-400">Server stores nothing. Token carries all info.</p>
          </div>
          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-purple-200 dark:border-purple-700">
            <h4 class="font-semibold text-purple-700 dark:text-purple-400 mb-1">Signed</h4>
            <p class="text-xs text-gray-600 dark:text-gray-400">Can't be tampered with — server verifies the signature.</p>
          </div>
          <div class="p-3 rounded-lg bg-white dark:bg-gray-800 border border-purple-200 dark:border-purple-700">
            <h4 class="font-semibold text-purple-700 dark:text-purple-400 mb-1">API-friendly</h4>
            <p class="text-xs text-gray-600 dark:text-gray-400">Works with mobile apps, SPAs, microservices.</p>
          </div>
        </div>
      </div>

      <!-- Phoenix approach -->
      <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
        <h4 class="font-semibold text-amber-700 dark:text-amber-400 mb-2">Phoenix Uses Sessions by Default</h4>
        <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">
          Phoenix uses signed, encrypted cookies to store session data. No external session store needed:
        </p>
        <pre class="p-3 bg-gray-900 rounded text-sm font-mono text-green-400 overflow-x-auto">{phoenix_session_code()}</pre>
      </div>
    </div>
    """
  end

  def handle_event("select_mechanism", %{"mechanism" => mech}, socket) do
    {:noreply, assign(socket, active_mechanism: mech)}
  end

  def handle_event("set_cookie", %{"key" => key, "val" => val}, socket) do
    cookie_jar = Map.put(socket.assigns.cookie_jar, key, val)
    {:noreply, assign(socket, cookie_jar: cookie_jar)}
  end

  def handle_event("send_request_with_cookies", _, socket) do
    {:noreply, assign(socket, request_count: socket.assigns.request_count + 1)}
  end

  def handle_event("session_login", _, socket) do
    session_store = %{"user" => "Alice", "role" => "admin", "cart_items" => "0"}
    {:noreply, assign(socket, logged_in: true, session_store: session_store)}
  end

  def handle_event("session_add_cart", _, socket) do
    if socket.assigns.logged_in do
      count = String.to_integer(socket.assigns.session_store["cart_items"] || "0") + 1
      session_store = Map.put(socket.assigns.session_store, "cart_items", "#{count}")
      {:noreply, assign(socket, session_store: session_store)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("session_logout", _, socket) do
    {:noreply, assign(socket, logged_in: false, session_store: %{})}
  end

  defp cookie_request_text(cookie_jar, count) do
    cookies =
      cookie_jar
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join("; ")

    cookie_header = if cookies != "", do: "\nCookie: #{cookies}", else: ""

    "# Request #{count}\nGET /dashboard HTTP/1.1\nHost: example.com#{cookie_header}"
  end

  defp phoenix_session_code do
    "# In your controller\nconn\n|> put_session(:user_id, 42)       # Store in session\n|> get_session(:user_id)           # Read from session\n\n# Phoenix encrypts the cookie automatically\n# Set-Cookie: _my_app_key=SFMyNTY...encrypted"
  end
end
