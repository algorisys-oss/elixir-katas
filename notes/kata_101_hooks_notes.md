# Kata 101: Phoenix LiveView Hooks

## Goal
Understand how JavaScript Hooks work in Phoenix LiveView - the official mechanism for running client-side code alongside server-rendered UI.

## What are Hooks?

Hooks are **JavaScript objects** with lifecycle callbacks that run in response to LiveView DOM events. They are the bridge between Elixir's server-side rendering and the browser's client-side APIs.

**When to use hooks:**
- Initializing third-party JS libraries (charts, maps, editors)
- Accessing browser APIs (clipboard, geolocation, notifications, localStorage)
- DOM manipulation LiveView cannot do (focus management, scroll position, element measurements)
- Custom event listeners (resize, intersection, drag/drop)

**When NOT to use hooks:**
- Simple click/change events (use `phx-click`, `phx-change`)
- CSS transitions (use `Phoenix.LiveView.JS`)
- Showing/hiding elements (use `:if` or `JS.toggle`)

## Core Concepts

### 1. Hook Registration

Hooks are defined in `assets/js/app.js` and passed to the LiveSocket constructor:

```javascript
let Hooks = {}

Hooks.MyHook = {
  mounted() {
    console.log("Element added to DOM:", this.el)
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
})
```

### 2. Attaching Hooks to Elements

In your HEEx template, use `phx-hook` with a **unique `id`**:

```html
<div id="my-element" phx-hook="MyHook">
  Content here
</div>
```

> **Critical:** Every element with `phx-hook` MUST have a unique `id` attribute. Without it, the hook will silently not fire.

### 3. The Six Lifecycle Callbacks

| Callback | When it fires | Common use |
|----------|--------------|------------|
| `mounted()` | Element added to DOM | Init libraries, add listeners |
| `beforeUpdate()` | Before server patches element | Save scroll pos, cursor state |
| `updated()` | After server patches element | Re-init plugins, restore state |
| `destroyed()` | Element removed from DOM | Cleanup: timers, observers, listeners |
| `disconnected()` | WebSocket connection lost | Show offline indicator |
| `reconnected()` | WebSocket reconnects | Refresh data, hide offline indicator |

#### mounted()
The most commonly used callback. Called once when the element enters the DOM.

```javascript
Hooks.Chart = {
  mounted() {
    this.chart = new Chart(this.el, {
      type: "bar",
      data: JSON.parse(this.el.dataset.chartData)
    })
  }
}
```

#### beforeUpdate() and updated()
Used together to preserve state across server patches:

```javascript
Hooks.ScrollPreserver = {
  beforeUpdate() {
    this.scrollTop = this.el.scrollTop
  },
  updated() {
    this.el.scrollTop = this.scrollTop
  }
}
```

#### destroyed()
**Critical for preventing memory leaks.** Every resource created in `mounted()` should be cleaned up here:

```javascript
Hooks.Poller = {
  mounted() {
    this.timer = setInterval(() => this.pushEvent("poll", {}), 5000)
    this.observer = new ResizeObserver(...)
    this.observer.observe(this.el)
  },
  destroyed() {
    clearInterval(this.timer)
    this.observer.disconnect()
  }
}
```

#### disconnected() and reconnected()
Handle WebSocket connection state:

```javascript
Hooks.ConnectionStatus = {
  disconnected() {
    this.el.innerText = "Offline"
    this.el.className = "badge badge-error"
  },
  reconnected() {
    this.el.innerText = "Connected"
    this.el.className = "badge badge-success"
  }
}
```

### 4. The Hook API (`this`)

Inside every callback, `this` provides:

| Property/Method | Description |
|----------------|-------------|
| `this.el` | The DOM element the hook is attached to |
| `this.liveSocket` | The LiveSocket instance |
| `this.pushEvent(event, payload, callback?)` | Push event to server's `handle_event/3` |
| `this.pushEventTo(selector, event, payload, callback?)` | Push to a specific LiveComponent |
| `this.handleEvent(event, callback)` | Listen for events pushed from server |
| `this.upload(name, files)` | Initiate file uploads programmatically |

### 5. Communication Patterns

#### Client to Server
```javascript
// JavaScript
this.pushEvent("search", { query: "elixir" })
```
```elixir
# Elixir
def handle_event("search", %{"query" => query}, socket) do
  results = MyApp.Search.find(query)
  {:noreply, assign(socket, results: results)}
end
```

#### Server to Client
```elixir
# Elixir - push event to client
{:noreply, push_event(socket, "highlight", %{color: "yellow"})}
```
```javascript
// JavaScript - listen for server event
this.handleEvent("highlight", ({ color }) => {
  this.el.style.backgroundColor = color
})
```

