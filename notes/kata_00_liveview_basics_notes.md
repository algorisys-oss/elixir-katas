# Kata 00: LiveView Fundamentals

## The Missing Manual
Welcome to **Phoenix LiveView**.
This isn't just a library; it's a paradigm shift.
Most web frameworks (React, Vue, Svelte) run on the **Client**. LiveView runs on the **Server**.

Understanding this mental model is the key to everything that follows.

---

## 1. The Mental Model

In a traditional SPA (Single Page App):
1.  Browser downloads HTML + Huge JS Bundle.
2.  Browser calls API (JSON).
3.  Browser renders UI.

In **LiveView**:
1.  Browser downloads HTML (Instant).
2.  Browser connects a WebSocket.
3.  **Server** renders UI.
4.  **Server** pushes tiny HTML updates to Browser.

**You write code on the server, but it feels like it runs in the browser.**

Each LiveView is an **Elixir process** (a GenServer under the hood). It holds state, receives messages, and re-renders when state changes. If you understand `GenServer`, you already understand LiveView's core — it's just a process with a UI.

---

## 2. The Lifecycle (How It Starts)

A LiveView goes through two stages when you visit a page:

### Stage 1: The Dead Render (HTTP)
*   **Request**: You type `localhost:4000/` in the bar.
*   **Action**: `mount` runs. `render` runs.
*   **Result**: Full HTML is sent. Search engines see this. Users see this instantly (First Paint).
*   **Status**: Disconnected.

### Stage 2: The Live Connection (WebSocket)
*   **Action**: A tiny JS file (`live.js`) wakes up. It opens a WebSocket to the server.
*   **Action**: `mount` runs *again*. `render` runs *again*.
*   **Result**: The page is now "Live". Events work. State persists.
*   **Status**: Connected.

> **Key Insight**: `mount` runs **twice** — once for the static HTML (SEO-friendly, fast first paint) and once when the WebSocket connects. Never perform side-effects (like API calls or database writes) in `mount` unless you guard with `connected?(socket)`:
>
> ```elixir
> def mount(socket) do
>   if connected?(socket) do
>     # Safe to start timers, subscribe to PubSub, etc.
>   end
>   {:ok, assign(socket, count: 0)}
> end
> ```

---

## 3. The Update Loop (How It Stays Alive)

Once connected, LiveView enters a loop:

1.  **Event**: User clicks a button (`phx-click="increment"`).
2.  **Network**: The event name + payload is sent over the WebSocket.
3.  **Server**: The function `handle_event("increment", params, socket)` runs.
4.  **State Change**: You update assigns: `assign(socket, count: socket.assigns.count + 1)`.
5.  **Render**: LiveView re-runs `render/1`.
6.  **Diff**: It compares the *new* HTML with the *old* HTML.
    *   Old: `<span>Count: 1</span>`
    *   New: `<span>Count: 2</span>`
    *   Diff sent: just `"2"`
7.  **Patch**: The server sends only the changed parts to the browser.
8.  **DOM**: The browser patches the DOM. No full page reload.

This is why LiveView feels instant — it sends **diffs**, not full pages.

---

## 4. HEEx Templates

LiveView uses **HEEx** (HTML + Embedded Elixir) for templates. You'll write them using the `~H` sigil.

### Interpolation
Use curly braces `{}` to embed Elixir expressions:

```heex
<h1>Hello, {@name}!</h1>
<p>You have {length(@items)} items.</p>
```

`@name` is shorthand for `assigns.name`. You'll use `@` everywhere in templates to access assigns.

### Conditional Rendering with `:if`
```heex
<p :if={@show_message}>This only renders when @show_message is truthy.</p>

<div :if={@logged_in}>
  Welcome back!
</div>
```

For if/else, use a standard Elixir expression:
```heex
<span>
  {if @active, do: "ON", else: "OFF"}
</span>
```

### Looping with `:for`
```heex
<ul>
  <li :for={item <- @items}>{item.name}</li>
</ul>
```

