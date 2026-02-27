# Kata 02: URLs, Paths & Query Strings

## What is a URL?

A **URL** (Uniform Resource Locator) is the address of a resource on the web. When you type a URL into your browser's address bar, you're telling the browser exactly where to find something and how to get it.

Every URL follows a specific structure:

```
https://shop.example.com:8080/products/shoes?color=red&size=10#reviews
└─┬──┘ └───────┬───────┘└┬─┘└─────┬───────┘└───────┬────────┘└──┬───┘
scheme       host      port     path           query         fragment
```

---

## The Parts of a URL

### 1. Scheme (Protocol)

```
https://
```

The scheme tells the browser **how** to communicate with the server:
- `http://` — HyperText Transfer Protocol (unencrypted)
- `https://` — HTTP Secure (encrypted with TLS/SSL)

**Always use HTTPS** in production. HTTP sends everything in plain text — anyone on the network can read it.

### 2. Host (Domain Name)

```
shop.example.com
```

The host identifies **which server** to connect to. It's a human-readable name that gets translated to an IP address by DNS (Domain Name System):

```
shop.example.com  →  DNS lookup  →  93.184.216.34
```

Subdomains (like `shop.` or `api.`) let you organize different services under the same domain.

### 3. Port

```
:8080
```

The port number specifies **which program** on the server should handle the request. Think of it like an apartment number — the host is the building address, the port is the specific apartment.

- **80** — Default for HTTP (usually omitted)
- **443** — Default for HTTPS (usually omitted)
- **4000** — Phoenix default in development
- **8080** — Common alternative

If you don't specify a port, the browser uses the default for the scheme.

### 4. Path

```
/products/shoes
```

The path identifies **which resource** you want on the server. Paths look like file system directories:

```
/                     → Root (home page)
/users                → Users collection
/users/42             → Specific user (ID: 42)
/users/42/posts       → Posts belonging to user 42
/users/42/posts/7     → Specific post by user 42
```

Each segment between `/` slashes is a **path segment**. In Phoenix, these become the `path_info` list:

```elixir
# URL: /users/42/posts
conn.path_info  # ["users", "42", "posts"]
```

### 5. Query String

```
?color=red&size=10
```

The query string passes **additional parameters** as key-value pairs:

```
?key1=value1&key2=value2&key3=value3
```

- Starts with `?`
- Pairs are separated by `&`
- Keys and values are connected by `=`
- Special characters must be **percent-encoded** (spaces become `%20` or `+`)

**Common uses:**
- Filtering: `?status=active&role=admin`
- Sorting: `?sort=name&order=asc`
- Pagination: `?page=2&per_page=25`
- Search: `?q=elixir+programming`

In Phoenix, query parameters are merged into `conn.params`:

```elixir
# URL: /products?color=red&size=10
conn.query_string  # "color=red&size=10"
conn.params        # %{"color" => "red", "size" => "10"}
```

### 6. Fragment

```
#reviews
```

The fragment (also called **anchor** or **hash**) points to a specific section within the page.

**Important:** The fragment is **never sent to the server**! It's purely client-side — the browser uses it to scroll to an element with that ID.

```
https://docs.example.com/guide#installation
                                └── Browser scrolls to <div id="installation">
```

---

## URL Encoding

URLs can only contain certain characters. Special characters must be **percent-encoded**:

| Character | Encoded | Example |
|-----------|---------|---------|
| Space | `%20` or `+` | `hello world` → `hello%20world` |
| `&` | `%26` | `rock&roll` → `rock%26roll` |
| `=` | `%3D` | `a=b` → `a%3Db` |
| `/` | `%2F` | `path/to` → `path%2Fto` |
| `?` | `%3F` | `what?` → `what%3F` |
| `#` | `%23` | `C#` → `C%23` |

In Elixir:
```elixir
URI.encode("hello world")       # "hello%20world"
URI.decode("hello%20world")     # "hello world"
URI.encode_query(%{"q" => "elixir & phoenix"})  # "q=elixir+%26+phoenix"
```

---

## Path Parameters vs Query Parameters

Both carry information, but they serve different purposes:

### Path Parameters — identify the resource

```
GET /users/42           ← "Give me user 42"
GET /posts/hello-world  ← "Give me the post with slug hello-world"
```

Path parameters are part of the URL structure. They identify **which** resource you want. In Phoenix:

```elixir
# Route: /users/:id
# URL:   /users/42

def show(conn, %{"id" => id}) do
  # id = "42"
end
```

### Query Parameters — modify the request

```
GET /users?role=admin&sort=name  ← "Give me users, filtered by admin role, sorted by name"
GET /search?q=elixir&page=2      ← "Search for elixir, page 2"
```

Query parameters are optional extras. They filter, sort, or modify what you get back. In Phoenix:

```elixir
# Route: /users
# URL:   /users?role=admin&sort=name

def index(conn, params) do
  # params = %{"role" => "admin", "sort" => "name"}
end
```

### Rule of Thumb

- **Path params** = nouns (the thing itself): `/users/42`, `/posts/my-article`
- **Query params** = adjectives/adverbs (how/which): `?sort=date`, `?page=3`, `?q=search`

---

## URLs in Phoenix

Phoenix gives you tools to work with URLs throughout your app:

```elixir
# In router.ex — define routes with path parameters
get "/users/:id", UserController, :show
get "/users/:user_id/posts/:id", PostController, :show

# In controllers — access both path and query params
def show(conn, %{"id" => id}) do
  # Path param from :id
end

def index(conn, %{"page" => page, "sort" => sort}) do
  # Query params from ?page=1&sort=name
end

# Generating URLs with verified routes
~p"/users/#{user.id}"                    # "/users/42"
~p"/users?#{[sort: "name", page: 2]}"   # "/users?sort=name&page=2"
```

---

## Try It Out

Use the **Interactive** tab to explore URLs:
1. Enter different URLs and see them broken down
2. Try adding query parameters
3. Notice how the Plug.Conn mapping changes
4. Click the example URLs to see common patterns

---

## Key Takeaways

1. A URL has 6 parts: **scheme**, **host**, **port**, **path**, **query**, **fragment**
2. **Path segments** identify resources: `/users/42/posts`
3. **Query strings** pass optional parameters: `?sort=name&page=2`
4. **Fragments** (`#section`) are client-only, never sent to server
5. Special characters need **percent-encoding**
6. In Phoenix, both path and query params end up in `conn.params`
