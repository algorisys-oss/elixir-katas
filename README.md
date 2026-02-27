# Elixir Katas

An interactive learning platform for mastering Elixir and Phoenix LiveView through hands-on exercises. Built with Phoenix LiveView, featuring 85 core Elixir katas, 55 Phoenix Web katas, 20 Phoenix API katas, and 97 LiveView katas with live code editing, real-time compilation, and searchable/filterable index pages.

## Prerequisites

- **Erlang** >= 26.0
- **Elixir** >= 1.15
- **Node.js** >= 18 (for asset compilation)

### System Dependencies

Some katas require OS-level packages to be installed:

#### ImageMagick (for Kata 97 - Image Processing)

```bash
# Ubuntu/Debian
sudo apt-get install imagemagick

# macOS
brew install imagemagick

# Fedora
sudo dnf install ImageMagick
```

#### wkhtmltopdf (for Kata 98 - PDF Generation)

```bash
# Ubuntu/Debian
sudo apt-get install wkhtmltopdf

# macOS
brew install wkhtmltopdf

# Fedora
sudo dnf install wkhtmltopdf
```

#### SQLite3 (database)

```bash
# Ubuntu/Debian
sudo apt-get install sqlite3 libsqlite3-dev

# macOS (usually pre-installed)
brew install sqlite3

# Fedora
sudo dnf install sqlite sqlite-devel
```

## Getting Started

```bash
# Install Elixir dependencies
mix setup

# Start the Phoenix server
mix phx.server

# Or start inside IEx
iex -S mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Project Structure

```
lib/
  elixir_katas_web/
    live/
      elixir_kata_*_live.ex        # Core Elixir katas (00-84)
      phoenix_kata_*_live.ex       # Phoenix Web katas (00-54)
      phoenix_api_kata_*_live.ex   # Phoenix API katas (00-19)
      kata_*_live.ex               # LiveView katas (00-140)
    elixir_kata_data.ex            # Elixir kata sections, tags, metadata
    phoenix_kata_data.ex           # Phoenix Web kata sections, tags, metadata
    phoenix_api_kata_data.ex       # Phoenix API kata sections, tags, metadata
    liveview_kata_data.ex          # LiveView kata sections, tags, metadata
notes/
  elixir_kata_*_notes.md           # Core Elixir kata notes
  phoenix_kata_*_notes.md          # Phoenix Web kata notes
  phoenix_api_kata_*_notes.md      # Phoenix API kata notes
  kata_*_notes.md                  # LiveView kata notes
```

## Curriculum

### Core Elixir Katas (85 katas, 12 sections)

| Section | Topics |
|---------|--------|
| 0. Foundations | Elixir foundations overview |
| 1. Types, Operators & Basics | Integer, float, string, atom, boolean, operators |
| 2. Pattern Matching | Match operator, tuples, lists, maps, pin operator |
| 3. Functions | Anonymous, named, guards, recursion, higher-order |
| 4. Control Flow | Case, cond, if, with, pipe, comprehensions |
| 5. Enum & Stream | Map, filter, reduce, streams, ranges |
| 6. Strings & Binaries | UTF-8, charlists, regex, sigils, formatting |
| 7. Structs & Protocols | Structs, protocols, behaviours, polymorphism |
| 8. Processes | Spawn, send/receive, links, monitors, Task, Agent |
| 9. GenServer & OTP | GenServer, supervisors, Registry, ETS |
| 10. Advanced | Macros, quote/unquote, application config |
| 11. Essentials | IO/File, Erlang interop, ExUnit, debugging |

### Phoenix Web Katas (55 katas, 14 sections)

| Section | Topics |
|---------|--------|
| 0. Foundations | Phoenix fundamentals, MVC, request lifecycle |
| 1. How the Web Works | HTTP protocol, URLs, HTML forms, client-server, state |
| 2. Elixir Web Stack | TCP sockets, HTTP parsing, Cowboy, Plug basics |
| 3. Phoenix First Steps | mix phx.new, endpoint, first route, route params |
| 4. Routing in Depth | RESTful resources, nested routes, pipelines, verified routes |
| 5. Controllers & Responses | Actions, params, JSON APIs, flash, error handling |
| 6. Views & Templates | HEEx, layouts, function components, helpers, static assets |
| 7. Custom Plugs | Function plugs, module plugs, Plug.Conn, auth plug |
| 8. Ecto Foundations | Schema, changesets, Repo CRUD, queries, associations |
| 9. Contexts & Architecture | Phoenix contexts, CRUD patterns, multi-context design |
| 10. Authentication & Security | Auth generator, sessions, authorization, CSRF |
| 11. Channels & Real-time | WebSockets, channel basics, broadcasting, presence |
| 12. Testing | Controller tests, context tests, integration tests |
| 13. Production & Deployment | Configuration, Mix releases, telemetry & monitoring |

### Phoenix API Katas (20 katas, 10 sections)

| Section | Topics |
|---------|--------|
| 0. API Foundations | REST conventions, JSON API design |
| 1. API Routing & Controllers | API pipeline, resource routes, controller actions |
| 2. Request & Response | Params, JSON encoding, status codes, error handling |
| 3. Authentication | Bearer tokens, JWT, API keys |
| 4. Authorization | Role-based access, policy modules |
| 5. File Operations | Multipart uploads, downloads, streaming |
| 6. Data & Pagination | Filtering, sorting, cursor/offset pagination |
| 7. Middleware & Security | Rate limiting, CORS, custom plugs |
| 8. Testing APIs | ConnTest, authenticated endpoint testing |
| 9. Advanced | Webhooks, OpenAPI, background jobs |

### LiveView Katas (97 katas, 10 sections)

| Section | Topics |
|---------|--------|
| 1. Basics & State | Hello world, counter, toggler, events, calculator |
| 2. Lists & Data | CRUD, filter, sort, paginate, grid, tree |
| 3. Forms & Validation | Inputs, selects, validation, uploads, wizard |
| 4. Navigation & Routing | URL params, breadcrumbs, redirects, i18n |
| 5. Components & UI | Functional components, modal, dropdown, flash |
| 6. LiveComponents | Stateful components, send_update, parent-child |
| 7. Data & Persistence | Changesets, CRUD, streams, bulk actions |
| 8. Real-time & PubSub | Clock, chat, presence, cursors, game state |
| 9. JS Interop & Hooks | Focus, scroll, clipboard, charts, hooks |
| 10. Advanced | Async, uploads, PDF, CSV, GenServer, state machines |

## Learn More

- Phoenix: https://hexdocs.pm/phoenix
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view
- Elixir: https://elixir-lang.org/getting-started/introduction.html
- Elixir Forum: https://elixirforum.com