#### Bidirectional (with reply)
```javascript
// JavaScript - push with callback
this.pushEvent("validate", { data: input }, (reply, ref) => {
  // reply = value from {:reply, ..., socket}
  console.log("Valid:", reply.valid)
})
```
```elixir
# Elixir - return reply
def handle_event("validate", %{"data" => data}, socket) do
  {:reply, %{valid: valid?(data)}, socket}
end
```

## Deep Dive

### 1. Data Attributes for Configuration

Pass server data to hooks via `data-*` attributes:

```html
<canvas
  id="my-chart"
  phx-hook="Chart"
  data-chart-type="bar"
  data-chart-data={Jason.encode!(@chart_data)}
  data-chart-options={Jason.encode!(@chart_options)}
>
</canvas>
```

```javascript
Hooks.Chart = {
  mounted() {
    const type = this.el.dataset.chartType
    const data = JSON.parse(this.el.dataset.chartData)
    const options = JSON.parse(this.el.dataset.chartOptions)
    this.chart = new Chart(this.el, { type, data, options })
  }
}
```

### 2. Hook Organization

For projects with many hooks, organize them in separate files:

```
assets/js/
  hooks/
    index.js          # Re-exports all hooks
    chart_hook.js
    clipboard_hook.js
    scroll_hook.js
  app.js              # Imports from hooks/index.js
```

```javascript
// assets/js/hooks/index.js
import ChartHook from "./chart_hook"
import ClipboardHook from "./clipboard_hook"
import ScrollHook from "./scroll_hook"

export default {
  ChartHook,
  ClipboardHook,
  ScrollHook
}
```

```javascript
// assets/js/app.js
import Hooks from "./hooks"
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks })
```

### 3. pushEvent vs pushEventTo

- `pushEvent` sends to the current LiveView
- `pushEventTo` sends to a specific LiveComponent by CSS selector

```javascript
// To the parent LiveView
this.pushEvent("global_action", {})

// To a specific LiveComponent
this.pushEventTo("#user-profile", "update_avatar", { url: newUrl })
```

On the server side, `pushEventTo` targets the component's `handle_event/3`:
```elixir
# In the targeted LiveComponent
def handle_event("update_avatar", %{"url" => url}, socket) do
  {:noreply, assign(socket, avatar_url: url)}
end
```

### 4. Handling LiveView Patches

When LiveView patches the DOM, the element's content may change but the hook instance persists (as long as the `id` stays the same). The lifecycle is:

1. Server sends diff
2. `beforeUpdate()` fires - save state
3. DOM is patched
4. `updated()` fires - restore state, re-init

If the element is removed entirely (e.g., conditional rendering with `:if`), `destroyed()` fires instead.

### 5. Debugging Hooks

```javascript
Hooks.Debug = {
  mounted()       { console.log("MOUNTED", this.el.id) },
  beforeUpdate()  { console.log("BEFORE UPDATE", this.el.id) },
  updated()       { console.log("UPDATED", this.el.id) },
  destroyed()     { console.log("DESTROYED", this.el.id) },
  disconnected()  { console.log("DISCONNECTED", this.el.id) },
  reconnected()   { console.log("RECONNECTED", this.el.id) }
}
```

Attach this hook temporarily to any element to trace its lifecycle.

## Common Pitfalls

1. **Missing `id`**: The element with `phx-hook` must have a unique `id`. Without it, the hook silently fails.

2. **Memory leaks**: Forgetting to clean up in `destroyed()`. Every `setInterval`, `addEventListener`, `observer.observe()`, or library instance created in `mounted()` must be cleaned up.

3. **Hook name mismatch**: The `phx-hook="Name"` value must exactly match the key in the Hooks object passed to LiveSocket. It is case-sensitive.

4. **Accessing removed DOM**: In `destroyed()`, `this.el` is still available but may already be detached from the document. Do not try to query parent elements.

5. **Assuming mounted() runs on updates**: `mounted()` runs only once. For logic that should run on every server patch, use `updated()` (and also call it from `mounted()` for the initial run).

6. **Blocking the main thread**: Long-running synchronous JS in hooks blocks LiveView's DOM patching. Use `requestAnimationFrame` or `setTimeout` for heavy work.

## Tips

- Use `this.el.dataset` to read `data-*` attributes set from the server
- Combine `beforeUpdate` + `updated` for scroll preservation patterns
- Use `disconnected` + `reconnected` to show connection status indicators
- For file uploads via drag-and-drop, use `this.upload(name, files)`
- Consider extracting common hook patterns into reusable modules
- Test hooks by adding console.log to each lifecycle callback during development