### Dynamic Attributes
```heex
<!-- Dynamic CSS class -->
<div class={if @is_active, do: "text-green-500", else: "text-gray-400"}>
  Status
</div>

<!-- Class list (falsy values are filtered out) -->
<button class={["btn", @selected && "btn-primary"]}>Click</button>

<!-- Dynamic inline style -->
<div style={"background-color: rgb(#{@r}, #{@g}, #{@b})"}>
  Color Preview
</div>

<!-- Disabled attribute -->
<button disabled={@loading}>Submit</button>
```

### Pattern Matching / Case in Templates
```heex
<div>
  {case @tab do
    :home -> "Welcome home"
    :settings -> "Settings page"
    _ -> "Unknown"
  end}
</div>
```

---

## 5. The Three Core Callbacks

Every LiveView (and LiveComponent) is built from three callbacks.

### `mount/1` — Initialize State
Called when the component starts. Set your initial assigns here.

```elixir
def mount(socket) do
  {:ok, assign(socket, count: 0, name: "World")}
end
```

Returns `{:ok, socket}`.

### `render/1` — Produce HTML
Called every time assigns change. Returns a HEEx template.

```elixir
def render(assigns) do
  ~H"""
  <div>
    <h1>Hello, {@name}!</h1>
    <p>Count: {@count}</p>
    <button phx-click="increment" phx-target={@myself}>+1</button>
  </div>
  """
end
```

The `assigns` argument is a map. Inside `~H`, you access values with `@key`.

### `handle_event/3` — Respond to User Actions
Called when a user triggers an event (click, form change, keypress, etc.).

```elixir
def handle_event("increment", _params, socket) do
  {:noreply, update(socket, :count, &(&1 + 1))}
end
```

Arguments:
- **Event name** (string) — matches the `phx-click`, `phx-change`, etc. value.
- **Params** (map with string keys) — data sent with the event.
- **Socket** — current state.

Returns `{:noreply, socket}`.

---

## 6. The Socket & Assigns

The `socket` is your state container. All your data lives in `socket.assigns`.

### `assign/2` — Set Values
```elixir
# Set one or more assigns
socket = assign(socket, count: 0)
socket = assign(socket, name: "Ada", role: :admin)
```

### `update/3` — Transform an Existing Value
When the new value depends on the old value, use `update`:
```elixir
# Increment count based on current value
socket = update(socket, :count, &(&1 + 1))

# Append to a list
socket = update(socket, :logs, fn logs -> ["new entry" | logs] end)
```

### Reading Assigns
```elixir
# In Elixir code:
socket.assigns.count

# In HEEx templates:
{@count}
```

### Immutability
You never mutate the socket. Every function returns a **new** socket:
```elixir
# This does nothing (result is discarded):
assign(socket, count: 5)

# This works (pipe the result):
socket
|> assign(count: 5)
|> assign(name: "updated")
```

---

## 7. LiveView vs LiveComponent

This is an important distinction for these katas.

### LiveView
- A full page. Has its own URL/route.
- Mounted with `live "/path", MyLive`.
- Uses `mount/3` (receives params, session, socket).
- Has its own process.

### LiveComponent
- A **reusable piece** embedded inside a LiveView.
- Does **not** have its own process — it runs inside the parent LiveView's process.
- Uses `mount/1` (receives just the socket).
- Must use `phx-target={@myself}` to handle its own events.

**All katas in this project are LiveComponents.** They are hosted inside a parent `KataHostLive` view. This is why you'll see:

```elixir
use ElixirKatasWeb, :live_component
```

### The `update/2` Callback
LiveComponents receive data from their parent through the `update/2` callback (not `mount/1` like LiveViews). Most katas use this pattern:

```elixir
def update(assigns, socket) do
  socket = assign(socket, assigns)
  # Set up your initial state here
  {:ok, assign(socket, count: 0, name: "World")}
end
```

`update/2` is called whenever the parent sends new assigns to the component. The first argument is the map of assigns passed from the parent; the second is the current socket.

