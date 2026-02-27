# Elixir Katas

Interactive learning platform for Elixir, Phoenix, and LiveView built with Phoenix LiveView.

## Tech Stack

Elixir, Phoenix, LiveView, SQLite (via Ecto), Tailwind CSS, esbuild

## Kata Tracks

| Track | Data Module | Route | File Prefix | Layout | Color |
|-------|-------------|-------|-------------|--------|-------|
| Core Elixir (85) | `ElixirKataData` | `/elixir-katas` | `elixir_kata_` | `:elixir_app` | Emerald |
| Phoenix Web (55) | `PhoenixKataData` | `/phoenix-katas` | `phoenix_kata_` | `:phoenix_app` | Amber |
| Phoenix API (20) | `PhoenixApiKataData` | `/phoenix-api-katas` | `phoenix_api_kata_` | `:phoenix_api_app` | Rose |
| LiveView (97) | `LiveviewKataData` | `/liveview-katas` | `kata_` | `:app` | Indigo |

## Adding a New Kata

1. Add entry to the data module (`lib/elixir_katas_web/<track>_kata_data.ex`)
2. Create `live_component` file: `lib/elixir_katas_web/live/<prefix><id>_<slug>_live.ex`
3. Create notes file: `notes/<prefix><id>_<slug>_notes.md`

Katas are discovered dynamically via `Path.wildcard/1` — no registration needed beyond the data entry.

## Key Files

- `lib/elixir_katas_web/router.ex` — routes and live_sessions per track
- `lib/elixir_katas_web/components/layouts.ex` — sidebar layouts per track
- `lib/elixir_katas_web/components/kata_components.ex` — shared kata_viewer, kata_card
- `lib/elixir_katas/katas/dynamic_compiler.ex` — runtime compilation for live editing

## Commands

```bash
mix setup          # Install deps + setup DB
mix phx.server     # Start dev server at localhost:4000
mix test           # Run tests
mix compile        # Check for compilation errors
```
