# Kata 92: Dropzone

## The Concept
**Drag and Drop**. Improving UX by allowing users to drop files anywhere (or in a specific box).

## The Elixir Way
*   `phx-drop-target={@uploads.files.ref}`.
    *   This attribute turns any `div` into a drop zone.
    *   When files are dropped, it triggers the same flow as `<.live_file_input>`.

## Deep Dive

### 1. Styling the Drop Zone
You want the zone to highlight when a file is dragged over it.
Tailwind doesn't support "dragover" natively easily. Use a custom CSS class or a tiny JS Hook if you need advanced "Active" states, but usually `cursor-pointer` and static styling is enough.

### 2. Cancelling Uploads
If a user drops the wrong file, they need a way to remove it *before* upload completes.
`cancel_upload(socket, :files, entry.ref)`
Pass the `entry.ref` (a unique string) to identify the file.

## Common Pitfalls

1.  **Hidden Input**: You still need the `<.live_file_input>` logic in the DOM for the drop zone to work, even if you hide the actual input element with `class="hidden"`.
2.  **Max Entries**: If `max_entries: 3` is set, dropping 5 files typically rejects *all* of them or accepts the first 3. Showing a clear error message `too_many_files` is robust.
