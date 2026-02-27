defmodule ElixirKatasWeb.PhoenixKata44AuthorizationLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Authorization — RBAC, Policies, and Scoped Queries

    # 1. User schema with role
    schema "users" do
      field :email, :string
      field :role, Ecto.Enum,
            values: [:user, :moderator, :admin],
            default: :user
    end

    # 2. Authorization module with permissions
    defmodule MyApp.Authorization do
      @role_permissions %{
        user:      [:read, :create, :update_own, :delete_own],
        moderator: [:read, :create, :update_own, :delete_own,
                    :delete_any, :hide],
        admin:     :all
      }

      def can?(%{role: :admin}, _action, _resource), do: true

      def can?(user, :update, resource) do
        perms = @role_permissions[user.role] || []
        :update_own in perms && resource.user_id == user.id
      end

      def can?(user, action, _resource) do
        perms = @role_permissions[user.role] || []
        action in perms
      end
    end

    # 3. Policy module (Bodyguard-style)
    defmodule MyApp.Blog.Policy do
      def authorize(:update, %{id: uid}, %{user_id: uid}), do: :ok
      def authorize(_action, %{role: :admin}, _resource), do: :ok
      def authorize(:read, _user, %{published: true}), do: :ok
      def authorize(:create, %{id: _}, _), do: :ok
      def authorize(_, _, _), do: {:error, :unauthorized}
    end

    # 4. Scope-based queries (filter at DB level)
    defmodule MyApp.Blog do
      import Ecto.Query

      def list_posts(%{role: :admin}), do: Repo.all(Post)
      def list_posts(user) do
        Post |> where(user_id: ^user.id) |> Repo.all()
      end

      def get_post_for_user!(user, id) do
        Post |> where(id: ^id, user_id: ^user.id) |> Repo.one!()
      end
    end

    # 5. LiveView authorization (mount + event handlers)
    defmodule MyAppWeb.PostLive.Edit do
      use MyAppWeb, :live_view
      on_mount {UserAuth, :ensure_authenticated}

      def mount(%{"id" => id}, _session, socket) do
        user = socket.assigns.current_user
        post = Blog.get_post!(id)
        if post.user_id != user.id && !Accounts.admin?(user) do
          {:ok, socket |> put_flash(:error, "Not authorized.") |> redirect(to: ~p"/posts")}
        else
          {:ok, assign(socket, post: post)}
        end
      end

      # Re-check authorization in EVERY handle_event:
      def handle_event("save", params, socket) do
        if socket.assigns.post.user_id != socket.assigns.current_user.id do
          {:noreply, put_flash(socket, :error, "Not authorized.")}
        else
          # proceed with update...
        end
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "roles")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Authorization</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Role-based access control, policy patterns, and scope-based authorization — controlling what authenticated users can do.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "policies", "scopes", "liveview", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-purple-50 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400 border-b-2 border-purple-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["roles", "rbac", "controller"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-purple-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Authentication</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Who are you? (Login/session)</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Authorization</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">What can you do? (Permissions)</p>
            </div>
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-1">Scoping</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">What data can you see? (Queries)</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Policy Patterns -->
      <%= if @active_tab == "policies" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Policy modules centralize authorization logic. Each resource gets a policy module.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{policy_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Using in Controller</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{policy_controller_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Policy Libraries</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li><strong>Bodyguard</strong>: simple policy pattern (recommended)</li>
                <li><strong>Canada</strong>: protocol-based authorization</li>
                <li><strong>Canary</strong>: declarative authorization</li>
                <li><strong>Heimdall</strong>: role + permission system</li>
                <li>Or roll your own — it's straightforward in Elixir</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Scope-Based -->
      <%= if @active_tab == "scopes" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Scope-based authorization filters data at the query level — users only see their own data.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{scope_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Phoenix 1.8 Scopes</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{phoenix_scope_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-2">Why Scope at the DB Level?</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>Prevents accidentally returning other users' data</li>
                <li>Works even if controller forgets to check</li>
                <li>Cleaner than filtering after fetch</li>
                <li>Admins get unscoped queries when needed</li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>

      <!-- LiveView Authorization -->
      <%= if @active_tab == "liveview" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            In LiveView, authorization must happen in <code>mount/3</code> and event handlers — not just in <code>on_mount</code> hooks.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{liveview_authz_code()}</div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Important</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Check authorization in every <code>handle_event</code> too. Users can send arbitrary events from the browser — don't assume the UI prevents unauthorized actions.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Authorization Example</h4>
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
  defp tab_label("policies"), do: "Policy Patterns"
  defp tab_label("scopes"), do: "Scope-Based"
  defp tab_label("liveview"), do: "LiveView"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("roles"), do: "Roles"
  defp topic_label("rbac"), do: "RBAC"
  defp topic_label("controller"), do: "In Controller"

  defp overview_code("roles") do
    """
    # Simple role system using a field on users:
    schema "users" do
      field :email, :string
      field :hashed_password, :string, redact: true
      field :role, Ecto.Enum,
            values: [:user, :moderator, :admin],
            default: :user
      timestamps()
    end

    # Check role in any context:
    def admin?(%User{role: :admin}), do: true
    def admin?(_user), do: false

    def moderator?(%User{role: role}),
      do: role in [:moderator, :admin]

    # In router:
    defp require_admin(conn, _opts) do
      if conn.assigns.current_user &&
         Accounts.admin?(conn.assigns.current_user) do
        conn
      else
        conn |> put_flash(:error, "Unauthorized.")
             |> redirect(to: ~p"/") |> halt()
      end
    end\
    """
    |> String.trim()
  end

  defp overview_code("rbac") do
    """
    # Role-Based Access Control with permissions:
    defmodule MyApp.Authorization do
      @permissions %{
        user: [:read_posts, :create_comment],
        moderator: [:read_posts, :create_comment,
                    :delete_comment, :hide_post],
        admin: :all  # special atom — all permissions
      }

      def can?(%{role: :admin}, _action), do: true

      def can?(%{role: role}, action) do
        perms = Map.get(@permissions, role, [])
        action in perms
      end

      # Usage:
      # if Authorization.can?(current_user, :delete_comment) do
      #   ...
      # end\
    """
    |> String.trim()
  end

  defp overview_code("controller") do
    """
    defmodule MyAppWeb.PostController do
      use MyAppWeb, :controller
      alias MyApp.{Blog, Authorization}

      # Load and authorize in a plug:
      plug :load_and_authorize_post
             when action in [:edit, :update, :delete]

      def edit(conn, _params), do: render(conn, :edit)

      defp load_and_authorize_post(conn, _opts) do
        post = Blog.get_post!(conn.params["id"])
        user = conn.assigns.current_user

        # Check: is this the author OR an admin?
        if post.user_id == user.id ||
           Authorization.can?(user, :moderate_posts) do
          assign(conn, :post, post)
        else
          conn
          |> put_flash(:error, "Not authorized.")
          |> redirect(to: ~p"/posts")
          |> halt()
        end
      end
    end\
    """
    |> String.trim()
  end

  defp policy_code do
    """
    # Bodyguard-style policy module:
    defmodule MyApp.Blog.Policy do
      @behaviour Bodyguard.Policy

      alias MyApp.Accounts.User
      alias MyApp.Blog.Post

      # Admins can do anything:
      def authorize(_action, %User{role: :admin}, _params), do: :ok

      # Authors can edit/delete their own posts:
      def authorize(action, %User{id: id}, %Post{user_id: id})
          when action in [:update, :delete], do: :ok

      # Everyone can read published posts:
      def authorize(:read, _user, %Post{published: true}), do: :ok

      # Logged-in users can create posts:
      def authorize(:create, %User{}, _params), do: :ok

      # Deny everything else:
      def authorize(_action, _user, _params), do: {:error, :unauthorized}
    end

    # Without Bodyguard library — manual policy:
    defmodule MyApp.Blog.Policy do
      def authorize(action, user, resource) do
        case check(action, user, resource) do
          true -> {:ok, resource}
          false -> {:error, :unauthorized}
        end
      end

      defp check(:update, %{id: uid}, %{user_id: uid}), do: true
      defp check(:update, %{role: :admin}, _), do: true
      defp check(_, _, _), do: false
    end\
    """
    |> String.trim()
  end

  defp policy_controller_code do
    """
    defmodule MyAppWeb.PostController do
      use MyAppWeb, :controller

      def update(conn, %{"id" => id, "post" => params}) do
        post = Blog.get_post!(id)
        user = conn.assigns.current_user

        case Policy.authorize(:update, user, post) do
          {:ok, _} ->
            case Blog.update_post(post, params) do
              {:ok, post} ->
                redirect(conn, to: ~p"/posts/\#{post}")
              {:error, changeset} ->
                render(conn, :edit, changeset: changeset)
            end

          {:error, :unauthorized} ->
            conn
            |> put_flash(:error, "Not authorized.")
            |> redirect(to: ~p"/posts")
        end
      end
    end\
    """
    |> String.trim()
  end

  defp scope_code do
    """
    # Scope queries to the current user:
    defmodule MyApp.Blog do
      import Ecto.Query

      # Regular user sees only their own posts:
      def list_posts(%{role: :admin}) do
        # Admin sees all posts
        Repo.all(Post)
      end

      def list_posts(user) do
        # Regular user sees only their posts
        Post
        |> where(user_id: ^user.id)
        |> Repo.all()
      end

      # Safely get a post — raises if user doesn't own it:
      def get_post_for_user!(user, id) do
        Post
        |> where(id: ^id, user_id: ^user.id)
        |> Repo.one!()
      end

      # Pattern: always scope, never trust the UI:
      def update_post(user, id, attrs) do
        post = get_post_for_user!(user, id)  # raises if not owner
        post |> Post.changeset(attrs) |> Repo.update()
      end
    end\
    """
    |> String.trim()
  end

  defp phoenix_scope_code do
    """
    # Phoenix 1.8 introduces first-class Scope concept:
    # The Scope is passed through contexts, carrying user info.

    defmodule MyApp.Scope do
      defstruct [:user, :role]

      def for_user(%User{} = user) do
        %__MODULE__{user: user, role: user.role}
      end
    end

    # Context functions accept a scope:
    defmodule MyApp.Blog do
      def list_posts(%Scope{role: :admin}) do
        Repo.all(Post)
      end

      def list_posts(%Scope{user: user}) do
        Post |> where(user_id: ^user.id) |> Repo.all()
      end
    end

    # Controller passes scope from conn:
    def index(conn, _params) do
      scope = Scope.for_user(conn.assigns.current_user)
      posts = Blog.list_posts(scope)
      render(conn, :index, posts: posts)
    end\
    """
    |> String.trim()
  end

  defp liveview_authz_code do
    """
    defmodule MyAppWeb.PostLive.Edit do
      use MyAppWeb, :live_view
      alias MyApp.Blog

      # on_mount ensures user is authenticated:
      on_mount {UserAuth, :ensure_authenticated}

      def mount(%{"id" => id}, _session, socket) do
        user = socket.assigns.current_user
        post = Blog.get_post!(id)

        # Authorize in mount:
        if post.user_id != user.id &&
           !Accounts.admin?(user) do
          {:ok,
           socket
           |> put_flash(:error, "Not authorized.")
           |> redirect(to: ~p"/posts")}
        else
          {:ok, assign(socket, post: post,
                               changeset: Blog.change_post(post))}
        end
      end

      # ALSO authorize in event handlers:
      def handle_event("save", params, socket) do
        user = socket.assigns.current_user
        post = socket.assigns.post

        # Re-check authorization (never trust UI state alone):
        if post.user_id != user.id do
          {:noreply,
           socket |> put_flash(:error, "Not authorized.")}
        else
          case Blog.update_post(post, params["post"]) do
            {:ok, _post} ->
              {:noreply, push_navigate(socket, to: ~p"/posts")}
            {:error, cs} ->
              {:noreply, assign(socket, changeset: cs)}
          end
        end
      end
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete RBAC authorization system:

    # 1. User schema with role:
    schema "users" do
      field :email, :string
      field :role, Ecto.Enum,
            values: [:guest, :user, :moderator, :admin],
            default: :user
    end

    # 2. Authorization module:
    defmodule MyApp.Authorization do
      @role_permissions %{
        user:      [:read, :create, :update_own, :delete_own],
        moderator: [:read, :create, :update_own, :delete_own,
                    :delete_any, :hide],
        admin:     :all
      }

      def can?(%{role: :admin}, _action, _resource), do: true

      def can?(user, :update, resource) do
        perms = @role_permissions[user.role] || []
        :update_own in perms && resource.user_id == user.id
      end

      def can?(user, action, _resource) do
        perms = @role_permissions[user.role] || []
        action in perms
      end

      def authorize!(user, action, resource) do
        if can?(user, action, resource),
          do: {:ok, resource},
          else: raise(MyApp.UnauthorizedError)
      end
    end

    # 3. Context with scoped queries:
    defmodule MyApp.Blog do
      def list_posts(%{role: :admin}), do: Repo.all(Post)
      def list_posts(user) do
        Post |> where(user_id: ^user.id) |> Repo.all()
      end
    end

    # 4. Controller usage:
    defmodule MyAppWeb.PostController do
      def update(conn, %{"id" => id, "post" => params}) do
        post = Blog.get_post!(id)
        user = conn.assigns.current_user

        with {:ok, post} <-
               Authorization.authorize(user, :update, post),
             {:ok, updated} <-
               Blog.update_post(post, params) do
          redirect(conn, to: ~p"/posts/\#{updated}")
        else
          {:error, :unauthorized} ->
            conn |> put_flash(:error, "Unauthorized.")
                 |> redirect(to: ~p"/posts")
          {:error, changeset} ->
            render(conn, :edit, changeset: changeset)
        end
      end
    end\
    """
    |> String.trim()
  end
end
