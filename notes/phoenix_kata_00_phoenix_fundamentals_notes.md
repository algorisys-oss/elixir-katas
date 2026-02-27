# Kata 00: Phoenix Fundamentals

## What is Phoenix?

Phoenix is a **web framework** written in Elixir that gives you everything you need to build fast, reliable, real-time web applications. Think of it as Elixir's answer to Ruby on Rails, Django, or Express — but built on top of the BEAM virtual machine, which means it inherits all the concurrency, fault-tolerance, and scalability superpowers that Elixir and Erlang are famous for.

### Why Phoenix?

- **Speed**: Phoenix is consistently one of the fastest web frameworks in benchmarks. It can handle millions of concurrent connections on a single server.
- **Real-time built-in**: WebSockets and real-time features (via Channels and LiveView) are first-class citizens, not afterthoughts.
- **Fault-tolerant**: If one request crashes, it doesn't take down other requests. Each connection runs in its own lightweight BEAM process.
- **Developer-friendly**: Clear conventions, helpful error pages, and excellent documentation make it pleasant to work with.

### Who Uses Phoenix?

Companies like **Discord** (handling millions of concurrent users), **Bleacher Report** (serving 150 million push notifications during events), and **Pinterest** (for backend services) use Elixir and Phoenix in production.

---

## The MVC Pattern

Phoenix follows the **Model-View-Controller (MVC)** pattern — a proven way to organize web applications:

```
┌──────────────┐     ┌────────────┐     ┌──────────┐     ┌──────────┐
│   Browser    │────▶│  Router    │────▶│Controller│────▶│   View   │
│  (Request)   │     │            │     │          │     │(Template)│
└──────────────┘     └────────────┘     └──────────┘     └──────────┘
                                              │                │
                                              ▼                │
                                        ┌──────────┐          │
                                        │  Model   │          │
                                        │ (Schema) │          ▼
                                        │  (Repo)  │    ┌──────────┐
                                        └──────────┘    │ Response │
                                                        │  (HTML)  │
                                                        └──────────┘
```

- **Model** (Ecto Schemas + Repo): Manages your data — database queries, validations, and data transformations.
- **View / Template**: Renders the response — HTML pages, JSON, or other formats.
- **Controller**: The coordinator — receives the request, talks to the model, picks a view, and sends the response.

---

## The Request Lifecycle

When a browser sends a request to your Phoenix app, here's exactly what happens:

```
HTTP Request
    │
    ▼
┌─────────────────┐
│    Endpoint      │  ← Entry point. Handles static files, parsing, logging.
│  (endpoint.ex)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Router       │  ← Matches the URL to a controller action.
│  (router.ex)     │     Also runs "pipelines" (groups of plugs).
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Pipeline      │  ← A chain of Plugs (middleware). Example: :browser
│  (:browser)      │     pipeline adds session, CSRF protection, etc.
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Controller     │  ← Your code! Fetches data, makes decisions.
│ (page_controller)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   View/Template  │  ← Renders the response (HTML, JSON, etc.)
│  (page_html)     │
└─────────────────┘
         │
         ▼
    HTTP Response
```

### Key Insight: Everything is a Plug

In Phoenix, the entire request lifecycle is built on **Plug** — a simple specification for composable modules that transform a connection. Think of plugs as middleware (like Express middleware or Rack middleware), but more explicit and composable.

Every step in the pipeline above is just a plug that takes a connection (`%Plug.Conn{}`) and returns a (possibly modified) connection.

---

## The `%Plug.Conn{}` Struct

The **connection struct** is the single most important data structure in Phoenix. It represents the entire HTTP request and response in one struct:

```elixir
%Plug.Conn{
  # Request fields (filled in by the web server)
  host: "localhost",
  port: 4000,
  method: "GET",
  path_info: ["users", "42"],
  query_string: "sort=name",
  req_headers: [{"accept", "text/html"}, ...],

  # Fields filled in by plugs along the way
  params: %{"id" => "42", "sort" => "name"},
  cookies: %{},
  assigns: %{},          # ← Your custom data! (e.g., current_user)

  # Response fields (filled in by your controller/view)
  status: 200,
  resp_body: "<html>...</html>",
  resp_headers: [{"content-type", "text/html"}]
}
```

### The Flow

```elixir
# A plug takes a conn and returns a conn
conn
|> fetch_session()       # Plug: loads session data into conn
|> fetch_flash()         # Plug: loads flash messages
|> protect_from_forgery() # Plug: adds CSRF protection
|> MyController.index()  # Your code: adds assigns, renders response
```

This "data flowing through transformations" pattern is very Elixir — it's just the pipe operator applied to web requests!

---

## Phoenix Project Structure

When you create a new Phoenix project with `mix phx.new my_app`, you get this structure:

```
my_app/
├── assets/              # Frontend: CSS, JavaScript
│   ├── css/
│   ├── js/
│   └── vendor/
│
├── config/              # Configuration files
│   ├── config.exs       # Shared config (all environments)
│   ├── dev.exs          # Development-specific config
│   ├── prod.exs         # Production config
│   ├── runtime.exs      # Runtime config (env vars)
│   └── test.exs         # Test config
│
├── lib/
│   ├── my_app/          # Business logic (Models, Contexts)
│   │   ├── application.ex   # OTP Application (supervision tree)
│   │   ├── repo.ex          # Database connection (Ecto Repo)
│   │   └── accounts/        # Context: groups related functionality
│   │       ├── user.ex      # Schema: defines data structure
│   │       └── ...
│   │
│   └── my_app_web/      # Web layer (Controllers, Views, Templates)
│       ├── endpoint.ex      # HTTP entry point
│       ├── router.ex        # URL routing
│       ├── controllers/     # Handle requests
│       ├── components/      # Reusable UI components
│       └── live/            # LiveView modules
│
├── priv/
│   ├── repo/
│   │   └── migrations/  # Database migrations
│   └── static/          # Static assets (served directly)
│
├── test/                # Tests
├── mix.exs              # Project definition & dependencies
└── mix.lock             # Locked dependency versions
```

