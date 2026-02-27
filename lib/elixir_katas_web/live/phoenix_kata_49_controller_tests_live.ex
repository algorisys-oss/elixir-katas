defmodule ElixirKatasWeb.PhoenixKata49ControllerTestsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Controller Tests — ConnTest, Assertions, Auth

    defmodule MyAppWeb.PostControllerTest do
      use MyAppWeb.ConnCase

      import MyApp.AccountsFixtures
      alias MyApp.Blog

      @create_attrs %{title: "Test Post", body: "Content here"}
      @invalid_attrs %{title: "", body: ""}

      # --- Auth setup ---
      setup :register_and_log_in_user

      # --- Index ---
      describe "index" do
        test "lists all posts", %{conn: conn} do
          conn = get(conn, ~p"/posts")
          assert html_response(conn, 200) =~ "Posts"
        end
      end

      # --- Create ---
      describe "create" do
        test "redirects when valid", %{conn: conn} do
          conn = post(conn, ~p"/posts", post: @create_attrs)
          assert %{id: id} = redirected_params(conn)
          assert redirected_to(conn) == ~p"/posts/\#{id}"

          # Follow the redirect:
          conn = get(recycle(conn), ~p"/posts/\#{id}")
          assert html_response(conn, 200) =~ "Test Post"
        end

        test "shows errors when invalid", %{conn: conn} do
          conn = post(conn, ~p"/posts", post: @invalid_attrs)
          assert html_response(conn, 422) =~ "can't be blank"
        end
      end

      # --- Delete ---
      describe "delete" do
        test "deletes post", %{conn: conn, user: user} do
          post = Blog.create_post!(Map.put(@create_attrs, :user_id, user.id))
          conn = delete(conn, ~p"/posts/\#{post}")
          assert redirected_to(conn) == ~p"/posts"
        end
      end
    end

    # --- JSON API Tests ---
    defmodule MyAppWeb.Api.ProductControllerTest do
      use MyAppWeb.ConnCase

      setup do
        {:ok, conn: build_conn() |> put_req_header("accept", "application/json")}
      end

      test "GET /api/products returns list", %{conn: conn} do
        conn = get(conn, ~p"/api/products")
        assert is_list(json_response(conn, 200)["data"])
      end

      test "POST /api/products creates product", %{conn: conn} do
        conn = post(conn, ~p"/api/products", %{
          "product" => %{"name" => "Widget", "price" => 999}
        })
        assert %{"id" => id, "name" => "Widget"} =
                 json_response(conn, 201)["data"]
      end
    end

    # --- Auth Helpers (test/support/conn_case.ex) ---
    def register_and_log_in_user(%{conn: conn}) do
      user = AccountsFixtures.user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    defp log_in_user(conn, user) do
      token = MyApp.Accounts.generate_user_session_token(user)
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, token)
    end

    # --- Key Assertions ---
    # html_response(conn, 200) =~ "text"
    # json_response(conn, 201)["key"]
    # redirected_to(conn) == ~p"/path"
    # get_flash(conn, :info) =~ "Created"
    # assert_raise Ecto.NoResultsError, fn -> ... end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "conntest")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Controller Tests</h2>
      <p class="text-gray-600 dark:text-gray-300">
        ConnTest, get/post assertions, response status — testing Phoenix controllers with ExUnit.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "assertions", "auth", "json", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-400 border-b-2 border-green-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["conntest", "setup", "basic"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-green-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">ConnTest</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Provides <code>build_conn/0</code>, <code>get/2</code>, <code>post/3</code> helpers.</p>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">No Browser</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Tests run through the full plug pipeline without a real HTTP server.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Fast</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">No external processes — controller tests run in milliseconds.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Assertions -->
      <%= if @active_tab == "assertions" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix provides rich assertion helpers for testing responses.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{assertions_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Response Assertions</p>
              <ul class="space-y-1 text-sm font-mono text-gray-600 dark:text-gray-300">
                <li>assert response.status == 200</li>
                <li>assert html_response(conn, 200)</li>
                <li>assert json_response(conn, 201)</li>
                <li>assert redirected_to(conn) == ~p"/items"</li>
                <li>assert get_flash(conn, :info)</li>
              </ul>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Form Submissions</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{form_test_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Auth Tests -->
      <%= if @active_tab == "auth" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Testing authenticated routes — log in a user in the test setup.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{auth_test_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Auth Helpers Pattern</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{auth_helpers_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Authorization Tests</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{authz_test_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- JSON API -->
      <%= if @active_tab == "json" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Testing JSON API endpoints with content-type headers and response body assertions.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{json_test_code()}</div>

          <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
            <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Testing Headers</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{headers_test_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Controller Test Suite</h4>
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
  defp tab_label("assertions"), do: "Assertions"
  defp tab_label("auth"), do: "Auth Tests"
  defp tab_label("json"), do: "JSON API Tests"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("conntest"), do: "ConnTest"
  defp topic_label("setup"), do: "Setup"
  defp topic_label("basic"), do: "Basic Test"

  defp overview_code("conntest") do
    """
    # Controller tests use Phoenix.ConnTest:
    defmodule MyAppWeb.PageControllerTest do
      use MyAppWeb.ConnCase   # sets up ConnTest + DataCase

      # ConnCase gives you:
      # - build_conn/0  -> new %Plug.Conn{}
      # - get/post/put/patch/delete helpers
      # - html_response/json_response assertions
      # - redirected_to/1

      test "GET /", %{conn: conn} do
        conn = get(conn, ~p"/")
        assert html_response(conn, 200) =~ "Welcome"
      end
    end

    # ConnCase = ConnTest + DataCase (database access)
    # Defined in test/support/conn_case.ex\
    """
    |> String.trim()
  end

  defp overview_code("setup") do
    """
    # test/support/conn_case.ex:
    defmodule MyAppWeb.ConnCase do
      use ExUnit.CaseTemplate

      using do
        quote do
          # Import ConnTest helpers:
          import Phoenix.ConnTest
          import Plug.Conn

          # Import path helpers:
          use MyAppWeb, :verified_routes

          # The endpoint to test against:
          @endpoint MyAppWeb.Endpoint
        end
      end

      setup tags do
        # Wrap each test in a transaction:
        pid = Ecto.Adapters.SQL.Sandbox.start_owner!(
          MyApp.Repo,
          shared: not tags[:async]
        )
        on_exit(fn ->
          Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
        end)

        {:ok, conn: Phoenix.ConnTest.build_conn()}
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("basic") do
    """
    defmodule MyAppWeb.ProductControllerTest do
      use MyAppWeb.ConnCase

      alias MyApp.Catalog

      describe "index" do
        test "lists all products", %{conn: conn} do
          conn = get(conn, ~p"/products")
          assert html_response(conn, 200) =~ "Products"
        end
      end

      describe "show" do
        test "shows a product", %{conn: conn} do
          product = Catalog.create_product!(%{
            name: "Widget",
            price: 9_99
          })
          conn = get(conn, ~p"/products/\#{product.id}")
          assert html_response(conn, 200) =~ "Widget"
        end

        test "404 for missing product", %{conn: conn} do
          assert_raise Ecto.NoResultsError, fn ->
            get(conn, ~p"/products/99999")
          end
        end
      end
    end\
    """
    |> String.trim()
  end

  defp assertions_code do
    """
    # HTTP method helpers:
    conn = get(conn, ~p"/products")
    conn = post(conn, ~p"/products", %{product: %{name: "Foo"}})
    conn = put(conn, ~p"/products/1", %{product: %{name: "Bar"}})
    conn = patch(conn, ~p"/products/1/toggle", %{})
    conn = delete(conn, ~p"/products/1")

    # Response assertions:
    assert html_response(conn, 200) =~ "text in page"
    assert html_response(conn, 200) =~ ~r/regex pattern/

    assert json_response(conn, 200) == %{"id" => 1, "name" => "Foo"}
    assert json_response(conn, 201)["name"] == "Foo"

    assert text_response(conn, 200) =~ "plain text"

    # Redirect:
    assert redirected_to(conn) == ~p"/products"
    assert redirected_to(conn, 301) == "https://example.com"

    # Flash messages:
    assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Created"
    assert get_flash(conn, :error) =~ "Not authorized"

    # Response code only:
    assert conn.status == 200\
    """
    |> String.trim()
  end

  defp form_test_code do
    """
    test "creates product with valid params", %{conn: conn} do
      conn = post(conn, ~p"/products", %{
        "product" => %{
          "name" => "Widget",
          "price" => "9.99",
          "description" => "A fine widget"
        }
      })

      # Should redirect to the new product:
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/products/\#{id}"

      # Follow the redirect:
      conn = get(recycle(conn), ~p"/products/\#{id}")
      assert html_response(conn, 200) =~ "Widget"
    end

    test "shows errors with invalid params", %{conn: conn} do
      conn = post(conn, ~p"/products", %{
        "product" => %{"name" => ""}  # invalid: blank name
      })
      assert html_response(conn, 422) =~ "can't be blank"
    end\
    """
    |> String.trim()
  end

  defp auth_test_code do
    """
    defmodule MyAppWeb.OrderControllerTest do
      use MyAppWeb.ConnCase

      import MyApp.AccountsFixtures  # generated by gen.auth

      describe "index (authenticated)" do
        setup :register_and_log_in_user

        test "shows user's orders", %{conn: conn, user: user} do
          # user is logged in via the setup
          order = OrderFixtures.create_order(user_id: user.id)
          conn = get(conn, ~p"/orders")
          assert html_response(conn, 200) =~ "My Orders"
        end
      end

      describe "index (unauthenticated)" do
        test "redirects to login", %{conn: conn} do
          conn = get(conn, ~p"/orders")
          assert redirected_to(conn) == ~p"/users/log_in"
        end
      end
    end\
    """
    |> String.trim()
  end

  defp auth_helpers_code do
    """
    # test/support/conn_case.ex — add setup helper:
    def register_and_log_in_user(%{conn: conn}) do
      user = AccountsFixtures.user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    defp log_in_user(conn, user) do
      token = MyApp.Accounts.generate_user_session_token(user)
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, token)
    end

    # Or use phx.gen.auth generated helpers:
    # test/support/fixtures/accounts_fixtures.ex
    # test/support/conn_case.ex (updated by gen.auth)\
    """
    |> String.trim()
  end

  defp authz_test_code do
    """
    test "cannot delete another user's order", context do
      %{conn: conn} = context
      other_user = AccountsFixtures.user_fixture()
      order = OrderFixtures.create_order(user_id: other_user.id)

      conn = delete(conn, ~p"/orders/\#{order.id}")

      # Should be forbidden or redirect:
      assert redirected_to(conn) == ~p"/orders"
      assert get_flash(conn, :error) =~ "Not authorized"
    end\
    """
    |> String.trim()
  end

  defp json_test_code do
    """
    defmodule MyAppWeb.Api.ProductControllerTest do
      use MyAppWeb.ConnCase

      setup do
        {:ok, conn: build_conn()
               |> put_req_header("accept", "application/json")}
      end

      test "GET /api/products returns list", %{conn: conn} do
        conn = get(conn, ~p"/api/products")
        response = json_response(conn, 200)

        assert is_list(response["data"])
      end

      test "POST /api/products creates product", %{conn: conn} do
        conn = post(conn, ~p"/api/products", %{
          "product" => %{
            "name" => "Widget",
            "price" => 999
          }
        })

        assert %{"id" => id, "name" => "Widget"} =
                 json_response(conn, 201)["data"]
        assert id > 0
      end

      test "POST /api/products with invalid data", %{conn: conn} do
        conn = post(conn, ~p"/api/products", %{
          "product" => %{"name" => ""}
        })

        assert %{"errors" => errors} = json_response(conn, 422)
        assert errors["name"] == ["can't be blank"]
      end
    end\
    """
    |> String.trim()
  end

  defp headers_test_code do
    """
    # Test response headers:
    test "sets correct content-type", %{conn: conn} do
      conn = get(conn, ~p"/api/products")
      assert get_resp_header(conn, "content-type") ==
               ["application/json; charset=utf-8"]
    end

    # Set request headers:
    conn = conn
      |> put_req_header("authorization", "Bearer token123")
      |> put_req_header("accept", "application/json")
      |> get(~p"/api/me")

    # Test custom headers:
    test "API key auth", %{conn: conn} do
      conn = conn
        |> put_req_header("x-api-key", "secret")
        |> get(~p"/api/data")
      assert json_response(conn, 200)
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyAppWeb.PostControllerTest do
      use MyAppWeb.ConnCase

      import MyApp.AccountsFixtures
      alias MyApp.Blog

      # Shared fixtures:
      @create_attrs %{title: "Test Post", body: "Content here"}
      @update_attrs %{title: "Updated Title"}
      @invalid_attrs %{title: "", body: ""}

      setup :register_and_log_in_user

      describe "index" do
        test "lists all posts", %{conn: conn} do
          conn = get(conn, ~p"/posts")
          assert html_response(conn, 200) =~ "Posts"
        end
      end

      describe "new" do
        test "renders form", %{conn: conn} do
          conn = get(conn, ~p"/posts/new")
          assert html_response(conn, 200) =~ "New Post"
        end
      end

      describe "create" do
        test "redirects when valid", %{conn: conn} do
          conn = post(conn, ~p"/posts", post: @create_attrs)
          assert %{id: id} = redirected_params(conn)
          assert redirected_to(conn) == ~p"/posts/\#{id}"

          conn = get(recycle(conn), ~p"/posts/\#{id}")
          assert html_response(conn, 200) =~ "Test Post"
        end

        test "shows errors when invalid", %{conn: conn} do
          conn = post(conn, ~p"/posts", post: @invalid_attrs)
          assert html_response(conn, 422) =~ "can't be blank"
        end
      end

      describe "delete" do
        setup [:create_post]

        test "deletes post", %{conn: conn, post: post} do
          conn = delete(conn, ~p"/posts/\#{post}")
          assert redirected_to(conn) == ~p"/posts"

          assert_raise Ecto.NoResultsError, fn ->
            get(recycle(conn), ~p"/posts/\#{post}")
          end
        end
      end

      defp create_post(%{user: user}) do
        post = Blog.create_post!(Map.put(@create_attrs, :user_id, user.id))
        %{post: post}
      end
    end\
    """
    |> String.trim()
  end
end
