defmodule ElixirKatasWeb.PhoenixKata51IntegrationTestsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Integration Tests — LiveView Testing & E2E Flows

    # 1. LiveView test basics (no browser needed!)
    defmodule MyAppWeb.CounterLiveTest do
      use MyAppWeb.ConnCase, async: true
      import Phoenix.LiveViewTest

      test "increments counter on click", %{conn: conn} do
        {:ok, view, html} = live(conn, ~p"/counter")
        assert html =~ "Count: 0"

        view |> element("button", "Increment") |> render_click()
        assert render(view) =~ "Count: 1"
      end
    end

    # 2. LiveView form interactions
    defmodule MyAppWeb.PostLive.IndexTest do
      use MyAppWeb.ConnCase, async: true
      import Phoenix.LiveViewTest
      import MyApp.BlogFixtures

      test "creates post via form", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/posts/new")

        view
        |> form("#post-form", post: %{title: "New Post", body: "Content"})
        |> render_submit()

        flash = assert_redirect(view, "/posts/" <> _)
        assert flash["info"] =~ "Post created"
      end

      test "shows validation errors", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/posts/new")
        html = view
          |> form("#post-form", post: %{title: ""})
          |> render_submit()
        assert html =~ "can't be blank"
      end

      test "search filters posts", %{conn: conn} do
        post_fixture(title: "Elixir Post")
        post_fixture(title: "Ruby Post")
        {:ok, view, _html} = live(conn, ~p"/posts")

        html = view
          |> form("#search-form", search: %{q: "Elixir"})
          |> render_change()

        assert html =~ "Elixir Post"
        refute html =~ "Ruby Post"
      end
    end

    # 3. Full auth + edit flow
    defmodule MyAppWeb.PostLive.EditFlowTest do
      use MyAppWeb.ConnCase, async: true
      import Phoenix.LiveViewTest
      import MyApp.AccountsFixtures
      import MyApp.BlogFixtures

      setup :register_and_log_in_user

      test "updates post with valid data", %{conn: conn, user: user} do
        post = post_fixture(user_id: user.id)
        {:ok, view, _html} = live(conn, ~p"/posts/\#{post.id}/edit")

        view
        |> form("#post-form", post: %{title: "Updated Title"})
        |> render_submit()

        {path, flash} = assert_redirect(view)
        assert path == ~p"/posts/\#{post.id}"
        assert flash["info"] =~ "updated"
      end

      test "403 for another user's post", %{conn: conn} do
        other_user = user_fixture()
        post = post_fixture(user_id: other_user.id)
        {:error, {:redirect, %{to: to}}} =
          live(conn, ~p"/posts/\#{post.id}/edit")
        assert to == ~p"/posts"
      end
    end

    # 4. Wallaby — real browser E2E tests
    # defmodule MyAppWeb.CheckoutFlowTest do
    #   use Wallaby.Feature
    #   feature "user can checkout", %{session: session} do
    #     session
    #     |> visit("/")
    #     |> click(button("Add to Cart"))
    #     |> click(link("Checkout"))
    #     |> fill_in(text_field("Card"), with: "4242...")
    #     |> click(button("Place Order"))
    #     |> assert_text("Order confirmed!")
    #   end
    # end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "liveview")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Integration Tests</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Feature tests, end-to-end flows, LiveView testing — verifying that all layers of your application work together correctly.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "liveview_tests", "flows", "wallaby", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-rose-50 dark:bg-rose-900/30 text-rose-700 dark:text-rose-400 border-b-2 border-rose-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["liveview", "e2e", "pyramid"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-rose-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Unit Tests</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">One function, one context. Fast and precise.</p>
            </div>
            <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
              <p class="text-sm font-semibold text-rose-700 dark:text-rose-300 mb-1">Integration Tests</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Multiple layers (HTTP + DB). Slower but catches wiring issues.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">E2E Tests</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Real browser. Slowest but most realistic user flow.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- LiveView Tests -->
      <%= if @active_tab == "liveview_tests" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix provides <code>Phoenix.LiveViewTest</code> for testing LiveViews without a real browser — fast and reliable.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{liveview_test_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">LiveViewTest Helpers</p>
              <ul class="space-y-1 text-sm font-mono text-gray-600 dark:text-gray-300">
                <li>live(conn, path) — mount a LiveView</li>
                <li>element(view, selector) — find DOM element</li>
                <li>render_click(element) — click it</li>
                <li>render_change(element, values) — input change</li>
                <li>render_submit(form, values) — submit form</li>
                <li>render(view) — get current HTML</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Form Interaction</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{form_liveview_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- End-to-End Flows -->
      <%= if @active_tab == "flows" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Testing complete user workflows end-to-end using Phoenix's built-in tools.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{flows_code()}</div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">recycle/1</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Use <code>recycle(conn)</code> to simulate following a redirect — it copies cookies from the response conn to a new conn.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Wallaby -->
      <%= if @active_tab == "wallaby" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Wallaby is a browser-based testing library for Phoenix — runs tests in a real Chrome/Firefox via ChromeDriver.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{wallaby_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">When to Use Wallaby</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>- Critical user journeys (checkout flow)</li>
                <li>- JS-heavy interactions</li>
                <li>- Visual regression detection</li>
                <li>- Accessibility testing</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">LiveViewTest vs Wallaby</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>LiveViewTest</strong>: fast, no browser, test LiveView logic</li>
                <li><strong>Wallaby</strong>: slower, real browser, full JS execution</li>
                <li>Use LiveViewTest for most things</li>
                <li>Use Wallaby for final E2E coverage</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Integration Test Suite</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("overview"), do: "Overview"
  defp tab_label("liveview_tests"), do: "LiveView Tests"
  defp tab_label("flows"), do: "E2E Flows"
  defp tab_label("wallaby"), do: "Wallaby"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("liveview"), do: "LiveView Testing"
  defp topic_label("e2e"), do: "E2E Testing"
  defp topic_label("pyramid"), do: "Test Pyramid"

  defp overview_code("liveview") do
    """
    # Phoenix.LiveViewTest — test LiveViews without a browser:
    defmodule MyAppWeb.CounterLiveTest do
      use MyAppWeb.ConnCase, async: true
      import Phoenix.LiveViewTest

      test "increments counter on click", %{conn: conn} do
        {:ok, view, html} = live(conn, ~p"/counter")

        # Initial state:
        assert html =~ "Count: 0"

        # Click the increment button:
        view
        |> element("button", "Increment")
        |> render_click()

        # Check updated state:
        assert render(view) =~ "Count: 1"
      end
    end

    # No ChromeDriver, no browser — just Elixir processes!
    # LiveViewTest communicates with the LiveView process directly.\
    """
    |> String.trim()
  end

  defp overview_code("e2e") do
    """
    # End-to-end test pyramid for Phoenix:
    #
    # ┌─────────────────────────────────────┐
    # │     E2E (Wallaby/Playwright)        │  few, slow
    # │  - Critical user journeys           │
    # │  - Real browser + JS execution      │
    # ├─────────────────────────────────────┤
    # │   Integration (ConnTest/LVTest)     │  moderate
    # │  - Feature flows across controllers │
    # │  - LiveView interactions            │
    # │  - Auth + authorization             │
    # ├─────────────────────────────────────┤
    # │     Unit (DataCase)                 │  many, fast
    # │  - Context functions                │
    # │  - Schema changesets                │
    # │  - Business logic                   │
    # └─────────────────────────────────────┘
    #
    # Aim: 70% unit, 20% integration, 10% E2E\
    """
    |> String.trim()
  end

  defp overview_code("pyramid") do
    """
    # Test types and what they cover:
    #
    # Unit tests (MyApp.DataCase):
    # mix test test/my_app/
    # - Context functions: Blog.create_post/1
    # - Changeset validation
    # - Pure business logic
    #
    # Integration tests (MyAppWeb.ConnCase):
    # mix test test/my_app_web/
    # - HTTP request -> response
    # - Controller + context + DB together
    # - Authentication flows
    #
    # LiveView tests (use Phoenix.LiveViewTest):
    # - LiveView mount + events + navigation
    # - Real-time updates
    # - Component interactions
    #
    # E2E tests (Wallaby or Playwright):
    # mix test test/e2e/
    # - Real browser
    # - JS execution
    # - Network requests\
    """
    |> String.trim()
  end

  defp liveview_test_code do
    """
    defmodule MyAppWeb.PostLive.IndexTest do
      use MyAppWeb.ConnCase, async: true
      import Phoenix.LiveViewTest
      import MyApp.BlogFixtures

      describe "Index" do
        test "lists posts", %{conn: conn} do
          post = post_fixture(title: "My Post")
          {:ok, _view, html} = live(conn, ~p"/posts")
          assert html =~ "My Post"
        end

        test "clicking post navigates to show", %{conn: conn} do
          post = post_fixture(title: "Click Me")
          {:ok, view, _html} = live(conn, ~p"/posts")

          {:ok, _show_view, show_html} =
            view
            |> element("a", "Click Me")
            |> render_click()
            |> follow_redirect(conn)

          assert show_html =~ "Click Me"
        end

        test "search filters posts", %{conn: conn} do
          post_fixture(title: "Elixir Post")
          post_fixture(title: "Ruby Post")

          {:ok, view, _html} = live(conn, ~p"/posts")

          html = view
            |> form("#search-form", search: %{q: "Elixir"})
            |> render_change()

          assert html =~ "Elixir Post"
          refute html =~ "Ruby Post"
        end
      end
    end\
    """
    |> String.trim()
  end

  defp form_liveview_code do
    """
    test "creates post via form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/new")

      view
      |> form("#post-form", post: %{
           title: "New Post",
           body: "Content here"
         })
      |> render_submit()

      # LiveView redirected to show page?
      flash = assert_redirect(view, "/posts/" <> _)
      assert flash["info"] =~ "Post created"
    end

    test "shows validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/new")

      html = view
        |> form("#post-form", post: %{title: ""})
        |> render_submit()

      assert html =~ "can't be blank"
    end\
    """
    |> String.trim()
  end

  defp flows_code do
    """
    # Full registration -> login -> action flow:
    defmodule MyAppWeb.UserFlowTest do
      use MyAppWeb.ConnCase
      import Phoenix.LiveViewTest

      test "register -> login -> create post flow" do
        # 1. Register:
        {:ok, view, _} = live(build_conn(),
          ~p"/users/register")

        {:ok, conn, _} = view
          |> form("#registration_form", user: %{
               email: "test@example.com",
               password: "password_12345!"
             })
          |> render_submit()
          |> follow_redirect(build_conn())

        # 2. Now logged in — create a post:
        {:ok, view, _} = live(conn, ~p"/posts/new")

        view
          |> form("#post-form", post: %{
               title: "My First Post",
               body: "Hello world!"
             })
          |> render_submit()

        # 3. Verify post was created:
        assert [post] = MyApp.Blog.list_posts()
        assert post.title == "My First Post"
      end
    end

    # recycle/1 copies session from response conn:
    conn = recycle(conn)
    # Useful for following redirects while keeping auth.\
    """
    |> String.trim()
  end

  defp wallaby_code do
    """
    # Wallaby — real browser tests:
    # {:wallaby, "~> 0.30", runtime: false, only: :test}

    defmodule MyAppWeb.CheckoutFlowTest do
      use ExUnit.Case, async: false
      use Wallaby.Feature

      import Wallaby.Query

      @tag :wallaby
      feature "user can checkout", %{session: session} do
        session
        |> visit("/")
        |> click(link("Shop"))
        |> click(button("Add to Cart"))
        |> click(link("Checkout"))
        |> fill_in(text_field("Credit card"), with: "4242 4242 4242 4242")
        |> fill_in(text_field("Expiry"), with: "12/29")
        |> click(button("Place Order"))
        |> assert_text("Order confirmed!")
      end
    end

    # Setup in config/test.exs:
    config :wallaby,
      otp_app: :my_app,
      chromedriver: [headless: true],
      base_url: "http://localhost:4002"\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete integration test: auth + LiveView + redirect

    defmodule MyAppWeb.PostLive.EditFlowTest do
      use MyAppWeb.ConnCase, async: true
      import Phoenix.LiveViewTest
      import MyApp.AccountsFixtures
      import MyApp.BlogFixtures

      setup :register_and_log_in_user

      describe "edit post flow" do
        test "loads edit form for own post",
             %{conn: conn, user: user} do
          post = post_fixture(user_id: user.id,
                              title: "My Post")

          {:ok, view, html} =
            live(conn, ~p"/posts/\#{post.id}/edit")

          assert html =~ "Edit Post"
          assert html =~ "My Post"
        end

        test "updates post with valid data",
             %{conn: conn, user: user} do
          post = post_fixture(user_id: user.id)

          {:ok, view, _html} =
            live(conn, ~p"/posts/\#{post.id}/edit")

          html = view
            |> form("#post-form",
                 post: %{title: "Updated Title"})
            |> render_submit()

          # Redirects to show:
          {path, flash} = assert_redirect(view)
          assert path == ~p"/posts/\#{post.id}"
          assert flash["info"] =~ "updated"
        end

        test "403 for another user's post",
             %{conn: conn} do
          other_user = user_fixture()
          post = post_fixture(user_id: other_user.id)

          # Should redirect with error:
          {:error, {:redirect, %{to: to}}} =
            live(conn, ~p"/posts/\#{post.id}/edit")

          assert to == ~p"/posts"
        end

        test "validates on change", %{conn: conn, user: user} do
          post = post_fixture(user_id: user.id)
          {:ok, view, _} =
            live(conn, ~p"/posts/\#{post.id}/edit")

          html = view
            |> form("#post-form",
                 post: %{title: ""})
            |> render_change()

          assert html =~ "can't be blank"
        end
      end
    end\
    """
    |> String.trim()
  end
end
