# Kata 91: Masked Input

## The Concept
Formatting text as the user types (e.g. `(123) 456-7890`).
Doing this server-side introduces lag (cursor jumping). It works best on the client.

## The Elixir Way
We wrap a library like `Inputmask` or `Cleave.js` in a Hook.
The library modifies the input value locally.
The `phx-change` event sends the *formatted* value to the server (or unformatted, depending on library settings).

## Deep Dive

### 1. `phx-update="ignore"` usage?
Usually **No**. Input fields benefit from server sync.
However, if the server re-renders the input while the user is typing, the cursor position might reset.
*   **Hybrid Approach**: The Hook handles the keystrokes. The Server validates on blur or via debounce.

### 2. Data Integrity
If the user types `(555` and stops, the library might show `(555) ___-____`.
What does the server receive? `(555) ___-____` or `555`.
Decide on a canonical format (usually raw numbers) and strip characters in `handle_event`.

## Common Pitfalls

1.  **Latency Fights**: If server attempts to format "555" -> "(555)" and sends it back *while* the user types the next digit, the mask library might break.
    *   **Fix**: Rely on the client library for visual formatting. Use the server for validation only.
