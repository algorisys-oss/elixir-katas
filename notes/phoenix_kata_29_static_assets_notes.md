# Kata 29: Static Assets

## Asset Pipeline Overview

Phoenix uses **esbuild** for JavaScript and **Tailwind CSS** for styling:

```
assets/
  js/
    app.js          ← Main JS entry point
  css/
    app.css         ← Main CSS entry point (Tailwind)
  vendor/           ← Third-party JS libraries

priv/static/
  assets/           ← Built output (app.js, app.css)
  images/           ← Static images
  favicon.ico       ← Favicon
  robots.txt        ← Search engine directives
```

---

## How It Works

1. **Development**: File watchers auto-rebuild on save
2. **Production**: `mix assets.deploy` builds and minifies

```elixir
# config/dev.exs — watchers run alongside the server:
config :my_app, MyAppWeb.Endpoint,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:my_app, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:my_app, ~w(--watch)]}
  ]
```

---

## Referencing Assets in Templates

Use `~p` for cache-busted URLs:

```heex
<link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
<script defer phx-track-static src={~p"/assets/app.js"}></script>
<img src={~p"/images/logo.png"} alt="Logo" />
```

`phx-track-static` tells Phoenix to track these files for change detection.

In production, files get fingerprinted hashes: `/assets/app-ABC123.css`

---

## Plug.Static

Static files are served by `Plug.Static` in the endpoint:

```elixir
plug Plug.Static,
  at: "/",
  from: :my_app,
  gzip: false,
  only: MyAppWeb.static_paths()
```

`static_paths/0` returns which directories to serve:

```elixir
def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
```

---

## Tailwind CSS

Phoenix ships with Tailwind CSS. Configuration in `assets/tailwind.config.js`:

```javascript
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/my_app_web.ex",
    "../lib/my_app_web/**/*.*ex"
  ],
  theme: { extend: {} },
  plugins: [require("@tailwindcss/forms")]
}
```

---

## Cache Busting

In production, Phoenix generates a **cache manifest** (`cache_manifest.json`) mapping filenames to digested versions:

```json
{
  "assets/app.css": "assets/app-ABC123.css",
  "assets/app.js": "assets/app-DEF456.js"
}
```

`~p"/assets/app.css"` automatically resolves to the digested version. Browsers cache aggressively, and new deploys get new hashes.

---

## Deployment

```bash
# Build assets for production:
mix assets.deploy

# This runs:
# 1. esbuild (bundle + minify JS)
# 2. tailwind (compile + minify CSS)
# 3. phx.digest (fingerprint files, generate manifest)
```

---

## Key Takeaways

1. **esbuild** bundles JavaScript, **Tailwind** compiles CSS
2. Use `~p"/assets/app.css"` for **cache-busted** static asset URLs
3. `phx-track-static` enables automatic asset change detection
4. `Plug.Static` serves files from `priv/static/`
5. `static_paths/0` controls which directories are served
6. File watchers auto-rebuild in development
7. `mix assets.deploy` builds, minifies, and fingerprints for production