> **Note**: If you define `update/2`, `mount/1` is **not** called on subsequent re-renders — only on the very first mount. `update/2` is the right place for initialization in LiveComponents.

### `send_update/2` — Parent Pushes New Assigns to a Child

Sometimes a parent LiveView needs to trigger a child component to update without re-rendering itself. Use `send_update/2`:

```elixir
# From the parent LiveView's handle_event or handle_info:
def handle_info({:new_data, data}, socket) do
  send_update(MyAppWeb.MyComponent, id: "my-component", data: data)
  {:noreply, socket}
end
```

The child component's `update/2` will be called with the new assigns. The parent does **not** re-render.

> **When to use**: Real-time updates to a specific child (e.g., a chat message component receiving a PubSub broadcast) without triggering a full parent re-render.

### Event Targeting
Event handlers need `phx-target={@myself}`:

```heex
<!-- Without phx-target, the event goes to the PARENT LiveView -->
<button phx-click="increment">Goes to parent (wrong!)</button>

<!-- With phx-target={@myself}, the event stays in THIS component -->
<button phx-click="increment" phx-target={@myself}>Handled here (correct!)</button>
```

> **Rule for Katas**: Always add `phx-target={@myself}` to your event bindings. Without it, your events will be sent to the host view instead of your kata component, and nothing will happen.

---

## 8. Event Bindings

LiveView provides HTML attributes that wire user actions to server-side handlers.

### `phx-click` — Click Events
```heex
<button phx-click="increment" phx-target={@myself}>+1</button>
```
```elixir
def handle_event("increment", _params, socket) do
  {:noreply, update(socket, :count, &(&1 + 1))}
end
```

### `phx-change` — Form Input Changes
Fires on every keystroke / input change. The event params contain the form field values.
```heex
<form phx-change="validate" phx-target={@myself}>
  <input type="text" name="query" value={@query} />
</form>
```
```elixir
def handle_event("validate", %{"query" => query}, socket) do
  {:noreply, assign(socket, query: query)}
end
```

### `phx-submit` — Form Submission
Fires when the form is submitted (Enter key or submit button).
```heex
<form phx-submit="save" phx-target={@myself}>
  <input type="text" name="title" value={@title} />
  <button type="submit">Save</button>
</form>
```
```elixir
def handle_event("save", %{"title" => title}, socket) do
  {:noreply, assign(socket, title: title, saved: true)}
end
```

### `phx-value-*` — Passing Data with Events
Attach extra data to events using `phx-value-` prefixed attributes:
```heex
<button phx-click="delete" phx-value-id="42" phx-target={@myself}>
  Delete Item 42
</button>
```
```elixir
def handle_event("delete", %{"id" => id}, socket) do
  # id is "42" (always a string!)
  {:noreply, assign(socket, items: Enum.reject(socket.assigns.items, &(&1.id == id)))}
end
```

### `phx-debounce` — Rate Limiting
Prevents events from firing too rapidly:
```heex
<input phx-change="search" phx-debounce="300" name="q" />
```
This waits 300ms after the user stops typing before sending the event.

### Other Event Bindings
*   `phx-focus` / `phx-blur` — Input focus events.
*   `phx-keyup` / `phx-keydown` — Keyboard events (params include `%{"key" => "Enter"}`).
*   `phx-window-keyup` / `phx-window-keydown` — Keyboard events on the whole window.

### `phx-update` — Controlling DOM Patch Behaviour

By default, LiveView **replaces** an element's children on every render. The `phx-update` attribute changes this:

| Value | Behaviour | Use Case |
|---|---|---|
| `replace` | *(default)* Replace children on every render | Most elements |
| `append` | Add new children **after** existing ones | Infinite scroll, log feeds |
| `prepend` | Add new children **before** existing ones | Chat (newest at top) |
| `stream` | LiveView manages a keyed list; only diffs are sent | Large collections (modern) |
| `ignore` | LiveView **never** touches this element's DOM | JS-managed elements (charts, maps) |

