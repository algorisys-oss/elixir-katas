# Kata 45: URL Tabs

## The Concept
Tabbed interfaces often use local state (`@active_tab`). But if the user refreshes, they lose their place.
**URL Tabs** store the active tab in the query string (`?tab=settings`), making the state persistent and bookmarkable.

## The Elixir Way
We treat the tab selection exactly like any other filter or ID.
*   **Clicking a Tab**: Does not fire a click event. It is a `<.link patch={~p"?tab=settings"}>`.
*   **Handling**: `handle_params` reads the param.

## Deep Dive

### 1. Handling Defaults
What if the user visits `/profile` (no query string)?
```elixir
def handle_params(params, _uri, socket) do
  tab = params["tab"] || "overview" # Default
  {:noreply, assign(socket, tab: tab)}
end
```
Alternatively, you can `push_patch(to: "?tab=overview")` to forcefully normalize the URL, ensuring the user always sees what they are viewing in the address bar.

### 2. CSS Architecture
Often we use `class={if @tab == "settings", do: "active"}`.
With extensive tabs, using a helper function `tab_class(@tab, "settings")` cleans up the template.

## Common Pitfalls

1.  **Unknown Tabs**: Authenticated users might manually type `?tab=admin`. Your logic must handle unknown strings (fallback to default) to avoid crashing or showing empty states.
2.  **Scroll Position**: `push_patch` preserves scroll position by default. This is usually desired for tabs, unlike full page navigation where you want to scroll to top.
