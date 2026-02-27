# Kata 04: Client-Server Architecture

## The Big Picture

Every web application follows the **client-server model** — a conversation between two programs:

- **Client** (Browser): Sends requests, displays responses. The "customer" who asks for things.
- **Server** (Phoenix): Receives requests, processes them, sends responses. The "waiter" who fulfills orders.

```
You (Human)
    │
    ▼
┌──────────┐         Internet          ┌──────────┐
│  Browser  │ ◀══════════════════════▶ │  Server   │
│ (Client)  │    HTTP Request/Response │ (Phoenix) │
└──────────┘                           └──────────┘
                                            │
                                            ▼
                                       ┌──────────┐
                                       │ Database  │
                                       │(Postgres) │
                                       └──────────┘
```

---

## The Journey of a Web Request

Let's trace what happens when you visit `https://shop.example.com/products`:

### Step 1: You Type a URL

You enter the URL in your browser and press Enter. This is the starting point of every web request.

### Step 2: DNS Lookup

The browser needs to find the server. It asks a **DNS** (Domain Name System) server to translate the human-readable domain name into an IP address:

```
shop.example.com  →  DNS  →  93.184.216.34
```

Think of DNS as the internet's phone book — it maps names to numbers.

**Caching**: Your browser and OS cache DNS results, so this lookup only happens once (until the cache expires).

### Step 3: TCP Connection

The browser opens a **TCP connection** to the server's IP address on port 443 (for HTTPS). If using HTTPS, a **TLS handshake** happens first to establish an encrypted channel.

### Step 4: HTTP Request Sent

The browser sends the HTTP request:

```
GET /products HTTP/1.1
Host: shop.example.com
Accept: text/html
Cookie: session_id=abc123
User-Agent: Mozilla/5.0 ...
```

### Step 5: Server Processes the Request

In Phoenix, the request flows through several layers:

```
HTTP Request
    │
    ▼
┌─────────────────────┐
│  Cowboy (HTTP Server)│  Accepts TCP connection, parses HTTP
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Phoenix Endpoint    │  Static files, logging, parsing
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Router              │  Matches URL to controller
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Pipeline (:browser) │  Session, CSRF, headers
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Controller          │  Your code! Business logic
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Database (Ecto)     │  Query data if needed
└─────────────────────┘
```

### Step 6: Response Sent Back

The server builds an HTTP response and sends it back:

```
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 4523

<!DOCTYPE html>
<html>
  <body>
    <h1>Products</h1>
    ...
  </body>
</html>
```

### Step 7: Browser Renders the Page

The browser receives the HTML and:
1. **Parses** the HTML into a DOM tree
2. **Fetches** linked resources (CSS, JavaScript, images) — each as a separate HTTP request
3. **Renders** the page on screen
4. **Executes** JavaScript

---

## Static vs Dynamic Content

### Static Content

Files that are served **as-is** — no code runs, no database queries:

- HTML files, CSS, JavaScript
- Images, fonts, videos, PDFs
- Any file in `priv/static/` in Phoenix

```
Browser: "GET /images/logo.png"
Server:  *reads file from disk, sends it* (no Phoenix code involved)
```

Phoenix serves static files directly through the Endpoint, before the request even reaches the router:

```elixir
# In endpoint.ex
plug Plug.Static,
  at: "/",
  from: :my_app,
  gzip: false,
  only: ~w(assets fonts images favicon.ico robots.txt)
```

### Dynamic Content

Generated **on each request** by running code:

```
Browser: "GET /products?category=books"
Server:  *runs controller code*
         *queries database*
         *renders template with data*
         *sends generated HTML*
```

This is where Phoenix shines — Controllers, LiveView, and Channels all generate dynamic responses.

---

## The Server Stack in Phoenix

Phoenix doesn't handle everything alone. It's built on layers:

```
┌────────────────────────────────────────────────┐
│                Your Phoenix App                 │  Your code (controllers, views, etc.)
├────────────────────────────────────────────────┤
│                 Phoenix Framework               │  MVC structure, routing, channels
├────────────────────────────────────────────────┤
│                     Plug                        │  HTTP middleware specification
├────────────────────────────────────────────────┤
│              Cowboy (HTTP Server)                │  Handles raw HTTP connections
├────────────────────────────────────────────────┤
│               Ranch (TCP Server)                │  Manages TCP socket connections
├────────────────────────────────────────────────┤
│                   BEAM VM                       │  Erlang VM (concurrency, fault tolerance)
├────────────────────────────────────────────────┤
│               Operating System                  │  Linux, macOS, Windows
└────────────────────────────────────────────────┘
```

Each layer handles one responsibility:
- **Ranch**: Accept TCP connections
- **Cowboy**: Parse HTTP, manage WebSockets
- **Plug**: Transform connections through middleware
- **Phoenix**: Route requests, render responses
- **Your Code**: Business logic, database queries, templates

---

## Multiple Requests per Page

A single page load often triggers **many** HTTP requests:

```
1. GET /products              → HTML page
2. GET /assets/css/app.css    → Stylesheet
3. GET /assets/js/app.js      → JavaScript
4. GET /images/logo.png       → Logo image
5. GET /images/product1.jpg   → Product image
6. GET /images/product2.jpg   → Product image
7. GET /api/cart              → Shopping cart data (AJAX)
```

Each is a separate HTTP request/response cycle. The browser's **Network tab** (in Developer Tools) shows all of these.

---

## Phoenix's Superpower: Concurrency

Most web servers handle requests one at a time (or with a limited thread pool). Phoenix, running on the BEAM VM, handles each request in its own **lightweight process**:

```
Request 1 ──→ Process #1 (2KB memory)
Request 2 ──→ Process #2 (2KB memory)
Request 3 ──→ Process #3 (2KB memory)
...
Request 2,000,000 ──→ Process #2,000,000
```

Each process is:
- **Isolated** — one crash doesn't affect others
- **Lightweight** — ~2KB each (vs ~1MB per OS thread)
- **Concurrent** — millions can run simultaneously

This is why Phoenix can handle millions of concurrent connections on a single server.

---

## Key Takeaways

1. **Client-server**: Browser sends requests, server sends responses
2. **DNS** translates domain names to IP addresses
3. Requests flow through: **Cowboy → Endpoint → Router → Pipeline → Controller**
4. **Static** content is served from files; **dynamic** content is generated by code
5. A single page load triggers **multiple** HTTP requests
6. Phoenix handles each request in an isolated **BEAM process** — enabling massive concurrency
