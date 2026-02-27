# Kata 11: File Uploads

## How Multipart Uploads Work

When a client sends a file to a Phoenix API, it uses `multipart/form-data` encoding. This is different from JSON — the request body contains boundaries separating each field, with binary file data included inline.

```
POST /api/documents/upload HTTP/1.1
Content-Type: multipart/form-data; boundary=----FormBoundary

------FormBoundary
Content-Disposition: form-data; name="file"; filename="report.csv"
Content-Type: text/csv

<binary file data>
------FormBoundary--
```

Phoenix (via Plug) automatically parses this and gives you a `%Plug.Upload{}` struct.

---

## The Plug.Upload Struct

```elixir
%Plug.Upload{
  filename: "report.csv",       # Original filename from the client
  content_type: "text/csv",     # MIME type (set by the client!)
  path: "/tmp/plug-1234/..."    # Temporary file on disk
}
```

### Important Details

- **`filename`** — comes from the client, so it's **untrusted**. Sanitize it before using as a file path.
- **`content_type`** — also from the client. For security, verify the actual content (e.g., check magic bytes).
- **`path`** — points to a temp file that Plug creates. This file is **automatically deleted** when the request ends.

---

## Controller Pattern

```elixir
defmodule MyAppWeb.Api.DocumentController do
  use MyAppWeb, :controller

  action_fallback MyAppWeb.FallbackController

  @max_size 5 * 1024 * 1024  # 5 MB
  @allowed_types ~w(image/jpeg image/png text/csv application/pdf)

  def upload(conn, %{"file" => %Plug.Upload{} = upload}) do
    with :ok <- validate_size(upload),
         :ok <- validate_type(upload),
         {:ok, stored_path} <- store_file(upload) do
      conn
      |> put_status(:created)
      |> json(%{
        data: %{
          filename: upload.filename,
          content_type: upload.content_type,
          size: File.stat!(upload.path).size,
          url: "/uploads/#{Path.basename(stored_path)}"
        }
      })
    end
  end

  # When no file is provided
  def upload(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{file: ["is required"]}})
  end
end
```

---

## Validation

### File Size

```elixir
defp validate_size(%Plug.Upload{path: path}) do
  case File.stat(path) do
    {:ok, %{size: size}} when size <= @max_size -> :ok
    {:ok, _} -> {:error, :file_too_large}
    {:error, _} -> {:error, :file_not_found}
  end
end
```

### Content Type

```elixir
defp validate_type(%Plug.Upload{content_type: type}) do
  if type in @allowed_types, do: :ok, else: {:error, :invalid_type}
end
```

### Security: Don't Trust the Client

The `content_type` is set by the client and can be spoofed. For sensitive applications:

```elixir
# Check the file's magic bytes instead
defp verify_content(%Plug.Upload{path: path}) do
  case File.read(path, 4) do
    {:ok, <<0xFF, 0xD8, 0xFF, _>>} -> {:ok, "image/jpeg"}
    {:ok, <<0x89, 0x50, 0x4E, 0x47>>} -> {:ok, "image/png"}
    {:ok, <<0x25, 0x50, 0x44, 0x46>>} -> {:ok, "application/pdf"}
    _ -> {:error, :unrecognized_format}
  end
end
```

---

## Storing Files

### Local Storage

```elixir
defp store_file(%Plug.Upload{path: temp_path, filename: name}) do
  # Sanitize filename
  safe_name = sanitize_filename(name)
  dest = Path.join(["priv/static/uploads", safe_name])
  File.mkdir_p!(Path.dirname(dest))

  case File.cp(temp_path, dest) do
    :ok -> {:ok, dest}
    error -> error
  end
end

defp sanitize_filename(name) do
  name
  |> Path.basename()           # Remove directory traversal
  |> String.replace(~r/[^\w\.\-]/, "_")  # Allow only safe chars
end
```

### S3 Storage (with ExAws)

```elixir
defp store_file(%Plug.Upload{path: temp_path, filename: name}) do
  key = "uploads/#{UUID.uuid4()}/#{sanitize_filename(name)}"

  temp_path
  |> ExAws.S3.Upload.stream_file()
  |> ExAws.S3.upload("my-bucket", key)
  |> ExAws.request()
  |> case do
    {:ok, _} -> {:ok, key}
    error -> error
  end
end
```

---

## Plug Configuration

### Max Upload Size

By default, Plug limits request bodies to 8 MB. Configure in your endpoint:

```elixir
# lib/my_app_web/endpoint.ex
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library(),
  length: 20_000_000  # 20 MB max
```

### Per-Route Limits

For different limits on different routes, use `Plug.Parsers` in the router pipeline:

```elixir
pipeline :large_uploads do
  plug Plug.Parsers,
    parsers: [:multipart],
    length: 100_000_000  # 100 MB for this pipeline
end
```

---

## Multiple File Uploads

```elixir
# Client sends: -F "files[]=@a.jpg" -F "files[]=@b.jpg"
def upload(conn, %{"files" => uploads}) when is_list(uploads) do
  results =
    Enum.map(uploads, fn %Plug.Upload{} = upload ->
      with :ok <- validate(upload),
           {:ok, path} <- store_file(upload) do
        %{filename: upload.filename, url: path}
      end
    end)

  json(conn, %{data: results})
end
```

---

## Testing File Uploads

```elixir
defmodule MyAppWeb.Api.DocumentControllerTest do
  use MyAppWeb.ConnCase

  test "uploads a CSV file", %{conn: conn} do
    upload = %Plug.Upload{
      filename: "test.csv",
      content_type: "text/csv",
      path: "test/fixtures/test.csv"
    }

    conn = post(conn, ~p"/api/documents/upload", file: upload)
    assert %{"data" => %{"filename" => "test.csv"}} = json_response(conn, 201)
  end

  test "rejects oversized files", %{conn: conn} do
    upload = %Plug.Upload{
      filename: "huge.bin",
      content_type: "application/octet-stream",
      path: "test/fixtures/huge_file.bin"
    }

    conn = post(conn, ~p"/api/documents/upload", file: upload)
    assert json_response(conn, 413)
  end
end
```

---

## Best Practices

1. **Always validate** file size and type on the server, even if the client validates too
2. **Sanitize filenames** to prevent directory traversal attacks
3. **Don't trust `content_type`** from the client — verify with magic bytes for security-sensitive uploads
4. **Copy the temp file** during the request — it's deleted when the request ends
5. **Use unique names** (UUIDs) for stored files to avoid collisions
6. **Set appropriate Plug.Parsers `:length`** to control max upload size at the framework level

## Common Pitfalls

- **Forgetting to copy**: The temp file at `upload.path` is deleted after the request. You must copy it to permanent storage during the request handler.
- **Path traversal**: A malicious `filename` like `../../etc/passwd` can overwrite system files if you don't sanitize.
- **Memory pressure**: Very large uploads are written to disk by Plug, not held in memory. But if you `File.read!()` the entire file, you load it into memory.
- **Missing multipart parser**: Ensure `:multipart` is in your `Plug.Parsers` config, or file uploads will be silently ignored.
