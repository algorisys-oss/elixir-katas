# Kata 51: Integration Tests

## The Test Pyramid

Phoenix applications have three layers of testing. Integration tests sit in the middle — they verify that multiple parts of your system work together correctly.

```
┌───────────────────────────────────────┐
│   E2E Tests (Wallaby/Playwright)      │  few, slowest
│ - Real browser, full JS execution     │
│ - Critical user journeys only         │
├───────────────────────────────────────┤
│  Integration Tests (ConnTest/LVTest)  │  moderate count
│ - HTTP request -> response cycles     │
│ - LiveView mount + events + forms     │
│ - Auth + authorization flows          │
├───────────────────────────────────────┤
│  Unit Tests (DataCase)                │  many, fastest
│ - Context functions, changesets       │
│ - Pure business logic                 │
└───────────────────────────────────────┘
```

Aim for roughly **70% unit, 20% integration, 10% E2E**.

---

## LiveView Testing with Phoenix.LiveViewTest

`Phoenix.LiveViewTest` lets you test LiveViews without a browser. It communicates directly with the LiveView process — no ChromeDriver, no HTTP server, just Elixir processes talking to each other.

```elixir
defmodule MyAppWeb.CounterLiveTest do
  use MyAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "increments counter on click", %{conn: conn} do
    # Mount the LiveView:
    {:ok, view, html} = live(conn, ~p"/counter")

    # Check the initial render:
    assert html =~ "Count: 0"

    # Click a button (fires phx-click event):
    view
    |> element("button", "Increment")
    |> render_click()

    # Check the updated HTML:
    assert render(view) =~ "Count: 1"
  end
end
```

The `live/2` function returns three things:
- `view` — a reference to the LiveView process (use it for interactions)
- `html` — the initial rendered HTML (the string from `mount` + `render`)
- The `:ok` atom confirming the mount succeeded

---

## LiveViewTest Helpers

These are the main functions for interacting with a mounted LiveView:

```elixir
# Mount a LiveView:
{:ok, view, html} = live(conn, ~p"/posts")

# Find DOM elements:
element(view, "button", "Click Me")   # by tag + text content
element(view, "#my-button")           # by CSS selector
element(view, ".submit-btn")          # by CSS class

# Interact with elements:
render_click(element)                          # simulate click
render_change(element, %{value: "new"})        # simulate input change
render_submit(form_element, %{field: "val"})   # submit a form
render_hook(view, "my_event", %{key: "val"})   # send a custom event

# Read current HTML:
html = render(view)

# Check and follow redirects:
{path, flash} = assert_redirect(view)
assert path == ~p"/posts"
assert flash["info"] =~ "Created"

{:ok, new_view, html} = follow_redirect(result, conn)
```

---

## Testing Forms in LiveView

LiveView forms fire two kinds of events: `phx-change` (as the user types) and `phx-submit` (when they submit). Test both:

```elixir
test "creates post via form", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/posts/new")

  # Simulate typing (fires phx-change):
  html = view
    |> form("#post-form", post: %{title: "My Post"})
    |> render_change()

  # No validation errors yet:
  refute html =~ "can't be blank"

  # Submit the form (fires phx-submit):
  view
    |> form("#post-form", post: %{
         title: "My Post",
         body: "Great content"
       })
    |> render_submit()

  # After submit, LiveView should redirect:
  {path, _flash} = assert_redirect(view)
  assert path =~ "/posts/"
end

test "shows validation errors on submit", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/posts/new")

  html = view
    |> form("#post-form", post: %{title: ""})
    |> render_submit()

  # Error message should appear:
  assert html =~ "can't be blank"
end
```

The `form/3` function finds the form by CSS selector and prepares the values. `render_change/1` and `render_submit/1` then fire the appropriate events.

---

## Testing Navigation

LiveView uses `push_navigate` and `push_patch` for client-side navigation. Test these with `follow_redirect`:

```elixir
test "clicking link navigates to show page", %{conn: conn} do
  post = post_fixture(title: "My Post")
  {:ok, index_view, _html} = live(conn, ~p"/posts")

  {:ok, _show_view, show_html} =
    index_view
    |> element("a", "My Post")
    |> render_click()
    |> follow_redirect(conn)

  assert show_html =~ "My Post"
end
```

---

## Testing Authorization in LiveView

When an unauthorized user tries to mount a protected LiveView, it returns `{:error, {:redirect, ...}}` instead of `{:ok, ...}`:

```elixir
test "unauthenticated user is redirected to login", %{conn: conn} do
  {:error, {:redirect, %{to: to}}} =
    live(conn, ~p"/posts/new")

  assert to == ~p"/users/log_in"
end

test "user cannot edit another user's post",
     %{conn: conn, user: _user} do
  other_user = user_fixture()
  post = post_fixture(user_id: other_user.id)

  {:error, {:redirect, %{to: to}}} =
    live(conn, ~p"/posts/#{post.id}/edit")

  assert to == ~p"/posts"
end
```