```heex
<!-- LiveView won't touch this canvas — JS owns it -->
<canvas id="my-chart" phx-hook="ChartJS" phx-update="ignore"></canvas>

<!-- New log lines are appended; old ones stay in the browser DOM -->
<div id="logs" phx-update="append">
  <p :for={line <- @log_lines} id={line.id}>{line.text}</p>
</div>
```

> **Key rule**: Any element using `append`, `prepend`, or `stream` **must** have a unique `id` attribute, and each child element must also have a unique `id`. LiveView uses these to track which DOM nodes to update.

---

## 9. Server-Side Messages with `handle_info/2`

Not all updates come from users. Sometimes the server sends messages to itself — for timers, PubSub broadcasts, or background task results.

```elixir
def mount(socket) do
  if connected?(socket) do
    # Send a :tick message to ourselves every second
    Process.send_after(self(), :tick, 1000)
  end
  {:ok, assign(socket, seconds: 0)}
end
```

Handle incoming messages with `handle_info/2`:
```elixir
def handle_info(:tick, socket) do
  # Schedule the next tick
  Process.send_after(self(), :tick, 1000)
  {:noreply, update(socket, :seconds, &(&1 + 1))}
end
```

> **Note**: In a LiveComponent, server messages go to the **parent LiveView**, not the component. The katas handle this for you via `update/2`. You'll see `handle_info` used in later katas (Kata 11+).

---

## 10. A Complete Example

Here's what a typical kata looks like — a simple counter component:

```elixir
defmodule ElixirKatasWeb.Kata02CounterLive do
  use ElixirKatasWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4 p-8">
      <h2 class="text-2xl font-bold">Count: {@count}</h2>

      <div class="flex gap-2">
        <button
          phx-click="decrement"
          phx-target={@myself}
          class="btn btn-outline"
        >
          -1
        </button>
        <button
          phx-click="increment"
          phx-target={@myself}
          class="btn btn-primary"
        >
          +1
        </button>
      </div>

      <button
        :if={@count != 0}
        phx-click="reset"
        phx-target={@myself}
        class="btn btn-sm btn-ghost"
      >
        Reset
      </button>
    </div>
    """
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, count: 0)}
  end
end
```

Notice the pattern: **mount** sets initial state → **render** displays it → **handle_event** updates it → render runs again. That's the whole loop.

---

## 11. Common Gotchas

### Event Params Are Always String-Keyed Maps
When a user submits a form or sends event data, the params arrive as a map with **string keys**, never atom keys:
```elixir
# Correct
def handle_event("save", %{"name" => name}, socket)

# Wrong (will not match)
def handle_event("save", %{name: name}, socket)
```

### `phx-value-*` Values Are Always Strings
Even if you write `phx-value-id="42"`, the handler receives `%{"id" => "42"}` — a string. Convert explicitly:
```elixir
id = String.to_integer(params["id"])
```

### Don't Forget `phx-target={@myself}`
In these katas (LiveComponents), omitting `phx-target` sends events to the parent LiveView, not your component. Your `handle_event` won't fire. If your button "doesn't work", this is likely why.

### Assign Before You Access
If you use `{@foo}` in your template but never assigned `:foo` in `mount`, you'll get a `KeyError`. Always initialize all assigns in `mount`.

### Pipe Your Socket Transformations
```elixir
# Good — each step builds on the previous
def handle_event("submit", params, socket) do
  {:noreply,
   socket
   |> assign(submitted: true)
   |> assign(name: params["name"])
   |> update(:count, &(&1 + 1))}
end

# Bad — intermediate results are lost
def handle_event("submit", params, socket) do
  assign(socket, submitted: true)    # discarded!
  assign(socket, name: params["name"]) # discarded!
  {:noreply, update(socket, :count, &(&1 + 1))}
end
```

---

## 12. Scaling Up: Assigns in Large Apps

The basics work great for small katas. But as apps grow, three problems appear:

1. **Memory bloat** — assigns accumulate large data structures in the socket.
2. **Slow diffs** — LiveView diffs the entire assigns map on every render.
3. **Redundant work** — `update/2` re-fetches data that hasn't changed.

Here's how to handle each.

