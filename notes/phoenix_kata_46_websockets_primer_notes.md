# Kata 46: WebSockets Primer

## Why WebSockets?

HTTP is great for fetching pages and submitting forms, but it falls short for **real-time** communication. The core problem: with HTTP, the server **cannot push data to the client** unprompted. The client must always ask first.

Before WebSockets, developers tried several workarounds:

| Technique | How It Works | Problems |
|-----------|-------------|----------|
| **Short Polling** | Client sends `GET /messages` every N seconds | Wastes bandwidth, high latency, hammers the server |
| **Long Polling** | Server holds the request open until new data arrives | Complex to implement, connection overhead, timeouts |
| **SSE (Server-Sent Events)** | Server pushes events over a long-lived HTTP response | One-directional only — client cannot send back |
| **Flash Sockets** | Used Flash plugin for TCP-like connections | Deprecated, security nightmare, requires plugin |

WebSockets (RFC 6455, standardized in 2011) solve all of these by providing a **persistent, full-duplex** connection over a single TCP socket.

---

## HTTP vs WebSocket — Side by Side

| | HTTP | WebSocket |
|--|------|-----------|
| **Connection** | Opens and closes per request | Stays open for the session |
| **Direction** | Half-duplex: client asks, server responds | Full-duplex: both sides send at any time |
| **Header Overhead** | ~500 bytes of headers per request | ~2-14 bytes per frame |
| **State** | Stateless — each request is independent | Stateful — persistent connection with context |
| **Caching** | Supported (Cache-Control, ETags) | Not supported |
| **Proxy/Firewall** | Universally supported | Supported (uses same port 80/443) |
| **Best For** | Pages, REST APIs, file downloads | Chat, live dashboards, gaming, notifications |

**Key insight**: HTTP/2 and HTTP/3 improve HTTP significantly (multiplexing, server push), but WebSockets still win for true bidirectional, low-latency streaming where both sides need to send data freely.

---

## The WebSocket Upgrade Handshake

A WebSocket connection does not start from scratch. It **begins as a regular HTTP request** and then "upgrades" to a WebSocket connection. This is clever because it means WebSockets work through the same firewalls and proxies as HTTP.

### Step-by-step

