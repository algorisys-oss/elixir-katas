defmodule ElixirKatasWeb.Kata101HooksLive do
  use ElixirKatasWeb, :live_component

  # ── Module Attributes: Code Snippets for Display ──────────────────────────

  @hook_registration ~s"""
  // assets/js/app.js
  import { LiveSocket } from "phoenix_live_view"

  let Hooks = {}

  Hooks.MyHook = {
    mounted() {
      console.log("Element added to DOM:", this.el)
    },
    updated() {
      console.log("Element updated:", this.el)
    },
    destroyed() {
      console.log("Element removed from DOM")
    }
  }

  let liveSocket = new LiveSocket("/live", Socket, {
    hooks: Hooks,       // <-- Register hooks here
    params: { _csrf_token: csrfToken }
  })
  """

  @hook_heex_usage ~s"""
  <!-- In your HEEx template -->
  <div id="my-element" phx-hook="MyHook">
    Content here...
  </div>

  <!-- IMPORTANT: phx-hook requires a unique id -->
  """

  @mounted_example ~s"""
  Hooks.ChartInit = {
    mounted() {
      // 'this.el' is the DOM element with phx-hook
      const ctx = this.el.getContext("2d")

      this.chart = new Chart(ctx, {
        type: "line",
        data: JSON.parse(this.el.dataset.chartData)
      })

      // Listen for server-pushed events
      this.handleEvent("update-chart", (data) => {
        this.chart.data = data
        this.chart.update()
      })
    }
  }
  """

  @before_update_example ~s"""
  Hooks.ScrollPreserver = {
    beforeUpdate() {
      // Save scroll position before LiveView patches DOM
      this.scrollTop = this.el.scrollTop
      this.scrollHeight = this.el.scrollHeight
    },
    updated() {
      // Restore after update
      const newScrollHeight = this.el.scrollHeight
      const diff = newScrollHeight - this.scrollHeight
      this.el.scrollTop = this.scrollTop + diff
    }
  }
  """

  @updated_example ~s"""
  Hooks.SyntaxHighlight = {
    mounted() {
      this.highlight()
    },
    updated() {
      // Re-run highlighting after server updates content
      this.highlight()
    },
    highlight() {
      this.el.querySelectorAll("pre code").forEach(block => {
        hljs.highlightElement(block)
      })
    }
  }
  """

  @destroyed_example ~s"""
  Hooks.Poller = {
    mounted() {
      this.timer = setInterval(() => {
        this.pushEvent("poll", {})
      }, 5000)

      this.observer = new ResizeObserver(entries => {
        this.pushEvent("resize", {
          width: entries[0].contentRect.width
        })
      })
      this.observer.observe(this.el)
    },
    destroyed() {
      // CRITICAL: Clean up to prevent memory leaks
      clearInterval(this.timer)
      this.observer.disconnect()
    }
  }
  """

  @disconnected_example ~s"""
  Hooks.ConnectionStatus = {
    mounted() {
      this.el.innerText = "Connected"
      this.el.className = "badge badge-success"
    },
    disconnected() {
      this.el.innerText = "Offline - Reconnecting..."
      this.el.className = "badge badge-error"
    },
    reconnected() {
      this.el.innerText = "Connected"
      this.el.className = "badge badge-success"
      // Optionally refresh data
      this.pushEvent("refresh_data", {})
    }
  }
  """

  @client_to_server ~s"""
  // JavaScript (Hook)
  Hooks.SearchInput = {
    mounted() {
      this.el.addEventListener("input", (e) => {
        // Push event to server
        this.pushEvent("search", {
          query: e.target.value,
          timestamp: Date.now()
        })
      })
    }
  }
  """

  @client_to_server_elixir ~s"""
  # Elixir (LiveView)
  def handle_event("search", %{"query" => query}, socket) do
    results = MyApp.Search.find(query)
    {:noreply, assign(socket, results: results)}
  end
  """

  @server_to_client ~s"""
  # Elixir - push event to client
  def handle_event("save_item", params, socket) do
    case Items.create(params) do
      {:ok, item} ->
        {:noreply,
         socket
         |> assign(:item, item)
         |> push_event("item-saved", %{
           id: item.id,
           message: "Saved successfully!"
         })}

      {:error, changeset} ->
        {:noreply,
         socket
         |> push_event("save-failed", %{
           errors: format_errors(changeset)
         })}
    end
  end
  """

  @server_to_client_js ~s"""
  // JavaScript - listen for server events
  Hooks.SaveNotifier = {
    mounted() {
      this.handleEvent("item-saved", (data) => {
        showToast(data.message)
        animateElement(this.el)
      })

      this.handleEvent("save-failed", (data) => {
        showErrors(data.errors)
      })
    }
  }
  """

  @bidirectional ~s"""
  // JS: Push event, receive reply in callback
  Hooks.Autocomplete = {
    mounted() {
      this.el.addEventListener("input", (e) => {
        this.pushEvent("autocomplete",
          { query: e.target.value },
          (reply, ref) => {
            // reply = server's return value
            this.renderSuggestions(reply.suggestions)
          }
        )
      })
    },
    renderSuggestions(items) {
      // Update DOM with suggestions
    }
  }
  """

  @bidirectional_elixir ~s"""
  # Elixir: Return reply from handle_event
  def handle_event("autocomplete", %{"query" => q}, socket) do
    suggestions = MyApp.Search.suggest(q)
    {:reply, %{suggestions: suggestions}, socket}
  end
  """

  @pattern_3rd_party ~s"""
  Hooks.MapView = {
    mounted() {
      this.map = L.map(this.el).setView(
        [51.505, -0.09], 13
      )
      L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png")
        .addTo(this.map)

      // Listen for server updates
      this.handleEvent("add-marker", ({lat, lng, label}) => {
        L.marker([lat, lng]).addTo(this.map)
          .bindPopup(label)
      })
    },
    destroyed() {
      this.map.remove()
    }
  }
  """

  @pattern_browser_api ~s"""
  Hooks.GeoLocation = {
    mounted() {
      this.el.addEventListener("click", () => {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            this.pushEvent("location_found", {
              lat: pos.coords.latitude,
              lng: pos.coords.longitude
            })
          },
          (err) => {
            this.pushEvent("location_error", {
              message: err.message
            })
          }
        )
      })
    }
  }
  """

  @pattern_dom_measurement ~s"""
  Hooks.InfiniteScroll = {
    mounted() {
      this.observer = new IntersectionObserver(
        (entries) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              this.pushEvent("load_more", {})
            }
          })
        },
        { threshold: 0.1 }
      )
      // Observe a sentinel element at the bottom
      const sentinel = this.el.querySelector(".sentinel")
      if (sentinel) this.observer.observe(sentinel)
    },
    destroyed() {
      this.observer.disconnect()
    }
  }
  """

  @pattern_local_storage ~s"""
  Hooks.PersistState = {
    mounted() {
      // Restore saved state on mount
      const saved = localStorage.getItem(this.el.id)
      if (saved) {
        this.pushEvent("restore_state", JSON.parse(saved))
      }

      // Listen for state changes from server
      this.handleEvent("state_changed", (state) => {
        localStorage.setItem(this.el.id, JSON.stringify(state))
      })
    }
  }
  """

  @demo_hook_js ~s"""
  // This hook would go in assets/js/app.js
  Hooks.CounterHook = {
    mounted() {
      console.log("CounterHook mounted on:", this.el.id)

      // Listen for "count-updated" from server
      this.handleEvent("count-updated", (payload) => {
        // Could trigger animations, sounds, etc.
        this.el.classList.add("animate-pulse")
        setTimeout(() => {
          this.el.classList.remove("animate-pulse")
        }, 500)
      })
    },
    destroyed() {
      console.log("CounterHook destroyed")
    }
  }
  """

  @demo_elixir_code ~s"""
  # In your LiveView / LiveComponent
  def handle_event("hook_increment", _params, socket) do
    new_count = socket.assigns.hook_count + 1

    {:noreply,
     socket
     |> assign(:hook_count, new_count)
     |> push_event("count-updated", %{count: new_count})}
  end
  """

  @push_event_to_example ~s"""
  // Push to a specific LiveComponent by CSS selector
  this.pushEventTo(
    "#user-profile",       // CSS selector
    "update_avatar",       // event name
    { url: newAvatarUrl }, // payload
    (reply, ref) => {}     // optional callback
  )
  """

  @upload_hook_example ~s"""
  Hooks.DragDropUpload = {
    mounted() {
      this.el.addEventListener("drop", (e) => {
        e.preventDefault()
        const files = e.dataTransfer.files
        // Programmatic upload via hook
        this.upload("avatar", files)
      })
      this.el.addEventListener("dragover", (e) => {
        e.preventDefault()
      })
    }
  }
  """

  # ── LiveComponent Callbacks ───────────────────────────────────────────────

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_tab, fn -> "notes" end)
     |> assign_new(:active_section, fn -> "overview" end)
     |> assign_new(:active_lifecycle, fn -> "mounted" end)
     |> assign_new(:active_api, fn -> "el" end)
     |> assign_new(:active_comm, fn -> "client_to_server" end)
     |> assign_new(:active_pattern, fn -> "third_party" end)
     |> assign_new(:hook_count, fn -> 0 end)
     |> assign_new(:hook_log, fn -> [] end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl mx-auto space-y-8">
      <div class="mb-6 text-sm text-gray-500">
        JavaScript Hooks let you run client-side code in response to LiveView lifecycle events.
        They bridge the gap between server-rendered UI and browser APIs.
      </div>

      <%!-- ━━━ Section Navigation ━━━ --%>
      <div class="flex flex-wrap gap-2 mb-6">
        <button
          :for={
            {id, label} <- [
              {"overview", "What are Hooks?"},
              {"lifecycle", "Lifecycle Callbacks"},
              {"api", "Hook API"},
              {"communication", "Communication"},
              {"patterns", "Common Patterns"},
              {"demo", "Live Demo"},
              {"setup", "Setup Guide"},
              {"takeaways", "Key Takeaways"}
            ]
          }
          phx-click="set_section"
          phx-value-section={id}
          phx-target={@myself}
          class={[
            "btn btn-sm",
            if(@active_section == id, do: "btn-primary", else: "btn-ghost border border-base-300")
          ]}
        >
          {label}
        </button>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 1: What are Hooks? --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "overview"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">What are Hooks?</h3>
            <p class="text-sm text-gray-600">
              Hooks are <strong>JavaScript objects</strong> that let you interact with the DOM and run
              client-side code in response to LiveView lifecycle events. They bridge the gap between
              server-side LiveView and client-side JavaScript.
            </p>

            <div class="alert alert-info mt-4">
              <div>
                <p class="font-semibold">When to use Hooks</p>
                <ul class="list-disc list-inside text-sm mt-1 space-y-1">
                  <li>Initializing third-party JS libraries (charts, maps, rich editors)</li>
                  <li>Accessing browser APIs (clipboard, geolocation, notifications)</li>
                  <li>DOM manipulation LiveView cannot do (focus, scroll, measurements)</li>
                  <li>Client-side event listeners (resize, intersection, drag/drop)</li>
                </ul>
              </div>
            </div>

            <div class="divider">How it works</div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-center text-sm">
              <div class="p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg mb-2">1</div>
                <p class="font-semibold">Define in app.js</p>
                <p class="text-xs text-gray-500 mt-1">Create a JS object with lifecycle callbacks</p>
              </div>
              <div class="p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg mb-2">2</div>
                <p class="font-semibold">Register with LiveSocket</p>
                <p class="text-xs text-gray-500 mt-1">Pass hooks object to LiveSocket constructor</p>
              </div>
              <div class="p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg mb-2">3</div>
                <p class="font-semibold">Attach via phx-hook</p>
                <p class="text-xs text-gray-500 mt-1">Add phx-hook="HookName" + unique id to element</p>
              </div>
            </div>

            <div class="mt-6 space-y-4">
              <div>
                <h4 class="font-semibold text-sm mb-2">Registering hooks in app.js:</h4>
                <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{hook_registration_code()}</code></pre>
              </div>
              <div>
                <h4 class="font-semibold text-sm mb-2">Using in HEEx template:</h4>
                <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{hook_heex_code()}</code></pre>
              </div>
            </div>

            <div class="alert alert-warning mt-4">
              <div>
                <p class="text-sm">
                  <strong>Important:</strong> Every element with <code class="bg-warning-content/20 px-1 rounded">phx-hook</code> must have a
                  unique <code class="bg-warning-content/20 px-1 rounded">id</code> attribute. Without it, the hook will not fire.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 2: Lifecycle Callbacks --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "lifecycle"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">Lifecycle Callbacks</h3>
            <p class="text-sm text-gray-600">
              Every hook can define up to 6 lifecycle callbacks. Each fires at a specific moment
              in the element's or connection's lifecycle.
            </p>

            <%!-- Lifecycle Tabs --%>
            <div class="tabs tabs-bordered mt-4">
              <button
                :for={
                  {id, label} <- [
                    {"mounted", "mounted()"},
                    {"before_update", "beforeUpdate()"},
                    {"updated", "updated()"},
                    {"destroyed", "destroyed()"},
                    {"disconnected", "disconnected()"},
                    {"reconnected", "reconnected()"}
                  ]
                }
                phx-click="set_lifecycle"
                phx-value-tab={id}
                phx-target={@myself}
                class={["tab", if(@active_lifecycle == id, do: "tab-active", else: "")]}
              >
                {label}
              </button>
            </div>

            <%!-- mounted --%>
            <div :if={@active_lifecycle == "mounted"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-success badge-lg">MOST COMMON</div>
                <div>
                  <p class="font-semibold">mounted()</p>
                  <p class="text-sm text-gray-600">
                    Called when the element is first added to the DOM. This is where you do most
                    hook work: initialize libraries, add event listeners, set up timers.
                  </p>
                </div>
              </div>
              <div class="text-sm text-gray-500">
                <strong>When it fires:</strong> After the element and its children are inserted into the DOM.
              </div>
              <div class="text-sm text-gray-500">
                <strong>Common uses:</strong> Init chart libraries, set up IntersectionObserver, bind keyboard shortcuts, start polling.
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{mounted_code()}</code></pre>
            </div>

            <%!-- beforeUpdate --%>
            <div :if={@active_lifecycle == "before_update"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-warning badge-lg">SAVE STATE</div>
                <div>
                  <p class="font-semibold">beforeUpdate()</p>
                  <p class="text-sm text-gray-600">
                    Called before the element is updated by a server patch. Use it to save state
                    that will be lost during the DOM update (e.g., scroll position, selection range).
                  </p>
                </div>
              </div>
              <div class="text-sm text-gray-500">
                <strong>When it fires:</strong> After the server sends a diff, but before LiveView applies the patch to the DOM.
              </div>
              <div class="text-sm text-gray-500">
                <strong>Common uses:</strong> Save scroll position, preserve cursor position, capture animation state.
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{before_update_code()}</code></pre>
            </div>

            <%!-- updated --%>
            <div :if={@active_lifecycle == "updated"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-info badge-lg">REINITIALIZE</div>
                <div>
                  <p class="font-semibold">updated()</p>
                  <p class="text-sm text-gray-600">
                    Called after the element has been updated by a server patch. Use it to
                    re-initialize anything that was affected by the DOM change.
                  </p>
                </div>
              </div>
              <div class="text-sm text-gray-500">
                <strong>When it fires:</strong> After LiveView applies the patch and the DOM is updated. Only fires when
                the element's content actually changes.
              </div>
              <div class="text-sm text-gray-500">
                <strong>Common uses:</strong> Re-run syntax highlighting, restore scroll position, update chart data, re-attach plugins.
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{updated_code()}</code></pre>
            </div>

            <%!-- destroyed --%>
            <div :if={@active_lifecycle == "destroyed"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-error badge-lg">CLEANUP</div>
                <div>
                  <p class="font-semibold">destroyed()</p>
                  <p class="text-sm text-gray-600">
                    Called when the element is removed from the DOM. Critical for preventing
                    memory leaks by cleaning up timers, observers, and event listeners.
                  </p>
                </div>
              </div>
              <div class="text-sm text-gray-500">
                <strong>When it fires:</strong> After the element is removed from the DOM by a server patch or navigation.
              </div>
              <div class="text-sm text-gray-500">
                <strong>Common uses:</strong> clearInterval/clearTimeout, disconnect observers, remove global event listeners, destroy library instances.
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{destroyed_code()}</code></pre>
            </div>

            <%!-- disconnected --%>
            <div :if={@active_lifecycle == "disconnected"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-ghost badge-lg">CONNECTION</div>
                <div>
                  <p class="font-semibold">disconnected()</p>
                  <p class="text-sm text-gray-600">
                    Called when the LiveView WebSocket connection drops. Use it to show
                    offline indicators or pause real-time features.
                  </p>
                </div>
              </div>
              <div class="text-sm text-gray-500">
                <strong>When it fires:</strong> When the WebSocket connection to the server is lost (network issue, server restart, etc.).
              </div>
              <div class="text-sm text-gray-500">
                <strong>Common uses:</strong> Show "offline" banner, pause polling, disable interactive features, show reconnection notice.
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{disconnected_code()}</code></pre>
            </div>

            <%!-- reconnected --%>
            <div :if={@active_lifecycle == "reconnected"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-accent badge-lg">RECOVERY</div>
                <div>
                  <p class="font-semibold">reconnected()</p>
                  <p class="text-sm text-gray-600">
                    Called when the LiveView WebSocket reconnects after a disconnect.
                    Use it to refresh stale data and restore the UI.
                  </p>
                </div>
              </div>
              <div class="text-sm text-gray-500">
                <strong>When it fires:</strong> After the WebSocket successfully reconnects and the LiveView process is restored.
              </div>
              <div class="text-sm text-gray-500">
                <strong>Common uses:</strong> Remove "offline" banner, refresh data from server, re-enable features, resume polling.
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{disconnected_code()}</code></pre>
              <div class="alert alert-info mt-2">
                <p class="text-sm">
                  The <code>reconnected()</code> and <code>disconnected()</code> callbacks are commonly
                  used together on the same hook, as shown above. This pattern provides a clean way to handle
                  connection state changes.
                </p>
              </div>
            </div>

            <%!-- Lifecycle Flow Diagram --%>
            <div class="mt-6 p-4 bg-base-200 rounded-lg">
              <h4 class="font-semibold text-sm mb-3">Lifecycle Flow</h4>
              <pre class="text-xs font-mono whitespace-pre overflow-x-auto">{lifecycle_flow_diagram()}</pre>
            </div>
          </div>
        </div>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 3: Hook API (this.*) --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "api"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">Hook API Reference</h3>
            <p class="text-sm text-gray-600">
              Inside every lifecycle callback, <code class="bg-base-200 px-1 rounded">this</code> provides
              access to the element, the LiveSocket, and methods for communicating with the server.
            </p>

            <%!-- API Tabs --%>
            <div class="tabs tabs-bordered mt-4">
              <button
                :for={
                  {id, label} <- [
                    {"el", "this.el"},
                    {"pushEvent", "pushEvent"},
                    {"pushEventTo", "pushEventTo"},
                    {"handleEvent", "handleEvent"},
                    {"upload", "this.upload"},
                    {"liveSocket", "liveSocket"}
                  ]
                }
                phx-click="set_api"
                phx-value-tab={id}
                phx-target={@myself}
                class={["tab", if(@active_api == id, do: "tab-active", else: "")]}
              >
                {label}
              </button>
            </div>

            <%!-- this.el --%>
            <div :if={@active_api == "el"} class="mt-4 space-y-3">
              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Property</th>
                      <th>Type</th>
                      <th>Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td><code>this.el</code></td>
                      <td class="text-xs">HTMLElement</td>
                      <td class="text-sm">The DOM element the hook is attached to</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{api_el_code()}</code></pre>
            </div>

            <%!-- pushEvent --%>
            <div :if={@active_api == "pushEvent"} class="mt-4 space-y-3">
              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Method</th>
                      <th>Signature</th>
                      <th>Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td><code>this.pushEvent</code></td>
                      <td class="text-xs font-mono">pushEvent(event, payload, callback?)</td>
                      <td class="text-sm">Push an event to the server's handle_event/3</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{api_push_event_code()}</code></pre>
            </div>

            <%!-- pushEventTo --%>
            <div :if={@active_api == "pushEventTo"} class="mt-4 space-y-3">
              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Method</th>
                      <th>Signature</th>
                      <th>Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td><code>this.pushEventTo</code></td>
                      <td class="text-xs font-mono">pushEventTo(selector, event, payload, callback?)</td>
                      <td class="text-sm">Push an event to a specific LiveComponent identified by CSS selector</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{push_event_to_code()}</code></pre>
            </div>

            <%!-- handleEvent --%>
            <div :if={@active_api == "handleEvent"} class="mt-4 space-y-3">
              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Method</th>
                      <th>Signature</th>
                      <th>Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td><code>this.handleEvent</code></td>
                      <td class="text-xs font-mono">handleEvent(event, callback)</td>
                      <td class="text-sm">Listen for events pushed from the server via push_event/3</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{api_handle_event_code()}</code></pre>
            </div>

            <%!-- this.upload --%>
            <div :if={@active_api == "upload"} class="mt-4 space-y-3">
              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Method</th>
                      <th>Signature</th>
                      <th>Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td><code>this.upload</code></td>
                      <td class="text-xs font-mono">upload(name, files)</td>
                      <td class="text-sm">Programmatically initiate a file upload (for drag-and-drop)</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{upload_hook_code()}</code></pre>
            </div>

            <%!-- liveSocket --%>
            <div :if={@active_api == "liveSocket"} class="mt-4 space-y-3">
              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Property</th>
                      <th>Type</th>
                      <th>Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td><code>this.liveSocket</code></td>
                      <td class="text-xs">LiveSocket</td>
                      <td class="text-sm">The LiveSocket instance; rarely needed directly</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{api_live_socket_code()}</code></pre>
            </div>
          </div>
        </div>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 4: Communication Patterns --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "communication"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">Communication Patterns</h3>
            <p class="text-sm text-gray-600">
              Hooks communicate with the server in three patterns: client-to-server, server-to-client,
              and bidirectional round-trips.
            </p>

            <%!-- Communication Tabs --%>
            <div class="tabs tabs-bordered mt-4">
              <button
                :for={
                  {id, label} <- [
                    {"client_to_server", "Client -> Server"},
                    {"server_to_client", "Server -> Client"},
                    {"bidirectional", "Bidirectional"}
                  ]
                }
                phx-click="set_comm"
                phx-value-tab={id}
                phx-target={@myself}
                class={["tab", if(@active_comm == id, do: "tab-active", else: "")]}
              >
                {label}
              </button>
            </div>

            <%!-- Client -> Server --%>
            <div :if={@active_comm == "client_to_server"} class="mt-4 space-y-4">
              <div class="alert alert-info">
                <p class="text-sm">
                  <strong>Flow:</strong>
                  <code>this.pushEvent(event, payload)</code> in JS triggers
                  <code>handle_event(event, payload, socket)</code> on the server.
                </p>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h4 class="text-sm font-semibold mb-2 badge badge-warning">JavaScript</h4>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto h-full"><code>{client_to_server_js_code()}</code></pre>
                </div>
                <div>
                  <h4 class="text-sm font-semibold mb-2 badge badge-primary">Elixir</h4>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto h-full"><code>{client_to_server_elixir_code()}</code></pre>
                </div>
              </div>
            </div>

            <%!-- Server -> Client --%>
            <div :if={@active_comm == "server_to_client"} class="mt-4 space-y-4">
              <div class="alert alert-info">
                <p class="text-sm">
                  <strong>Flow:</strong>
                  <code>push_event(socket, event, payload)</code> on server triggers
                  <code>this.handleEvent(event, callback)</code> in JS.
                </p>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h4 class="text-sm font-semibold mb-2 badge badge-primary">Elixir</h4>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto h-full"><code>{server_to_client_elixir_code()}</code></pre>
                </div>
                <div>
                  <h4 class="text-sm font-semibold mb-2 badge badge-warning">JavaScript</h4>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto h-full"><code>{server_to_client_js_code()}</code></pre>
                </div>
              </div>
            </div>

            <%!-- Bidirectional --%>
            <div :if={@active_comm == "bidirectional"} class="mt-4 space-y-4">
              <div class="alert alert-info">
                <p class="text-sm">
                  <strong>Flow:</strong>
                  <code>pushEvent</code> with a callback receives the server's reply directly.
                  The server returns <code>&lbrace;:reply, payload, socket&rbrace;</code> from handle_event.
                </p>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h4 class="text-sm font-semibold mb-2 badge badge-warning">JavaScript</h4>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto h-full"><code>{bidirectional_js_code()}</code></pre>
                </div>
                <div>
                  <h4 class="text-sm font-semibold mb-2 badge badge-primary">Elixir</h4>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto h-full"><code>{bidirectional_elixir_code()}</code></pre>
                </div>
              </div>
              <div class="alert alert-warning mt-2">
                <p class="text-sm">
                  <strong>Note:</strong> The callback approach is great for one-off request/response
                  patterns (like autocomplete). For ongoing server-to-client pushes, use
                  <code>this.handleEvent</code> instead.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 5: Common Patterns --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "patterns"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">Common Hook Patterns</h3>
            <p class="text-sm text-gray-600">
              Real-world patterns you will encounter when building LiveView applications.
            </p>

            <%!-- Pattern Tabs --%>
            <div class="tabs tabs-bordered mt-4">
              <button
                :for={
                  {id, label} <- [
                    {"third_party", "3rd-Party Libs"},
                    {"browser_api", "Browser APIs"},
                    {"dom_measurement", "DOM Measurement"},
                    {"local_storage", "Local Storage"}
                  ]
                }
                phx-click="set_pattern"
                phx-value-tab={id}
                phx-target={@myself}
                class={["tab", if(@active_pattern == id, do: "tab-active", else: "")]}
              >
                {label}
              </button>
            </div>

            <%!-- 3rd Party --%>
            <div :if={@active_pattern == "third_party"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-primary badge-lg">MAP</div>
                <div>
                  <p class="font-semibold">Initializing Third-Party Libraries</p>
                  <p class="text-sm text-gray-600">
                    Charts (Chart.js), maps (Leaflet), editors (CodeMirror, Trix),
                    date pickers, and similar libraries need direct DOM access to initialize.
                  </p>
                </div>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{pattern_3rd_party_code()}</code></pre>
              <div class="alert alert-warning">
                <p class="text-sm">
                  <strong>Key pattern:</strong> Always destroy library instances in the
                  <code>destroyed()</code> callback to prevent memory leaks, especially for
                  map and chart libraries.
                </p>
              </div>
            </div>

            <%!-- Browser API --%>
            <div :if={@active_pattern == "browser_api"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-secondary badge-lg">GEO</div>
                <div>
                  <p class="font-semibold">Browser API Integration</p>
                  <p class="text-sm text-gray-600">
                    Clipboard, Geolocation, Notifications, Web Audio, MediaRecorder - these
                    browser APIs are only available in JavaScript. Hooks bridge the gap.
                  </p>
                </div>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{pattern_browser_api_code()}</code></pre>
            </div>

            <%!-- DOM Measurement --%>
            <div :if={@active_pattern == "dom_measurement"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-accent badge-lg">SCROLL</div>
                <div>
                  <p class="font-semibold">DOM Measurement and Observation</p>
                  <p class="text-sm text-gray-600">
                    IntersectionObserver for infinite scroll, ResizeObserver for responsive
                    behavior, MutationObserver for DOM changes - these are hook territory.
                  </p>
                </div>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{pattern_dom_measurement_code()}</code></pre>
            </div>

            <%!-- Local Storage --%>
            <div :if={@active_pattern == "local_storage"} class="mt-4 space-y-4">
              <div class="flex items-start gap-3">
                <div class="badge badge-info badge-lg">PERSIST</div>
                <div>
                  <p class="font-semibold">Local Storage Persistence</p>
                  <p class="text-sm text-gray-600">
                    Persist user preferences, form drafts, or UI state to localStorage so it
                    survives page refreshes without needing a database.
                  </p>
                </div>
              </div>
              <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{pattern_local_storage_code()}</code></pre>
            </div>
          </div>
        </div>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 6: Live Demo --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "demo"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">Live Demo: Counter Hook</h3>
            <p class="text-sm text-gray-600">
              This demonstrates the full hook communication cycle. The button triggers a
              server event, the server updates state and pushes an event back to the client.
            </p>

            <%!-- Working Demo Area --%>
            <div class="mt-4 p-6 bg-base-200 rounded-lg">
              <div class="flex flex-col items-center gap-4">
                <div class="text-6xl font-bold text-primary" id={"hook-counter-display-#{@id}"}>
                  {@hook_count}
                </div>

                <div class="flex gap-3">
                  <button
                    phx-click="hook_increment"
                    phx-target={@myself}
                    class="btn btn-primary btn-lg"
                  >
                    + Increment via Hook
                  </button>
                  <button
                    phx-click="hook_reset"
                    phx-target={@myself}
                    class="btn btn-outline btn-lg"
                  >
                    Reset
                  </button>
                </div>

                <div class="text-sm text-gray-500 mt-2">
                  Count: {@hook_count} | Events logged: {length(@hook_log)}
                </div>
              </div>
            </div>

            <%!-- Event Log --%>
            <div class="mt-4">
              <h4 class="font-semibold text-sm mb-2">Event Flow Log</h4>
              <div class="bg-gray-900 text-green-400 font-mono text-xs p-4 rounded-lg max-h-48 overflow-y-auto">
                <%= if Enum.empty?(@hook_log) do %>
                  <div class="text-gray-500">Click "Increment via Hook" to see the event flow...</div>
                <% else %>
                  <%= for {entry, idx} <- Enum.with_index(@hook_log) do %>
                    <div class="mb-1">
                      <span class="text-gray-500">[{idx + 1}]</span> {entry}
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>

            <div class="divider">How it works</div>

            <%!-- Side-by-Side Code --%>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <h4 class="text-sm font-semibold mb-2 badge badge-warning">JavaScript Hook</h4>
                <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{demo_hook_js_code()}</code></pre>
              </div>
              <div>
                <h4 class="text-sm font-semibold mb-2 badge badge-primary">Elixir Server</h4>
                <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{demo_elixir_code()}</code></pre>
              </div>
            </div>

            <%!-- Flow Diagram --%>
            <div class="mt-4 p-4 bg-base-200 rounded-lg">
              <h4 class="font-semibold text-sm mb-3">Communication Flow</h4>
              <pre class="text-xs font-mono whitespace-pre overflow-x-auto">{demo_flow_diagram()}</pre>
            </div>
          </div>
        </div>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 7: Setup Guide --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "setup"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">Hook Setup Guide</h3>
            <p class="text-sm text-gray-600">
              Step-by-step guide to adding hooks to your Phoenix LiveView project.
            </p>

            <%!-- Step 1 --%>
            <div class="mt-4 space-y-6">
              <div class="flex gap-4">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">1</div>
                <div class="flex-1">
                  <h4 class="font-semibold">Create your hook object</h4>
                  <p class="text-sm text-gray-600 mb-2">
                    Define a JavaScript object with lifecycle callbacks in
                    <code class="bg-base-200 px-1 rounded">assets/js/app.js</code> (or a separate file you import).
                  </p>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{setup_step1_code()}</code></pre>
                </div>
              </div>

              <%!-- Step 2 --%>
              <div class="flex gap-4">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">2</div>
                <div class="flex-1">
                  <h4 class="font-semibold">Register with LiveSocket</h4>
                  <p class="text-sm text-gray-600 mb-2">
                    Import your hooks and pass them to the LiveSocket constructor.
                  </p>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{setup_step2_code()}</code></pre>
                </div>
              </div>

              <%!-- Step 3 --%>
              <div class="flex gap-4">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">3</div>
                <div class="flex-1">
                  <h4 class="font-semibold">Attach to an element in HEEx</h4>
                  <p class="text-sm text-gray-600 mb-2">
                    Add <code class="bg-base-200 px-1 rounded">phx-hook="HookName"</code> and a unique
                    <code class="bg-base-200 px-1 rounded">id</code> to the element.
                  </p>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{setup_step3_code()}</code></pre>
                </div>
              </div>

              <%!-- Step 4 --%>
              <div class="flex gap-4">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">4</div>
                <div class="flex-1">
                  <h4 class="font-semibold">Handle events on the server</h4>
                  <p class="text-sm text-gray-600 mb-2">
                    Add <code class="bg-base-200 px-1 rounded">handle_event/3</code> callbacks to process events pushed from the hook.
                  </p>
                  <pre class="bg-gray-900 text-green-400 text-xs p-4 rounded-lg overflow-x-auto"><code>{setup_step4_code()}</code></pre>
                </div>
              </div>
            </div>

            <%!-- Connection Diagram --%>
            <div class="mt-6 p-4 bg-base-200 rounded-lg">
              <h4 class="font-semibold text-sm mb-3">How phx-hook connects to app.js</h4>
              <pre class="text-xs font-mono whitespace-pre overflow-x-auto">{setup_connection_diagram()}</pre>
            </div>

            <div class="alert alert-warning mt-4">
              <div>
                <p class="text-sm">
                  <strong>Common mistake:</strong> Forgetting the <code>id</code> attribute.
                  Without a unique id, LiveView cannot track the element and the hook will
                  never fire. You will see no errors - it will just silently not work.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <%!-- SECTION 8: Key Takeaways --%>
      <%!-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --%>
      <div :if={@active_section == "takeaways"} class="space-y-6">
        <div class="card bg-base-100 shadow border">
          <div class="card-body">
            <h3 class="card-title text-lg">Key Takeaways</h3>

            <div class="space-y-4 mt-4">
              <div class="flex gap-4 items-start p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">1</div>
                <div>
                  <p class="font-semibold">Hooks are the escape hatch to JavaScript</p>
                  <p class="text-sm text-gray-600">
                    When you need browser APIs, third-party JS libraries, or client-side DOM
                    manipulation that LiveView cannot handle, hooks are the official solution.
                  </p>
                </div>
              </div>

              <div class="flex gap-4 items-start p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">2</div>
                <div>
                  <p class="font-semibold">Always clean up in destroyed()</p>
                  <p class="text-sm text-gray-600">
                    Memory leaks are the most common hook bug. Every setInterval, observer,
                    or event listener created in mounted() should be cleaned up in destroyed().
                  </p>
                </div>
              </div>

              <div class="flex gap-4 items-start p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">3</div>
                <div>
                  <p class="font-semibold">phx-hook requires a unique id</p>
                  <p class="text-sm text-gray-600">
                    This is the number one "silent failure" with hooks. No id means the hook
                    simply will not fire - and you will get no error message.
                  </p>
                </div>
              </div>

              <div class="flex gap-4 items-start p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">4</div>
                <div>
                  <p class="font-semibold">Two-way communication is straightforward</p>
                  <p class="text-sm text-gray-600">
                    Client-to-server: <code>this.pushEvent</code>. Server-to-client:
                    <code>push_event</code> + <code>this.handleEvent</code>. Bidirectional:
                    <code>pushEvent</code> with callback + <code>&lbrace;:reply, ...&rbrace;</code>.
                  </p>
                </div>
              </div>

              <div class="flex gap-4 items-start p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">5</div>
                <div>
                  <p class="font-semibold">Prefer LiveView features over hooks when possible</p>
                  <p class="text-sm text-gray-600">
                    Before reaching for a hook, check if Phoenix.LiveView.JS, phx-click,
                    phx-change, or other built-in bindings can do what you need. Hooks add
                    complexity and a JavaScript dependency.
                  </p>
                </div>
              </div>

              <div class="flex gap-4 items-start p-4 bg-base-200 rounded-lg">
                <div class="badge badge-primary badge-lg w-8 h-8 shrink-0">6</div>
                <div>
                  <p class="font-semibold">Use data attributes to pass configuration</p>
                  <p class="text-sm text-gray-600">
                    Pass data from the server to hooks via <code>data-*</code> attributes on the
                    element. Access them with <code>this.el.dataset</code>. This keeps hooks generic
                    and reusable.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Event Handlers ────────────────────────────────────────────────────────

  def handle_event("set_section", %{"section" => section}, socket) do
    {:noreply, assign(socket, :active_section, section)}
  end

  def handle_event("set_lifecycle", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_lifecycle, tab)}
  end

  def handle_event("set_api", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_api, tab)}
  end

  def handle_event("set_comm", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_comm, tab)}
  end

  def handle_event("set_pattern", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_pattern, tab)}
  end

  def handle_event("hook_increment", _params, socket) do
    new_count = socket.assigns.hook_count + 1

    log_entries =
      socket.assigns.hook_log ++
        [
          "Client: pushEvent(\"hook_increment\", {})",
          "Server: handle_event(\"hook_increment\", ...) -> count = #{new_count}",
          "Server: push_event(socket, \"count-updated\", %{count: #{new_count}})",
          "Client: handleEvent(\"count-updated\") -> animate pulse"
        ]

    {:noreply,
     socket
     |> assign(:hook_count, new_count)
     |> assign(:hook_log, log_entries)
     |> push_event("count-updated", %{count: new_count})}
  end

  def handle_event("hook_reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:hook_count, 0)
     |> assign(:hook_log, [])}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  # ── Code Display Helpers ──────────────────────────────────────────────────

  defp hook_registration_code, do: @hook_registration
  defp hook_heex_code, do: @hook_heex_usage
  defp mounted_code, do: @mounted_example
  defp before_update_code, do: @before_update_example
  defp updated_code, do: @updated_example
  defp destroyed_code, do: @destroyed_example
  defp disconnected_code, do: @disconnected_example
  defp client_to_server_js_code, do: @client_to_server
  defp client_to_server_elixir_code, do: @client_to_server_elixir
  defp server_to_client_elixir_code, do: @server_to_client
  defp server_to_client_js_code, do: @server_to_client_js
  defp bidirectional_js_code, do: @bidirectional
  defp bidirectional_elixir_code, do: @bidirectional_elixir
  defp pattern_3rd_party_code, do: @pattern_3rd_party
  defp pattern_browser_api_code, do: @pattern_browser_api
  defp pattern_dom_measurement_code, do: @pattern_dom_measurement
  defp pattern_local_storage_code, do: @pattern_local_storage
  defp demo_hook_js_code, do: @demo_hook_js
  defp demo_elixir_code, do: @demo_elixir_code
  defp push_event_to_code, do: @push_event_to_example
  defp upload_hook_code, do: @upload_hook_example

  defp api_el_code do
    "mounted() {\n" <>
    "  // Access element properties\n" <>
    "  console.log(this.el.id)              // element id\n" <>
    "  console.log(this.el.dataset.userId)  // data-user-id attribute\n" <>
    "  console.log(this.el.innerText)       // text content\n" <>
    "  this.el.classList.add(\"active\")      // manipulate classes\n" <>
    "}"
  end

  defp api_push_event_code do
    "mounted() {\n" <>
    "  // Simple push\n" <>
    "  this.pushEvent(\"clicked\", {item_id: 42})\n" <>
    "\n" <>
    "  // With reply callback\n" <>
    "  this.pushEvent(\"validate\", {data: \"test\"}, (reply, ref) => {\n" <>
    "    console.log(\"Server replied:\", reply)\n" <>
    "    // reply comes from {:reply, %{...}, socket}\n" <>
    "  })\n" <>
    "}"
  end

  defp api_handle_event_code do
    "mounted() {\n" <>
    "  // Listen for server-pushed events\n" <>
    "  this.handleEvent(\"highlight\", (payload) => {\n" <>
    "    // payload = the map passed from push_event/3\n" <>
    "    this.el.style.backgroundColor = payload.color\n" <>
    "  })\n" <>
    "\n" <>
    "  this.handleEvent(\"scroll-to\", ({position}) => {\n" <>
    "    window.scrollTo({top: position, behavior: \"smooth\"})\n" <>
    "  })\n" <>
    "}"
  end

  defp api_live_socket_code do
    "mounted() {\n" <>
    "  // Access the LiveSocket (advanced use)\n" <>
    "  const ls = this.liveSocket\n" <>
    "\n" <>
    "  // Check if currently connected\n" <>
    "  console.log(\"Connected:\", ls.isConnected())\n" <>
    "\n" <>
    "  // Access the underlying Phoenix Socket\n" <>
    "  console.log(\"Socket:\", ls.socket)\n" <>
    "}"
  end

  defp setup_step1_code do
    "// assets/js/hooks/my_hook.js\n" <>
    "let MyHook = {\n" <>
    "  mounted() {\n" <>
    "    console.log(\"Hook mounted!\", this.el)\n" <>
    "  }\n" <>
    "}\n" <>
    "\n" <>
    "export default MyHook"
  end

  defp setup_step2_code do
    "// assets/js/app.js\n" <>
    "import MyHook from \"./hooks/my_hook\"\n" <>
    "\n" <>
    "let Hooks = {}\n" <>
    "Hooks.MyHook = MyHook\n" <>
    "// or: let Hooks = { MyHook }\n" <>
    "\n" <>
    "let liveSocket = new LiveSocket(\"/live\", Socket, {\n" <>
    "  hooks: Hooks,\n" <>
    "  params: { _csrf_token: csrfToken }\n" <>
    "})"
  end

  defp setup_step3_code do
    "<div id=\"my-unique-element\" phx-hook=\"MyHook\">\n" <>
    "  Hook is attached here\n" <>
    "</div>\n" <>
    "\n" <>
    "<!-- Dynamic ids for lists -->\n" <>
    "<div\n" <>
    "  :for={item <- @items}\n" <>
    "  id={\"item-\#{item.id}\"}\n" <>
    "  phx-hook=\"ItemHook\"\n" <>
    ">\n" <>
    "  {item.name}\n" <>
    "</div>"
  end

  defp setup_step4_code do
    "# In your LiveView or LiveComponent\n" <>
    "def handle_event(\"my_event\", payload, socket) do\n" <>
    "  # Process the event from the hook\n" <>
    "  {:noreply, socket}\n" <>
    "end"
  end

  defp lifecycle_flow_diagram do
    """
    Element Added to DOM
           |
           v
      +-----------+
      | mounted() |  <-- Initialize JS libs, add listeners
      +-----------+
           |
           |  Server sends update
           v
    +----------------+
    | beforeUpdate() |  <-- Save scroll position, state
    +----------------+
           |
           v
      +-----------+
      | updated() |  <-- Re-init, restore state
      +-----------+
           |
           |  (repeats on each server update)
           |
    Element Removed from DOM
           |
           v
      +-------------+
      | destroyed() |  <-- Clean up timers, observers
      +-------------+

    === Connection Events (independent) ===

    WebSocket Disconnects        WebSocket Reconnects
           |                            |
           v                            v
    +----------------+          +----------------+
    | disconnected() |          | reconnected()  |
    +----------------+          +----------------+
    """
  end

  defp demo_flow_diagram do
    """
    Browser                         Server
    -------                         ------
       |                               |
       |  User clicks button           |
       |  phx-click="hook_increment"   |
       | ----------------------------> |
       |                               |  handle_event("hook_increment", ...)
       |                               |  new_count = count + 1
       |                               |  assign(:hook_count, new_count)
       |                               |  push_event("count-updated", %{...})
       |                               |
       |  LiveView patches DOM         |
       |  (count display updates)      |
       | <---------------------------- |
       |                               |
       |  handleEvent("count-updated") |
       |  -> animate pulse effect      |
       |                               |
    """
  end

  defp setup_connection_diagram do
    """
    assets/js/app.js                    HEEx Template
    -------------------                 ---------------

    let Hooks = {}          <-------->  phx-hook="MyHook"
    Hooks.MyHook = {                    id="unique-id"
      mounted() { ... },
      destroyed() { ... }      The hook name in phx-hook
    }                          must EXACTLY match the key
                               in the Hooks object.
    let liveSocket =
      new LiveSocket(          If Hooks.MyHook exists and
        "/live", Socket,       the element has id + phx-hook,
        { hooks: Hooks }       then mounted() fires when
      )                        the element enters the DOM.
    """
  end
end
