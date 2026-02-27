# Kata 07: Parsing HTTP by Hand

## Why Parse HTTP Manually?

In Kata 06, we built a TCP server that received raw bytes from a browser. Those bytes *were* an HTTP request — but we just echoed them back without understanding them. Now we'll **parse** that raw text into structured data.

This is exactly what Cowboy does under the hood. By doing it ourselves first, you'll understand:
- Why HTTP is called a **text-based** protocol
- How headers, methods, paths, and bodies are structured
- What Cowboy does before Phoenix ever sees a request

---

## HTTP Request Format

Every HTTP request follows this exact structure:

```
REQUEST-LINE\r\n
HEADER: VALUE\r\n
HEADER: VALUE\r\n
\r\n
BODY (optional)
```

### Example: A Real Browser Request

```
GET /products?page=2 HTTP/1.1\r\n
Host: shop.example.com\r\n
Accept: text/html\r\n
User-Agent: Mozilla/5.0\r\n
Cookie: session=abc123\r\n
\r\n
```

Let's break this apart:

### 1. The Request Line

```
GET /products?page=2 HTTP/1.1
│    │                 │
│    │                 └── HTTP Version
│    └── Path + Query String (the "resource")
└── Method (what to do)
```

The request line has exactly three parts, separated by spaces:
- **Method**: `GET`, `POST`, `PUT`, `DELETE`, etc.
- **Path**: The URL path with optional query string
- **Version**: Usually `HTTP/1.1`

### 2. Headers

```
Host: shop.example.com
Accept: text/html
User-Agent: Mozilla/5.0
```

Headers are `Key: Value` pairs, one per line. They provide metadata:
- `Host` — which domain (needed because one server can host multiple sites)
- `Accept` — what format the client wants
- `Content-Type` — what format the body is in (for POST/PUT)
- `Content-Length` — size of the body in bytes
- `Cookie` — session data

### 3. The Blank Line

The `\r\n\r\n` (double CRLF) marks the end of headers and start of the body. This is critical — it's how the parser knows headers are done.

### 4. The Body (Optional)

For `GET` requests, there's usually no body. For `POST`:

```
POST /login HTTP/1.1\r\n
Host: example.com\r\n
Content-Type: application/x-www-form-urlencoded\r\n
Content-Length: 29\r\n
\r\n
email=alice@ex.com&pass=secret
```

---

## Parsing in Elixir

### Step 1: Split Request Line from Headers

```elixir
[request_line | header_lines] = String.split(raw_request, "\r\n")
```

### Step 2: Parse the Request Line

```elixir
[method, path, version] = String.split(request_line, " ")
# method  = "GET"
# path    = "/products?page=2"
# version = "HTTP/1.1"
```

### Step 3: Parse Path and Query String

```elixir
[path_only | query_parts] = String.split(path, "?")
query_string = Enum.join(query_parts, "?")  # handles edge case of ? in query
# path_only    = "/products"
# query_string = "page=2"
```

### Step 4: Parse Query Parameters

```elixir
params = URI.decode_query(query_string)
# %{"page" => "2"}
```

### Step 5: Parse Headers

```elixir
headers =
  header_lines
  |> Enum.reject(&(&1 == ""))  # Remove the blank line
  |> Enum.map(fn line ->
    [key, value] = String.split(line, ": ", parts: 2)
    {String.downcase(key), value}
  end)
  |> Map.new()
# %{"host" => "shop.example.com", "accept" => "text/html", ...}
```

### Complete Parser

```elixir
defmodule HTTPParser do
  def parse(raw) do
    [head, body] = String.split(raw, "\r\n\r\n", parts: 2)
    [request_line | header_lines] = String.split(head, "\r\n")
    [method, full_path, version] = String.split(request_line, " ")

    {path, query_string} =
      case String.split(full_path, "?", parts: 2) do
        [p, q] -> {p, q}
        [p]    -> {p, ""}
      end

    headers =
      header_lines
      |> Enum.map(fn line ->
        [k, v] = String.split(line, ": ", parts: 2)
        {String.downcase(k), v}
      end)
      |> Map.new()

    %{
      method: method,
      path: path,
      query_string: query_string,
      params: URI.decode_query(query_string),
      version: version,
      headers: headers,
      body: body
    }
  end
end
```

