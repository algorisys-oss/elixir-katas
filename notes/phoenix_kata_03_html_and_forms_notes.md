# Kata 03: HTML & Forms

## How Browsers Send Data

When you fill out a form on a website and click "Submit", the browser needs to send your data to the server. But how? There are two primary ways: **GET** (data in the URL) and **POST** (data in the body).

Understanding this is essential because **every web framework** — Phoenix, Rails, Django, Express — receives data this way. The framework doesn't invent its own protocol; it parses what the browser sends via standard HTTP.

---

## HTML Forms: The Basics

An HTML form is the standard way for users to input data in a web page:

```html
<form action="/login" method="POST">
  <label>Username</label>
  <input type="text" name="username" />

  <label>Password</label>
  <input type="password" name="password" />

  <button type="submit">Log In</button>
</form>
```

### Key Attributes

- **`action`** — The URL to send the data to (e.g., `/login`, `/users`)
- **`method`** — HTTP method to use (`GET` or `POST`)
- **`name`** — Each input's `name` attribute becomes the key in the submitted data

### The `name` Attribute Matters

The `name` attribute is what the server sees. Without it, the input's value is **never sent**:

```html
<!-- ✅ This gets sent: name="email" -->
<input type="text" name="email" value="alice@example.com" />

<!-- ❌ This is NEVER sent: no name attribute -->
<input type="text" value="invisible data" />
```

---

## Form Encoding: How Data Gets Packaged

### URL-encoded (default)

By default, forms use `application/x-www-form-urlencoded` encoding:

```
username=alice&password=secret123&remember=true
```

Rules:
- Key-value pairs separated by `&`
- Keys and values connected by `=`
- Spaces become `+` or `%20`
- Special characters are percent-encoded

### Multipart (for file uploads)

When a form includes file uploads, it uses `multipart/form-data`:

```html
<form action="/upload" method="POST" enctype="multipart/form-data">
  <input type="file" name="avatar" />
  <button type="submit">Upload</button>
</form>
```

Multipart encoding packages each field separately with boundaries:

```
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="avatar"; filename="photo.jpg"
Content-Type: image/jpeg

[binary file data]
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

---

## GET Forms: Data in the URL

With `method="GET"`, the browser appends form data to the URL as query parameters:

```html
<form action="/search" method="GET">
  <input type="text" name="q" value="elixir" />
  <input type="text" name="page" value="1" />
</form>
```

When submitted, the browser navigates to:
```
/search?q=elixir&page=1
```

The raw HTTP request:
```
GET /search?q=elixir&page=1 HTTP/1.1
Host: example.com
Accept: text/html

(no body)
```

### When to Use GET

- **Search forms** — So users can bookmark/share search results
- **Filters** — `?category=books&sort=price`
- **Pagination** — `?page=3`
- Any request that **reads** data without changing it

---

## POST Forms: Data in the Body

With `method="POST"`, the browser sends form data in the request body (invisible in the URL):

```html
<form action="/login" method="POST">
  <input type="text" name="username" value="alice" />
  <input type="password" name="password" value="secret123" />
</form>
```

The raw HTTP request:
```
POST /login HTTP/1.1
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 33

username=alice&password=secret123
```

### When to Use POST

- **Login forms** — Passwords should never appear in URLs
- **Creating data** — New user, new post, new comment
- **Uploading files** — Files can't fit in a URL
- Any request that **changes** data on the server

---

## GET vs POST: The Key Differences

| Aspect | GET | POST |
|--------|-----|------|
| Data location | In the URL (visible) | In the body (hidden) |
| Browser history | Saved (with data) | Not saved |
| Bookmarkable | Yes | No |
| Back button | Safe to repeat | Browser warns "resubmit?" |
| Size limit | ~2KB (URL length) | Practically unlimited |
| Caching | Can be cached | Never cached |
| File uploads | Not possible | Supported |
| Idempotent | Yes (same result each time) | No (may create duplicates) |

**Rule of thumb**: GET for reading, POST for writing.

---

## Input Types

HTML provides many input types, each with different behaviors:

```html
<!-- Text inputs -->
<input type="text" name="name" />         <!-- Free text -->
<input type="email" name="email" />       <!-- Email validation -->
<input type="password" name="pass" />     <!-- Hidden characters -->
<input type="number" name="age" />        <!-- Numbers only -->
<input type="tel" name="phone" />         <!-- Phone keyboard on mobile -->
<input type="url" name="website" />       <!-- URL validation -->

<!-- Selection inputs -->
<input type="checkbox" name="agree" value="yes" />    <!-- On/off toggle -->
<input type="radio" name="plan" value="basic" />      <!-- Pick one -->
<select name="country">                                <!-- Dropdown -->
  <option value="us">United States</option>
  <option value="uk">United Kingdom</option>
</select>

<!-- Special inputs -->
<input type="hidden" name="csrf_token" value="abc" /> <!-- Hidden data -->
<input type="file" name="avatar" />                    <!-- File upload -->
<textarea name="bio">Long text here</textarea>         <!-- Multi-line text -->
```

### Hidden Inputs

Hidden inputs are crucial for web apps. They carry data the user doesn't see:

```html
<input type="hidden" name="_csrf_token" value="abc123def" />
<input type="hidden" name="user_id" value="42" />
```

Phoenix uses hidden inputs for **CSRF protection** — preventing malicious sites from submitting forms on your behalf.

---

## Forms in Phoenix

In Phoenix, form data arrives in your controller as the `params` map:

```elixir
# HTML form:
# <form action="/users" method="POST">
#   <input name="user[name]" value="Alice" />
#   <input name="user[email]" value="alice@ex.com" />
# </form>

def create(conn, %{"user" => user_params}) do
  # user_params = %{"name" => "Alice", "email" => "alice@ex.com"}
end
```

### Nested Parameters

Notice the `user[name]` syntax — the brackets create **nested maps** in Phoenix:

```
user[name]=Alice&user[email]=alice@ex.com
```

Becomes:
```elixir
%{"user" => %{"name" => "Alice", "email" => "alice@ex.com"}}
```

This is a convention that helps organize parameters, especially when a form has data for multiple resources.

---

## Key Takeaways

1. Forms send data via **GET** (in URL) or **POST** (in body)
2. The `name` attribute on inputs determines the parameter key
3. Default encoding is `application/x-www-form-urlencoded`
4. Use `multipart/form-data` for file uploads
5. **GET** for reading (search, filters), **POST** for writing (create, login)
6. In Phoenix, form data arrives as `params` map in your controller
7. Bracket syntax (`user[name]`) creates nested parameter maps
