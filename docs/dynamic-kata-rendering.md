# Dynamic Kata Rendering

How user code edits flow from the editor through compilation to a live demo — with no page reloads.

## Architecture Overview

```
User types in CodeMirror editor (browser)
    │  (1000ms debounce)
    ▼
JavaScript Hook pushes "save_source" event via WebSocket
    │
    ▼
KataHostLive.handle_event("save_source")
    ├── Immediately: assign compiling: true (shows spinner)
    └── Spawn Task.async ──►  DynamicCompiler.compile/3
                               ├── Generate unique module name
                               ├── Regex-rewrite defmodule line
                               └── Code.compile_string/1
    │
    ▼
Task completes → handle_info receives result
    ├── Success: assign dynamic_module to new module
    └── Failure: assign compile_error message
    │
    ▼
LiveView re-renders template
    └── <.live_component module={@dynamic_module} id="kata-sandbox" />
        └── New compiled kata component mounts with updated logic
```

## Key Files

| Component | File |
|-----------|------|
| Host LiveView | `lib/elixir_katas_web/live/kata_host_live.ex` |
| Dynamic Compiler | `lib/elixir_katas/katas/dynamic_compiler.ex` |
| Kata Viewer UI | `lib/elixir_katas_web/components/kata_components.ex` |
| Code Editor Hook | `assets/js/hooks/code_editor.js` |
| Persistence Context | `lib/elixir_katas/katas.ex` |
| UserKata Schema | `lib/elixir_katas/katas/user_kata.ex` |

## Step-by-Step Walkthrough

### 1. CodeMirror Editor (Client)

`assets/js/hooks/code_editor.js` is a Phoenix Hook wrapping a CodeMirror 6 editor. It uses the Elixir language mode and One Dark theme.

When the user types, the hook captures the full document text and **debounces for 1 second** before pushing it to the server:

```javascript
this.pushEventTo(this.el, "save_source", { source: this.source })
```

The editor div is rendered with `phx-update="ignore"` so that LiveView never overwrites the editor DOM during re-renders — the user's cursor position and scroll state are preserved.

### 2. KataHostLive Receives the Event

`KataHostLive.handle_event("save_source", ...)` does two things immediately:

1. Sets `compiling: true` — this triggers a spinner in the UI.
2. Spawns an **async Task** so compilation never blocks the LiveView process:

```elixir
Task.async(fn ->
  DynamicCompiler.compile(user_id, kata_name, source)
  ElixirKatas.Katas.save_user_kata(user_id, kata_name, source)
end)
```

The source code is also persisted to the `user_katas` SQLite table so it survives across sessions.

### 3. DynamicCompiler Rewrites and Compiles

`DynamicCompiler.compile/3` performs runtime compilation in three steps:

1. **Generate a unique module name** per user — e.g., `ElixirKatas.User42.Kata02`. This prevents users from clobbering each other's modules.

2. **Regex-rewrite the `defmodule` line** in the source code to use the unique name:
   ```elixir
   Regex.replace(~r/defmodule\s+[\w\.]+\s+do/s, source_code, "defmodule #{module_name} do")
   ```

3. **Compile to BEAM bytecode in memory** via `Code.compile_string/1`. If the module already exists, the old version is purged first with `:code.purge/1` and `:code.delete/1`.

On success it returns `{:ok, module_name}`. On failure it returns `{:error, message}`.

### 4. Task Completion Triggers Re-render

When the async task finishes, `KataHostLive.handle_info/2` receives the result:

- **Success** — assigns the new `dynamic_module`, clears `compile_error`, sets `compiling: false`, and records a `saved_at` timestamp (shows a "Saved!" indicator).
- **Failure** — sets `compile_error` with the error message (displayed as a red banner) and clears the compiling state.

### 5. Dynamic Module Swap

The critical line in the host template:

```heex
<.live_component module={@dynamic_module} id="kata-sandbox" />
```

When `@dynamic_module` changes to the newly compiled module, LiveView **re-mounts** the live_component. The kata's `update/2` and `render/1` callbacks fire with the new code. The demo updates instantly in the browser — no page reload required.

## Kata Component Structure

Each kata is a `live_component` (not a `live_view`). A minimal kata looks like:

```elixir
defmodule ElixirKatasWeb.Kata02CounterLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_new(:count, fn -> 0 end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>{@count}</div>
      <button phx-click="inc" phx-target={@myself}>+</button>
    </div>
    """
  end

  def handle_event("inc", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end
end
```

Key points:
- Uses `phx-target={@myself}` so events route to the component, not the host.
- State is local to the component via assigns.
- The host forwards any unhandled events and info messages to the kata component.

## User Isolation

Each user's code compiles to a unique BEAM module namespace:

```
ElixirKatas.User1.Kata02   ← User 1's version
ElixirKatas.User7.Kata02   ← User 7's version
```

This means multiple users can edit the same kata concurrently without interference.

## Persistence and Revert

- **Persistence**: User edits are saved to the `user_katas` table (SQLite via Ecto). On mount, the host checks for a saved version before falling back to the original file.
- **Revert**: The "Revert" button deletes the user's DB record, reloads the original source from disk, and recompiles.

## Why It Feels Instant

| Concern | Solution |
|---------|----------|
| Editor doesn't reset on re-render | `phx-update="ignore"` on the editor div |
| UI doesn't freeze during compile | `Task.async` for non-blocking compilation |
| Users don't clobber each other | Unique module namespace per user |
| Old modules don't leak | `:code.purge` + `:code.delete` before recompile |
| Code persists across sessions | Saved to `user_katas` SQLite table |
| Can undo all edits | Revert reloads original file from disk |
| Debounced saves | 1 second debounce prevents compile spam |
