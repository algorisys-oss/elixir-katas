defmodule ElixirKatasWeb.PhoenixApiKata09RoleBasedAccessLive do
  use ElixirKatasWeb, :live_component

  @users [
    %{id: 1, name: "Alice", email: "alice@example.com", role: "admin", avatar: "A"},
    %{id: 2, name: "Bob", email: "bob@example.com", role: "editor", avatar: "B"},
    %{id: 3, name: "Carol", email: "carol@example.com", role: "viewer", avatar: "C"}
  ]

  @endpoints [
    %{method: "GET", path: "/api/users", action: "List all users", required_role: "viewer"},
    %{method: "GET", path: "/api/users/:id", action: "View a user", required_role: "viewer"},
    %{method: "POST", path: "/api/users", action: "Create a user", required_role: "admin"},
    %{method: "PUT", path: "/api/users/:id", action: "Update a user", required_role: "editor"},
    %{method: "DELETE", path: "/api/users/:id", action: "Delete a user", required_role: "admin"},
    %{method: "GET", path: "/api/posts", action: "List posts", required_role: "viewer"},
    %{method: "POST", path: "/api/posts", action: "Create a post", required_role: "editor"},
    %{method: "DELETE", path: "/api/posts/:id", action: "Delete a post", required_role: "admin"},
    %{method: "GET", path: "/api/admin/stats", action: "View admin dashboard", required_role: "admin"}
  ]

  @role_hierarchy %{"admin" => 3, "editor" => 2, "viewer" => 1}

  def phoenix_source do
    """
    # Role-Based Access Control (RBAC) Plug
    #
    # Checks if the authenticated user has the required role
    # to access the current route. Runs AFTER the auth plug.

    defmodule MyAppWeb.Plugs.RequireRole do
      @behaviour Plug
      import Plug.Conn

      @role_hierarchy %{"admin" => 3, "editor" => 2, "viewer" => 1}

      # init/1 receives the required role from the plug declaration
      def init(role) when is_binary(role), do: role

      # call/2 checks if the user's role is >= the required role
      def call(conn, required_role) do
        user = conn.assigns[:current_user]

        if user && has_role?(user.role, required_role) do
          conn  # User has permission — continue
        else
          conn
          |> put_status(:forbidden)
          |> Phoenix.Controller.json(%{
            errors: %{detail: "Forbidden — requires \#{required_role} role"}
          })
          |> halt()
        end
      end

      defp has_role?(user_role, required_role) do
        user_level = Map.get(@role_hierarchy, user_role, 0)
        required_level = Map.get(@role_hierarchy, required_role, 0)
        user_level >= required_level
      end
    end

    # Using in the router with scope-based pipelines:
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :api_auth do
        plug MyAppWeb.Plugs.VerifyApiToken
      end

      pipeline :require_admin do
        plug MyAppWeb.Plugs.RequireRole, "admin"
      end

      pipeline :require_editor do
        plug MyAppWeb.Plugs.RequireRole, "editor"
      end

      # Public API
      scope "/api", MyAppWeb.Api do
        pipe_through [:api, :api_auth]

        # Viewers can read
        get "/users", UserController, :index
        get "/users/:id", UserController, :show
        get "/posts", PostController, :index
      end

      # Editor routes
      scope "/api", MyAppWeb.Api do
        pipe_through [:api, :api_auth, :require_editor]

        post "/posts", PostController, :create
        put "/users/:id", UserController, :update
      end

      # Admin-only routes
      scope "/api", MyAppWeb.Api do
        pipe_through [:api, :api_auth, :require_admin]

        post "/users", UserController, :create
        delete "/users/:id", UserController, :delete
        delete "/posts/:id", PostController, :delete
      end

      # Admin dashboard
      scope "/api/admin", MyAppWeb.Api.Admin do
        pipe_through [:api, :api_auth, :require_admin]

        get "/stats", StatsController, :index
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(users: @users)
     |> assign(endpoints: @endpoints)
     |> assign(selected_user: nil)
     |> assign(selected_endpoint: nil)
     |> assign(access_result: nil)
     |> assign(pipeline_step: 0)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Role-Based Access Control</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Pick a user with a role, then pick an API endpoint. Watch the <code>RequireRole</code> plug
        decide whether to grant or deny access (403 Forbidden).
      </p>

      <!-- Step 1: Pick a User -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">1. Pick a User</h3>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <%= for user <- @users do %>
            <button
              phx-click="select_user"
              phx-value-id={user.id}
              phx-target={@myself}
              class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
                if(@selected_user && @selected_user.id == user.id,
                  do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                  else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
              ]}
            >
              <div class="flex items-center gap-3">
                <div class={["w-10 h-10 rounded-full flex items-center justify-center font-bold text-white text-sm",
                  role_avatar_color(user.role)
                ]}>
                  {user.avatar}
                </div>
                <div>
                  <div class="font-semibold text-gray-900 dark:text-white">{user.name}</div>
                  <div class="flex items-center gap-1.5">
                    <span class={["px-2 py-0.5 rounded-full text-xs font-semibold", role_badge_class(user.role)]}>
                      {user.role}
                    </span>
                    <span class="text-xs text-gray-400">level {role_level(user.role)}</span>
                  </div>
                </div>
              </div>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Role Hierarchy -->
      <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Role Hierarchy (higher includes lower)</h4>
        <div class="flex items-center gap-2">
          <span class="px-3 py-1 rounded-full text-xs font-semibold bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400">viewer (1)</span>
          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
          <span class="px-3 py-1 rounded-full text-xs font-semibold bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400">editor (2)</span>
          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
          <span class="px-3 py-1 rounded-full text-xs font-semibold bg-rose-100 dark:bg-rose-900/30 text-rose-700 dark:text-rose-400">admin (3)</span>
        </div>
      </div>

      <!-- Step 2: Pick an Endpoint -->
      <%= if @selected_user do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">
            2. Pick an Endpoint (as {@selected_user.name}, role: {@selected_user.role})
          </h3>
          <div class="space-y-2">
            <%= for {ep, i} <- Enum.with_index(@endpoints) do %>
              <% allowed = role_allowed?(@selected_user.role, ep.required_role) %>
              <button
                phx-click="select_endpoint"
                phx-value-index={i}
                phx-target={@myself}
                class={["w-full text-left p-3 rounded-lg border-2 transition-all cursor-pointer",
                  if(@selected_endpoint == i,
                    do: if(allowed,
                      do: "border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20 shadow-md",
                      else: "border-red-500 bg-red-50 dark:bg-red-900/20 shadow-md"),
                    else: "border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600 bg-white dark:bg-gray-800")
                ]}
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <span class={["px-2 py-0.5 rounded text-xs font-bold font-mono", method_color(ep.method)]}>
                      {ep.method}
                    </span>
                    <span class="font-mono text-sm text-gray-900 dark:text-white">{ep.path}</span>
                    <span class="text-sm text-gray-500 dark:text-gray-400">{ep.action}</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class={["px-2 py-0.5 rounded-full text-xs font-semibold", role_badge_class(ep.required_role)]}>
                      {ep.required_role}+
                    </span>
                    <%= if allowed do %>
                      <svg class="w-5 h-5 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                    <% else %>
                      <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    <% end %>
                  </div>
                </div>
              </button>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Pipeline Visualization -->
      <%= if @access_result do %>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Plug Pipeline</h3>
            <div class="flex gap-2">
              <button
                phx-click="reset_pipeline"
                phx-target={@myself}
                class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
              >
                Reset
              </button>
              <button
                phx-click="next_pipeline_step"
                phx-target={@myself}
                disabled={@pipeline_step >= length(@access_result.steps)}
                class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                  if(@pipeline_step >= length(@access_result.steps),
                    do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                    else: "bg-rose-600 hover:bg-rose-700 text-white")
                ]}
              >
                <%= if @pipeline_step == 0, do: "Start Flow", else: "Next Step" %>
              </button>
            </div>
          </div>

          <div class="space-y-3">
            <%= for {step, i} <- Enum.with_index(@access_result.steps) do %>
              <div class={["flex items-start gap-4 p-4 rounded-lg transition-all duration-300",
                cond do
                  i < @pipeline_step -> "bg-gray-50 dark:bg-gray-800 opacity-100"
                  i == @pipeline_step -> "bg-rose-50 dark:bg-rose-900/20 border-2 border-rose-300 dark:border-rose-700 shadow-md"
                  true -> "bg-gray-50 dark:bg-gray-800 opacity-30"
                end
              ]}>
                <div class={["flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                  cond do
                    i < @pipeline_step && step.status == :ok -> "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400"
                    i < @pipeline_step && step.status == :error -> "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
                    true -> "bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400"
                  end
                ]}>
                  <%= if i < @pipeline_step do %>
                    <%= if step.status == :ok do %>
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                    <% else %>
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    <% end %>
                  <% else %>
                    {i + 1}
                  <% end %>
                </div>

                <div class="flex-1 min-w-0">
                  <span class="text-xs font-semibold uppercase tracking-wide text-rose-600 dark:text-rose-400">{step.label}</span>
                  <div class="font-mono text-sm text-gray-900 dark:text-white">{step.code}</div>
                  <%= if i <= @pipeline_step do %>
                    <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">{step.detail}</div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Final Result -->
          <%= if @pipeline_step >= length(@access_result.steps) do %>
            <div class={["mt-4 p-4 rounded-lg border-2",
              if(@access_result.allowed,
                do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
                else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
            ]}>
              <div class="flex items-center gap-2 mb-2">
                <%= if @access_result.allowed do %>
                  <svg class="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                  <span class="font-bold text-emerald-800 dark:text-emerald-300">200 OK &mdash; Access Granted</span>
                <% else %>
                  <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                  </svg>
                  <span class="font-bold text-red-800 dark:text-red-300">403 Forbidden &mdash; Access Denied</span>
                <% end %>
              </div>
              <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm">
                <pre class={["whitespace-pre-wrap", if(@access_result.allowed, do: "text-emerald-400", else: "text-red-400")]}><%= @access_result.response %></pre>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Auth + Role: Two Plugs, One Pipeline</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          The auth plug (<code>VerifyApiToken</code>) runs first and assigns <code>current_user</code>.
          The role plug (<code>RequireRole</code>) runs second and checks <code>current_user.role</code>.
          If either fails, the pipeline halts. This separation of concerns keeps each plug simple and testable.
        </p>
      </div>
    </div>
    """
  end

  defp role_level(role), do: Map.get(@role_hierarchy, role, 0)

  defp role_allowed?(user_role, required_role) do
    user_level = Map.get(@role_hierarchy, user_role, 0)
    required_level = Map.get(@role_hierarchy, required_role, 0)
    user_level >= required_level
  end

  defp role_avatar_color("admin"), do: "bg-rose-600"
  defp role_avatar_color("editor"), do: "bg-blue-600"
  defp role_avatar_color("viewer"), do: "bg-emerald-600"
  defp role_avatar_color(_), do: "bg-gray-600"

  defp role_badge_class("admin"), do: "bg-rose-100 dark:bg-rose-900/30 text-rose-700 dark:text-rose-400"
  defp role_badge_class("editor"), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp role_badge_class("viewer"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp role_badge_class(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp method_color("GET"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp method_color("POST"), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp method_color("PUT"), do: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400"
  defp method_color("DELETE"), do: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
  defp method_color(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp build_access_result(user, endpoint) do
    allowed = role_allowed?(user.role, endpoint.required_role)
    user_level = Map.get(@role_hierarchy, user.role, 0)
    required_level = Map.get(@role_hierarchy, endpoint.required_role, 0)

    if allowed do
      %{
        allowed: true,
        steps: [
          %{label: "Request", code: "#{endpoint.method} #{endpoint.path}", detail: "Incoming request from #{user.name}", status: :ok},
          %{label: "Auth Plug", code: "VerifyApiToken.call(conn, opts)", detail: "Token valid — assigned current_user: #{user.name} (#{user.role})", status: :ok},
          %{label: "Role Plug", code: "RequireRole.call(conn, \"#{endpoint.required_role}\")", detail: "Check: #{user.role} (level #{user_level}) >= #{endpoint.required_role} (level #{required_level}) — PASS", status: :ok},
          %{label: "Controller", code: "#{action_module(endpoint)}", detail: "Request reaches the controller action — processing...", status: :ok}
        ],
        response: "HTTP/1.1 200 OK\nContent-Type: application/json\n\n{\n  \"data\": { ... }\n}"
      }
    else
      %{
        allowed: false,
        steps: [
          %{label: "Request", code: "#{endpoint.method} #{endpoint.path}", detail: "Incoming request from #{user.name}", status: :ok},
          %{label: "Auth Plug", code: "VerifyApiToken.call(conn, opts)", detail: "Token valid — assigned current_user: #{user.name} (#{user.role})", status: :ok},
          %{label: "Role Plug", code: "RequireRole.call(conn, \"#{endpoint.required_role}\")", detail: "Check: #{user.role} (level #{user_level}) < #{endpoint.required_role} (level #{required_level}) — FAIL", status: :error},
          %{label: "Halt", code: "conn |> put_status(:forbidden) |> halt()", detail: "Pipeline stopped. 403 Forbidden response sent.", status: :error}
        ],
        response: "HTTP/1.1 403 Forbidden\nContent-Type: application/json\n\n{\n  \"errors\": {\n    \"detail\": \"Forbidden — requires #{endpoint.required_role} role\"\n  }\n}"
      }
    end
  end

  defp action_module(%{method: "GET", path: "/api/users"}), do: "UserController.index/2"
  defp action_module(%{method: "GET", path: "/api/users/:id"}), do: "UserController.show/2"
  defp action_module(%{method: "POST", path: "/api/users"}), do: "UserController.create/2"
  defp action_module(%{method: "PUT", path: "/api/users/:id"}), do: "UserController.update/2"
  defp action_module(%{method: "DELETE", path: "/api/users/:id"}), do: "UserController.delete/2"
  defp action_module(%{method: "GET", path: "/api/posts"}), do: "PostController.index/2"
  defp action_module(%{method: "POST", path: "/api/posts"}), do: "PostController.create/2"
  defp action_module(%{method: "DELETE", path: "/api/posts/:id"}), do: "PostController.delete/2"
  defp action_module(%{method: "GET", path: "/api/admin/stats"}), do: "Admin.StatsController.index/2"
  defp action_module(_), do: "Controller.action/2"

  def handle_event("select_user", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    user = Enum.find(@users, &(&1.id == id))
    {:noreply, assign(socket, selected_user: user, selected_endpoint: nil, access_result: nil, pipeline_step: 0)}
  end

  def handle_event("select_endpoint", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    endpoint = Enum.at(@endpoints, idx)
    result = build_access_result(socket.assigns.selected_user, endpoint)
    {:noreply, assign(socket, selected_endpoint: idx, access_result: result, pipeline_step: 0)}
  end

  def handle_event("next_pipeline_step", _params, socket) do
    max = length(socket.assigns.access_result.steps)
    new_step = min(socket.assigns.pipeline_step + 1, max)
    {:noreply, assign(socket, pipeline_step: new_step)}
  end

  def handle_event("reset_pipeline", _params, socket) do
    {:noreply, assign(socket, pipeline_step: 0)}
  end
end
