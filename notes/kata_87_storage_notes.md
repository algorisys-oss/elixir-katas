# Kata 87: LocalStorage

## The Concept
**Client-Side Persistence**. Maintaining state across browser refreshes without a database.
Useful for: Dark mode preference, Drafts, collapsed sidebar state.

## The Elixir Way
LiveView runs on the server. LocalStorage is on the client.
We must bridge them.
1.  **Mount**: Hook reads LS and sends to server.
2.  **Update**: Server sends `push_event` to Hook to write LS.

## Deep Dive

### 1. The "Flash" on Mount
Since we can't read LS until the socket matches, the initial HTTP render knows nothing about the user's preference.
*   **Solution**: Use a tiny inline script in `root.html.heex` to set a class on `<body>` before LiveView loads (for Dark Mode).
*   **For Data**: Render a loading state until the Hook reports back.

### 2. `handle_event("restore", ...)`
The hook sends:
```javascript
mounted() {
  const data = localStorage.getItem("key")
  this.pushEvent("restore", {data})
}
```
The LiveView receives this and updates internal state.

## Common Pitfalls

1.  **JSON Limits**: LocalStorage is synchronous and size-limited (5MB). Don't store large datasets.
2.  **Security**: Never store JWTs or sensitive user data in LocalStorage (XSS vulnerable). Use Cookies (HttpOnly) for auth.
