# Kata 01: API Pipeline

## The `:api` Pipeline

Phoenix ships with two default pipelines in `router.ex`:

```elixir
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
```

The `:api` pipeline is intentionally minimal — one plug. API clients don't need sessions, CSRF protection, or HTML layouts.

## Adding Custom API Plugs

You'll often extend the `:api` pipeline with authentication:

```elixir
pipeline :api do
  plug :accepts, ["json"]
end

# A separate pipeline for authenticated API routes
pipeline :api_auth do
  plug MyAppWeb.Plugs.VerifyApiToken
end

scope "/api", MyAppWeb.Api do
  pipe_through :api

  # Public endpoints
  post "/auth/login", AuthController, :login

  # Protected endpoints
  pipe_through :api_auth
  resources "/users", UserController, except: [:new, :edit]
end
```

## Key Takeaway

The `:api` pipeline is **stateless** — no cookies, no sessions. Authentication happens via tokens in the `Authorization` header, not session cookies.
