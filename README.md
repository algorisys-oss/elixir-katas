# Elixir Katas

An interactive learning platform for mastering Elixir and Phoenix LiveView through hands-on exercises. Built with Phoenix LiveView, featuring 83 core Elixir katas and 100+ LiveView katas with live code editing, real-time compilation, and searchable/filterable index pages.

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
      elixir_kata_*_live.ex    # Core Elixir katas (01-83)
      kata_*_live.ex           # LiveView katas (00-140)
    elixir_kata_data.ex        # Elixir kata sections, tags, metadata
    liveview_kata_data.ex      # LiveView kata sections, tags, metadata
notes/
  elixir_kata_*_notes.md       # Core Elixir kata notes
  kata_*_notes.md              # LiveView kata notes
```

## Curriculum

### Core Elixir Katas (83 katas, 11 sections)

| Section | Topics |
|---------|--------|
| 1. Types & Basics | Integer, float, string, atom, boolean, operators |
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

### LiveView Katas (100+ katas, 10 sections)

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