### `assign_new/3` — Lazy, One-Time Initialization

In a LiveComponent, `update/2` is called every time the parent re-renders. If you naively fetch data inside `update/2`, you'll re-fetch on every parent change.

Use `assign_new/3` to only compute a value if the key doesn't already exist in the socket:

```elixir
def update(assigns, socket) do
  socket =
    socket
    |> assign(assigns)
    # Only fetches the user ONCE — skipped on subsequent parent re-renders
    |> assign_new(:user, fn -> Accounts.get_user!(assigns.user_id) end)

  {:ok, socket}
end
```

> **Rule**: Use `assign_new/3` for any expensive computation in `update/2` that only needs to run once (e.g., DB fetches, heavy transformations).

---

### `temporary_assigns` — Clearing Assigns After Render

By default, every assign lives in the socket **forever**. If you push 1,000 messages into `@messages`, all 1,000 stay in memory for the lifetime of the LiveView process.

`temporary_assigns` tells LiveView: *"after each render, reset this key back to its default value."*

```elixir
def mount(socket) do
  {:ok,
   assign(socket, messages: []),
   temporary_assigns: [messages: []]}
end
```

Now the flow works like this:

1. A new message arrives → you `assign(socket, messages: [new_msg])`.
2. LiveView renders — the browser sees the new message appended.
3. After render, `messages` is automatically reset to `[]`.
4. Memory stays flat, no matter how many messages arrive.

> **Important**: `temporary_assigns` only works correctly with `phx-update="append"` or `phx-update="prepend"` in the template, so the browser accumulates the items — not the server.

```heex
<div id="messages" phx-update="append">
  <div :for={msg <- @messages} id={"msg-#{msg.id}"}>
    {msg.text}
  </div>
</div>
```

> **Modern Alternative**: For new code, prefer **Streams** (see below). `temporary_assigns` is the older pattern but is still valid and widely used.

---

### Streams — The Modern Answer for Large Lists

Streams are LiveView's built-in solution for rendering large, dynamic collections **without keeping the full list in the socket**. The server only tracks diffs; the browser owns the full DOM list.

```elixir
def mount(socket) do
  items = Repo.all(Item)
  {:ok, stream(socket, :items, items)}
end
```

```heex
<div id="items" phx-update="stream">
  <div :for={{dom_id, item} <- @streams.items} id={dom_id}>
    {item.name}
  </div>
</div>
```

Updating the stream — only the changed item is sent to the browser:

```elixir
# Add or update an item
{:noreply, stream_insert(socket, :items, new_item)}

# Remove an item
{:noreply, stream_delete(socket, :items, item)}
```

#### Streams vs Plain Assigns — When to Use Which

| Scenario | Use |
|---|---|
| Small, static list (< ~50 items, rarely changes) | Plain `assign` |
| Large list or infinite scroll | `stream` |
| Real-time feed (chat, notifications, logs) | `stream` |
| List where you need to sort/filter on the server | `stream` (re-stream on filter change) |
| Single item or scalar value | Plain `assign` |

---

### Keeping Assigns Lean

Every key in `socket.assigns` is serialized and diffed on every render. Large structs slow things down.

**Don'ts:**
```elixir
# Bad — storing the entire user record when you only need the name
assign(socket, current_user: %User{id: 1, name: "Ada", hashed_password: "...", ...})
```

**Dos:**
```elixir
# Good — store only what the template needs
assign(socket, user_name: user.name, user_id: user.id)

# Or store the full struct but be intentional about it
assign(socket, current_user: Map.take(user, [:id, :name, :role]))
```

**Other tips:**
- Don't store derived data — compute it in the template or in a function component.
- Avoid deeply nested maps in assigns; flatten where possible.
- Use `stream` for collections instead of storing lists in assigns.

---

## 13. Concepts Ahead (Roadmap)

As you progress through the katas, you'll encounter these additional LiveView features. Each kata's notes explain them in detail — this is just a preview so nothing catches you off guard.

### Function Components

