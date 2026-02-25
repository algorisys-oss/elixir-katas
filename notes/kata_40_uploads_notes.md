# Kata 40: File Uploads

## Goal
Implement client-side file previews and server-side handling of file uploads using LiveView's built-in `allow_upload`.

## Core Concepts

### 1. `allow_upload/3`
Configures the upload capabilities (file types, max size, max entries).
```elixir
allow_upload(socket, :avatar, accept: ~w(.jpg .png), max_entries: 1)
```

### 2. `consume_uploaded_entries/3`
The function used to process the files once standard form validation passes. Files are temporarily stored on the server until consumed.

## Implementation Details

1.  **Mount**: Call `allow_upload`.
2.  **Render**:
    *   `<.live_file_input upload={@uploads.avatar} />`
    *   Loop over `@uploads.avatar.entries` to show `<.live_img_preview />`.
3.  **Events**:
    *   `validate`: Required to trigger the upload flow.
    *   `save`: Call `consume_uploaded_entries` to move files to permanent storage.

## Tips
- LiveView uploads are direct-to-server (or direct-to-cloud with presigned URLs).

## Challenge
Update the configuration to allow **PDF** files (`.pdf`) as well.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># In mount/2
allow_upload(socket, :avatar, accept: ~w(.jpg .png .pdf), ...)
</code></pre>
</details>