### The Two Main Directories

Phoenix separates your code into two key areas:

1. **`lib/my_app/`** — Your **business logic**. This is where Ecto schemas, contexts, and domain logic live. This code knows nothing about HTTP, HTML, or web concepts.

2. **`lib/my_app_web/`** — Your **web interface**. Controllers, views, templates, channels, and LiveViews. This layer talks to the business logic layer but handles all the web-specific concerns.

This separation matters because your business logic can be reused in different contexts — a CLI tool, a background job, or an API could all use the same `lib/my_app/` code.

---

## The Router

The router is where you define which URLs map to which code. Here's a typical router:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # A pipeline is a group of plugs that run for certain requests
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Routes for browser requests
  scope "/", MyAppWeb do
    pipe_through :browser       # Run the :browser pipeline first

    get "/", PageController, :home           # GET /  → PageController.home/2
    get "/about", PageController, :about     # GET /about → PageController.about/2

    resources "/users", UserController       # Generates all CRUD routes
    # GET    /users          → UserController.index/2
    # GET    /users/new      → UserController.new/2
    # POST   /users          → UserController.create/2
    # GET    /users/:id      → UserController.show/2
    # GET    /users/:id/edit → UserController.edit/2
    # PUT    /users/:id      → UserController.update/2
    # DELETE /users/:id      → UserController.delete/2
  end

  # Routes for API requests
  scope "/api", MyAppWeb.Api do
    pipe_through :api

    get "/status", StatusController, :index
  end
end
```

### Key Concepts

- **`scope`**: Groups routes under a URL prefix and module namespace.
- **`pipe_through`**: Specifies which pipeline(s) to run before the controller.
- **`resources`**: A shortcut that generates all 7 RESTful routes for a resource.
- **`get`, `post`, `put`, `delete`**: Define individual routes for specific HTTP methods.

You can see all routes with:
```bash
mix phx.routes
```

---

## Controllers

Controllers are the "decision-makers" of your app. They receive the request, do something with it, and send a response:

```elixir
defmodule MyAppWeb.PageController do
  use MyAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)    # Renders the "home" template
  end

  def about(conn, _params) do
    render(conn, :about, company: "Acme Inc")  # Pass data to template
  end
end
```

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()        # Call the business logic
    render(conn, :index, users: users)   # Pass users to template
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)        # Pattern match the params
    render(conn, :show, user: user)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created!")
        |> redirect(to: ~p"/users/#{user}")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
```

### What Controllers Do

1. **Receive** the connection (`conn`) and request parameters (`params`)
2. **Call** business logic functions (from contexts like `Accounts`)
3. **Respond** by rendering a template, redirecting, or sending JSON

### What Controllers Don't Do

Controllers should NOT contain business logic. Don't put database queries, complex calculations, or validation rules in controllers. That belongs in your contexts (`lib/my_app/`).

---

## Essential Mix Tasks

Phoenix provides several Mix tasks to help you during development:

```bash
# Create a new Phoenix project
mix phx.new my_app

# Start the development server
mix phx.server

# Start an interactive server (with IEx shell)
iex -S mix phx.server

# Show all routes
mix phx.routes

# Generate a complete HTML resource (migration + schema + controller + views)
mix phx.gen.html Accounts User users name:string email:string

# Generate a JSON API resource
mix phx.gen.json Accounts User users name:string email:string

# Generate a LiveView resource
mix phx.gen.live Accounts User users name:string email:string

# Generate just a context + schema (no web layer)
mix phx.gen.context Accounts User users name:string email:string

# Database tasks
mix ecto.create          # Create the database
mix ecto.migrate         # Run pending migrations
mix ecto.rollback        # Rollback the last migration
mix ecto.reset           # Drop + create + migrate + seed

# Generate a migration
mix ecto.gen.migration add_users_table
```

---

## Phoenix vs Other Frameworks

| Feature | Phoenix | Rails | Django | Express |
|---------|---------|-------|--------|---------|
| Language | Elixir | Ruby | Python | JavaScript |
| Concurrency | BEAM processes (millions) | Threads (limited) | Threads/async | Event loop (single) |
| Real-time | Built-in (Channels/LiveView) | Action Cable (add-on) | Django Channels (add-on) | Socket.io (add-on) |
| Fault tolerance | Per-process isolation | Process crash = down | Process crash = down | Uncaught exception = down |
| Performance | ~15μs response times | ~5ms response times | ~5ms response times | ~1ms response times |
| Hot code reload | Built-in (BEAM) | Requires restart | Requires restart | Requires restart |

---

## What's Next?

In the following katas, you'll get hands-on with each of these concepts:
- **Routing**: Defining routes, scopes, and pipelines
- **Controllers**: Handling requests and responses
- **Templates**: Building HTML with HEEx (HTML + Embedded Elixir)
- **Ecto**: Working with databases — schemas, migrations, and queries
- **Plugs**: Writing custom middleware
- **Channels**: Real-time communication with WebSockets
- **LiveView**: Building interactive UIs without writing JavaScript
