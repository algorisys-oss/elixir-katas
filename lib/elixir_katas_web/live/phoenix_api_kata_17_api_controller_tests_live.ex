defmodule ElixirKatasWeb.PhoenixApiKata17ApiControllerTestsLive do
  use ElixirKatasWeb, :live_component

  @test_scenarios [
    %{
      id: "index",
      name: "List Resources (index)",
      method: "GET",
      path: "/api/posts",
      description: "Test that GET /api/posts returns a JSON list of posts",
      test_code: """
      test "lists all posts", %{conn: conn} do
        insert(:post, title: "First Post")
        insert(:post, title: "Second Post")

        conn = get(conn, ~p"/api/posts")

        assert %{"data" => posts} = json_response(conn, 200)
        assert length(posts) == 2
        assert Enum.any?(posts, &(&1["title"] == "First Post"))
      end\
      """,
      assertions: [
        "json_response(conn, 200) -- parses JSON and asserts 200 status",
        "Pattern match on the response structure",
        "Verify the list length and contents"
      ],
      helpers_used: ["get/2", "json_response/2", "insert/2 (factory)"]
    },
    %{
      id: "show",
      name: "Get Single Resource (show)",
      method: "GET",
      path: "/api/posts/:id",
      description: "Test that GET /api/posts/:id returns the post or 404",
      test_code: """
      test "returns a post by id", %{conn: conn} do
        post = insert(:post, title: "My Post")

        conn = get(conn, ~p"/api/posts/\#{post.id}")

        assert %{
          "data" => %{
            "id" => id,
            "title" => "My Post"
          }
        } = json_response(conn, 200)

        assert id == post.id
      end

      test "returns 404 for non-existent post", %{conn: conn} do
        conn = get(conn, ~p"/api/posts/999999")
        assert json_response(conn, 404)
      end\
      """,
      assertions: [
        "json_response(conn, 200) -- parses and asserts status",
        "Pattern match on nested JSON structure",
        "json_response(conn, 404) -- asserts not found"
      ],
      helpers_used: ["get/2", "json_response/2"]
    },
    %{
      id: "create",
      name: "Create Resource (create)",
      method: "POST",
      path: "/api/posts",
      description: "Test that POST /api/posts creates a new post and returns 201",
      test_code: """
      test "creates post with valid data", %{conn: conn} do
        attrs = %{title: "New Post", body: "Content here"}

        conn =
          conn
          |> put_req_header("content-type", "application/json")
          |> post(~p"/api/posts", %{post: attrs})

        assert %{"data" => %{"id" => id}} =
          json_response(conn, 201)

        assert id != nil
      end\
      """,
      assertions: [
        "json_response(conn, 201) -- asserts 201 Created status",
        "Returned data includes the new resource's ID",
        "put_req_header sets Content-Type for JSON"
      ],
      helpers_used: ["post/3", "put_req_header/3", "json_response/2"]
    },
    %{
      id: "create_errors",
      name: "Create with Validation Errors",
      method: "POST",
      path: "/api/posts",
      description: "Test that POST with invalid data returns 422 with error details",
      test_code: """
      test "returns errors with invalid data", %{conn: conn} do
        # Missing required fields
        conn =
          conn
          |> put_req_header("content-type", "application/json")
          |> post(~p"/api/posts", %{post: %{}})

        assert %{"errors" => errors} =
          json_response(conn, 422)

        assert %{"title" => ["can't be blank"]} = errors
      end

      test "returns errors for duplicate title", %{conn: conn} do
        insert(:post, title: "Taken")

        conn =
          conn
          |> put_req_header("content-type", "application/json")
          |> post(~p"/api/posts", %{post: %{title: "Taken"}})

        assert %{"errors" => %{"title" => ["has already been taken"]}} =
          json_response(conn, 422)
      end\
      """,
      assertions: [
        "json_response(conn, 422) -- asserts Unprocessable Entity",
        "Error response follows a consistent structure",
        "Pattern match on specific validation messages"
      ],
      helpers_used: ["post/3", "put_req_header/3", "json_response/2"]
    },
    %{
      id: "delete",
      name: "Delete Resource (delete)",
      method: "DELETE",
      path: "/api/posts/:id",
      description: "Test that DELETE /api/posts/:id removes the resource",
      test_code: """
      test "deletes the post", %{conn: conn} do
        post = insert(:post, title: "To Delete")

        conn = delete(conn, ~p"/api/posts/\#{post.id}")

        assert response(conn, 204)

        # Verify it's gone
        conn = get(build_conn(), ~p"/api/posts/\#{post.id}")
        assert json_response(conn, 404)
      end

      test "returns 404 when post does not exist", %{conn: conn} do
        conn = delete(conn, ~p"/api/posts/999999")
        assert json_response(conn, 404)
      end\
      """,
      assertions: [
        "response(conn, 204) -- asserts No Content (empty body)",
        "Follow-up GET confirms resource is deleted",
        "404 for deleting non-existent resource"
      ],
      helpers_used: ["delete/2", "response/2", "build_conn/0", "get/2"]
    }
  ]

  def phoenix_source do
    """
    # API Controller Tests with Phoenix.ConnTest
    #
    # Phoenix provides ConnTest helpers for testing controllers.
    # Each test builds a conn, sends a request, and asserts on the response.

    defmodule MyAppWeb.Api.PostControllerTest do
      use MyAppWeb.ConnCase

      # ConnCase provides: build_conn(), get(), post(), put(), delete(),
      # json_response(), response(), put_req_header(), etc.

      # Setup: create a conn with JSON headers
      setup do
        conn =
          build_conn()
          |> put_req_header("accept", "application/json")

        {:ok, conn: conn}
      end

      describe "GET /api/posts" do
        test "lists all posts", %{conn: conn} do
          insert(:post, title: "First Post")
          insert(:post, title: "Second Post")

          conn = get(conn, ~p"/api/posts")

          assert %{"data" => posts} = json_response(conn, 200)
          assert length(posts) == 2
        end

        test "returns empty list when no posts", %{conn: conn} do
          conn = get(conn, ~p"/api/posts")
          assert %{"data" => []} = json_response(conn, 200)
        end
      end

      describe "GET /api/posts/:id" do
        test "returns a post by id", %{conn: conn} do
          post = insert(:post, title: "My Post")
          conn = get(conn, ~p"/api/posts/\#{post.id}")

          assert %{"data" => %{"id" => _, "title" => "My Post"}} =
            json_response(conn, 200)
        end

        test "returns 404 for non-existent post", %{conn: conn} do
          conn = get(conn, ~p"/api/posts/999999")
          assert json_response(conn, 404)
        end
      end

      describe "POST /api/posts" do
        test "creates post with valid data", %{conn: conn} do
          attrs = %{title: "New Post", body: "Content"}

          conn = post(conn, ~p"/api/posts", %{post: attrs})

          assert %{"data" => %{"id" => id}} =
            json_response(conn, 201)
          assert id != nil
        end

        test "returns errors with invalid data", %{conn: conn} do
          conn = post(conn, ~p"/api/posts", %{post: %{}})

          assert %{"errors" => errors} =
            json_response(conn, 422)
          assert errors["title"] != nil
        end
      end

      describe "DELETE /api/posts/:id" do
        test "deletes the post", %{conn: conn} do
          post = insert(:post, title: "To Delete")
          conn = delete(conn, ~p"/api/posts/\#{post.id}")
          assert response(conn, 204)
        end
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(scenarios: @test_scenarios)
     |> assign(selected_scenario: nil)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">API Controller Tests</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Explore testing patterns for Phoenix API controllers. Pick a test scenario to see the test code,
        assertions, and which <code>ConnTest</code> helpers are used.
      </p>

      <!-- ConnTest Helpers Reference -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Key ConnTest Helpers</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-900/50">
            <div class="font-mono text-sm font-semibold text-rose-600 dark:text-rose-400">get(conn, path)</div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Sends a GET request through the router</p>
          </div>
          <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-900/50">
            <div class="font-mono text-sm font-semibold text-rose-600 dark:text-rose-400">post(conn, path, params)</div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Sends a POST request with params as body</p>
          </div>
          <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-900/50">
            <div class="font-mono text-sm font-semibold text-rose-600 dark:text-rose-400">json_response(conn, status)</div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Asserts status and parses JSON response body</p>
          </div>
          <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-900/50">
            <div class="font-mono text-sm font-semibold text-rose-600 dark:text-rose-400">response(conn, status)</div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Asserts status and returns raw body (for 204, etc.)</p>
          </div>
          <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-900/50">
            <div class="font-mono text-sm font-semibold text-rose-600 dark:text-rose-400">put_req_header(conn, k, v)</div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Adds a request header (Authorization, Content-Type)</p>
          </div>
          <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-900/50">
            <div class="font-mono text-sm font-semibold text-rose-600 dark:text-rose-400">build_conn()</div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Creates a fresh test conn (useful after first request)</p>
          </div>
        </div>
      </div>

      <!-- Scenario Selector -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Pick a Test Scenario</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          <%= for scenario <- @scenarios do %>
            <button
              phx-click="select_scenario"
              phx-value-id={scenario.id}
              phx-target={@myself}
              class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
                if(@selected_scenario && @selected_scenario.id == scenario.id,
                  do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                  else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
              ]}
            >
              <div class="flex items-center gap-2 mb-1">
                <span class={["px-2 py-0.5 rounded text-xs font-bold font-mono", method_color(scenario.method)]}>
                  {scenario.method}
                </span>
                <span class="font-mono text-xs text-gray-500 dark:text-gray-400">{scenario.path}</span>
              </div>
              <div class="font-semibold text-sm text-gray-900 dark:text-white">{scenario.name}</div>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Selected Scenario Details -->
      <%= if @selected_scenario do %>
        <div class="space-y-4">
          <!-- Description -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <div class="flex items-center gap-3 mb-3">
              <span class={["px-3 py-1 rounded text-sm font-bold font-mono", method_color(@selected_scenario.method)]}>
                {@selected_scenario.method}
              </span>
              <span class="font-mono text-gray-900 dark:text-white">{@selected_scenario.path}</span>
            </div>
            <p class="text-gray-600 dark:text-gray-300">{@selected_scenario.description}</p>
          </div>

          <!-- Test Code -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Test Code</h3>
            <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
              <pre class="text-sm text-gray-100 whitespace-pre-wrap">{@selected_scenario.test_code}</pre>
            </div>
          </div>

          <!-- Assertions Breakdown -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Key Assertions</h3>
            <div class="space-y-2">
              <%= for assertion <- @selected_scenario.assertions do %>
                <div class="flex items-start gap-3 p-3 rounded-lg bg-emerald-50 dark:bg-emerald-900/10">
                  <svg class="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                  <span class="text-sm text-gray-700 dark:text-gray-300">{assertion}</span>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Helpers Used -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">ConnTest Helpers Used</h3>
            <div class="flex flex-wrap gap-2">
              <%= for helper <- @selected_scenario.helpers_used do %>
                <span class="px-3 py-1.5 bg-rose-100 dark:bg-rose-900/30 text-rose-700 dark:text-rose-400 rounded-lg text-sm font-mono">
                  {helper}
                </span>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Test Setup Pattern -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">The Test Setup Pattern</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">1. Setup</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Build a conn with JSON headers in <code>setup</code>. Use factories to insert test data.
              Each test gets a clean database via Sandbox.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">2. Action</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Use ConnTest helpers: <code>get/2</code>, <code>post/3</code>, <code>put/3</code>,
              <code>delete/2</code>. These dispatch through the router.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">3. Assert</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Use <code>json_response/2</code> to parse JSON and assert status.
              Pattern match on the response to verify structure and values.
            </p>
          </div>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Test the Contract, Not the Implementation</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          API controller tests should verify the HTTP contract: status codes, response structure, and headers.
          Don't test internal implementation details -- that belongs in context or unit tests.
          A good controller test catches routing, serialization, and status code regressions.
        </p>
      </div>
    </div>
    """
  end

  def handle_event("select_scenario", %{"id" => id}, socket) do
    scenario = Enum.find(@test_scenarios, &(&1.id == id))
    {:noreply, assign(socket, selected_scenario: scenario)}
  end

  defp method_color("GET"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp method_color("POST"), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp method_color("PUT"), do: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400"
  defp method_color("DELETE"), do: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
  defp method_color(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"
end
