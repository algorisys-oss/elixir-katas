defmodule ElixirKatasWeb.PhoenixKata50ContextTestsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Context Tests — DataCase, Fixtures, Changesets

    # 1. Fixtures (test/support/fixtures/blog_fixtures.ex)
    defmodule MyApp.BlogFixtures do
      alias MyApp.Blog

      def post_fixture(attrs \\\\ %{}) do
        user = MyApp.AccountsFixtures.user_fixture()
        {:ok, post} =
          attrs
          |> Enum.into(%{
               title: "Test Post",
               body: "Some content here",
               user_id: user.id
             })
          |> Blog.create_post()
        post
      end
    end

    # 2. Context function tests
    defmodule MyApp.CatalogTest do
      use MyApp.DataCase, async: true

      import MyApp.CatalogFixtures
      alias MyApp.Catalog
      alias MyApp.Catalog.Product

      @valid_attrs %{name: "Widget", price: 999, stock: 100}

      describe "create_product/1" do
        test "with valid data creates product" do
          assert {:ok, %Product{} = product} =
            Catalog.create_product(@valid_attrs)
          assert product.name == "Widget"
          assert product.price == 999
        end

        test "with duplicate name returns error" do
          Catalog.create_product!(@valid_attrs)
          assert {:error, changeset} = Catalog.create_product(@valid_attrs)
          assert "has already been taken" in errors_on(changeset).name
        end
      end

      describe "decrease_stock/2" do
        test "decreases stock by amount" do
          product = product_fixture(stock: 10)
          assert {:ok, updated} = Catalog.decrease_stock(product, 3)
          assert updated.stock == 7
        end

        test "returns error when insufficient stock" do
          product = product_fixture(stock: 2)
          assert {:error, :insufficient_stock} =
            Catalog.decrease_stock(product, 5)
        end
      end
    end

    # 3. Changeset tests
    defmodule MyApp.Blog.PostTest do
      use MyApp.DataCase, async: true
      alias MyApp.Blog.Post

      test "changeset with valid attributes" do
        changeset = Post.changeset(%Post{}, %{title: "Hello", body: "World!"})
        assert changeset.valid?
      end

      test "changeset requires title" do
        changeset = Post.changeset(%Post{}, %{body: "content"})
        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset).title
      end
    end

    # 4. DataCase setup (test/support/data_case.ex)
    defmodule MyApp.DataCase do
      use ExUnit.CaseTemplate

      setup tags do
        pid = Ecto.Adapters.SQL.Sandbox.start_owner!(
          MyApp.Repo, shared: not tags[:async])
        on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
        :ok
      end
    end

    # async: true -> each test gets its own DB transaction
    # Tests run in parallel without interfering
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "datacase")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Context Tests</h2>
      <p class="text-gray-600 dark:text-gray-300">
        DataCase, fixtures, test helpers — testing your application's business logic context modules with ExUnit.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "fixtures", "changesets", "async", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-yellow-50 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400 border-b-2 border-yellow-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["datacase", "sandbox", "structure"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-yellow-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">DataCase</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Wraps each test in a DB transaction. Rolled back after test.</p>
            </div>
            <div class="p-4 rounded-lg bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800">
              <p class="text-sm font-semibold text-yellow-700 dark:text-yellow-300 mb-1">Sandbox</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">SQL Sandbox isolates tests. Supports async: true for parallel tests.</p>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">Fixtures</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Factory functions that create test data with sensible defaults.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Fixtures -->
      <%= if @active_tab == "fixtures" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Fixtures are simple functions that create test data. Phoenix uses a fixture-function pattern (not factory libraries by default).
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{fixtures_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Using Fixtures in Tests</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{using_fixtures_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">ExMachina (optional library)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{exmachina_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Changeset Tests -->
      <%= if @active_tab == "changesets" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Testing changesets and context functions directly — the core of context testing.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{changeset_test_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Changeset Assertions</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{changeset_assertions_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Context Function Tests</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{context_func_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Async Tests -->
      <%= if @active_tab == "async" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Running context tests asynchronously for faster test suites.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{async_code()}</div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">When Can You Use async: true?</p>
            <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
              <li>- Tests that only use the database (use DataCase)</li>
              <li>- Tests that don't write to shared global state</li>
              <li>- Tests that don't call external services</li>
              <li>- Context tests are usually a good candidate</li>
            </ul>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Context Test Example</h4>
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
  defp tab_label("fixtures"), do: "Fixtures"
  defp tab_label("changesets"), do: "Changeset Tests"
  defp tab_label("async"), do: "Async Tests"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("datacase"), do: "DataCase"
  defp topic_label("sandbox"), do: "SQL Sandbox"
  defp topic_label("structure"), do: "Test Structure"

  defp overview_code("datacase") do
    """
    # DataCase wraps each test in a DB sandbox:
    defmodule MyApp.BlogTest do
      use MyApp.DataCase   # <- this gives us DB access

      alias MyApp.Blog

      test "create_post/1 creates a post" do
        attrs = %{title: "Hello", body: "World"}
        assert {:ok, post} = Blog.create_post(attrs)
        assert post.title == "Hello"
        # DB changes are rolled back after test!
      end
    end

    # DataCase is defined in test/support/data_case.ex:
    defmodule MyApp.DataCase do
      use ExUnit.CaseTemplate

      setup tags do
        MyApp.DataCase.setup_sandbox(tags)
        :ok
      end

      def setup_sandbox(tags) do
        pid = Ecto.Adapters.SQL.Sandbox.start_owner!(
          MyApp.Repo,
          shared: not tags[:async]
        )
        ExUnit.Callbacks.on_exit(fn ->
          Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
        end)
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("sandbox") do
    """
    # SQL Sandbox modes:

    # 1. Checkout mode (default for async: false):
    #    Each test gets exclusive DB access in a transaction.
    #    Transaction is rolled back at end of test.

    # 2. Shared mode (for async: false, multi-process tests):
    #    Multiple processes can share one test's DB transaction.
    Ecto.Adapters.SQL.Sandbox.allow(
      MyApp.Repo, self(), child_pid)

    # 3. For async: true tests:
    #    Each test gets its OWN transaction (isolated).
    #    Tests run in parallel without interfering.

    # test_helper.exs — enable sandbox:
    Ecto.Adapters.SQL.Sandbox.mode(
      MyApp.Repo, :manual)

    # config/test.exs — pool size for parallel tests:
    config :my_app, MyApp.Repo,
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: System.schedulers_online() * 2\
    """
    |> String.trim()
  end

  defp overview_code("structure") do
    """
    # Standard context test structure:
    defmodule MyApp.AccountsTest do
      use MyApp.DataCase, async: true

      import MyApp.AccountsFixtures  # test data helpers

      alias MyApp.Accounts
      alias MyApp.Accounts.User

      # Group related tests with describe:
      describe "get_user!/1" do
        test "returns user for valid id" do
          user = user_fixture()  # from fixtures
          assert Accounts.get_user!(user.id) == user
        end

        test "raises for invalid id" do
          assert_raise Ecto.NoResultsError, fn ->
            Accounts.get_user!(99999)
          end
        end
      end

      describe "create_user/1" do
        test "with valid data creates user" do
          valid_attrs = %{email: "t@t.com", password: "12_char_pw!"}
          assert {:ok, %User{} = user} =
            Accounts.create_user(valid_attrs)
          assert user.email == "t@t.com"
        end

        test "with invalid data returns error" do
          assert {:error, %Ecto.Changeset{}} =
            Accounts.create_user(%{email: "bad"})
        end
      end
    end\
    """
    |> String.trim()
  end

  defp fixtures_code do
    """
    # test/support/fixtures/blog_fixtures.ex:
    defmodule MyApp.BlogFixtures do
      alias MyApp.Blog
      alias MyApp.AccountsFixtures

      # Simple fixture with defaults:
      def post_fixture(attrs \\\\ %{}) do
        user = AccountsFixtures.user_fixture()

        {:ok, post} =
          attrs
          |> Enum.into(%{
               title: "Test Post",
               body: "Some content here",
               published: false,
               user_id: user.id
             })
          |> Blog.create_post()

        post
      end

      # Fixture with related data:
      def published_post_fixture(attrs \\\\ %{}) do
        post_fixture(Map.merge(%{published: true}, attrs))
      end

      # Unique value generators:
      def unique_post_title, do: "Post \#{System.unique_integer()}"
    end\
    """
    |> String.trim()
  end

  defp using_fixtures_code do
    """
    defmodule MyApp.BlogTest do
      use MyApp.DataCase, async: true

      import MyApp.BlogFixtures

      describe "list_posts/0" do
        test "returns all posts" do
          post = post_fixture()
          assert Blog.list_posts() == [post]
        end

        test "returns empty list when no posts" do
          assert Blog.list_posts() == []
        end
      end

      describe "list_published_posts/0" do
        test "only returns published posts" do
          _draft = post_fixture(published: false)
          pub = post_fixture(published: true)

          assert Blog.list_published_posts() == [pub]
        end
      end
    end\
    """
    |> String.trim()
  end

  defp exmachina_code do
    """
    # ExMachina library (optional, but popular):
    # add {:ex_machina, "~> 2.7", only: :test} to mix.exs

    defmodule MyApp.Factory do
      use ExMachina.Ecto, repo: MyApp.Repo

      def user_factory do
        %MyApp.Accounts.User{
          email: sequence(:email, &"user\#{&1}@example.com"),
          hashed_password: Bcrypt.hash_pwd_salt("password123!")
        }
      end

      def post_factory do
        %MyApp.Blog.Post{
          title: sequence("Post title"),
          body: "Lorem ipsum...",
          user: build(:user)
        }
      end
    end

    # Usage:
    # insert(:user)
    # insert(:post, title: "Custom Title")
    # build(:user, email: "custom@test.com")\
    """
    |> String.trim()
  end

  defp changeset_test_code do
    """
    defmodule MyApp.Blog.PostTest do
      use MyApp.DataCase, async: true

      alias MyApp.Blog.Post

      @valid_attrs %{title: "Hello", body: "World!"}
      @invalid_attrs %{title: "", body: ""}

      test "changeset with valid attributes" do
        changeset = Post.changeset(%Post{}, @valid_attrs)
        assert changeset.valid?
      end

      test "changeset requires title" do
        changeset = Post.changeset(%Post{}, %{body: "content"})
        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset).title
      end

      test "changeset validates title length" do
        changeset = Post.changeset(%Post{}, %{
          title: String.duplicate("a", 201),
          body: "ok"
        })
        refute changeset.valid?
        assert "should be at most 200 character(s)" in
                 errors_on(changeset).title
      end

      test "changeset validates unique title" do
        post_fixture(title: "Duplicate")
        changeset = Post.changeset(%Post{}, %{
          title: "Duplicate", body: "body"
        })
        {:error, changeset} = Repo.insert(changeset)
        assert "has already been taken" in
                 errors_on(changeset).title
      end
    end\
    """
    |> String.trim()
  end

  defp changeset_assertions_code do
    """
    # DataCase provides errors_on/1 helper:
    # Returns a map of field -> list of error strings

    # Check a field has a specific error:
    errors = errors_on(changeset)
    assert "can't be blank" in errors.email
    assert "is invalid" in errors.price

    # Check no errors on a field:
    refute errors[:name]

    # Check the whole changeset is valid:
    assert changeset.valid?
    refute changeset.valid?

    # Check specific error on changeset (without helper):
    assert changeset.errors[:email] ==
      {"can't be blank", [validation: :required]}\
    """
    |> String.trim()
  end

  defp context_func_code do
    """
    describe "update_post/2" do
      test "updates with valid data" do
        post = post_fixture()

        assert {:ok, updated} = Blog.update_post(
          post, %{title: "New Title"})

        assert updated.title == "New Title"
        # Reload from DB to verify:
        assert Repo.get!(Post, post.id).title == "New Title"
      end

      test "returns error with invalid data" do
        post = post_fixture()

        assert {:error, changeset} =
          Blog.update_post(post, %{title: ""})

        # Original unchanged:
        assert Repo.get!(Post, post.id).title == post.title
      end
    end\
    """
    |> String.trim()
  end

  defp async_code do
    """
    # Context tests can run async because each test gets
    # its own DB transaction via SQL Sandbox:

    defmodule MyApp.AccountsTest do
      use MyApp.DataCase, async: true  # <- parallel!

      # These tests run concurrently with other async: true tests
    end

    defmodule MyApp.BlogTest do
      use MyApp.DataCase, async: true

      # Also runs in parallel
    end

    # ConnCase tests should NOT be async: true by default
    # (they use shared mode for the whole request pipeline)
    defmodule MyAppWeb.PostControllerTest do
      use MyAppWeb.ConnCase  # async: false by default
    end

    # To run tests:
    # mix test                    # all tests
    # mix test test/my_app/       # only context tests
    # mix test --seed 0           # deterministic order
    # mix test --max-failures 5   # stop after 5 failures\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete context test example:
    defmodule MyApp.CatalogTest do
      use MyApp.DataCase, async: true

      import MyApp.CatalogFixtures
      alias MyApp.Catalog
      alias MyApp.Catalog.Product

      @valid_attrs %{
        name: "Widget",
        description: "A nice widget",
        price: 999,       # cents
        stock: 100
      }

      describe "list_products/0" do
        test "returns empty list" do
          assert Catalog.list_products() == []
        end

        test "returns all products" do
          p1 = product_fixture(name: "A")
          p2 = product_fixture(name: "B")
          assert Catalog.list_products() == [p1, p2]
        end
      end

      describe "get_product!/1" do
        test "returns product" do
          product = product_fixture()
          assert Catalog.get_product!(product.id).id == product.id
        end

        test "raises for invalid id" do
          assert_raise Ecto.NoResultsError, fn ->
            Catalog.get_product!(0)
          end
        end
      end

      describe "create_product/1" do
        test "with valid data creates product" do
          assert {:ok, %Product{} = product} =
            Catalog.create_product(@valid_attrs)
          assert product.name == "Widget"
          assert product.price == 999
        end

        test "with invalid price returns error" do
          attrs = Map.put(@valid_attrs, :price, -1)
          assert {:error, changeset} =
            Catalog.create_product(attrs)
          assert "must be greater than 0" in
                   errors_on(changeset).price
        end

        test "with duplicate name returns error" do
          Catalog.create_product!(@valid_attrs)
          assert {:error, changeset} =
            Catalog.create_product(@valid_attrs)
          assert "has already been taken" in
                   errors_on(changeset).name
        end
      end

      describe "decrease_stock/2" do
        test "decreases stock by amount" do
          product = product_fixture(stock: 10)
          assert {:ok, updated} =
            Catalog.decrease_stock(product, 3)
          assert updated.stock == 7
        end

        test "returns error when insufficient stock" do
          product = product_fixture(stock: 2)
          assert {:error, :insufficient_stock} =
            Catalog.decrease_stock(product, 5)
        end
      end
    end\
    """
    |> String.trim()
  end
end
