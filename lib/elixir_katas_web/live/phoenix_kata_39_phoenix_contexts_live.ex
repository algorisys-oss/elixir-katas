defmodule ElixirKatasWeb.PhoenixKata39PhoenixContextsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # A context is a boundary module grouping related business logic.
    # Controllers/LiveViews call context functions — never Repo directly.

    # lib/my_app/accounts/user.ex (schema — private implementation)
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :name, :string
        field :email, :string
        field :hashed_password, :string
        field :password, :string, virtual: true
        field :confirmed_at, :naive_datetime
        timestamps()
      end

      def registration_changeset(user, attrs) do
        user
        |> cast(attrs, [:name, :email, :password])
        |> validate_required([:name, :email, :password])
        |> validate_format(:email, ~r/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i)
        |> validate_length(:password, min: 8)
        |> unique_constraint(:email)
        |> put_password_hash()
      end

      defp put_password_hash(changeset) do
        if changeset.valid? do
          put_change(changeset, :hashed_password,
            Bcrypt.hash_pwd_salt(get_change(changeset, :password)))
        else
          changeset
        end
      end
    end

    # lib/my_app/accounts.ex (context — public API)
    defmodule MyApp.Accounts do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Accounts.User

      def list_users, do: Repo.all(User)
      def get_user(id), do: Repo.get(User, id)
      def get_user!(id), do: Repo.get!(User, id)
      def get_user_by_email(email), do: Repo.get_by(User, email: email)

      def register_user(attrs) do
        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
      end

      def update_user(%User{} = user, attrs) do
        user
        |> User.update_changeset(attrs)
        |> Repo.update()
      end

      def delete_user(%User{} = user), do: Repo.delete(user)

      def change_user(%User{} = user, attrs \\\\ %{}) do
        User.registration_changeset(user, attrs)
      end
    end

    # Generate context + schema + migration:
    # mix phx.gen.context Blog Post posts title:string body:text
    # mix phx.gen.html Blog Post posts title:string body:text  (with controller)
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "what")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Phoenix Contexts</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Contexts are boundary modules that group related business logic, expose a clean public API,
        and keep your web layer decoupled from your data layer.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "structure", "generator", "design", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-400 border-b-2 border-indigo-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["what", "why", "anatomy"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-indigo-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 border border-indigo-200 dark:border-indigo-800">
              <p class="text-sm font-semibold text-indigo-700 dark:text-indigo-300 mb-1">Boundary Module</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">A context is the single entry point for a domain area. Nothing outside it accesses the database directly.</p>
            </div>
            <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800">
              <p class="text-sm font-semibold text-teal-700 dark:text-teal-300 mb-1">Public API</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Functions like <code>Accounts.create_user/1</code> hide schema and Repo details from callers.</p>
            </div>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Domain Cohesion</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Related schemas, queries, and logic live together. Easier to find, test, and replace.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Structure -->
      <%= if @active_tab == "structure" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            A typical Phoenix app groups business domains into context modules. Each context owns its schemas and exposes only what callers need.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{structure_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Context Module</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{context_module_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Schema Module</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{schema_module_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Rule of thumb</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Controllers and LiveViews call context functions. They never call <code>Repo</code> or use schemas directly.
              Schemas live inside the context directory and are considered private implementation details.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Generator -->
      <%= if @active_tab == "generator" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>mix phx.gen.context</code> scaffolds a context module, schema, migration, and test fixtures in one command.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{generator_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800">
              <p class="text-sm font-semibold text-teal-700 dark:text-teal-300 mb-2">Generated files</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li class="flex items-start gap-2"><span class="text-teal-500">+</span> <code>lib/my_app/blog.ex</code> — context module</li>
                <li class="flex items-start gap-2"><span class="text-teal-500">+</span> <code>lib/my_app/blog/post.ex</code> — schema</li>
                <li class="flex items-start gap-2"><span class="text-teal-500">+</span> <code>priv/repo/migrations/..._create_posts.exs</code></li>
                <li class="flex items-start gap-2"><span class="text-teal-500">+</span> <code>test/my_app/blog_test.exs</code></li>
                <li class="flex items-start gap-2"><span class="text-teal-500">+</span> <code>test/support/fixtures/blog_fixtures.ex</code></li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-2">Field types</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{generator_field_types_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
            <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Full HTML scaffold (context + controller + templates)</h4>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{generator_html_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Design -->
      <%= if @active_tab == "design" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Designing good context boundaries avoids tight coupling and keeps your codebase maintainable as it grows.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{design_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Good context design</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>- Functions named after domain actions (not DB operations)</li>
                <li>- Returns structs or <code>&#123;:ok, _&#125;/&#123;:error, _&#125;</code> tuples</li>
                <li>- One context per bounded domain area</li>
                <li>- Caller does not need to know schema names</li>
                <li>- Easy to unit test with <code>DataCase</code></li>
              </ul>
            </div>
            <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <p class="text-sm font-semibold text-red-700 dark:text-red-300 mb-2">Avoid these patterns</p>
              <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
                <li>- Calling <code>Repo</code> from a controller or LiveView</li>
                <li>- Importing schemas in the web layer</li>
                <li>- A single <code>Helpers</code> context for everything</li>
                <li>- Leaking Ecto.Query outside the context</li>
                <li>- Contexts that depend on each other circularly</li>
              </ul>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 border border-indigo-200 dark:border-indigo-800">
            <p class="text-sm font-semibold text-indigo-700 dark:text-indigo-300 mb-1">Splitting large contexts</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{split_context_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Full Code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Accounts Context</h4>
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
  defp tab_label("structure"), do: "Structure"
  defp tab_label("generator"), do: "Generator"
  defp tab_label("design"), do: "Design Principles"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("what"), do: "What is a Context?"
  defp topic_label("why"), do: "Why Contexts?"
  defp topic_label("anatomy"), do: "Anatomy"

  defp overview_code("what") do
    """
    # A context is an Elixir module that:
    #  1. Groups related business logic and schemas
    #  2. Exposes a clean public API to the rest of the app
    #  3. Is the ONLY place that calls Repo for its domain

    # Example: the Accounts context
    defmodule MyApp.Accounts do
      alias MyApp.Repo
      alias MyApp.Accounts.User

      # Public API — callers only see these functions:
      def list_users, do: Repo.all(User)
      def get_user!(id), do: Repo.get!(User, id)
      def create_user(attrs), do: ...
      def update_user(user, attrs), do: ...
      def delete_user(user), do: Repo.delete(user)
    end

    # Controllers call context functions, never Repo:
    def index(conn, _params) do
      users = MyApp.Accounts.list_users()
      render(conn, :index, users: users)
    end\
    """
    |> String.trim()
  end

  defp overview_code("why") do
    """
    # Without contexts — the "fat controller" problem:
    def create(conn, %{"user" => params}) do
      changeset = User.changeset(%User{}, params)    # schema in web layer
      case Repo.insert(changeset) do                 # Repo in web layer
        {:ok, user} ->
          Mailer.send_welcome_email(user)            # side effects tangled in
          redirect(conn, to: ~p"/users/\#{user.id}")
        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end

    # With contexts — clean separation:
    def create(conn, %{"user" => params}) do
      case Accounts.create_user(params) do           # single call
        {:ok, user} ->
          redirect(conn, to: ~p"/users/\#{user.id}")
        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end
    # Accounts.create_user handles changeset, Repo, and email internally\
    """
    |> String.trim()
  end

  defp overview_code("anatomy") do
    """
    # A context has two layers:

    # Layer 1: The context module (public API)
    # lib/my_app/accounts.ex
    defmodule MyApp.Accounts do
      alias MyApp.Repo
      alias MyApp.Accounts.{User, Token}

      # Public functions that the rest of the app uses
      def register_user(attrs) do
        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
      end
    end

    # Layer 2: Schema modules (private implementation)
    # lib/my_app/accounts/user.ex
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :email, :string
        field :password_hash, :string
        timestamps()
      end

      def registration_changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :password])
        |> validate_required([:email, :password])
        |> validate_format(:email, ~r/@/)
        |> hash_password()
      end
    end\
    """
    |> String.trim()
  end

  defp structure_code do
    """
    lib/
    └── my_app/
        ├── accounts.ex              # Accounts context (public API)
        ├── accounts/
        │   ├── user.ex              # User schema
        │   └── token.ex             # Token schema
        ├── blog.ex                  # Blog context (public API)
        ├── blog/
        │   ├── post.ex              # Post schema
        │   └── comment.ex           # Comment schema
        ├── catalog.ex               # Catalog context
        ├── catalog/
        │   ├── product.ex
        │   └── category.ex
        └── repo.ex                  # Only accessed inside contexts

    lib/my_app_web/
        ├── controllers/
        │   ├── user_controller.ex   # Calls MyApp.Accounts.*
        │   └── post_controller.ex   # Calls MyApp.Blog.*
        └── live/
            └── dashboard_live.ex    # Calls MyApp.Accounts.*, MyApp.Blog.*

    # The web layer NEVER imports schemas or calls Repo directly.
    # It only calls functions defined in context modules.\
    """
    |> String.trim()
  end

  defp context_module_code do
    """
    # lib/my_app/blog.ex
    defmodule MyApp.Blog do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Blog.Post

      def list_posts do
        Repo.all(Post)
      end

      def get_post!(id) do
        Repo.get!(Post, id)
      end

      def create_post(attrs \\\\ %{}) do
        %Post{}
        |> Post.changeset(attrs)
        |> Repo.insert()
      end

      def change_post(%Post{} = post, attrs \\\\ %{}) do
        Post.changeset(post, attrs)
      end
    end\
    """
    |> String.trim()
  end

  defp schema_module_code do
    """
    # lib/my_app/blog/post.ex
    defmodule MyApp.Blog.Post do
      use Ecto.Schema
      import Ecto.Changeset

      schema "posts" do
        field :title, :string
        field :body, :string
        field :published, :boolean, default: false
        field :published_at, :utc_datetime

        timestamps()
      end

      @doc false
      def changeset(post, attrs) do
        post
        |> cast(attrs, [:title, :body, :published])
        |> validate_required([:title, :body])
        |> validate_length(:title, min: 3, max: 200)
      end
    end\
    """
    |> String.trim()
  end

  defp generator_code do
    """
    # mix phx.gen.context generates a context + schema + migration:
    $ mix phx.gen.context Blog Post posts \\
        title:string body:text published:boolean

    # This creates:
    # - lib/my_app/blog.ex               (context module)
    # - lib/my_app/blog/post.ex          (Ecto schema)
    # - priv/repo/migrations/*_create_posts.exs
    # - test/my_app/blog_test.exs
    # - test/support/fixtures/blog_fixtures.ex

    # Run the migration:
    $ mix ecto.migrate

    # The context module has all standard CRUD functions generated:
    Blog.list_posts()
    Blog.get_post!(id)
    Blog.create_post(attrs)
    Blog.update_post(post, attrs)
    Blog.delete_post(post)
    Blog.change_post(post, attrs)   # returns a changeset (for forms)\
    """
    |> String.trim()
  end

  defp generator_field_types_code do
    """
    # Supported field types for the generator:
    string       # VARCHAR
    text         # TEXT (long string)
    integer      # INTEGER
    float        # FLOAT
    boolean      # BOOLEAN
    map          # JSONB (Postgres)
    array:string # ARRAY
    references:users  # foreign key (user_id)
    uuid         # UUID primary key
    date         # DATE
    time         # TIME
    datetime     # DATETIME (naive)
    utc_datetime # DATETIME (with UTC)\
    """
    |> String.trim()
  end

  defp generator_html_code do
    """
    # Full scaffold: context + controller + HTML templates + tests
    $ mix phx.gen.html Blog Post posts \\
        title:string body:text published:boolean

    # Also creates:
    # - lib/my_app_web/controllers/post_controller.ex
    # - lib/my_app_web/controllers/post_html.ex
    # - lib/my_app_web/controllers/post_html/
    #     index.html.heex
    #     new.html.heex
    #     edit.html.heex
    #     show.html.heex
    # - test/my_app_web/controllers/post_controller_test.exs

    # And adds to router.ex:
    resources "/posts", PostController\
    """
    |> String.trim()
  end

  defp design_code do
    """
    # Good: context named after the domain
    defmodule MyApp.Accounts do
      # user management, tokens, sessions
    end

    defmodule MyApp.Catalog do
      # products, categories, pricing
    end

    defmodule MyApp.Orders do
      # orders, line items, fulfillment
    end

    defmodule MyApp.Notifications do
      # email/SMS sending, notification preferences
    end

    # Bad: context named after a layer or technology
    defmodule MyApp.Models do     # too broad
    defmodule MyApp.Database do   # names the HOW, not the WHAT
    defmodule MyApp.Helpers do    # catch-all, will grow unboundedly

    # Ask: "What does this context DO for the business?"
    # Not: "What database tables does this context touch?"\
    """
    |> String.trim()
  end

  defp split_context_code do
    """
    # If Accounts grows too large, split by sub-domain:
    defmodule MyApp.Accounts do
      # identity: create_user, authenticate, get_user
    end

    defmodule MyApp.Accounts.Sessions do
      # session tokens, login, logout, token rotation
    end

    defmodule MyApp.Accounts.Notifications do
      # password reset emails, confirmation emails
    end

    # Or use delegation:
    defmodule MyApp.Accounts do
      alias MyApp.Accounts.{UserQueries, SessionTokens}

      def list_users, do: UserQueries.all()
      def create_session_token(user), do: SessionTokens.create(user)
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Complete example: Accounts context with User schema

    # lib/my_app/accounts/user.ex
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :name, :string
        field :email, :string
        field :hashed_password, :string
        field :password, :string, virtual: true
        field :confirmed_at, :naive_datetime
        timestamps()
      end

      def registration_changeset(user, attrs) do
        user
        |> cast(attrs, [:name, :email, :password])
        |> validate_required([:name, :email, :password])
        |> validate_format(:email, ~r/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i)
        |> validate_length(:password, min: 8)
        |> unique_constraint(:email)
        |> put_password_hash()
      end

      defp put_password_hash(changeset) do
        if changeset.valid? do
          put_change(changeset, :hashed_password,
            Bcrypt.hash_pwd_salt(get_change(changeset, :password)))
        else
          changeset
        end
      end
    end

    # lib/my_app/accounts.ex
    defmodule MyApp.Accounts do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Accounts.User

      def list_users, do: Repo.all(User)

      def get_user(id), do: Repo.get(User, id)
      def get_user!(id), do: Repo.get!(User, id)
      def get_user_by_email(email), do: Repo.get_by(User, email: email)

      def register_user(attrs) do
        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
      end

      def update_user(%User{} = user, attrs) do
        user
        |> User.update_changeset(attrs)
        |> Repo.update()
      end

      def delete_user(%User{} = user), do: Repo.delete(user)

      def change_user(%User{} = user, attrs \\\\ %{}) do
        User.registration_changeset(user, attrs)
      end

      def authenticate_user(email, password) do
        user = get_user_by_email(email)
        cond do
          user && Bcrypt.verify_pass(password, user.hashed_password) ->
            {:ok, user}
          user ->
            {:error, :invalid_password}
          true ->
            Bcrypt.no_user_verify()
            {:error, :not_found}
        end
      end
    end\
    """
    |> String.trim()
  end
end
