# Kata 12: File Downloads & Streaming

## Four Ways to Send Data

Phoenix provides several mechanisms to send data to clients, each suited for different scenarios:

| Approach | Function | Best For |
|----------|----------|----------|
| Inline JSON | `json/2` | Normal API responses |
| Binary download | `send_download/3` | Generated files (CSV, Excel) |
| File from disk | `send_file/5` | Static files on disk |
| Chunked stream | `chunk/2` | Large/infinite data streams |

---

## 1. Inline JSON with json/2

The simplest approach — encode data as JSON and send it inline:

```elixir
def show(conn, %{"id" => id}) do
  report = Reports.get_report!(id)
  json(conn, %{data: report})
end
```

- Full response is held in memory
- Phoenix automatically sets `Content-Type: application/json`
- Calculates `Content-Length` automatically
- Best for small, structured API responses

---

## 2. Binary Download with send_download/3

For content generated in memory that the client should download as a file:

```elixir
def export_csv(conn, %{"id" => id}) do
  records = Reports.list_records(id)

  csv_content =
    records
    |> Enum.map(fn r -> [r.name, r.email, r.status] end)
    |> CSV.encode(headers: ["Name", "Email", "Status"])
    |> Enum.join()

  send_download(conn, {:binary, csv_content},
    filename: "export_#{id}.csv",
    content_type: "text/csv"
  )
end
```

### How send_download/3 Works

1. Takes `{:binary, content}` — the data to send
2. Sets `Content-Disposition: attachment; filename="..."` — triggers browser download
3. Sets `Content-Type` from the option or infers from filename
4. Calculates `Content-Length` from the binary size

### Alternative: Send an Existing File

```elixir
# send_download can also send a file from disk
send_download(conn, {:file, "/path/to/report.pdf"},
  filename: "report.pdf"
)
```

---

## 3. File from Disk with send_file/5

The most efficient way to send existing files:

```elixir
def download_pdf(conn, %{"id" => id}) do
  path = Reports.pdf_path(id)

  conn
  |> put_resp_header("content-disposition",
     ~s(attachment; filename="report_#{id}.pdf"))
  |> send_file(200, path)
end
```

### Why send_file Is Fast

- Uses the OS-level `sendfile(2)` system call
- **Zero-copy**: the kernel sends the file directly from disk to the TCP socket
- The file data never passes through the Erlang VM
- Best performance for static files

### send_file/5 Signature

```elixir
send_file(conn, status, path, offset \\ 0, length \\ :all)
```

- `offset` — start reading from this byte position
- `length` — send only this many bytes (useful for range requests)

---

## 4. Chunked Streaming with chunk/2

For large files or data that's generated on the fly:

```elixir
def stream_large_csv(conn, %{"id" => id}) do
  # Step 1: Start a chunked response
  conn =
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition",
       ~s(attachment; filename="large_#{id}.csv"))
    |> send_chunked(200)

  # Step 2: Stream data in batches
  Reports.stream_records(id)
  |> Stream.chunk_every(1000)
  |> Enum.reduce_while(conn, fn batch, conn ->
    csv_chunk = CSV.encode(batch) |> Enum.join()

    case chunk(conn, csv_chunk) do
      {:ok, conn} -> {:cont, conn}
      {:error, :closed} -> {:halt, conn}
    end
  end)
end
```

### Key Points

- `send_chunked(200)` starts the response with `Transfer-Encoding: chunked`
- No `Content-Length` header (the total size is unknown)
- `chunk(conn, data)` sends one chunk
- Returns `{:ok, conn}` on success, `{:error, :closed}` if the client disconnected
- Memory usage stays constant regardless of total data size

---

## Content-Disposition Header

The `Content-Disposition` header controls how the browser handles the response:

```
# Trigger a download with a suggested filename
Content-Disposition: attachment; filename="report.pdf"

# Display inline (e.g., show PDF in browser)
Content-Disposition: inline; filename="report.pdf"
```

### Setting Content-Disposition

```elixir
# For downloads (save dialog)
conn
|> put_resp_header("content-disposition",
   ~s(attachment; filename="#{filename}"))
|> send_file(200, path)

# For inline display
conn
|> put_resp_header("content-disposition",
   ~s(inline; filename="#{filename}"))
|> send_file(200, path)
```

---

## Streaming from Ecto

Ecto's `Repo.stream/2` is perfect for streaming large query results:

```elixir
def stream_export(conn, _params) do
  conn =
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition",
       ~s(attachment; filename="full_export.csv"))
    |> send_chunked(200)

  # Repo.stream must run inside a transaction
  Repo.transaction(fn ->
    User
    |> order_by(asc: :id)
    |> Repo.stream(max_rows: 500)
    |> Stream.chunk_every(500)
    |> Enum.reduce_while(conn, fn batch, conn ->
      csv = encode_csv(batch)
      case chunk(conn, csv) do
        {:ok, conn} -> {:cont, conn}
        {:error, :closed} -> {:halt, conn}
      end
    end)
  end)
end
```

---

## Range Requests (Partial Downloads)

For resumable downloads and video streaming:

```elixir
def stream_video(conn, %{"id" => id}) do
  path = Videos.file_path(id)
  %{size: total_size} = File.stat!(path)

  case get_req_header(conn, "range") do
    ["bytes=" <> range] ->
      {start, finish} = parse_range(range, total_size)
      length = finish - start + 1

      conn
      |> put_resp_header("content-range", "bytes #{start}-#{finish}/#{total_size}")
      |> put_resp_header("accept-ranges", "bytes")
      |> put_resp_content_type("video/mp4")
      |> send_file(206, path, start, length)

    [] ->
      conn
      |> put_resp_header("accept-ranges", "bytes")
      |> put_resp_content_type("video/mp4")
      |> send_file(200, path)
  end
end
```

---

## Best Practices

1. **Use `send_file/5` for existing files** — it's the most efficient (zero-copy)
2. **Use `send_download/3` for generated content** — cleaner API than manually setting headers
3. **Use `chunk/2` for large data** — keeps memory usage constant
4. **Always handle `{:error, :closed}`** in streaming — clients can disconnect at any time
5. **Set `Content-Disposition`** to control download vs inline behavior
6. **Sanitize filenames** in Content-Disposition to prevent header injection

## Common Pitfalls

- **Loading large files into memory**: Don't `File.read!()` a large file and then `json/2` it. Use `send_file/5` or streaming.
- **Forgetting transactions with Repo.stream**: `Repo.stream/2` requires a transaction to keep the database cursor open.
- **Missing Content-Type**: Always set the correct MIME type so clients know how to handle the response.
- **Not handling client disconnects**: In chunked streaming, always pattern match on `{:error, :closed}` to stop processing when the client is gone.