1. **Client sends an HTTP GET** with special upgrade headers
2. The request includes a random `Sec-WebSocket-Key` (base64 encoded)
3. **Server responds with `101 Switching Protocols`** if it accepts the upgrade
4. Server returns `Sec-WebSocket-Accept` (a hash derived from the client's key)
5. **The TCP connection is now a WebSocket** — no more HTTP on this connection

### The Raw Handshake

```
CLIENT REQUEST:
GET /socket/websocket HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Sec-WebSocket-Protocol: phoenix
Origin: http://example.com

SERVER RESPONSE:
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Sec-WebSocket-Protocol: phoenix
```

The `Sec-WebSocket-Accept` value is computed as:
```
base64(sha1(client_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
```

This magic GUID is a fixed constant from the spec. The computation prevents HTTP caching proxies from accidentally treating a cached response as a valid WebSocket upgrade.

---

## Full-Duplex Communication

**Half-duplex** (HTTP): only one side talks at a time, like a walkie-talkie. The client sends a request, waits, and then the server sends a response.

**Full-duplex** (WebSocket): both sides can send data simultaneously, like a phone call. The server can push a notification to the client at the exact same moment the client is sending a message.

This is what makes WebSockets ideal for:
- **Chat**: the server pushes new messages instantly while you type
- **Live dashboards**: metrics stream in continuously
- **Collaborative editing**: multiple users' keystrokes arrive in real time
- **Gaming**: game state updates flow in both directions constantly

---

## WebSocket Frame Protocol

After the handshake, data is sent as lightweight **frames** (not HTTP requests):

```
Byte 0: [FIN bit (1)] [RSV1-3 (3)] [Opcode (4)]
Byte 1: [MASK bit (1)] [Payload length (7)]
[Extended payload length: 2 or 8 bytes if needed]
[Masking key: 4 bytes if MASK=1]
[Payload data...]
```

### Frame Types (Opcodes)

| Opcode | Type | Purpose |
|--------|------|---------|
| `0x1` | Text | UTF-8 encoded text (used for JSON) |
| `0x2` | Binary | Arbitrary binary data |
| `0x8` | Close | Graceful connection shutdown |
| `0x9` | Ping | Keepalive heartbeat (server sends) |
| `0xA` | Pong | Response to ping (client replies) |

**Rules**:
- Client-to-server frames **MUST be masked** (XOR masking with a random key)
- Server-to-client frames **MUST NOT be masked**
- The masking prevents proxy cache poisoning attacks

---

## Phoenix on Top of WebSockets

Phoenix does not use raw WebSocket messages. It adds a **higher-level protocol** with structure:

```json
[join_ref, ref, topic, event, payload]
```

Example messages flowing over a single WebSocket:
```json
[null, "1", "room:lobby", "phx_join", {}]
[null, "2", "room:lobby", "new_msg", {"body": "Hello!"}]
["1",  "3", "room:lobby", "phx_reply", {"status": "ok", "response": {}}]
[null, null, "room:lobby", "new_msg", {"body": "Hi back!"}]
```

Phoenix supports two serialization formats:
- **JSON** (default): human-readable, works everywhere
- **Erlang binary** (via `:erlpack`): more compact, better for high-throughput scenarios

---

## Phoenix Endpoint Configuration

In your Phoenix app, WebSocket endpoints are declared in `endpoint.ex`:

```elixir
# lib/my_app_web/endpoint.ex

# LiveView WebSocket (auto-generated by mix phx.new):
socket "/live", Phoenix.LiveView.Socket,
  websocket: [connect_info: [session: @session_options]]

# Custom Channels WebSocket:
socket "/socket", MyAppWeb.UserSocket,
  websocket: true,
  longpoll: false
```

Under the hood, this is what happens when a client connects:
1. HTTP GET arrives at `/socket/websocket` with `Upgrade: websocket`
2. Cowboy (the Erlang HTTP server) detects the upgrade header
3. Cowboy calls the Phoenix socket handler
4. Phoenix spawns a new Elixir process for the connection
5. Returns `101 Switching Protocols` — the connection is now a WebSocket

---

## Browser WebSocket API

The raw browser API is simple but low-level:

```javascript
const ws = new WebSocket("wss://example.com/socket/websocket");

ws.onopen = () => {
  console.log("Connected!");
  // Join a Phoenix channel (raw protocol):
  ws.send(JSON.stringify([null, "1", "room:lobby", "phx_join", {}]));
};

ws.onmessage = (event) => {
  const [joinRef, ref, topic, eventName, payload] = JSON.parse(event.data);
  console.log("Event:", eventName, payload);
};

ws.onclose = (event) => {
  console.log("Disconnected:", event.code, event.reason);
};

ws.onerror = (error) => console.error("Error:", error);

// Close gracefully:
ws.close(1000, "Normal closure");
```

**Nobody uses the raw API with Phoenix.** Instead, use the `phoenix.js` client which wraps all of this with reconnection, channel multiplexing, heartbeats, and presence:

```javascript
import {Socket} from "phoenix"

const socket = new Socket("/socket", {params: {token: userToken}})
socket.connect()

const channel = socket.channel("room:lobby", {})
channel.join()
  .receive("ok", resp => console.log("Joined!", resp))
  .receive("error", resp => console.log("Failed:", resp))

channel.push("new_msg", {body: "Hello!"})
channel.on("new_msg", msg => console.log("Got:", msg))
```

---

## Why Phoenix/Elixir Excels at WebSockets

The BEAM virtual machine is uniquely suited for WebSocket-heavy applications:

| Property | Benefit |
|----------|---------|
| **Lightweight processes** | Each connection = one ~2KB process. No OS threads needed. |
| **Massive concurrency** | A single Phoenix server handles **2 million+ simultaneous connections** |
| **Fault isolation** | One crashing connection does not affect any other connection |
| **Supervisor trees** | Failed processes restart automatically |
| **Distributed by nature** | Clustering multiple BEAM nodes for horizontal scaling is built-in |
| **Garbage collection** | Per-process GC means no global pauses across all connections |

Compare this to Node.js (single-threaded event loop, shared memory) or Java (one OS thread per connection, heavy memory overhead). The BEAM's actor model makes WebSocket servers almost trivially scalable.

---

## Use Cases — When to Pick WebSockets vs HTTP

**Choose WebSockets when:**
- Chat / messaging (WhatsApp Web, Slack, Discord)
- Live sports scores / stock tickers
- Collaborative editors (Google Docs, Figma)
- Multiplayer online gaming
- DevOps dashboards (Grafana, Phoenix LiveDashboard)
- Push notifications (GitHub, Twitter)
- Phoenix LiveView (real-time server-rendered UI)
- Phoenix Channels (pub/sub real-time messaging)

**Stick with HTTP when:**
- REST APIs (stateless request/response)
- File uploads and downloads
- Simple page navigation (click, load, read)
- Search engine crawlers (they don't run JavaScript)
- Content that benefits from caching (Cache-Control, ETags)
- One-off requests with no ongoing state

---

## Timeline

- **2009**: WebSocket protocol proposed
- **2011**: RFC 6455 standardized
- **2012**: Supported in all major browsers
- **2015**: Phoenix Channels built on WebSockets
- **2018**: Phoenix LiveView uses WebSockets for server-rendered real-time UI

---

## Key Takeaways

1. WebSockets start as HTTP and **upgrade** via the `101 Switching Protocols` handshake
2. After upgrade, the connection is **full-duplex** — both sides send data at any time
3. Frame overhead is tiny (~2-14 bytes) compared to HTTP headers (~500 bytes per request)
4. Phoenix adds a structured **topic/event/payload protocol** on top of raw WebSockets
5. Each Phoenix WebSocket connection is a **lightweight BEAM process** (~2KB)
6. Use WebSockets for **real-time bidirectional** communication; stick with HTTP for APIs and static pages
7. The `phoenix.js` client handles reconnection, heartbeats, and channel multiplexing automatically
8. The BEAM VM makes Phoenix one of the best platforms for WebSocket-heavy applications
