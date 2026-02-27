# Kata 52: Configuration

## Configuration Files Overview

Phoenix uses a layered configuration system:

| File | When | Purpose |
|------|------|---------|
| `config/config.exs` | Compile-time, always | Base configuration for all environments |
| `config/dev.exs` | Compile-time, dev only | Development settings |
| `config/prod.exs` | Compile-time, prod only | Production compile-time settings (minimal) |
| `config/test.exs` | Compile-time, test only | Test settings |
| `config/runtime.exs` | Runtime, always | Runtime config, reads env vars at startup |

Values in later files override earlier ones. `runtime.exs` always wins.

---

## config/config.exs (Base Configuration)

```elixir
import Config

config :my_app,
  ecto_repos: [MyApp.Repo]

config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "abc123"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment-specific config last:
import_config "#{config_env()}.exs"
```

---

## config/dev.exs

```elixir
import Config

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "a_long_dev_secret_key_...",
  watchers: [
    esbuild: {Esbuild, :install_and_run,
              [:my_app, ~w(--bundle --watch --target=es2017)]}
  ]

# Enable dev routes (mailbox, dashboard):
config :my_app, dev_routes: true
```

---

## config/test.exs

```elixir
import Config

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false  # don't start real HTTP server in tests

config :logger, level: :warning  # quieter test output
```

**`MIX_TEST_PARTITION`**: allows parallel CI runs with different DB names (partition 1 uses `my_app_test1`, etc.).

---

## config/runtime.exs (The Key One)

This runs **at startup**, not at compile time. Perfect for secrets from environment variables:

```elixir
import Config

# PHX_SERVER=true -> start HTTP server from a release:
if System.get_env("PHX_SERVER") do
  config :my_app, MyAppWeb.Endpoint, server: true
end

if config_env() == :prod do
  # Database:
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL environment variable is missing!"

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(
      System.get_env("POOL_SIZE") || "10"),
    ssl: true

  # Endpoint:
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is missing!"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base

  # Mailer:
  config :my_app, MyApp.Mailer,
    adapter: Swoosh.Adapters.Postmark,
    api_key: System.fetch_env!("POSTMARK_API_KEY")
end
```

---

## Compile-time vs Runtime

```elixir
# COMPILE-TIME (config.exs, dev.exs, prod.exs):
# These values are baked into the compiled binary.
# Changing them requires recompiling.
config :my_app, :feature_flag, true

# RUNTIME (runtime.exs):
# Read when the app starts. Same binary, different envs!
config :my_app, :stripe_key,
  System.fetch_env!("STRIPE_SECRET_KEY")

# Using System.get_env in compile-time files is WRONG:
# config :my_app, :key, System.get_env("KEY")
# This reads the env var during compilation, not at startup!
```

**The 12-Factor App rule**: store config in environment variables, not in code. `runtime.exs` makes this easy.

---

## System.get_env vs System.fetch_env!

```elixir
# Returns nil if missing (silent failure):
System.get_env("DATABASE_URL")       # => nil
System.get_env("DATABASE_URL", "default")  # => "default"

# Raises at startup if missing (fail fast -- PREFERRED):
System.fetch_env!("DATABASE_URL")    # => raises if missing

# Pattern: raise with helpful message:
database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    DATABASE_URL environment variable is missing!
    Set it to your database connection string:
    DATABASE_URL=postgres://user:pass@host/db
    """
```

**Use `System.fetch_env!`** for required secrets. Your app should fail at startup (not deep in production) if a required secret is missing.

---

## Reading Config at Runtime (in Application Code)

```elixir
# Read application config at call-time:
Application.get_env(:my_app, :stripe_key)

# With default:
Application.get_env(:my_app, :feature_flags, [])

# Raises if not set:
Application.fetch_env!(:my_app, MyApp.Repo)

# Nested config:
Application.get_env(:my_app, MyAppWeb.Endpoint)
|> Keyword.get(:secret_key_base)

# Compile-time (module attribute, only for compile-time config):
@feature_flag Application.compile_env(:my_app, :feature_flag, false)
```

---

## Environment Variables for Common Secrets

```bash
# Generate a secure secret_key_base:
mix phx.gen.secret       # 64-character hex string

# Required environment variables:
SECRET_KEY_BASE="..."     # Phoenix signing key
DATABASE_URL="postgres://user:pass@host/db"  # DB connection
PHX_HOST="myapp.com"     # hostname for URL generation
PORT="4000"              # HTTP port

# Optional:
POOL_SIZE="10"           # DB connection pool size
PHX_SERVER="true"        # start HTTP server from release
ECTO_IPV6="true"         # use IPv6 for DB connection

# Third-party services:
STRIPE_SECRET_KEY="sk_live_..."
POSTMARK_API_KEY="..."
AWS_ACCESS_KEY_ID="..."
AWS_SECRET_ACCESS_KEY="..."
```

---

## Checking Current Environment

```elixir
# In config files:
config_env()       # :dev, :test, or :prod

# In mix tasks:
Mix.env()         # :dev, :test, or :prod

# In application code (configure this in config.exs):
# config :my_app, env: config_env()
Application.get_env(:my_app, :env)
```

---

## .env Files in Development

For local development, use a `.env` file (never commit it):

```bash
# .env (add to .gitignore!)
DATABASE_URL=postgres://postgres:postgres@localhost/my_app_dev
SECRET_KEY_BASE=your_dev_secret_key
STRIPE_SECRET_KEY=sk_test_...

# Load in shell:
source .env
# or with dotenv tool:
eval $(cat .env | sed 's/^/export /')
```

Or use the `dotenvy` Elixir library to load `.env` files automatically in dev.

---

## Key Takeaways

1. **`runtime.exs`** is where secrets belong -- it runs at startup, reads from env vars
2. **`System.fetch_env!`** for required secrets -- fails fast with a clear error if missing
3. **Never use `System.get_env` in compile-time config files** -- it reads at compilation, not startup
4. The same **compiled binary** runs in dev, staging, and production -- only env vars differ
5. **`config_env()`** in config files returns the current Mix environment (`:dev`, `:test`, `:prod`)
6. Generate `secret_key_base` with `mix phx.gen.secret` -- never hardcode it
7. Use **`.gitignore`** to exclude `.env` files -- secrets must never reach version control
8. **Raise on missing secrets** at startup rather than getting mysterious errors in production
