# Kata 47: Protected Routes

## The Concept
Preventing access to specific UI elements or pages based on **Authentication** (Logged in?) and **Authorization** (Admin?).

## The Elixir Way
*   **Layer 1: Router**: The primary defense. `live_session :authenticated, on_mount: EnsureAuth` blocks access before the LiveView starts.
*   **Layer 2: Render**: Conditional rendering (`if @current_user`) controls visibility of buttons/sections.

## Deep Dive

### 1. `on_mount` Hooks
LiveView uses hooks in the router to intercept the mount process.
```elixir
def on_mount(:default, _params, _session, socket) do
  if user = get_user(session) do
    {:cont, assign(socket, current_user: user)}
  else
    {:halt, redirect(socket, to: "/login")}
  end
end
```
This is far more secure than checking in `mount` of every single LiveView.

### 2. Security via Obscurity
Hiding the "Delete" button via `<button class="hidden">` is **NOT security**. A savvy user can inspect element or trigger the event via console.
**You must verify permissions in `handle_event` as well.**
```elixir
def handle_event("delete", _, socket) do
  if socket.assigns.current_user.role == :admin do
    # Proceed
  else
    # Log unauthorized attempt
    {:noreply, socket}
  end
end
```

## Common Pitfalls

1.  **Leaking Data**: Sending admin data to the client (`assign(socket, admin_logs: ...)`) and simply hiding it with CSS means the data is still on the user's computer. `if/else` in HEEx generally prevents the data from being sent, which is safer.
