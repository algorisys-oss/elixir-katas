# Kata 26: Layouts

## Layout System

Phoenix uses a **two-layer layout** system:

```
root.html.heex        ← HTML skeleton (<html>, <head>, <body>)
  └─ app.html.heex    ← App chrome (navbar, sidebar, footer)
       └─ template    ← Page content
```

---

## Root Layout

The outermost wrapper — the full HTML document:

```heex
<!-- lib/my_app_web/components/layouts/root.html.heex -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
    <.live_title>{assigns[:page_title] || "MyApp"}</.live_title>
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    <script defer phx-track-static src={~p"/assets/app.js"}></script>
  </head>
  <body>
    {@inner_content}
  </body>
</html>
```

`@inner_content` is where the app layout gets inserted.

## App Layout

The inner layout with navigation and structure:

```heex
<!-- lib/my_app_web/components/layouts/app.html.heex -->
<header>
  <nav>
    <.link navigate={~p"/"}>Home</.link>
    <.link navigate={~p"/products"}>Products</.link>
  </nav>
</header>

<main class="container mx-auto px-4 py-8">
  <.flash_group flash={@flash} />
  {@inner_content}
</main>

<footer>
  <p>© 2024 MyApp</p>
</footer>
```

---

## Setting Layouts

### In the Router (via pipeline)

```elixir
pipeline :browser do
  plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
end
```

### In a Controller

```elixir
# Use a different app layout:
def index(conn, _params) do
  conn
  |> put_layout(html: {MyAppWeb.Layouts, :admin})
  |> render(:index)
end

# No app layout (root only):
def embed(conn, _params) do
  conn
  |> put_layout(false)
  |> render(:embed)
end
```

### In LiveView

```elixir
live_session :admin, layout: {MyAppWeb.Layouts, :admin} do
  live "/admin", AdminLive
end
```

---

## @inner_content

The special assign that contains the rendered content from the layer below:

- In **root layout**: `@inner_content` = rendered app layout
- In **app layout**: `@inner_content` = rendered page template

---

## Multiple Layouts

Create different layouts for different sections:

```elixir
# In lib/my_app_web/components/layouts.ex:
defmodule MyAppWeb.Layouts do
  use MyAppWeb, :html

  embed_templates "layouts/*"

  # Or define as functions:
  def admin(assigns) do
    ~H"..."
  end
end
```

Files:
```
lib/my_app_web/components/layouts/
  root.html.heex   ← HTML shell
  app.html.heex     ← Default layout
  admin.html.heex   ← Admin layout
  auth.html.heex    ← Login/register layout
```

---

## Key Takeaways

1. Phoenix uses **two-layer layouts**: root (HTML shell) + app (page chrome)
2. `@inner_content` inserts content from the layer below
3. Set layouts via `put_root_layout` (pipeline) or `put_layout` (controller)
4. LiveView sessions can specify their own layout
5. Create multiple app layouts for different sections (admin, auth, etc.)
6. Root layout contains `<head>`, CSS/JS links, CSRF token
7. App layout contains navigation, flash messages, footer