## Challenges

<h3>Challenge 1: Clipboard Copy Hook</h3>

<p>Create a hook that copies text to the clipboard when clicked, shows a "Copied!" indicator, and reverts after 2 seconds.</p>

<details>
<summary>View Solution</summary>

<pre><code class="javascript">Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.copyText
      navigator.clipboard.writeText(text).then(() => {
        const original = this.el.innerText
        this.el.innerText = "Copied!"
        setTimeout(() => {
          this.el.innerText = original
        }, 2000)
      })
    })
  }
}
</code></pre>

<pre><code class="elixir">&lt;button
  id="copy-btn"
  phx-hook="CopyToClipboard"
  data-copy-text={@text_to_copy}
&gt;
  Copy
&lt;/button&gt;
</code></pre>
</details>


<h3>Challenge 2: Auto-Resize Textarea</h3>

<p>Create a hook that automatically adjusts a textarea's height to fit its content as the user types.</p>

<details>
<summary>View Solution</summary>

<pre><code class="javascript">Hooks.AutoResize = {
  mounted() {
    this.resize()
    this.el.addEventListener("input", () => this.resize())
  },
  updated() {
    this.resize()
  },
  resize() {
    this.el.style.height = "auto"
    this.el.style.height = this.el.scrollHeight + "px"
  }
}
</code></pre>

<pre><code class="elixir">&lt;textarea
  id="auto-resize-textarea"
  phx-hook="AutoResize"
  rows="1"
  style="overflow: hidden; resize: none;"
&gt;&lt;/textarea&gt;
</code></pre>
</details>


<h3>Challenge 3: Dark Mode Toggle with localStorage</h3>

<p>Create a hook that toggles dark mode and persists the preference in localStorage, restoring it on page load.</p>

<details>
<summary>View Solution</summary>

<pre><code class="javascript">Hooks.DarkMode = {
  mounted() {
    const saved = localStorage.getItem("dark-mode")
    if (saved === "true") {
      document.documentElement.classList.add("dark")
      this.pushEvent("set_theme", { dark: true })
    }

    this.handleEvent("toggle-theme", ({ dark }) => {
      if (dark) {
        document.documentElement.classList.add("dark")
      } else {
        document.documentElement.classList.remove("dark")
      }
      localStorage.setItem("dark-mode", dark)
    })
  }
}
</code></pre>

<pre><code class="elixir">def handle_event("toggle_dark_mode", _params, socket) do
  dark = !socket.assigns.dark_mode
  {:noreply,
   socket
   |> assign(:dark_mode, dark)
   |> push_event("toggle-theme", %{dark: dark})}
end
</code></pre>
</details>


<h3>Challenge 4: Connection-Aware UI</h3>

<p>Create a hook that shows a connection status indicator and queues events while disconnected, replaying them on reconnect.</p>

<details>
<summary>View Solution</summary>

<pre><code class="javascript">Hooks.ConnectionAware = {
  mounted() {
    this.queue = []
    this.connected = true
  },
  disconnected() {
    this.connected = false
    this.el.querySelector(".status").innerText = "Offline"
    this.el.querySelector(".status").className = "status badge badge-error"
  },
  reconnected() {
    this.connected = true
    this.el.querySelector(".status").innerText = "Online"
    this.el.querySelector(".status").className = "status badge badge-success"

    // Replay queued events
    this.queue.forEach(({ event, payload }) => {
      this.pushEvent(event, payload)
    })
    this.queue = []
  },
  // Call this instead of pushEvent directly
  safePush(event, payload) {
    if (this.connected) {
      this.pushEvent(event, payload)
    } else {
      this.queue.push({ event, payload })
    }
  }
}
</code></pre>
</details>


## Related Katas

<ul>
<li><strong>Kata 84</strong>: Focus Management - Uses JS hooks for focus control</li>
<li><strong>Kata 85</strong>: Scroll Positioning - Uses hooks for scroll behavior</li>
<li><strong>Kata 86</strong>: Clipboard Copy - Browser API via hooks</li>
<li><strong>Kata 87</strong>: Local Storage - Persistence via hooks</li>
<li><strong>Kata 88</strong>: Theme Toggle - Dark mode with hooks</li>
<li><strong>Kata 89</strong>: Chart Integration - Third-party library via hooks</li>
<li><strong>Kata 90</strong>: Map Integration - Leaflet maps via hooks</li>
<li><strong>Kata 139</strong>: Virtual Scrolling - IntersectionObserver via hooks</li>
</ul>