This pattern works because the LiveView's `mount/3` callback checks authorization and calls `{:halt, redirect(socket, to: path)}` for unauthorized access.

---

## End-to-End User Flows

Integration tests shine when testing complete user journeys that span multiple pages and actions:

```elixir
defmodule MyAppWeb.UserFlowTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "register -> login -> create post flow" do
    # 1. Visit registration page:
    {:ok, view, _} = live(build_conn(), ~p"/users/register")

    # 2. Fill in and submit registration form:
    {:ok, conn, _} = view
      |> form("#registration_form", user: %{
           email: "user@example.com",
           password: "password_12345!"
         })
      |> render_submit()
      |> follow_redirect(build_conn())

    # 3. Now logged in — navigate to new post page:
    {:ok, view, _} = live(conn, ~p"/posts/new")

    # 4. Create a post:
    view
      |> form("#post-form", post: %{
           title: "My First Post",
           body: "Hello world!"
         })
      |> render_submit()

    # 5. Verify at the data layer:
    assert [post] = MyApp.Blog.list_posts()
    assert post.title == "My First Post"
  end
end
```

Notice that after the redirect, we use the returned `conn` (which carries the session) for subsequent requests. This simulates a real user session across page navigations.

---

## Testing PubSub in Integration

When LiveViews subscribe to PubSub topics, you can test that real-time updates appear:

```elixir
test "new order appears in real time", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/orders")

  # Create an order from outside the LiveView:
  Orders.create_order(%{product: "Widget", quantity: 1})

  # render/1 returns the latest state after the broadcast:
  assert render(view) =~ "Widget"
end
```

You can also subscribe directly in the test and use `assert_receive`:

```elixir
Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
Orders.create_order(%{product: "Widget"})
assert_receive %{event: "order_created"}, 500
```

---

## Wallaby — Browser-Based E2E Tests

For tests that need real JavaScript execution, use Wallaby. It drives a real Chrome browser:

```elixir
# mix.exs: {:wallaby, "~> 0.30", runtime: false, only: :test}

defmodule MyAppWeb.CheckoutFlowTest do
  use ExUnit.Case, async: false
  use Wallaby.Feature
  import Wallaby.Query

  @tag :wallaby
  feature "user can complete checkout", %{session: session} do
    session
    |> visit("/")
    |> click(link("Shop Now"))
    |> click(button("Add to Cart"))
    |> click(link("Checkout"))
    |> fill_in(text_field("Card number"), with: "4242424242424242")
    |> click(button("Place Order"))
    |> assert_text("Order Confirmed!")
  end
end
```

**LiveViewTest vs Wallaby**: LiveViewTest is fast (milliseconds), needs no browser, and handles most LiveView testing. Wallaby is slow (seconds), requires ChromeDriver, but executes real JavaScript. Use LiveViewTest for 90% of tests; reserve Wallaby for critical flows that depend on JS behavior.

---

## Full Integration Test Example

```elixir
defmodule MyAppWeb.PostLive.EditFlowTest do
  use MyAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import MyApp.AccountsFixtures
  import MyApp.BlogFixtures

  setup :register_and_log_in_user

  describe "edit post flow" do
    test "saves changes and redirects",
         %{conn: conn, user: user} do
      post = post_fixture(user_id: user.id)
      {:ok, view, _} = live(conn, ~p"/posts/#{post.id}/edit")

      view
        |> form("#post-form", post: %{title: "Updated"})
        |> render_submit()

      {path, flash} = assert_redirect(view)
      assert path == ~p"/posts/#{post.id}"
      assert flash["info"] =~ "updated"
    end

    test "validates on change", %{conn: conn, user: user} do
      post = post_fixture(user_id: user.id)
      {:ok, view, _} = live(conn, ~p"/posts/#{post.id}/edit")

      html = view
        |> form("#post-form", post: %{title: ""})
        |> render_change()

      assert html =~ "can't be blank"
    end

    test "blocks access to another user's post",
         %{conn: conn} do
      other_user = user_fixture()
      post = post_fixture(user_id: other_user.id)

      {:error, {:redirect, %{to: to}}} =
        live(conn, ~p"/posts/#{post.id}/edit")

      assert to == ~p"/posts"
    end
  end
end
```

---

## Key Takeaways

1. **`Phoenix.LiveViewTest`** tests LiveViews without a browser — fast and reliable
2. Use **`element/2-3`** + **`render_click/change/submit`** to simulate user interactions
3. **`form/3`** finds a form by CSS selector and prepares values for change or submit
4. **`assert_redirect/1`** checks that the LiveView redirected — returns `{path, flash}`
5. **`follow_redirect/2`** mounts the new LiveView at the redirect destination
6. Test **authorization** by checking for `{:error, {:redirect, ...}}` on protected routes
7. Use **Wallaby** sparingly — only for critical flows that require real JavaScript
8. Integration tests catch **wiring issues** that unit tests miss (routes, plugs, templates)
