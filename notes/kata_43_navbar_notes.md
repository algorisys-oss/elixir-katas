# Kata 43: Navbar Integration

## The Concept
A persistent navigation bar that highlights the current page. This introduces **Conditional Class Rendering** based on state.

## The Elixir Way
*   **Functional Components**: We define `<.nav_link>` to encapsulate the logic of "am I active?".
*   **Verified Routes**: We use `~p"/path"` to ensure compile-time safety of all links.

## Deep Dive

### 1. Calculating Active State
How do we know we are on "Home"?
*   **Option A**: Check URI path.
*   **Option B (Preferred)**: Set `@current_page` assign in the Router's `live_session` via `on_mount` hooks.
In this basic kata, we manually calculate it from `handle_params`.

### 2. `.link` Component
Phoenix provides `<.link>`. It replaces `<a>`, `<live_patch>`, and `<live_redirect>`.
*   `navigate`: Full page transition (stops current LiveView, starts new one).
*   `patch`: Same LiveView, updates params.
*   `href`: Standard HTTP request (full browser reload). use for external links or login/logout.

### 3. Layouts
Navbars usually live in `app.html.heex` (the Layout), not the individual LiveView.
However, the Layout *wraps* the LiveView. This means the Layout shares the `@socket` assigns.
If you update `assign(socket, active_tab: :home)` in the LiveView, the Layout can read `@active_tab`.

## Common Pitfalls

1.  **Nested Active States**: "Settings" is active, but so should be the parent "Profile" dropdown. Logic can get complex.
2.  **Patching Config**: Using `patch` to go to a different LiveView (e.g. Home to Settings) effectively degrades to a `navigate` or crashes, depending on router setup. Use `navigate` for different pages.
