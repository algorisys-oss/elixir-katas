# Kata 12: mix phx.new

## Creating a Phoenix Project

Everything starts with one command:

```bash
mix phx.new my_app
```

This generates a complete Phoenix project with:
- Web server (Cowboy)
- Database integration (Ecto + PostgreSQL)
- Asset pipeline (esbuild + Tailwind)
- Testing setup (ExUnit)
- LiveView support
- Authentication-ready structure

---

## Generator Options

```bash
# Standard app (full features)
mix phx.new my_app

# Without database (no Ecto)
mix phx.new my_app --no-ecto

# Without HTML views (API only)
mix phx.new my_app --no-html

# Without LiveView
mix phx.new my_app --no-live

# Without assets (no esbuild/tailwind)
mix phx.new my_app --no-assets

# Without mailer
mix phx.new my_app --no-mailer

# Different database
mix phx.new my_app --database mysql
mix phx.new my_app --database sqlite3

# Umbrella project
mix phx.new my_app --umbrella
```

---

## Project Structure Walkthrough

After running `mix phx.new my_app`, here's what you get:

```
my_app/
├── config/                  # Configuration
│   ├── config.exs           # Shared config (all environments)
│   ├── dev.exs              # Development config
│   ├── test.exs             # Test config
│   ├── prod.exs             # Production compile-time config
│   └── runtime.exs          # Production runtime config
│
├── lib/
│   ├── my_app/              # Business logic (non-web)
│   │   ├── application.ex   # OTP application, supervision tree
│   │   ├── repo.ex          # Database repository
│   │   └── mailer.ex        # Email sending
│   │
│   └── my_app_web/          # Web layer
│       ├── endpoint.ex      # HTTP entry point (plugs)
│       ├── router.ex        # URL → controller mapping
│       ├── telemetry.ex     # Metrics & monitoring
│       ├── components/
│       │   ├── core_components.ex  # Shared UI components
│       │   └── layouts.ex          # Page layouts
│       ├── controllers/
│       │   ├── page_controller.ex  # Default controller
│       │   ├── page_html.ex        # View module
│       │   └── page_html/
│       │       └── home.html.heex  # Template
│       └── live/             # LiveView modules (added later)
│
├── priv/
│   ├── repo/
│   │   ├── migrations/      # Database migrations
│   │   └── seeds.exs        # Seed data
│   └── static/              # Static assets (served directly)
│       ├── favicon.ico
│       └── robots.txt
│
├── assets/                  # Frontend assets (compiled)
│   ├── js/
│   │   └── app.js           # JavaScript entry point
│   ├── css/
│   │   └── app.css          # CSS entry point
│   └── vendor/              # Third-party JS
│
├── test/                    # Tests
│   ├── my_app/              # Business logic tests
│   ├── my_app_web/          # Web layer tests
│   ├── support/             # Test helpers
│   └── test_helper.exs      # Test configuration
│
├── mix.exs                  # Project definition & dependencies
├── mix.lock                 # Locked dependency versions
├── .formatter.exs           # Code formatter config
└── .gitignore
```

---

## Key Files Explained

### `mix.exs` — Project Definition

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MyApp.Application, []},  # ← App starts here
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end
end
```

### `lib/my_app/application.ex` — Supervision Tree

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,          # Database connection pool
      MyAppWeb.Telemetry,  # Metrics
      {Phoenix.PubSub, name: MyApp.PubSub},  # PubSub for channels/LiveView
      MyAppWeb.Endpoint    # Web server (starts Cowboy)
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### `lib/my_app_web/endpoint.ex` — HTTP Entry Point

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  plug Plug.Static, ...      # Serve static files
  plug Plug.RequestId         # Add request ID
  plug Plug.Telemetry, ...    # Timing metrics
  plug Plug.Parsers, ...      # Parse request body
  plug Plug.MethodOverride    # Support _method param
  plug Plug.Head              # Convert HEAD → GET
  plug Plug.Session, ...      # Session management
  plug MyAppWeb.Router        # Route to controller
end
```

### `lib/my_app_web/router.ex` — Routing

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", MyAppWeb do
    pipe_through :browser
    get "/", PageController, :home
  end
end
```

---

## The Two Directories: `my_app` vs `my_app_web`

Phoenix enforces a clean separation:

```
lib/my_app/          → Business logic
lib/my_app_web/      → Web interface
```

| `my_app/` | `my_app_web/` |
|-----------|---------------|
| Ecto schemas | Controllers |
| Contexts (business logic) | LiveViews |
| Background jobs | Templates (HEEx) |
| External API clients | Components |
| Domain rules | Router |

**Rule**: `my_app_web` can call `my_app`, but `my_app` should NEVER call `my_app_web`. The web layer is just one interface to your business logic.

---

## Essential Mix Tasks

```bash
# Create the project
mix phx.new my_app

# Install dependencies
mix deps.get

# Create the database
mix ecto.create

# Run migrations
mix ecto.migrate

# Start the server
mix phx.server

# Start with IEx
iex -S mix phx.server

# List all routes
mix phx.routes

# Generate authentication
mix phx.gen.auth Accounts User users

# Generate a context with CRUD
mix phx.gen.context Blog Post posts title:string body:text

# Generate HTML scaffold
mix phx.gen.html Blog Post posts title:string body:text

# Generate a LiveView scaffold
mix phx.gen.live Blog Post posts title:string body:text

# Generate a JSON API
mix phx.gen.json Blog Post posts title:string body:text

# Run tests
mix test

# Format code
mix format
```

---

## First Run

```bash
$ mix phx.new my_app
$ cd my_app
$ mix setup          # deps.get + ecto.setup + assets.setup
$ mix phx.server     # Start on http://localhost:4000
```

Open `http://localhost:4000` and you'll see the Phoenix welcome page.

---

## Key Takeaways

1. `mix phx.new` generates a complete, production-ready project structure
2. `lib/my_app/` is business logic, `lib/my_app_web/` is the web interface
3. The **Endpoint** is the HTTP entry point — a chain of plugs
4. The **Router** maps URLs to controllers/LiveViews
5. `config/` has per-environment configuration files
6. `priv/` holds database migrations, seeds, and static files
7. `assets/` contains frontend JS/CSS (compiled by esbuild/tailwind)
8. Use `mix phx.server` to start, `mix phx.routes` to see routes
