# Kata 01: HTTP Protocol

## What is HTTP?

**HTTP** (HyperText Transfer Protocol) is the language that web browsers and web servers use to talk to each other. Every time you visit a website, your browser sends an HTTP **request** and the server sends back an HTTP **response**. That's it — the entire web is built on this simple request/response cycle.

HTTP is a **text-based protocol** — the messages sent between browser and server are plain text that follows a specific format. This makes it easy to read, debug, and understand.

---

## The Request/Response Cycle

```
┌──────────┐                        ┌──────────┐
│          │   1. HTTP Request       │          │
│  Browser │ ──────────────────────▶ │  Server  │
│ (Client) │                         │          │
│          │   2. HTTP Response      │          │
│          │ ◀────────────────────── │          │
└──────────┘                        └──────────┘
```

1. **You type a URL** (e.g., `http://example.com/users`) in your browser
2. **Browser sends an HTTP request** to the server
3. **Server processes the request** (reads from database, runs code, etc.)
4. **Server sends an HTTP response** back (HTML page, JSON data, an image, etc.)
5. **Browser renders the response** (displays the page)

This happens every single time — for every page, every image, every API call.

---

## Anatomy of an HTTP Request

An HTTP request has 4 parts:

```
GET /users?page=1 HTTP/1.1        ← Request Line (method + path + version)
Host: example.com                  ← Headers (metadata)
Accept: text/html                  ←
User-Agent: Mozilla/5.0            ←
                                   ← Empty line (separates headers from body)
                                   ← Body (empty for GET requests)
```

### 1. Request Line

The first line tells the server **what you want to do** and **where**:

```
GET /users?page=1 HTTP/1.1
 │    │              │
 │    │              └── Protocol version
 │    └── Path (what resource you want)
 └── Method (what action to take)
```

### 2. HTTP Methods

Methods tell the server what **action** to perform:

| Method | Purpose | Has Body? | Example |
|--------|---------|-----------|---------|
| **GET** | Retrieve data | No | View a web page, fetch API data |
| **POST** | Create new data | Yes | Submit a form, create a user |
| **PUT** | Replace data entirely | Yes | Update a user's entire profile |
| **PATCH** | Partially update data | Yes | Change just the email address |
| **DELETE** | Remove data | No | Delete a user account |
| **HEAD** | GET without body | No | Check if a resource exists |
| **OPTIONS** | Ask what's allowed | No | CORS preflight checks |

**Memory aid**: Think of it like a library:
- **GET** = "Can I see this book?"
- **POST** = "Here's a new book to add"
- **PUT** = "Replace this book with this updated version"
- **PATCH** = "Fix the typo on page 42 of this book"
- **DELETE** = "Remove this book from the shelf"

### 3. Headers

Headers are **key-value pairs** that provide extra information about the request:

```
Host: example.com                    ← Which server to talk to
Accept: text/html, application/json  ← What response formats I understand
Content-Type: application/json       ← What format my body is in
Authorization: Bearer abc123         ← My credentials
User-Agent: Mozilla/5.0             ← What browser I'm using
Cookie: session_id=xyz               ← My session data
```

### 4. Body

The body carries **data you're sending to the server**. Only some methods have bodies (POST, PUT, PATCH):

```
POST /users HTTP/1.1
Host: example.com
Content-Type: application/json
Content-Length: 42

{"name": "Alice", "email": "alice@ex.com"}
```

GET and DELETE requests typically have **no body** — all the information is in the URL and headers.

---

## Anatomy of an HTTP Response

```
HTTP/1.1 200 OK                    ← Status Line (version + code + reason)
Content-Type: text/html             ← Headers
Content-Length: 1234                 ←
Set-Cookie: session_id=abc          ←
                                    ← Empty line
<html><body>Hello!</body></html>    ← Body (the actual content)
```

### Status Codes

The three-digit **status code** tells you what happened:

| Range | Category | Meaning |
|-------|----------|---------|
| **1xx** | Informational | Request received, continuing... |
| **2xx** | Success | Request was successful |
| **3xx** | Redirection | Go look somewhere else |
| **4xx** | Client Error | You (the browser) did something wrong |
| **5xx** | Server Error | The server broke |

**The most important codes to memorize**:

- **200 OK** — Everything worked
- **201 Created** — New resource was created (after POST)
- **204 No Content** — Success, but nothing to return (after DELETE)
- **301 Moved Permanently** — This URL has moved forever
- **302 Found** — Temporary redirect
- **304 Not Modified** — Use your cached version
- **400 Bad Request** — Your request doesn't make sense
- **401 Unauthorized** — You need to log in
- **403 Forbidden** — You're logged in but not allowed
- **404 Not Found** — This resource doesn't exist
- **422 Unprocessable Entity** — Validation failed (common in APIs)
- **500 Internal Server Error** — The server crashed

---

## HTTP is Stateless

A crucial concept: **HTTP has no memory**. Each request is completely independent — the server doesn't remember your previous requests.

```
Request 1: GET /users     → Server: "Here are the users" (forgets everything)
Request 2: GET /users/1   → Server: "Who are you? Here's user 1" (forgets again)
Request 3: POST /login    → Server: "Logged in! Here's a cookie" (forgets again)
Request 4: GET /dashboard → Server: "I see your cookie — here's your dashboard"
```

To maintain **state** (like "who is logged in"), we use:
- **Cookies** — Small pieces of data the server asks the browser to store
- **Sessions** — Server-side storage linked to a cookie
- **Tokens** — Credentials sent in headers (like JWT)

We'll cover these in detail in Kata 05.

---

## HTTP in Phoenix

In Phoenix, every HTTP request becomes a `%Plug.Conn{}` struct:

```elixir
# The request above becomes:
%Plug.Conn{
  method: "GET",
  request_path: "/users",
  query_string: "page=1",
  req_headers: [
    {"host", "example.com"},
    {"accept", "text/html"}
  ],
  params: %{"page" => "1"},
  status: nil,           # Set by your controller
  resp_body: nil         # Set when you render
}
```

Every controller action, every plug, every middleware in Phoenix receives this connection struct and returns a modified version. The entire Phoenix request lifecycle is just transforming this struct step by step.

---

## Try It Out

Use the **Interactive** tab to build HTTP requests and see what the raw text looks like. Try:
1. Change the method to POST and add a body
2. Try different paths like `/404`
3. Notice how the raw HTTP text changes with each option

---

## Key Takeaways

1. **HTTP = request + response**, both are plain text
2. **Methods** describe the action (GET, POST, PUT, DELETE)
3. **Status codes** tell you what happened (2xx = good, 4xx = your fault, 5xx = server's fault)
4. **Headers** carry metadata, **body** carries data
5. **HTTP is stateless** — each request starts fresh
6. In Phoenix, every request becomes a `%Plug.Conn{}` struct
