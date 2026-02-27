# Kata 06: TCP Sockets in Elixir

## Why Start with TCP?

Before HTTP, before Phoenix, before even Cowboy — there's **TCP** (Transmission Control Protocol). TCP is the transport layer that HTTP rides on top of. Understanding TCP gives you deep insight into how web servers actually work.

When Phoenix handles a web request, here's what's really happening underneath:

```
Browser → TCP connection → Cowboy (reads TCP) → Plug → Phoenix → Your Code
```

In this kata, we'll build the leftmost part — a raw TCP server in Elixir using Erlang's `:gen_tcp` module.

---

## What is TCP?

TCP is a **reliable, ordered, connection-based** protocol. Think of it like a phone call:

1. **Connection**: You dial a number (connect to a server)
2. **Communication**: You talk back and forth (send/receive data)
3. **Disconnection**: You hang up (close the connection)

TCP guarantees:
- Data arrives **in order** (packet 1 before packet 2)
- Data arrives **completely** (no missing bytes)
- You know if the connection **fails**

HTTP, WebSockets, and most web protocols run on top of TCP.

---

## Elixir's `:gen_tcp` Module

Elixir (via Erlang) provides the `:gen_tcp` module for working with TCP sockets. Here are the key functions:

| Function | Purpose |
|----------|---------|
| `:gen_tcp.listen(port, opts)` | Create a socket and listen on a port |
| `:gen_tcp.accept(socket)` | Wait for a client to connect |
| `:gen_tcp.recv(socket, length)` | Read data from the connection |
| `:gen_tcp.send(socket, data)` | Send data to the connection |
| `:gen_tcp.close(socket)` | Close the connection |

---

## Building a TCP Server: Step by Step

### Step 1: Listen on a Port

```elixir
{:ok, listen_socket} = :gen_tcp.listen(4001, [
  :binary,           # Receive data as Elixir binaries (not charlists)
  packet: :raw,      # Raw TCP data (no framing)
  active: false,     # We control when to read (passive mode)
  reuseaddr: true    # Allow restarting without "address in use" error
])
```

This creates a **listening socket** bound to port 4001. It doesn't connect to anyone yet — it just announces "I'm ready to accept connections on port 4001."

### Step 2: Accept a Connection

```elixir
{:ok, client_socket} = :gen_tcp.accept(listen_socket)
```

This **blocks** (waits) until a client connects. When a browser or curl hits `http://localhost:4001`, this function returns with a new socket representing that specific connection.

### Step 3: Read the Request

```elixir
{:ok, request} = :gen_tcp.recv(client_socket, 0)
# 0 means "read whatever data is available"
```

`request` is now a binary containing whatever the client sent — for a browser, this is the raw HTTP request text:

```
"GET / HTTP/1.1\r\nHost: localhost:4001\r\nAccept: text/html\r\n\r\n"
```

### Step 4: Send a Response

```elixir
response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Hello!</h1>"
:gen_tcp.send(client_socket, response)
```

We manually construct an HTTP response string and send it. The browser will parse this and display the HTML.

### Step 5: Close the Connection

```elixir
:gen_tcp.close(client_socket)
```

Terminates the TCP connection. The browser shows the response.

---

## The Complete Server

```elixir
defmodule SimpleServer do
  def start(port \\ 4001) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [
      :binary, packet: :raw, active: false, reuseaddr: true
    ])
    IO.puts("Listening on port #{port}...")
    accept_loop(listen_socket)
  end

  defp accept_loop(listen_socket) do
    {:ok, client} = :gen_tcp.accept(listen_socket)
    spawn(fn -> handle_client(client) end)  # Handle in new process!
    accept_loop(listen_socket)               # Accept next connection
  end

  defp handle_client(client) do
    {:ok, request} = :gen_tcp.recv(client, 0)
    IO.puts("Request: #{String.split(request, "\r\n") |> hd()}")

    response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Hello from raw TCP!</h1>"
    :gen_tcp.send(client, response)
    :gen_tcp.close(client)
  end
end
```

### Key Pattern: `spawn` for Concurrency

Notice the `spawn(fn -> handle_client(client) end)` — each client gets its own process! This is the same pattern Phoenix/Cowboy uses, but at a much larger scale. While we handle one client, the accept loop immediately goes back to waiting for the next one.

---

## Active vs Passive Mode

There are two ways to read TCP data:

### Passive Mode (`active: false`)

You manually call `:gen_tcp.recv/2` to read data. You control when and how much to read.

```elixir
# You decide when to read
{:ok, data} = :gen_tcp.recv(socket, 0)
```

### Active Mode (`active: true`)

Data arrives as messages in your process mailbox. Good for long-lived connections.

```elixir
# Data arrives automatically as messages
receive do
  {:tcp, socket, data} -> IO.puts("Got: #{data}")
  {:tcp_closed, socket} -> IO.puts("Connection closed")
end
```

Phoenix/Cowboy uses a combination — passive for the initial HTTP request, active for WebSockets.

---

## Try It Yourself

You can run this in IEx right now:

```bash
# Terminal 1: Start the server
iex> SimpleServer.start(4001)
Listening on port 4001...

# Terminal 2: Send a request
$ curl http://localhost:4001/hello
<h1>Hello from raw TCP!</h1>
```

---

## How This Connects to Phoenix

```
Your TCP Server          Phoenix Stack
═══════════════          ═════════════
:gen_tcp.listen   →      Ranch (manages listeners)
:gen_tcp.accept   →      Ranch (accepts connections)
:gen_tcp.recv     →      Cowboy (reads & parses HTTP)
Your code         →      Plug → Phoenix → Controller
:gen_tcp.send     →      Cowboy (sends HTTP response)
:gen_tcp.close    →      Cowboy (closes connection)
```

Phoenix doesn't call `:gen_tcp` directly — **Ranch** and **Cowboy** handle all the low-level socket management. But the flow is exactly the same.

---

## Key Takeaways

1. **TCP** is the transport layer underneath HTTP — reliable, ordered, connection-based
2. Elixir's `:gen_tcp` module provides listen, accept, recv, send, close
3. A server **listens** on a port, **accepts** connections, **reads** requests, **sends** responses
4. Use `spawn` to handle each client in a separate process (concurrency!)
5. Phoenix uses Ranch/Cowboy to do this at scale, but the pattern is identical
6. `\r\n` (CRLF) separates HTTP headers — this matters when crafting raw responses
