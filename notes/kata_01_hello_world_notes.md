# Kata 01: Hello World

## The Concept
Standard web frameworks (Rails, Django, React+Node) follow a **Request/Response** cycle: the browser asks for a page, the server builds it, sends it, and forgets the user exists.
Phoenix LiveView is different. It keeps a **stateful process** alive on the server for each user.

## The Elixir Way
When you load this "Hello World" page:
1.  **Standard HTTP**: The server sends a static HTML page (SEO friendly, instant load).
2.  **WebSocket upgrade**: The browser connects back to the server.
3.  **Stateful Process**: Elixir spawns a lightweight process (GenServer) dedicated to *you*. It holds your state (`socket.assigns`).
4.  **"It's Alive"**: When you click a button, the browser sends a tiny message over the socket. The process handles it, re-renders *only* what changed, and pushes the diff back.

## Deep Dive

### 1. The `mount/3` Lifecycle
This callback runs **twice**:
1.  Once for the initial HTTP request (Static Render).
2.  Once when the WebSocket connects (Live Render).
This is why you shouldn't perform expensive side-effects (like charging a credit card) directly in `mount` without checking connection status, or it might happen twice!

### 2. The `~H` Sigil (HEEx)
Elixir's HTML-aware template engine.
*   **Interpolation**: `{ @name }` or `<%= @name %>` injects data.
*   **Compile-time Checks**: It verifies that your HTML tags are closed and your function components exist. It catches typos before you even run the app.

### 3. Change Tracking
LiveView doesn't re-transmit the whole page. It splits your template into static parts ("Hello") and dynamic parts (`@name`).
```html
<h1>Hello <%= @name %></h1>
```
If `@name` changes from "Alice" to "Bob", LiveView sends *only* "Bob". The strings "<h1>Hello " and "</h1>" are never sent again.

## Common Pitfalls

1.  **Atom Keys vs String Keys**: In `handle_event`, the params map always uses **String keys** (`%{"value" => "..."}`), not Atoms.
2.  **Private Assigns**: Variables defined in `render` or `mount` (like `x = 1`) are not available in the template. Only data inside `socket.assigns` (`@x`) is visible.
3.  **Double Mount**: Beginners often get confused seeing log messages twice. This is normal (HTTP + WebSocket).