A **Function Component** is a plain Elixir function that takes `assigns` and returns a HEEx template. It has **no state and no process** — it's just a reusable template fragment.

```elixir
# Defined with defp (private) or def (public/shared)
defp alert(assigns) do
  ~H"""
  <div class={"alert alert-#{@type}"}>
    {@message}
  </div>
  """
end
```

Called in templates with **dot syntax** (`.function_name`):

```heex
<.alert type="error" message="Something went wrong" />
```

#### Declaring Attributes with `attr`

Use `attr` to document and validate the inputs your component accepts:

```elixir
attr :type, :string, default: "info"   # optional, has a default
attr :message, :string, required: true  # required — error if missing

defp alert(assigns) do
  ~H"""
  <div class={"alert alert-#{@type}"}>{@message}</div>
  """
end
```

#### Slots — Passing Content Blocks

Slots let callers inject HTML content into a component, like children in React:

```elixir
slot :inner_block, required: true

defp card(assigns) do
  ~H"""
  <div class="card">
    {render_slot(@inner_block)}
  </div>
  """
end
```

```heex
<.card>
  <p>This content is passed as the inner_block slot.</p>
</.card>
```

Named slots let you pass **multiple distinct content areas**:

```elixir
slot :header
slot :footer
slot :inner_block, required: true

defp card(assigns) do
  ~H"""
  <div class="card">
    <div class="card-header">{render_slot(@header)}</div>
    <div class="card-body">{render_slot(@inner_block)}</div>
    <div class="card-footer">{render_slot(@footer)}</div>
  </div>
  """
end
```

```heex
<.card>
  <:header>My Title</:header>
  <p>Main body content here.</p>
  <:footer>Footer text</:footer>
</.card>
```

#### CoreComponents — Pre-built Function Components

Phoenix generates a `CoreComponents` module (`core_components.ex`) with ready-made components like `<.button>`, `<.input>`, `<.modal>`, `<.flash>`, `<.table>`. These are available in every LiveView and template automatically.

```heex
<!-- These are all function components from CoreComponents -->
<.button phx-click="save" phx-target={@myself}>Save</.button>
<.input field={@form[:email]} type="email" label="Email" />
<.modal id="confirm-modal">Are you sure?</.modal>
```

> **Key distinction**: Function Components ≠ LiveComponents. Function Components are stateless template helpers. LiveComponents are stateful, have a lifecycle (`mount`, `update`, `handle_event`), and run inside a LiveView process.

*First appears: Kata 25+. Heavy use: Kata 50+.*

### Forms with `to_form`
Phoenix provides a `.form` component and `to_form/1` helper for structured form handling with validation and error display:

```elixir
socket |> assign(:form, to_form(%{"email" => "", "name" => ""}))
```
```heex
<.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
  <input name="email" value={@form[:email].value} />
  <span :if={@form[:email].errors != []}>{@form[:email].errors}</span>
</.form>
```
*First appears: Kata 26+.*

### Flash Messages
Temporary notifications shown to users after actions:

```elixir
{:noreply, socket |> put_flash(:info, "Saved!") |> put_flash(:error, "Failed")}
```
*First appears: Kata 26+.*

### Navigation
Update the URL without a full page reload:

```elixir
# Same LiveView, different params (triggers handle_params):
push_patch(socket, to: ~p"/katas/41?filter=active")

# Different LiveView (full remount):
push_navigate(socket, to: ~p"/other-page")
```
```heex
<!-- Clickable link that patches: -->
<.link patch={~p"/katas/42/#{item.id}"}>View</.link>
```
*First appears: Kata 41+.*

### File Uploads
LiveView has built-in upload support with progress tracking and drag-and-drop:

```elixir
socket |> allow_upload(:avatar, accept: ~w(.jpg .png), max_entries: 2)
```
```heex
<.live_file_input upload={@uploads.avatar} />
<div phx-drop-target={@uploads.avatar.ref}>Drop files here</div>
```
*First appears: Kata 40.*

### Streams
For large lists, streams send only diffs instead of re-rendering the entire list:

```elixir
socket |> stream(:items, items)               # Initialize
socket |> stream_insert(:items, new_item)     # Add
socket |> stream_delete_by_dom_id(:items, id) # Remove
```
```heex
<div id="items" phx-update="stream">
  <div :for={{dom_id, item} <- @streams.items} id={dom_id}>
    {item.name}
  </div>
</div>
```
*First appears: Kata 71+.*

### JavaScript Hooks
When you need client-side behavior (charts, scroll events, animations), use `phx-hook`:

```heex
<canvas id="chart" phx-hook="ChartJS" phx-update="ignore"></canvas>
```

- `phx-hook="Name"` — Connects a JS hook to the element.
- `phx-update="ignore"` — Tells LiveView not to touch this element's DOM (let JS manage it).
- `push_event(socket, "event-name", payload)` — Push data from server to JS.

*First appears: Kata 72+.*

### PubSub (Real-Time Broadcasting)
Send messages between LiveView processes (different users, different tabs):

```elixir
# Subscribe (in mount or update, when connected):
Phoenix.PubSub.subscribe(ElixirKatas.PubSub, "chat:lobby")

# Broadcast (from anywhere):
Phoenix.PubSub.broadcast(ElixirKatas.PubSub, "chat:lobby", {:new_message, msg})

# Receive (in handle_info):
def handle_info({:new_message, msg}, socket) do
  {:noreply, update(socket, :messages, &[msg | &1])}
end
```
*First appears: Kata 77+.*

### Async Assigns
Load data asynchronously with automatic loading/error states:

```elixir
socket |> assign_async(:stats, fn ->
  {:ok, %{stats: fetch_stats()}}
end)
```
```heex
<.async_result :let={stats} assign={@stats}>
  <:loading>Loading...</:loading>
  <:failed>Error</:failed>
  {stats.revenue}
</.async_result>
```
*First appears: Kata 95.*

---

## 14. Quick Reference

| Concept | Code |
|---------|------|
| Set state | `assign(socket, key: value)` |
| Update state | `update(socket, :key, &(&1 + 1))` |
| Read state (Elixir) | `socket.assigns.key` |
| Read state (HEEx) | `{@key}` |
| Handle click | `phx-click="event_name"` |
| Handle form change | `phx-change="event_name"` |
| Handle form submit | `phx-submit="event_name"` |
| Pass data | `phx-value-id="42"` |
| Target component | `phx-target={@myself}` |
| Conditional render | `<div :if={@show}>...</div>` |
| Loop render | `<li :for={x <- @list}>{x}</li>` |
| Debounce input | `phx-debounce="300"` |
| Function component | `<.btn variant="primary">Click</.btn>` |
| Form component | `<.form for={@form} phx-submit="save">` |
| Flash message | `put_flash(socket, :info, "Saved!")` |
| URL patch | `push_patch(socket, to: ~p"/path?q=1")` |
| Stream init | `stream(socket, :items, list)` |
| Stream insert | `stream_insert(socket, :items, item)` |
| JS hook | `<div phx-hook="MyHook">` |
| PubSub subscribe | `Phoenix.PubSub.subscribe(PS, topic)` |
| PubSub broadcast | `Phoenix.PubSub.broadcast(PS, topic, msg)` |

---

## 15. What's Next?

You now have the foundation to write LiveView code. Here's the progression:

*   **Kata 01–10**: Core basics — rendering, events, state, conditional UI, dynamic styles.
*   **Kata 11–15**: Timers, keyboard events, animation.
*   **Kata 16–25**: Lists, editing, filtering, sorting, pagination, tree structures.
*   **Kata 26–40**: Forms, validation, file uploads, multi-step wizards.
*   **Kata 41–55**: Navigation, URL params, function components, slots, modals.
*   **Kata 56–70**: Component patterns, lifecycle, JS interop basics.
*   **Kata 71–85**: Streams, PubSub, real-time chat, presence.
*   **Kata 86+**: Advanced patterns — async, uploads, hooks, virtual scrolling.

Click **Next Kata** in the sidebar to begin.
