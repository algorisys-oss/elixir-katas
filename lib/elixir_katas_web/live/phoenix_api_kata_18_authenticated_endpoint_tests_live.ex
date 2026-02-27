defmodule ElixirKatasWeb.PhoenixApiKata18AuthenticatedEndpointTestsLive do
  use ElixirKatasWeb, :live_component

  @test_scenarios [
    %{
      id: "valid_token",
      name: "Valid Token",
      icon: "check",
      status: :pass,
      description: "Request with a valid, non-expired Bearer token for an authorized user.",
      setup_code: """
      setup do
        user = insert(:user, role: "editor")
        token = MyApp.Auth.generate_token(user)

        conn =
          build_conn()
          |> put_req_header("accept", "application/json")
          |> put_req_header("authorization", "Bearer \#{token}")

        {:ok, conn: conn, user: user}
      end\
      """,
      test_code: """
      test "returns posts for authenticated user", %{conn: conn} do
        insert(:post, title: "My Post")

        conn = get(conn, ~p"/api/posts")

        assert %{"data" => [%{"title" => "My Post"}]} =
          json_response(conn, 200)
      end

      test "conn has current_user assigned", %{conn: conn, user: user} do
        conn = get(conn, ~p"/api/posts")
        # After the auth plug runs, current_user is set
        assert conn.assigns.current_user.id == user.id
      end\
      """,
      expected_status: "200 OK",
      badge_color: "emerald"
    },
    %{
      id: "expired_token",
      name: "Expired Token",
      icon: "clock",
      status: :fail,
      description: "Request with a token that has passed its expiration time.",
      setup_code: """
      setup do
        user = insert(:user, role: "editor")
        # Generate a token that expired 1 hour ago
        token = MyApp.Auth.generate_token(user, ttl: -3600)

        conn =
          build_conn()
          |> put_req_header("accept", "application/json")
          |> put_req_header("authorization", "Bearer \#{token}")

        {:ok, conn: conn}
      end\
      """,
      test_code: """
      test "returns 401 with expired token", %{conn: conn} do
        conn = get(conn, ~p"/api/posts")

        assert %{"errors" => %{"detail" => message}} =
          json_response(conn, 401)

        assert message =~ "expired"
      end\
      """,
      expected_status: "401 Unauthorized",
      badge_color: "red"
    },
    %{
      id: "no_token",
      name: "No Token",
      icon: "x",
      status: :fail,
      description: "Request without any Authorization header at all.",
      setup_code: """
      setup do
        conn =
          build_conn()
          |> put_req_header("accept", "application/json")
          # No authorization header!

        {:ok, conn: conn}
      end\
      """,
      test_code: """
      test "returns 401 without token", %{conn: conn} do
        conn = get(conn, ~p"/api/posts")

        assert %{"errors" => %{"detail" => "Missing authorization header"}} =
          json_response(conn, 401)
      end

      test "conn is halted", %{conn: conn} do
        conn = get(conn, ~p"/api/posts")
        assert conn.halted
      end\
      """,
      expected_status: "401 Unauthorized",
      badge_color: "red"
    },
    %{
      id: "wrong_role",
      name: "Wrong Role",
      icon: "shield",
      status: :fail,
      description: "Request with a valid token but insufficient role permissions.",
      setup_code: """
      setup do
        # User is a "viewer" but endpoint requires "admin"
        user = insert(:user, role: "viewer")
        token = MyApp.Auth.generate_token(user)

        conn =
          build_conn()
          |> put_req_header("accept", "application/json")
          |> put_req_header("authorization", "Bearer \#{token}")

        {:ok, conn: conn}
      end\
      """,
      test_code: """
      test "returns 403 when role is insufficient", %{conn: conn} do
        conn = delete(conn, ~p"/api/admin/users/1")

        assert %{"errors" => %{"detail" => message}} =
          json_response(conn, 403)

        assert message =~ "Forbidden"
      end

      test "viewer cannot access admin endpoints", %{conn: conn} do
        conn = get(conn, ~p"/api/admin/stats")
        assert json_response(conn, 403)
      end\
      """,
      expected_status: "403 Forbidden",
      badge_color: "amber"
    },
    %{
      id: "malformed_token",
      name: "Malformed Token",
      icon: "bug",
      status: :fail,
      description: "Request with a garbled or tampered Authorization header.",
      setup_code: """
      setup do
        conn =
          build_conn()
          |> put_req_header("accept", "application/json")
          |> put_req_header("authorization", "Bearer not.a.valid.token")

        {:ok, conn: conn}
      end\
      """,
      test_code: """
      test "returns 401 for malformed token", %{conn: conn} do
        conn = get(conn, ~p"/api/posts")

        assert %{"errors" => %{"detail" => message}} =
          json_response(conn, 401)

        assert message =~ "invalid"
      end

      test "rejects non-Bearer auth scheme", %{conn: conn} do
        conn =
          build_conn()
          |> put_req_header("authorization", "Basic dXNlcjpwYXNz")
          |> get(~p"/api/posts")

        assert json_response(conn, 401)
      end\
      """,
      expected_status: "401 Unauthorized",
      badge_color: "red"
    }
  ]

  @helper_approaches [
    %{
      name: "Setup Block Helper",
      description: "Create a shared setup function that inserts a user and builds an authenticated conn.",
      code: """
      defmodule MyAppWeb.ConnCase do
        # Add to your ConnCase
        def setup_auth(%{conn: conn}) do
          user = insert(:user, role: "editor")
          token = MyApp.Auth.generate_token(user)

          conn =
            conn
            |> put_req_header("authorization", "Bearer \#{token}")

          %{conn: conn, user: user, token: token}
        end
      end

      # Usage in tests:
      describe "authenticated endpoints" do
        setup [:setup_auth]

        test "works", %{conn: conn, user: user} do
          # conn already has the token
        end
      end\
      """
    },
    %{
      name: "Test Tag + Setup",
      description: "Use @tag to control which auth setup runs per test.",
      code: """
      setup context do
        conn = build_conn()
              |> put_req_header("accept", "application/json")

        case context[:auth] do
          :admin ->
            user = insert(:user, role: "admin")
            token = MyApp.Auth.generate_token(user)
            %{conn: put_req_header(conn, "authorization", "Bearer \#{token}"), user: user}

          :editor ->
            user = insert(:user, role: "editor")
            token = MyApp.Auth.generate_token(user)
            %{conn: put_req_header(conn, "authorization", "Bearer \#{token}"), user: user}

          _ ->
            %{conn: conn}
        end
      end

      @tag auth: :admin
      test "admin can delete", %{conn: conn} do
        # ...
      end

      @tag auth: :editor
      test "editor can edit", %{conn: conn} do
        # ...
      end\
      """
    },
    %{
      name: "Helper Function",
      description: "A simple function that adds auth to any conn.",
      code: """
      defp authenticate(conn, role \\\\ "editor") do
        user = insert(:user, role: role)
        token = MyApp.Auth.generate_token(user)

        conn
        |> put_req_header("authorization", "Bearer \#{token}")
        |> Plug.Conn.assign(:current_user, user)
      end

      test "editor creates post", %{conn: conn} do
        conn =
          conn
          |> authenticate("editor")
          |> post(~p"/api/posts", %{post: %{title: "New"}})

        assert json_response(conn, 201)
      end\
      """
    }
  ]

  def phoenix_source do
    """
    # Authenticated Endpoint Tests
    #
    # Testing endpoints that require authentication involves:
    # 1. Setting up test users with specific roles
    # 2. Generating valid/invalid tokens
    # 3. Attaching tokens to the test conn
    # 4. Testing all auth scenarios (valid, expired, missing, wrong role)

    defmodule MyAppWeb.Api.PostControllerTest do
      use MyAppWeb.ConnCase

      # Shared setup: build a conn with JSON headers
      setup do
        conn =
          build_conn()
          |> put_req_header("accept", "application/json")

        {:ok, conn: conn}
      end

      # Helper to authenticate a conn
      defp authenticate(conn, role \\\\ "editor") do
        user = insert(:user, role: role)
        token = MyApp.Auth.generate_token(user)

        conn
        |> put_req_header("authorization", "Bearer \#{token}")
      end

      describe "authenticated GET /api/posts" do
        test "returns posts with valid token", %{conn: conn} do
          insert(:post, title: "Test Post")

          conn =
            conn
            |> authenticate("editor")
            |> get(~p"/api/posts")

          assert %{"data" => [_]} = json_response(conn, 200)
        end

        test "returns 401 without token", %{conn: conn} do
          conn = get(conn, ~p"/api/posts")
          assert json_response(conn, 401)
        end

        test "returns 401 with expired token", %{conn: conn} do
          user = insert(:user)
          token = MyApp.Auth.generate_token(user, ttl: -3600)

          conn =
            conn
            |> put_req_header("authorization", "Bearer \#{token}")
            |> get(~p"/api/posts")

          assert json_response(conn, 401)
        end
      end

      describe "admin-only DELETE /api/posts/:id" do
        test "admin can delete", %{conn: conn} do
          post = insert(:post)

          conn =
            conn
            |> authenticate("admin")
            |> delete(~p"/api/posts/\#{post.id}")

          assert response(conn, 204)
        end

        test "editor gets 403", %{conn: conn} do
          post = insert(:post)

          conn =
            conn
            |> authenticate("editor")
            |> delete(~p"/api/posts/\#{post.id}")

          assert json_response(conn, 403)
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
     |> assign(helper_approaches: @helper_approaches)
     |> assign(selected_helper: 0)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Authenticated Endpoint Tests</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Explore how to test API endpoints that require authentication. Pick a scenario to see
        the setup block, test code, and expected response.
      </p>

      <!-- Scenario Cards -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Auth Test Scenarios</h3>
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
              <div class="flex items-center justify-between mb-2">
                <span class="font-semibold text-sm text-gray-900 dark:text-white">{scenario.name}</span>
                <span class={["px-2 py-0.5 rounded text-xs font-bold",
                  status_badge_class(scenario.badge_color)
                ]}>
                  {scenario.expected_status}
                </span>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 line-clamp-2">{scenario.description}</p>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Selected Scenario -->
      <%= if @selected_scenario do %>
        <div class="space-y-4">
          <!-- Scenario Header -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <div class="flex items-center gap-3 mb-2">
              <span class={["px-3 py-1 rounded-lg text-sm font-bold",
                status_badge_class(@selected_scenario.badge_color)
              ]}>
                {@selected_scenario.expected_status}
              </span>
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{@selected_scenario.name}</h3>
            </div>
            <p class="text-gray-600 dark:text-gray-300">{@selected_scenario.description}</p>
          </div>

          <!-- Setup Block -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">
              <span class="text-rose-600 dark:text-rose-400">setup</span> Block
            </h3>
            <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
              <pre class="text-sm text-gray-100 whitespace-pre-wrap">{@selected_scenario.setup_code}</pre>
            </div>
          </div>

          <!-- Test Code -->
          <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">
              <span class="text-rose-600 dark:text-rose-400">test</span> Block
            </h3>
            <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
              <pre class="text-sm text-gray-100 whitespace-pre-wrap">{@selected_scenario.test_code}</pre>
            </div>
          </div>

          <!-- Expected Result -->
          <div class={["p-4 rounded-lg border-2",
            if(@selected_scenario.status == :pass,
              do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
              else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
          ]}>
            <div class="flex items-center gap-2">
              <%= if @selected_scenario.status == :pass do %>
                <svg class="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="font-semibold text-emerald-800 dark:text-emerald-300">
                  Test passes -- request succeeds with {@selected_scenario.expected_status}
                </span>
              <% else %>
                <svg class="w-5 h-5 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span class="font-semibold text-red-800 dark:text-red-300">
                  Test expects {@selected_scenario.expected_status} -- auth plug rejects the request
                </span>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Auth Helper Approaches -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Auth Test Helper Approaches</h3>
        <div class="flex flex-wrap gap-2 mb-4">
          <%= for {approach, i} <- Enum.with_index(@helper_approaches) do %>
            <button
              phx-click="select_helper"
              phx-value-index={i}
              phx-target={@myself}
              class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
                if(@selected_helper == i,
                  do: "border-rose-500 bg-rose-600 text-white",
                  else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
              ]}
            >
              {approach.name}
            </button>
          <% end %>
        </div>

        <% current_helper = Enum.at(@helper_approaches, @selected_helper) %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <p class="text-gray-600 dark:text-gray-300 mb-3">{current_helper.description}</p>
          <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
            <pre class="text-sm text-gray-100 whitespace-pre-wrap">{current_helper.code}</pre>
          </div>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Test Every Auth Boundary</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          Auth-related tests should cover the full matrix: valid token, expired token, no token, wrong role,
          and malformed token. Each scenario exercises a different branch in your auth plugs.
          A missing test here can lead to security vulnerabilities.
        </p>
      </div>
    </div>
    """
  end

  def handle_event("select_scenario", %{"id" => id}, socket) do
    scenario = Enum.find(@test_scenarios, &(&1.id == id))
    {:noreply, assign(socket, selected_scenario: scenario)}
  end

  def handle_event("select_helper", %{"index" => idx_str}, socket) do
    {:noreply, assign(socket, selected_helper: String.to_integer(idx_str))}
  end

  defp status_badge_class("emerald"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp status_badge_class("red"), do: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
  defp status_badge_class("amber"), do: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400"
  defp status_badge_class(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"
end
