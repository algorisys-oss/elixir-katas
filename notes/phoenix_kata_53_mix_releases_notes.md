# Kata 53: Mix Releases

## What is a Mix Release?

A Mix Release packages your Phoenix application as a **self-contained binary**:
- Includes the Erlang/OTP runtime (BEAM VM)
- Includes all compiled BEAM bytecode
- Includes all Elixir/Erlang dependencies
- Does **not** include Mix, Elixir source code, or hex

The production server only needs the release tarball and environment variables -- no Elixir installation required.

---

## Why Use Releases?

| Development (`mix phx.server`) | Production (`mix release`) |
|------|------|
| Hot reloading | No reloading (must restart) |
| Mix available | No Mix needed |
| Verbose logging | Structured logging |
| Source maps | Minified assets |
| Slow startup | Fast startup (ms) |
| Large footprint | Minimal footprint |
| Not for production | The right way |

---

## Building a Release

```bash
# 1. Set production environment:
export MIX_ENV=prod

# 2. Get production dependencies:
mix deps.get --only prod

# 3. Compile:
mix compile

# 4. Compile JavaScript/CSS assets:
mix assets.deploy
# This runs: esbuild + mix phx.digest

# 5. Build the release:
mix release

# Output: _build/prod/rel/my_app/
```

---

## Asset Pipeline Before Release

```bash
# mix assets.deploy runs two steps:
# Step 1 -- esbuild compiles/bundles JS:
# assets/app.js -> priv/static/assets/app.js

# Step 2 -- phx.digest adds fingerprints:
mix phx.digest
# priv/static/assets/app.js
# -> priv/static/assets/app-abc123def.js
# + priv/static/cache_manifest.json

# The manifest lets Phoenix serve the right fingerprinted file:
# <script src={~p"/assets/app.js"} />
# -> <script src="/assets/app-abc123def.js" />
# Browser can cache with max-age=1year
```

---

## Release Structure

```
_build/prod/rel/my_app/
├── bin/
│   ├── my_app          # main executable script
│   └── server          # convenience script for Fly.io
├── erts-14.0.1/        # Erlang runtime (self-contained!)
├── lib/
│   ├── my_app-0.1.0/   # your app's BEAM files
│   ├── phoenix-1.7.x/  # Phoenix BEAM files
│   ├── ecto-3.11.x/    # Ecto BEAM files
│   └── ...             # all dependencies
├── releases/
│   └── 0.1.0/
│       ├── start.boot   # boot configuration
│       ├── sys.config   # system config
│       ├── vm.args      # BEAM VM arguments
│       └── runtime.exs  # runtime config (copied in)
└── tmp/
```

---

## Release Commands

```bash
# Start in foreground:
bin/my_app start

# Start with IEx attached:
bin/my_app start_iex

# Start as background daemon:
bin/my_app daemon

# Stop the app:
bin/my_app stop

# Connect IEx to a running node:
bin/my_app remote

# Check if running:
bin/my_app pid

# Print version:
bin/my_app version

# Run a one-off expression:
bin/my_app eval "IO.puts(:hello_world)"

# Run migrations:
bin/my_app eval "MyApp.Release.migrate()"
```

---

## Custom Release Module

Used for running migrations without Mix:

```elixir
# lib/my_app/release.ex:
defmodule MyApp.Release do
  @app :my_app

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(
        repo,
        &Ecto.Migrator.run(&1, :up, all: true)
      )
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} = Ecto.Migrator.with_repo(
      repo,
      &Ecto.Migrator.run(&1, :down, to: version)
    )
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

---

## mix.exs Release Configuration

```elixir
def project do
  [
    app: :my_app,
    version: "0.1.0",
    # ...
    releases: [
      my_app: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]  # also create a .tar.gz
      ]
    ]
  ]
end
```

---

## rel/overlays

Overlay files are copied into the release at build time:

```
rel/overlays/
├── bin/
│   ├── migrate       # custom migration script
│   └── server        # custom start script
└── etc/
    └── config.ini    # extra config files
```

```elixir
# mix.exs:
releases: [
  my_app: [
    include_executables_for: [:unix],
    overlays: "rel/overlays"
  ]
]
```

---

## Dockerfile (Multi-Stage Build)

Phoenix generates a `Dockerfile` with multi-stage builds:

```dockerfile
# Stage 1: Builder (has all dev tools)
FROM hexpm/elixir:1.16.0-erlang-26.2.1-debian-bullseye-slim AS builder

RUN apt-get update -y && \
    apt-get install -y build-essential git && \
    apt-get clean

WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY assets/ assets/
COPY priv/ priv/
COPY lib/ lib/
COPY config/ config/

RUN mix assets.deploy
RUN mix compile
RUN mix release

# Stage 2: Runtime (small, only what's needed)
FROM debian:bullseye-slim AS app

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 && \
    apt-get clean

WORKDIR /app
RUN chown nobody /app

# Copy only the release from builder:
COPY --from=builder --chown=nobody:root \
  /app/_build/prod/rel/my_app ./

USER nobody
ENV PHX_SERVER=true

CMD ["/app/bin/my_app", "start"]
```

Multi-stage builds: **build image** is ~1GB (has compilers). **Runtime image** is ~50MB (just the release).

---

## Build and Run with Docker

```bash
# Build the image:
docker build -t my_app:latest .

# Run it:
docker run -d \
  -p 4000:4000 \
  -e DATABASE_URL="postgres://..." \
  -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  -e PHX_HOST="example.com" \
  --name my_app \
  my_app:latest

# Run migrations:
docker exec my_app \
  bin/my_app eval "MyApp.Release.migrate()"

# Or a one-off migration container:
docker run --rm \
  -e DATABASE_URL="postgres://..." \
  my_app:latest bin/my_app eval "MyApp.Release.migrate()"
```

---

## Fly.io Deployment

Fly.io uses the generated Dockerfile natively:

```bash
# Initialize (sets up fly.toml):
fly launch

# Set secrets:
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set DATABASE_URL=postgres://...

# Deploy:
fly deploy

# Run migrations on deploy (fly.toml):
[deploy]
  release_command = "bin/my_app eval 'MyApp.Release.migrate()'"
```

---

## entrypoint.sh Pattern

```bash
#!/bin/bash
set -e

echo "Running migrations..."
bin/my_app eval "MyApp.Release.migrate()"

echo "Starting application..."
exec bin/my_app start
```

```dockerfile
COPY entrypoint.sh /app/bin/entrypoint.sh
RUN chmod +x /app/bin/entrypoint.sh
CMD ["/app/bin/entrypoint.sh"]
```

---

## Key Takeaways

1. **Mix releases** create self-contained binaries -- no Elixir/Mix needed on production servers
2. **Build assets first** (`mix assets.deploy`) before `mix release`
3. The release includes the **Erlang runtime** -- it's portable across the same OS/architecture
4. Use a **multi-stage Dockerfile**: builder image (large, has compilers) to runtime image (tiny, ~50MB)
5. **`lib/my_app/release.ex`** provides `migrate/0` for running migrations from a release
6. Run migrations with `bin/my_app eval "MyApp.Release.migrate()"` -- not Mix
7. **`config/runtime.exs`** is automatically included in releases -- it reads env vars at startup
8. **Fly.io** uses the Phoenix-generated Dockerfile directly -- `fly launch` + `fly deploy`
