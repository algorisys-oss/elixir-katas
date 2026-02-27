# Kata 31: Module Plugs

## What Is a Module Plug?

A **module plug** is an Elixir module that implements the `Plug` behaviour with two callbacks:

- `init/1` — called once at compile time (production) or startup (dev) to transform options
- `call/2` — called on every request with the conn and the result of `init/1`

```elixir
defmodule MyApp.Plugs.MyPlug do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    # Transform the conn
    conn
  end
end
```

---

## The Two Callbacks

### init/1 — Compile-Time Initialization

`init/1` receives the options passed at `plug` declaration and returns a value stored as the compiled options:

```elixir
def init(opts) do
  # Validate options:
  unless Keyword.has_key?(opts, :required) do
    raise ArgumentError, "required option is missing"
  end

  # Transform for fast runtime use:
  %{
    timeout: Keyword.get(opts, :timeout, 5000),
    paths: opts |> Keyword.get(:paths, []) |> MapSet.new()
  }
end
```

In production, `init/1` runs **once** when the module is compiled. The result is stored and passed to every `call/2` invocation — no per-request overhead.

### call/2 — Per-Request Logic

`call/2` receives the conn and the precomputed result of `init/1`:

```elixir
def call(conn, %{timeout: timeout, paths: paths}) do
  if conn.request_path in paths do
    Plug.Conn.assign(conn, :timeout, timeout)
  else
    conn
  end
end
```

---

## Lifecycle

```
Router compiles
  └── plug MyPlug, key: "value"
        └── MyPlug.init([key: "value"]) => %{key: "value"}   # Once!

Request arrives
  └── MyPlug.call(conn, %{key: "value"})   # Every request
        └── returns modified conn
```

In development with live reload, `init/1` may run per-request since modules recompile frequently. Always design `init/1` to be idempotent and side-effect-free.

---

## Options Patterns

### Keyword List Options

```elixir
def init(opts) do
  %{
    level: Keyword.get(opts, :level, :info),
    format: Keyword.get(opts, :format, :json)
  }
end

# Usage:
plug MyApp.Plugs.Logger, level: :debug, format: :text
```

### Validated Options

```elixir
def init(opts) do
  limit = Keyword.fetch!(opts, :limit)
  unless is_integer(limit) and limit > 0 do
    raise ArgumentError, "limit must be a positive integer"
  end
  %{limit: limit, window: Keyword.get(opts, :window, 60_000)}
end
```

### Precomputing Expensive Structures

```elixir
def init(opts) do
  # Compile regex once instead of on every request:
  pattern = Keyword.fetch!(opts, :pattern)
  %{regex: Regex.compile!(pattern)}
end

def call(conn, %{regex: regex}) do
  if Regex.match?(regex, conn.request_path) do
    Plug.Conn.assign(conn, :path_matched, true)
  else
    conn
  end
end
```

---

## Common Module Plug Patterns

### SetLocale

```elixir
defmodule MyApp.Plugs.SetLocale do
  import Plug.Conn

  @supported ~w(en fr de es ja)

  def init(opts), do: %{default: Keyword.get(opts, :default, "en")}

  def call(conn, %{default: default}) do
    locale =
      get_session(conn, :locale) ||
      parse_accept_language(conn) ||
      default

    assign(conn, :locale, locale)
  end

  defp parse_accept_language(conn) do
    conn
    |> get_req_header("accept-language")
    |> List.first("")
    |> String.slice(0, 2)
    |> then(&if &1 in @supported, do: &1)
  end
end
```

### RequireRole

```elixir
defmodule MyApp.Plugs.RequireRole do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: %{role: Keyword.fetch!(opts, :role)}

  def call(conn, %{role: required_role}) do
    case conn.assigns[:current_user] do
      nil ->
        conn |> redirect(to: "/login") |> halt()

      user when user.role != required_role ->
        conn |> put_flash(:error, "Access denied") |> redirect(to: "/") |> halt()

      _ ->
        conn
    end
  end
end

# Usage:
plug MyApp.Plugs.RequireRole, role: :admin
```

### RateLimit

```elixir
defmodule MyApp.Plugs.RateLimit do
  import Plug.Conn

  def init(opts) do
    %{
      limit: Keyword.get(opts, :limit, 100),
      window: Keyword.get(opts, :window, 60_000)
    }
  end

  def call(conn, %{limit: limit, window: window}) do
    key = "rl:#{:inet.ntoa(conn.remote_ip)}"
    count = MyApp.Cache.incr(key, ttl: window)

    if count > limit do
      conn
      |> put_resp_header("x-ratelimit-limit", to_string(limit))
      |> send_resp(429, "Too Many Requests")
      |> halt()
    else
      put_resp_header(conn, "x-ratelimit-remaining",
        to_string(limit - count))
    end
  end
end
```

---

## Using Module Plugs in Pipelines

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug MyApp.Plugs.RequestLogger, level: :info    # module plug
    plug MyApp.Plugs.SetLocale, default: "en"       # module plug
  end

  pipeline :require_auth do
    plug MyApp.Plugs.FetchCurrentUser
    plug MyApp.Plugs.RequireAuth
  end

  pipeline :api_auth do
    plug MyApp.Plugs.VerifyAPIKey
  end

  scope "/" do
    pipe_through [:browser, :require_auth]
    resources "/orders", OrderController
  end
end
```

---

## Module Plug vs Function Plug

| Aspect | Module Plug | Function Plug |
|--------|------------|---------------|
| Location | Separate module | Same module |
| `init/1` | Yes — compile-time options processing | No |
| Reusability | Any module can `plug MyModule` | Only within the same module |
| Options processing | Compile-time via `init/1` | Runtime, every call |
| Use case | Shared middleware, libraries | Quick, local transforms |

---

## Testing Module Plugs

```elixir
defmodule MyApp.Plugs.SetLocaleTest do
  use ExUnit.Case
  use Plug.Test

  alias MyApp.Plugs.SetLocale

  test "sets locale from session" do
    opts = SetLocale.init(default: "en")

    conn =
      conn(:get, "/")
      |> init_test_session(%{locale: "fr"})
      |> SetLocale.call(opts)

    assert conn.assigns.locale == "fr"
  end

  test "falls back to default" do
    opts = SetLocale.init(default: "de")
    conn = conn(:get, "/") |> SetLocale.call(opts)
    assert conn.assigns.locale == "de"
  end
end
```

---

## Key Takeaways

1. Module plugs implement `init/1` (compile time) and `call/2` (runtime)
2. `init/1` validates and preprocesses options — runs **once** in production
3. The return value of `init/1` is what `call/2` receives as its second argument
4. Use module plugs for reusable middleware used across many modules
5. `@behaviour Plug` with `@impl` gives you compile-time callback verification
6. Test module plugs directly with `Plug.Test` helpers
7. Always `halt/1` after sending a response to stop pipeline execution
