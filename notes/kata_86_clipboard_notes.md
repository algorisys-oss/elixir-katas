# Kata 86: Clipboard Interaction

## Goal
Copy text to the user's system clipboard.

## Core Concepts

### 1. `navigator.clipboard.writeText`
Modern browser API. Must be called from a client-side Hook or `phx-click` with `JS` commands (though pure JS command for clipboard is tricky without a Hook wrapper).

### 2. Feedback
Always show a "Copied!" message so the user knows it worked.

## Implementation Details

1.  **Event**: Button click triggers server event `copy_to_clipboard`.
2.  **Response**: Server updates state (`copied: true`) AND pushes an event to the client (`push_event`) which the Hook listens to.

## Tips
- Clipboard API usually requires a secure context (HTTPS) or localhost.

## Challenge
Implement **Cut**. Add a "Cut" button. It should:
1. Copy the text to clipboard.
2. Clear the input field (`text_to_copy: ""`).

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("cut", _, socket) do
  # Push event to copy, then assign empty string
  {:noreply, 
   socket 
   |> push_event("copy", %{text: socket.assigns.text_to_copy}) 
   |> assign(text_to_copy: "")}
end
</code></pre>
</details>
