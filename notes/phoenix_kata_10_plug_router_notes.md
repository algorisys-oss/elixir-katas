# Kata 10: Plug Router

## What is Plug.Router?

`Plug.Router` is a **minimal routing DSL** built into the Plug library. It lets you build a complete web application **without Phoenix** — just Plug and Cowboy.

This is important because:
1. Phoenix's router is inspired by Plug.Router
2. Understanding Plug.Router shows you what Phoenix adds on top
3. It's perfect for tiny services, health check endpoints, or learning

---

## A Complete Plug.Router App

```elixir
defmodule MyApp.Router do
  use Plug.Router

  plug :match    # Find which route matches the request
  plug :dispatch # Execute the matched route's handler

  get "/" do
    send_resp(conn, 200, "Welcome!")
  end

  get "/hello/:name" do
    send_resp(conn, 200, "Hello, #{name}!")
  end

  post "/api/echo" do
    {:ok, body, conn} = read_body(conn)
    send_resp(conn, 200, body)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
```

### Starting the Server

```elixir
# In your application supervisor:
children = [
  {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [port: 4001]}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

That's it! A complete web server in ~20 lines.

---

## Route Macros

Plug.Router provides macros that match HTTP methods and paths:

| Macro | Matches |
|-------|---------|
| `get "/path"` | GET /path |
| `post "/path"` | POST /path |
| `put "/path"` | PUT /path |
| `patch "/path"` | PATCH /path |
| `delete "/path"` | DELETE /path |
| `match "/path"` | Any method |
| `options "/path"` | OPTIONS /path |

### Path Parameters

```elixir
get "/users/:id" do
  # `id` is automatically bound as a variable
  send_resp(conn, 200, "User #{id}")
end

get "/posts/:post_id/comments/:id" do
  # Both `post_id` and `id` are bound
  send_resp(conn, 200, "Comment #{id} on post #{post_id}")
end
```

### Wildcard Matching

```elixir
# Catch-all route (must be last!)
match _ do
  send_resp(conn, 404, "Not Found")
end

# Glob matching
get "/files/*glob" do
  path = Enum.join(glob, "/")
  send_resp(conn, 200, "File: #{path}")
end
```

---

## Adding Plugs to the Router

You can add any plug before `:match` and `:dispatch`:

```elixir
defmodule MyApp.Router do
  use Plug.Router

  # These plugs run BEFORE routing
  plug Plug.Logger                                    # Log requests
  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    json_decoder: Jason                               # Parse request bodies
  plug :match
  plug :dispatch

  post "/api/users" do
    # conn.body_params is available because of Plug.Parsers
    name = conn.body_params["name"]
    send_resp(conn, 201, "Created user: #{name}")
  end
end
```

### Plug Order Matters

```
Request arrives
    │
    ▼
Plug.Logger        ← Logs the request
    │
    ▼
Plug.Parsers       ← Parses JSON/form body
    │
    ▼
:match             ← Finds matching route
    │
    ▼
:dispatch          ← Executes route handler
    │
    ▼
Response sent
```

Plugs before `:match` run for **every** request. This is where you put authentication, logging, and body parsing.

---

## Forwarding to Sub-Routers

You can compose multiple routers together:

```elixir
defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/api", to: MyApp.ApiRouter
  forward "/admin", to: MyApp.AdminRouter

  get "/" do
    send_resp(conn, 200, "Main site")
  end
end

defmodule MyApp.ApiRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/users" do
    send_resp(conn, 200, ~s({"users": []}))
  end

  get "/products" do
    send_resp(conn, 200, ~s({"products": []}))
  end
end
```

Now `GET /api/users` is handled by `MyApp.ApiRouter`, and `GET /` by the main router.

---

## Plug.Router vs Phoenix.Router

| Feature | Plug.Router | Phoenix.Router |
|---------|------------|----------------|
| Route matching | `get "/path"` | `get "/path", Controller, :action` |
| Path params | `:id` bound as variable | `:id` in `conn.params` |
| Pipelines | Manual plug calls | Named pipelines |
| Scoping | `forward "/prefix"` | `scope "/prefix"` |
| Named routes | No | `~p"/users/#{id}"` |
| LiveView | No | Built-in |
| Channels | No | Built-in |
| Code generation | No | `mix phx.gen.*` |
| Error handling | Manual | Built-in error views |

**Plug.Router** is for simple apps. **Phoenix.Router** adds pipelines, scoping, named routes, and integrates with the full Phoenix ecosystem.

---

## Example: JSON API with Plug.Router

```elixir
defmodule MyApp.ApiRouter do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Jason

  plug :match
  plug :dispatch

  @users [
    %{id: 1, name: "Alice"},
    %{id: 2, name: "Bob"}
  ]

  get "/users" do
    json_resp(conn, 200, @users)
  end

  get "/users/:id" do
    user = Enum.find(@users, &(&1.id == String.to_integer(id)))

    if user do
      json_resp(conn, 200, user)
    else
      json_resp(conn, 404, %{error: "User not found"})
    end
  end

  post "/users" do
    name = conn.body_params["name"]
    user = %{id: 3, name: name}
    json_resp(conn, 201, user)
  end

  match _ do
    json_resp(conn, 404, %{error: "Not found"})
  end

  defp json_resp(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
```

---

## Key Takeaways

1. **Plug.Router** is a minimal routing DSL — build web apps without Phoenix
2. Routes use macros: `get`, `post`, `put`, `delete`, `match`
3. Path params (`:id`) are bound as local variables in the route block
4. `plug :match` + `plug :dispatch` are required — they do the routing
5. `forward "/prefix"` composes sub-routers (like Phoenix scopes)
6. Phoenix.Router adds pipelines, named routes, LiveView, and more on top
7. Plug.Router is great for learning and tiny services
