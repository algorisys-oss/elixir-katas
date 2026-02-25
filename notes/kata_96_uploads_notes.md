# Kata 96: File Uploads

## The Concept
**Zero-JS Uploads**. Managing file uploads usually requires complex JS (Multipart forms, progress bars).
LiveView handles the entire lifecycle: Selection -> Preview -> Progress -> Consumption.

## The Elixir Way
*   `allow_upload(socket, :name, restrictions)`: Registers an upload configuration.
*   `.live_file_input`: Renders the file picker.
*   `consume_uploaded_entries`: Moves the temp file to permanent storage.

## Deep Dive

### 1. The Lifecycle
1.  **Selection**: The user picks a file. The browser sends metadata (name, size) to the server.
2.  **Validation**: The server checks `accept`, `max_entries`, and `max_file_size`. Errors appear in `@uploads.avatar.errors`.
3.  **Transport**: The file is chunked and sent over the WebSocket (Binary channel).
4.  **Consumption**: Once 100%, the file sits in a temp directory. You *must* consume it in `handle_event("save")`, otherwise it is deleted when the process ends.

### 2. Live Preview
Since the file is still on the client, how do we show a preview?
```elixir
<%= for entry <- @uploads.avatar.entries do %>
  <.live_img_preview entry={entry} />
<% end %>
```
LiveView uses a local ObjectURL for instant previews.

## Common Pitfalls

1.  **Form Validation**: If `phx-change` isn't on the form, you won't get validation errors until submit. Always listen to `validate`.
2.  **Consumption Limits**: You can't consume the same entry twice. Once `consume_uploaded_entries` returns, the temp file is gone.
