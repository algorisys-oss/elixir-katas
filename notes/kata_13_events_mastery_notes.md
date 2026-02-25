# Kata 13: Events Mastery

## The Concept
Rich UIs require more than just "clicks". We need to handle focus, blur, keystrokes, and mouse movements. This kata explores the wide range of **DOM Bindings** LiveView provides natively.

## The Elixir Way
Other frameworks require `addEventListener`.
LiveView uses HTML attributes (`phx-click`, `phx-blur`).
Under the hood, **Everything is a Message**.
When you trigger an event, the JavaScript client pushes a message to the WebSocket. The Elixir process receives this message. `handle_event/3` is just a specialized version of the standard GenServer `handle_info/2` callback, designed specifically for these frontend messages.

## Deep Dive

### 1. The Event Payload
The second argument in `handle_event` is the payload.
*   **Click**: usually `%{}`, or values from `phx-value-*`.
*   **Form**: `%{"field" => "val", "_target" => ...}`.
*   **Keyup**: `%{"key" => "Enter", "code" => "Enter", "altKey" => false ...}`.

### 2. `phx-value-*`
You can pass custom data with any event.
```html
<button phx-click="delete" phx-value-id="42" phx-value-confirm="true">Delete</button>
```
Receive it as:
```elixir
def handle_event("delete", %{"id" => id, "confirm" => "true"}, socket) ...
```
This avoids "hidden inputs" or state hacking. The data lives right on the element.

### 3. Rate Limiting (`debounce` / `throttle`)
*   `phx-debounce="1000"`: Wait 1 second after the *last* event before sending. (Good for search inputs).
*   `phx-throttle="1000"`: Only allow one event every 1 second. (Good for scroll events or expensive buttons).
This logic happens **client-side** in JavaScript, saving your server from processing spam.

## Common Pitfalls

1.  **String Keys**: We repeat this often because it bites everyone. Access params with `param["key"]`, never `param[:key]`.
2.  **Focus Loss**: If an event causes the element to be removed from the DOM and re-added (full re-render), it loses focus. LiveView is smart about DOM patching to avoid this, but poor `id` management can break it. Always give updated lists unique IDs.
3.  **Missing `handle_event`**: If you trigger an event name that creates a crash ("no function clause matching"), the entire process crashes and restarts. LiveView recovers quickly, but the user loses their ephemeral state. Always define a "catch-all" handler if you aren't sure.