---

## Building an HTTP Response

HTTP responses follow a similar structure:

```
STATUS-LINE\r\n
HEADER: VALUE\r\n
\r\n
BODY
```

### Status Line

```
HTTP/1.1 200 OK
│        │   │
│        │   └── Reason Phrase (human-readable)
│        └── Status Code
└── Version
```

### Building a Response in Elixir

```elixir
defmodule HTTPResponse do
  def build(status, headers, body) do
    status_line = "HTTP/1.1 #{status} #{reason_phrase(status)}"

    header_lines =
      headers
      |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
      |> Enum.join("\r\n")

    "#{status_line}\r\n#{header_lines}\r\n\r\n#{body}"
  end

  defp reason_phrase(200), do: "OK"
  defp reason_phrase(201), do: "Created"
  defp reason_phrase(301), do: "Moved Permanently"
  defp reason_phrase(302), do: "Found"
  defp reason_phrase(400), do: "Bad Request"
  defp reason_phrase(404), do: "Not Found"
  defp reason_phrase(500), do: "Internal Server Error"
end
```

### Example: Complete Request-Response Cycle

```elixir
# In our TCP server's handle_client:
defp handle_client(client) do
  {:ok, raw} = :gen_tcp.recv(client, 0)

  # Parse the request
  request = HTTPParser.parse(raw)
  IO.inspect(request, label: "Parsed request")

  # Build a response based on the path
  {status, body} =
    case request.path do
      "/"          -> {200, "<h1>Home</h1>"}
      "/about"     -> {200, "<h1>About Us</h1>"}
      "/products"  -> {200, "<h1>Products (page #{request.params["page"] || 1})</h1>"}
      _            -> {404, "<h1>Not Found</h1>"}
    end

  response = HTTPResponse.build(status, [
    {"Content-Type", "text/html"},
    {"Content-Length", "#{byte_size(body)}"},
    {"Connection", "close"}
  ], body)

  :gen_tcp.send(client, response)
  :gen_tcp.close(client)
end
```

---

## What Cowboy Does Better

Our parser is educational but fragile. Real HTTP parsing must handle:

| Challenge | Our Parser | Cowboy |
|-----------|-----------|--------|
| Malformed requests | Crashes | Returns proper error |
| Chunked encoding | Not supported | Full support |
| Keep-alive | Closes connection | Reuses connections |
| HTTP/2 | Not supported | Full support |
| Large bodies | Reads all at once | Streams |
| Header size limits | None | Configurable |
| Timeout handling | None | Built-in |

Cowboy is **battle-tested** and handles all of these edge cases. But the core logic — splitting on `\r\n`, parsing the request line, extracting headers — is the same pattern.

---

## How This Connects to Phoenix

```
Raw TCP bytes
    │
    ▼ (our HTTPParser.parse/1 ... or Cowboy's parser)
Parsed request struct
    │
    ▼ (Cowboy wraps it into...)
%Plug.Conn{}
    │
    ▼ (Phoenix reads from...)
conn.method, conn.request_path, conn.params, conn.req_headers
```

When you write `conn.params["page"]` in a Phoenix controller, you're reading data that was originally parsed from raw text bytes — exactly like our `HTTPParser` does.

---

## Key Takeaways

1. HTTP is a **text-based protocol** — requests and responses are structured strings
2. The request line contains **method**, **path**, and **version**, separated by spaces
3. Headers are **key-value pairs** separated by `\r\n`
4. A **blank line** (`\r\n\r\n`) separates headers from the body
5. Parsing HTTP = splitting strings on known delimiters
6. Cowboy does this parsing for Phoenix, producing `%Plug.Conn{}`
7. Understanding the raw format helps you debug HTTP issues
