# Kata 09: The Tabs

## Goal
Build a tabbed interface where clicking a header switches the visible content. This simulates a "multi-page" feel within a single component.

## Core Concepts

### 1. Atom State
Using atoms (e.g., `:home`, `:pricing`) is a clean way to represent a finite set of states (Enums).

```elixir
assign(socket, selected_tab: :home)
```

### 2. Case Statements in HEEx
Use Elixir's `case` statement to render completely different blocks of HTML based on the state.

```elixir
<%= case @selected_tab do %>
  <% :home -> %> <HomeComponent />
  <% :pricing -> %> <PricingComponent />
<% end %>
```

### 3. Styling the Active Tab
Apply specific styles to the button that matches the current state.

```elixir
class={if @selected_tab == :home, do: "border-b-2 border-primary", else: "text-gray-500"}
```

## Implementation Details

1.  **State**: `selected_tab` (default `:home`).
2.  **UI**:
    - Navigation bar with buttons.
    - Content area using a `case` statement.
3.  **Events**:
    - `handle_event("set_tab", %{"tab" => tab_str}, socket)`
    - Convert the string parameter (from HTML) to an existing atom.

## Tips
- `String.to_existing_atom/1` is safer than `String.to_atom/1` to prevent atom exhaustion attacks, though for a fixed set of tabs, either is generally fine in a constrained environment.

## Challenge
Add a new tab called **"Settings"**, but only show the button for it if a boolean assign `show_settings` is `true`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># In render
&lt;%= if @show_settings do %&gt;
  &lt;.button phx-click="set_tab" phx-value-tab="settings"&gt;Settings&lt;/.button&gt;
&lt;% end %&gt;

# In handle_event logic
def handle_event("set_tab", %{"tab" => "settings"}, socket) do
  if socket.assigns.show_settings do
     {:noreply, assign(socket, selected_tab: :settings)}
  else
     {:noreply, socket}
  end
end</code></pre>
</details>
