# Kata 74: Application Config

## The Concept

Elixir uses a **layered configuration system** with config files for compile-time settings and `runtime.exs` for runtime settings. Understanding when each file is loaded is essential for proper application deployment.

```elixir
# config/config.exs - loaded at compile time
import Config

config :my_app,
  ecto_repos: [MyApp.Repo]

config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"]
```

## Config Files

### config/config.exs
Shared configuration loaded at **compile time**. Common settings across all environments.

### config/dev.exs
Development-specific overrides. Imported from config.exs.

### config/test.exs
Test-specific overrides. Database sandbox, disabled server.

### config/prod.exs
Production compile-time config. Static manifests, log levels.

### config/runtime.exs
Loaded at **application start** (runtime). Can read environment variables.

## Loading Order

```
Compile Time:
  1. config/config.exs
  2. config/{dev|test|prod}.exs (based on MIX_ENV)

Application Start:
  3. config/runtime.exs
```

## Accessing Config

### Application.get_env/3

Read config at runtime with an optional default:

```elixir
Application.get_env(:my_app, :timeout, 5000)
# => 5000 (if not configured)
```

### Application.fetch_env!/2

Like `get_env`, but raises if the key is not set:

```elixir
Application.fetch_env!(:my_app, :secret_key_base)
# => "abc123..." or raises ArgumentError
```

### Application.compile_env/3

Read config at **compile time** for module attributes:

```elixir
defmodule MyApp.Config do
  @pool_size Application.compile_env(:my_app, :pool_size, 10)

  def pool_size, do: @pool_size
end
```

Elixir tracks `compile_env` calls and warns if the value changes between compilations, ensuring your compiled code stays in sync with config.

### Application.put_env/3

Set config at runtime (useful in tests):

```elixir
Application.put_env(:my_app, :feature_flag, true)
```

## Compile-Time vs Runtime Config

| Aspect | Compile-Time (config.exs) | Runtime (runtime.exs) |
|--------|--------------------------|----------------------|
| When loaded | During `mix compile` | When app starts |
| Can read env vars? | No (System.get_env at compile time) | Yes |
| Suitable for secrets? | No | Yes |
| Changes require | Recompilation | Restart |
| Access via | `compile_env/3` or `get_env/3` | `get_env/3` |
| Overrides in releases | Not possible | Via env vars |

## Namespaced Config

Use module names as namespaces to organize related settings:

```elixir
# config.exs
config :my_app, MyApp.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.example.com",
  port: 587

# Access:
Application.get_env(:my_app, MyApp.Mailer)
# => [adapter: Swoosh.Adapters.SMTP, relay: "smtp.example.com", port: 587]
```

## Runtime.exs for Secrets

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL not set"

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE not set"

  config :my_app, MyAppWeb.Endpoint,
    secret_key_base: secret_key_base
end
```

## Config in Releases

When building releases with `mix release`, only `runtime.exs` can be customized after the release is built. All other config files are baked in at compile time.

```bash
# Build release
MIX_ENV=prod mix release

# Run with env vars
DATABASE_URL="ecto://..." SECRET_KEY_BASE="..." ./bin/my_app start
```

## Best Practices

1. **Secrets in runtime.exs**: Never hardcode passwords or API keys in config files.
2. **Use compile_env for attributes**: It tracks changes and ensures consistency.
3. **Provide defaults**: Always use `get_env/3` with a default value.
4. **Namespace config**: Use module names to group related settings.
5. **Validate at startup**: Use `raise` in `runtime.exs` for required env vars.

## Common Pitfalls

1. **Using System.get_env in config.exs**: This reads the env var at compile time, which is wrong for production deployments.
2. **Forgetting runtime.exs exists**: Many developers put everything in prod.exs, making releases inflexible.
3. **Missing defaults**: `get_env/2` returns `nil` if the key isn't set, which can cause subtle bugs.
4. **Not using compile_env**: Using `get_env` in module attributes works but won't warn you about config changes.
