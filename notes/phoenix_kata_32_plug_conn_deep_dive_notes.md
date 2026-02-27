# Kata 32: Plug.Conn Deep Dive

## The Connection Struct

`%Plug.Conn{}` is the heart of every request. Every plug receives a conn, transforms it, and passes it along. Understanding its fields and functions is essential for writing plugs.

```elixir
# The full Plug.Conn struct (selected fields):
%Plug.Conn{
  # Request fields (read-only once set):
  method: "GET",
  host: "example.com",
  port: 443,
  scheme: :https,
  request_path: "/users/1",
  query_string: "page=2",
  params: %{"id" => "1", "page" => "2"},
  req_headers: [{"accept", "text/html"}, {"host", "example.com"}],
  remote_ip: {93, 184, 216, 34},

  # Response fields (set by plugs/controllers):
  status: nil,       # nil until response is sent
  resp_headers: [],
  resp_body: "",
  state: :unset,     # :unset | :set | :chunked | :sent

  # Application data:
  assigns: %{},      # user/app data — visible in templates
  private: %{},      # library/framework internal data

  # Control:
  halted: false      # true after halt/1 is called
}
```

---

## assigns vs private

### conn.assigns — Application Data

`assigns` holds data meant for your application code and templates:

```elixir
import Plug.Conn

# Setting assigns:
conn = assign(conn, :current_user, user)
conn = assign(conn, :locale, "en")

# Multiple at once (Plug >= 1.14):
conn = merge_assigns(conn, current_user: user, locale: "en")

# Reading in plugs/controllers:
user = conn.assigns.current_user
locale = conn.assigns[:locale]   # nil-safe version

# Reading in HEEx templates:
# @current_user  (available via the @ shorthand)
# @locale
```

### conn.private — Framework/Library Data

`private` is reserved for libraries and framework internals:

```elixir
import Plug.Conn

# Phoenix sets these automatically:
conn.private.phoenix_action      # => :show
conn.private.phoenix_controller  # => MyAppWeb.UserController
conn.private.phoenix_format      # => "html"
conn.private.phoenix_view        # => MyAppWeb.UserHTML
conn.private.phoenix_root_layout # => {MyAppWeb.Layouts, :root}

# Setting private (for your own library/middleware):
conn = put_private(conn, :my_lib_config, %{version: "2"})

# Reading back:
conn.private[:my_lib_config]
```

**Key rule**: use `assigns` for application data, `private` for library internals. Templates can only access `assigns` via `@`.

---

## Request Headers

All request headers are lowercase. `get_req_header/2` always returns a list:

```elixir
import Plug.Conn

# Get a specific header:
get_req_header(conn, "authorization")
# => ["Bearer token123"]  or  []

get_req_header(conn, "accept")
# => ["text/html,application/xhtml+xml;q=0.9,*/*;q=0.8"]

# Extract first value:
conn
|> get_req_header("x-forwarded-for")
|> List.first()
# => "1.2.3.4" or nil

# Pattern match on presence:
case get_req_header(conn, "authorization") do
  ["Bearer " <> token | _] -> verify_token(token)
  _ -> {:error, :unauthorized}
end

# All headers as a list of {name, value} tuples:
conn.req_headers
# => [{"host", "example.com"}, {"accept", "text/html"}, ...]
```

---

## Response Headers

```elixir
import Plug.Conn

# Add a response header:
conn = put_resp_header(conn, "x-request-id", "abc123")

# Delete:
conn = delete_resp_header(conn, "x-powered-by")

# Set content type:
conn = put_resp_content_type(conn, "application/json")
conn = put_resp_content_type(conn, "text/plain")

# Read response headers (already set):
get_resp_header(conn, "content-type")
# => ["application/json; charset=utf-8"]
```

### Security Headers from Phoenix

`plug :put_secure_browser_headers` sets these automatically:

```
x-content-type-options: nosniff
x-download-options: noopen
x-frame-options: SAMEORIGIN
x-permitted-cross-domain-policies: none
x-xss-protection: 1; mode=block
```

---

## Session

