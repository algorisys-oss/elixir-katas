defmodule ElixirKatasWeb.PhoenixApiKata10PolicyModulesLive do
  use ElixirKatasWeb, :live_component

  @users [
    %{id: 1, name: "Alice", role: "admin", avatar: "A"},
    %{id: 2, name: "Bob", role: "editor", avatar: "B"},
    %{id: 3, name: "Carol", role: "viewer", avatar: "C"}
  ]

  @resources [
    %{type: "post", id: 101, title: "Elixir Tips", owner_id: 2, published: true},
    %{type: "post", id: 102, title: "Draft Post", owner_id: 3, published: false},
    %{type: "comment", id: 201, body: "Great article!", owner_id: 3, post_id: 101},
    %{type: "comment", id: 202, body: "Thanks!", owner_id: 2, post_id: 101}
  ]

  @actions ["view", "edit", "delete", "publish"]

  def phoenix_source do
    """
    # Policy Modules — Resource-Level Authorization
    #
    # Policies decide: "Can THIS user perform THIS action on THIS resource?"
    # Unlike role-based plugs, policies check ownership, resource state, etc.

    defmodule MyApp.Policy do
      @moduledoc "Central authorization — authorize(user, action, resource)"

      # Admin override: admins can do anything
      def authorize(%{role: "admin"}, _action, _resource), do: :ok

      # --- Post Policies ---

      # Anyone can view published posts
      def authorize(_user, :view, %Post{published: true}), do: :ok

      # Owners and editors can view their own drafts
      def authorize(%{id: uid}, :view, %Post{owner_id: uid}), do: :ok
      def authorize(%{role: "editor"}, :view, %Post{}), do: :ok

      # Only the owner or editors can edit a post
      def authorize(%{id: uid}, :edit, %Post{owner_id: uid}), do: :ok
      def authorize(%{role: "editor"}, :edit, %Post{}), do: :ok

      # Only the owner can delete their own post
      def authorize(%{id: uid}, :delete, %Post{owner_id: uid}), do: :ok

      # Only editors+ can publish
      def authorize(%{role: "editor"}, :publish, %Post{}), do: :ok

      # --- Comment Policies ---

      # Anyone can view comments
      def authorize(_user, :view, %Comment{}), do: :ok

      # Only the comment author can edit their comment
      def authorize(%{id: uid}, :edit, %Comment{owner_id: uid}), do: :ok

      # Comment author or post owner can delete a comment
      def authorize(%{id: uid}, :delete, %Comment{owner_id: uid}), do: :ok

      # Catch-all: deny
      def authorize(_user, _action, _resource), do: {:error, :forbidden}
    end

    # Using in a controller:
    defmodule MyAppWeb.Api.PostController do
      use MyAppWeb, :controller

      def update(conn, %{"id" => id, "post" => params}) do
        user = conn.assigns.current_user
        post = Posts.get_post!(id)

        with :ok <- MyApp.Policy.authorize(user, :edit, post),
             {:ok, updated} <- Posts.update_post(post, params) do
          json(conn, %{data: updated})
        end
      end

      def delete(conn, %{"id" => id}) do
        user = conn.assigns.current_user
        post = Posts.get_post!(id)

        with :ok <- MyApp.Policy.authorize(user, :delete, post) do
          Posts.delete_post(post)
          send_resp(conn, :no_content, "")
        end
      end
    end

    # FallbackController handles {:error, :forbidden}
    defmodule MyAppWeb.FallbackController do
      def call(conn, {:error, :forbidden}) do
        conn
        |> put_status(:forbidden)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render(:"403")
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
     |> assign(resources: @resources)
     |> assign(actions: @actions)
     |> assign(selected_user: nil)
     |> assign(selected_resource: nil)
     |> assign(selected_action: nil)
     |> assign(policy_result: nil)
     |> assign(evaluation_steps: [])
     |> assign(eval_step: 0)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Policy Modules</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Resource-level authorization: pick a user, a resource, and an action. See which policy clause
        matches and whether access is granted or denied.
      </p>

      <!-- Step 1: Pick a User -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">1. Who is acting?</h3>
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
                  user_color(user.role)
                ]}>
                  {user.avatar}
                </div>
                <div>
                  <div class="font-semibold text-gray-900 dark:text-white">{user.name}</div>
                  <span class={["px-2 py-0.5 rounded-full text-xs font-semibold", role_badge(user.role)]}>
                    {user.role}
                  </span>
                </div>
              </div>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Step 2: Pick a Resource -->
      <%= if @selected_user do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">2. Which resource?</h3>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <%= for res <- @resources do %>
              <button
                phx-click="select_resource"
                phx-value-id={res.id}
                phx-target={@myself}
                class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
                  if(@selected_resource && @selected_resource.id == res.id,
                    do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                    else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
                ]}
              >
                <div class="flex items-center justify-between mb-1">
                  <span class={["px-2 py-0.5 rounded text-xs font-bold uppercase", resource_badge(res.type)]}>
                    {res.type}
                  </span>
                  <span class="text-xs text-gray-400">
                    owned by {owner_name(res.owner_id)}
                  </span>
                </div>
                <div class="font-medium text-gray-900 dark:text-white text-sm">
                  <%= if res.type == "post" do %>
                    {res.title}
                    <%= if Map.get(res, :published) do %>
                      <span class="ml-1 px-1.5 py-0.5 rounded text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400">published</span>
                    <% else %>
                      <span class="ml-1 px-1.5 py-0.5 rounded text-xs bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400">draft</span>
                    <% end %>
                  <% else %>
                    {"\""}<%= res.body %>{"\""} <span class="text-xs text-gray-400">on post #{res.post_id}</span>
                  <% end %>
                </div>
              </button>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Step 3: Pick an Action -->
      <%= if @selected_resource do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">3. What action?</h3>
          <div class="flex flex-wrap gap-2">
            <%= for action <- @actions do %>
              <button
                phx-click="select_action"
                phx-value-action={action}
                phx-target={@myself}
                class={["px-4 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer border-2",
                  if(@selected_action == action,
                    do: "border-rose-500 bg-rose-600 text-white",
                    else: "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:border-rose-300")
                ]}
              >
                {action}
              </button>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Policy Evaluation -->
      <%= if @policy_result do %>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              Policy Evaluation: authorize({@selected_user.name}, :{@selected_action}, {@selected_resource.type})
            </h3>
            <div class="flex gap-2">
              <button
                phx-click="reset_eval"
                phx-target={@myself}
                class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
              >
                Reset
              </button>
              <button
                phx-click="next_eval_step"
                phx-target={@myself}
                disabled={@eval_step >= length(@evaluation_steps)}
                class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                  if(@eval_step >= length(@evaluation_steps),
                    do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                    else: "bg-rose-600 hover:bg-rose-700 text-white")
                ]}
              >
                <%= if @eval_step == 0, do: "Start Evaluation", else: "Next Clause" %>
              </button>
            </div>
          </div>

          <!-- Evaluation Steps (policy clauses tried) -->
          <div class="space-y-3">
            <%= for {step, i} <- Enum.with_index(@evaluation_steps) do %>
              <div class={["flex items-start gap-4 p-4 rounded-lg transition-all duration-300",
                cond do
                  i < @eval_step -> "bg-gray-50 dark:bg-gray-800 opacity-100"
                  i == @eval_step -> "bg-rose-50 dark:bg-rose-900/20 border-2 border-rose-300 dark:border-rose-700 shadow-md"
                  true -> "bg-gray-50 dark:bg-gray-800 opacity-30"
                end
              ]}>
                <div class={["flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                  cond do
                    i < @eval_step && step.match == :match -> "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400"
                    i < @eval_step && step.match == :skip -> "bg-gray-200 dark:bg-gray-700 text-gray-400"
                    i < @eval_step && step.match == :deny -> "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
                    true -> "bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400"
                  end
                ]}>
                  <%= if i < @eval_step do %>
                    <%= case step.match do %>
                      <% :match -> %>
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                      <% :deny -> %>
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      <% _ -> %>
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7" />
                        </svg>
                    <% end %>
                  <% else %>
                    {i + 1}
                  <% end %>
                </div>

                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-0.5">
                    <span class={["text-xs font-semibold uppercase tracking-wide",
                      case step.match do
                        :match -> "text-emerald-600 dark:text-emerald-400"
                        :deny -> "text-red-600 dark:text-red-400"
                        _ -> "text-gray-400"
                      end
                    ]}>
                      <%= case step.match do %>
                        <% :match -> %>
                          MATCHED
                        <% :deny -> %>
                          CATCH-ALL (DENIED)
                        <% _ -> %>
                          SKIPPED
                      <% end %>
                    </span>
                  </div>
                  <div class="font-mono text-sm text-gray-900 dark:text-white">{step.clause}</div>
                  <%= if i <= @eval_step do %>
                    <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">{step.reason}</div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Final Result -->
          <%= if @eval_step >= length(@evaluation_steps) do %>
            <div class={["mt-4 p-4 rounded-lg border-2",
              if(@policy_result == :ok,
                do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
                else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
            ]}>
              <div class="flex items-center gap-2">
                <%= if @policy_result == :ok do %>
                  <svg class="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                  <span class="font-bold text-emerald-800 dark:text-emerald-300">
                    :ok &mdash; {@selected_user.name} CAN {@selected_action} this {@selected_resource.type}
                  </span>
                <% else %>
                  <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                  </svg>
                  <span class="font-bold text-red-800 dark:text-red-300">
                    <code class="text-red-600 dark:text-red-400">{"{:error, :forbidden}"}</code> &mdash; {@selected_user.name} CANNOT {@selected_action} this {@selected_resource.type}
                  </span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Pattern Overview -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">The Policy Module Pattern</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">1. authorize/3</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Single function with multiple clauses. Pattern matches on user, action, and resource.
              Returns <code>:ok</code> or <code>{"{:error, :forbidden}"}</code>.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">2. Admin Override</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              First clause matches <code>role: "admin"</code> with any action and resource.
              Admins bypass all other checks.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">3. Catch-All Deny</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Last clause matches anything not explicitly allowed.
              <strong>Default deny</strong> &mdash; if no clause grants access, access is denied.
            </p>
          </div>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Policies vs Role Plugs</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          <strong>Role plugs</strong> answer: "Does this user have the right role for this route?"
          <strong>Policy modules</strong> answer: "Can this specific user do this action on this specific resource?"
          Policies are more granular &mdash; they check ownership, resource state (published/draft), and relationships.
          Use role plugs for broad access control, and policies for resource-level decisions.
        </p>
      </div>
    </div>
    """
  end

  defp user_color("admin"), do: "bg-rose-600"
  defp user_color("editor"), do: "bg-blue-600"
  defp user_color("viewer"), do: "bg-emerald-600"
  defp user_color(_), do: "bg-gray-600"

  defp role_badge("admin"), do: "bg-rose-100 dark:bg-rose-900/30 text-rose-700 dark:text-rose-400"
  defp role_badge("editor"), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp role_badge("viewer"), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp role_badge(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp resource_badge("post"), do: "bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400"
  defp resource_badge("comment"), do: "bg-cyan-100 dark:bg-cyan-900/30 text-cyan-700 dark:text-cyan-400"
  defp resource_badge(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp owner_name(1), do: "Alice"
  defp owner_name(2), do: "Bob"
  defp owner_name(3), do: "Carol"
  defp owner_name(_), do: "Unknown"

  defp evaluate_policy(user, action, resource) do
    is_owner = user.id == resource.owner_id
    is_admin = user.role == "admin"
    is_editor = user.role == "editor"
    is_published = Map.get(resource, :published, true)
    res_type = resource.type

    # Build the list of clauses tried
    clauses = []

    # Clause 1: Admin override
    admin_clause = %{
      clause: "authorize(%{role: \"admin\"}, _action, _resource)",
      reason: if(is_admin, do: "User is admin — admin override grants access", else: "User role is \"#{user.role}\", not \"admin\" — skip"),
      match: if(is_admin, do: :match, else: :skip)
    }
    clauses = clauses ++ [admin_clause]

    if is_admin do
      {:ok, clauses}
    else
      # Build resource-specific clauses
      specific_clauses = build_resource_clauses(user, action, resource, is_owner, is_editor, is_published, res_type)
      clauses = clauses ++ specific_clauses

      # Check if any specific clause matched
      matched = Enum.any?(specific_clauses, &(&1.match == :match))

      if matched do
        {:ok, clauses}
      else
        # Add catch-all deny
        catch_all = %{
          clause: "authorize(_user, _action, _resource)",
          reason: "No clause matched — catch-all returns {:error, :forbidden}",
          match: :deny
        }
        {{:error, :forbidden}, clauses ++ [catch_all]}
      end
    end
  end

  defp build_resource_clauses(user, action, resource, is_owner, is_editor, is_published, "post") do
    case action do
      "view" ->
        clauses = []
        pub_clause = %{
          clause: "authorize(_user, :view, %Post{published: true})",
          reason: if(is_published, do: "Post is published — anyone can view", else: "Post is a draft, not published — skip"),
          match: if(is_published, do: :match, else: :skip)
        }
        clauses = clauses ++ [pub_clause]

        if is_published do
          clauses
        else
          owner_clause = %{
            clause: "authorize(%{id: uid}, :view, %Post{owner_id: uid})",
            reason: if(is_owner, do: "User is the owner — can view own draft", else: "User (id: #{user.id}) is not the owner (id: #{resource.owner_id}) — skip"),
            match: if(is_owner, do: :match, else: :skip)
          }
          clauses = clauses ++ [owner_clause]

          if is_owner do
            clauses
          else
            editor_clause = %{
              clause: "authorize(%{role: \"editor\"}, :view, %Post{})",
              reason: if(is_editor, do: "User is an editor — can view all posts", else: "User is not an editor — skip"),
              match: if(is_editor, do: :match, else: :skip)
            }
            clauses ++ [editor_clause]
          end
        end

      "edit" ->
        owner_clause = %{
          clause: "authorize(%{id: uid}, :edit, %Post{owner_id: uid})",
          reason: if(is_owner, do: "User is the owner — can edit own post", else: "User (id: #{user.id}) is not the owner (id: #{resource.owner_id}) — skip"),
          match: if(is_owner, do: :match, else: :skip)
        }

        if is_owner do
          [owner_clause]
        else
          editor_clause = %{
            clause: "authorize(%{role: \"editor\"}, :edit, %Post{})",
            reason: if(is_editor, do: "User is an editor — can edit any post", else: "User is not an editor — skip"),
            match: if(is_editor, do: :match, else: :skip)
          }
          [owner_clause, editor_clause]
        end

      "delete" ->
        [%{
          clause: "authorize(%{id: uid}, :delete, %Post{owner_id: uid})",
          reason: if(is_owner, do: "User is the owner — can delete own post", else: "User (id: #{user.id}) is not the owner (id: #{resource.owner_id}) — skip"),
          match: if(is_owner, do: :match, else: :skip)
        }]

      "publish" ->
        [%{
          clause: "authorize(%{role: \"editor\"}, :publish, %Post{})",
          reason: if(is_editor, do: "User is an editor — can publish posts", else: "User role is \"#{user.role}\", not \"editor\" — skip"),
          match: if(is_editor, do: :match, else: :skip)
        }]

      _ -> []
    end
  end

  defp build_resource_clauses(user, action, resource, is_owner, _is_editor, _is_published, "comment") do
    case action do
      "view" ->
        [%{
          clause: "authorize(_user, :view, %Comment{})",
          reason: "Anyone can view comments",
          match: :match
        }]

      "edit" ->
        [%{
          clause: "authorize(%{id: uid}, :edit, %Comment{owner_id: uid})",
          reason: if(is_owner, do: "User is the comment author — can edit", else: "User (id: #{user.id}) is not the author (id: #{resource.owner_id}) — skip"),
          match: if(is_owner, do: :match, else: :skip)
        }]

      "delete" ->
        [%{
          clause: "authorize(%{id: uid}, :delete, %Comment{owner_id: uid})",
          reason: if(is_owner, do: "User is the comment author — can delete", else: "User (id: #{user.id}) is not the author (id: #{resource.owner_id}) — skip"),
          match: if(is_owner, do: :match, else: :skip)
        }]

      "publish" ->
        [%{
          clause: "# No publish clause for comments",
          reason: "Comments cannot be published — no matching clause",
          match: :skip
        }]

      _ -> []
    end
  end

  def handle_event("select_user", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    user = Enum.find(@users, &(&1.id == id))
    {:noreply, assign(socket, selected_user: user, selected_resource: nil, selected_action: nil, policy_result: nil, evaluation_steps: [], eval_step: 0)}
  end

  def handle_event("select_resource", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    resource = Enum.find(@resources, &(&1.id == id))
    {:noreply, assign(socket, selected_resource: resource, selected_action: nil, policy_result: nil, evaluation_steps: [], eval_step: 0)}
  end

  def handle_event("select_action", %{"action" => action}, socket) do
    user = socket.assigns.selected_user
    resource = socket.assigns.selected_resource
    {result, steps} = evaluate_policy(user, action, resource)
    {:noreply, assign(socket, selected_action: action, policy_result: result, evaluation_steps: steps, eval_step: 0)}
  end

  def handle_event("next_eval_step", _params, socket) do
    max = length(socket.assigns.evaluation_steps)
    new_step = min(socket.assigns.eval_step + 1, max)
    {:noreply, assign(socket, eval_step: new_step)}
  end

  def handle_event("reset_eval", _params, socket) do
    {:noreply, assign(socket, eval_step: 0)}
  end
end
