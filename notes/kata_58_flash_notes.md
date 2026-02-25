# Kata 58: Flash Messages

## The Concept
Ephemeral feedback ("Saved successfully", "Error uploading").
Typically used after a form redirect.

## The Elixir Way
*   **Process.send_after**: Since LiveView is a long-running process, we can queue a message to ourselves to auto-clear the flash.
    ```elixir
    Process.send_after(self(), :clear_flash, 3000)
    ```
*   **Flash Assigns**: `put_flash` writes to a special area in the socket/conn.

## Deep Dive

### 1. Functional Component Implementation
Centralize the Flash UI in your Layout (`app.html.heex`) using `<.flash_group flash={@flash}>`.
Inside, iterate over `:info` and `:error` keys.

### 2. Animation (Enter/Leave)
Toast messages need to slide in/out.
*   **Enter**: `phx-mounted={JS.transition(...)}`.
*   **Leave**: `phx-click="close" phx-value-key="info"`.

### 3. The `clear_flash` Pattern
When the timer fires, we receive `handle_info(:clear_flash, socket)`.
We must then `assign(socket, flash: %{})` (or clear specific keys) to remove it from the UI, triggering the exit animation.

## Common Pitfalls

1.  **Race Conditions w/ Navigation**: If you navigate away *before* the timer fires, the message is lost (good) but the timer message might arrive to the dead process (harmless).
2.  **Persistent Connectivity**: If the user disconnects and reconnects, standard flash messages might persist or disappear depending on session store. LiveView handles this recovery mostly transparently.