```elixir
import Plug.Conn

# Reading (requires :fetch_session in pipeline):
get_session(conn, :user_id)       # => 42 or nil
get_session(conn, "user_id")      # same — atom or string

# Writing:
conn = put_session(conn, :user_id, 42)
conn = put_session(conn, :locale, "fr")

# Deleting a key:
conn = delete_session(conn, :user_id)

# Clearing all session data:
conn = clear_session(conn)

# Regenerating session ID (prevents fixation attacks):
conn = configure_session(conn, renew: true)

# Dropping the session (force re-auth):
conn = configure_session(conn, drop: true)
```

---

## Sending Responses

```elixir
import Plug.Conn

# Raw response:
conn |> send_resp(200, "Hello, World!")
conn |> send_resp(404, "Not Found")
conn |> send_resp(401, ~s({"error":"Unauthorized"}))

# Set status and body separately:
conn
|> put_status(201)
|> put_resp_content_type("application/json")
|> send_resp(201, Jason.encode!(%{id: 1}))

# Named status codes:
put_status(conn, :created)           # 201
put_status(conn, :not_found)         # 404
put_status(conn, :unprocessable_entity)  # 422

# Chunked responses (streaming):
conn = send_chunked(conn, 200)
{:ok, conn} = chunk(conn, "first chunk")
{:ok, conn} = chunk(conn, "second chunk")
```

---

## Halting the Pipeline

```elixir
import Plug.Conn

# halt/1 sets conn.halted = true.
# Remaining plugs in the pipeline are SKIPPED.
# You MUST also send a response before halting!

# Auth guard:
def require_auth(conn, _opts) do
  if conn.assigns[:current_user] do
    conn   # let the pipeline continue
  else
    conn
    |> Phoenix.Controller.redirect(to: "/login")
    |> halt()
  end
end

# API unauthorized:
def check_api_key(conn, _opts) do
  case get_req_header(conn, "x-api-key") do
    [key] when key != "" ->
      conn
    _ ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(401, ~s({"error":"Invalid API key"}))
      |> halt()
  end
end
```

### conn.state — Response Lifecycle

```
:unset    → initial; no response set
:set      → send_resp/put_resp called
:chunked  → chunked transfer encoding active
:sent     → response bytes written to socket
:upgraded → connection upgraded (e.g. WebSocket)
```

`conn.halted` and `conn.state` are independent:
- `halted`: whether the plug **pipeline** is stopped
- `state`: whether the **response** has been sent

---

## register_before_send

Run code after the controller returns but before bytes are written:

```elixir
def track_response(conn, _opts) do
  start = System.monotonic_time(:millisecond)

  Plug.Conn.register_before_send(conn, fn conn ->
    elapsed = System.monotonic_time(:millisecond) - start
    MyApp.Metrics.record_request(conn.request_path, elapsed, conn.status)
    conn  # must return conn
  end)
end
```

Multiple `register_before_send` callbacks run in **reverse** registration order.

---

## Conn Quick Reference

```elixir
# Reading
conn.method           # "GET", "POST", "PUT", "DELETE", "PATCH"
conn.request_path     # "/users/1"
conn.query_string     # "page=2"
conn.params           # %{"id" => "1", "page" => "2"}
conn.host             # "example.com"
conn.scheme           # :http or :https
conn.remote_ip        # {127, 0, 0, 1}

# Modifying (all return a new conn)
assign(conn, :key, value)
put_private(conn, :key, value)
put_resp_header(conn, "name", "value")
put_resp_content_type(conn, "application/json")
put_status(conn, 201)
put_session(conn, :key, value)
halt(conn)

# Sending
send_resp(conn, status, body)
send_file(conn, status, path)
send_chunked(conn, status)
```

---

## Key Takeaways

1. `%Plug.Conn{}` is the single data structure flowing through the entire request lifecycle
2. `assigns` is for **application data** (visible in templates); `private` is for **framework/library data**
3. Request headers are lowercase; `get_req_header/2` always returns a list
4. `halt/1` stops pipeline execution — but you must also send a response
5. `conn.halted` tracks pipeline state; `conn.state` tracks response state
6. `register_before_send/2` allows post-controller, pre-response hooks
7. Never modify `%Plug.Conn{}` fields directly — always use the provided functions
