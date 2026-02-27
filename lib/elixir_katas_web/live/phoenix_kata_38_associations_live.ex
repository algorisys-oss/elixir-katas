defmodule ElixirKatasWeb.PhoenixKata38AssociationsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # User has_many Posts, Post belongs_to User
    # Post many_to_many Tags via join table

    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      schema "users" do
        field :email,    :string
        field :username, :string
        has_many :posts,    MyApp.Blog.Post,    foreign_key: :author_id
        has_one  :profile,  MyApp.Accounts.Profile
        timestamps()
      end
    end

    defmodule MyApp.Blog.Post do
      use Ecto.Schema
      import Ecto.Changeset
      schema "posts" do
        field :title,  :string
        field :body,   :text
        field :status, :string, default: "draft"
        belongs_to :author,   MyApp.Accounts.User
        has_many   :comments, MyApp.Blog.Comment
        many_to_many :tags,   MyApp.Blog.Tag,
          join_through: "post_tags",
          on_replace: :delete
        timestamps()
      end
    end

    # --- Preloading (associations are NOT loaded automatically) ---
    user = Repo.get!(User, 1)
    user.posts  # => %Ecto.Association.NotLoaded{} !!

    # Preload after fetch:
    user = Repo.preload(user, [:posts, :profile])

    # Preload in query (avoids N+1):
    from(p in Post,
      join: u in assoc(p, :author),
      preload: [author: u])
    |> Repo.all()

    # Nested preloads:
    Repo.preload(user, posts: [:comments, :tags])

    # --- many_to_many with put_assoc ---
    tags = Repo.all(from t in Tag, where: t.id in ^tag_ids)
    post = Repo.get!(Post, id) |> Repo.preload(:tags)

    post
    |> Ecto.Changeset.cast(attrs, [:title, :body])
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()

    # --- Migration for join table ---
    create table(:post_tags, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all)
      add :tag_id,  references(:tags,  on_delete: :delete_all)
    end
    create unique_index(:post_tags, [:post_id, :tag_id])
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "belongs_to")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Associations</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Ecto associations define relationships between schemas: <code>belongs_to</code>, <code>has_one</code>, <code>has_many</code>, and <code>many_to_many</code>. Associations must be explicitly preloaded.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "has_many", "many_to_many", "preloading", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border-b-2 border-emerald-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Overview -->
      <%= if @active_tab == "overview" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["belongs_to", "has_one", "not_loaded"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-emerald-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{overview_code(@selected_topic)}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <%= for row <- assoc_type_rows() do %>
              <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
                <p class="font-mono font-semibold text-emerald-600 dark:text-emerald-400 mb-1">{row.macro}</p>
                <p class="text-sm text-gray-600 dark:text-gray-300 mb-1">{row.desc}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400 font-mono">{row.example}</p>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- has_many -->
      <%= if @active_tab == "has_many" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>has_many</code> declares a one-to-many relationship. The foreign key lives on the child table. Use it alongside <code>belongs_to</code> on the child schema.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{has_many_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">has_one</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{has_one_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">on_delete Options</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{on_delete_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Through Associations</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{has_many_through_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- many_to_many -->
      <%= if @active_tab == "many_to_many" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>many_to_many</code> uses a join table. Ecto can manage the join table automatically, or you can give it a schema module for a richer join with extra fields.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{many_to_many_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Rich Join Table (with schema)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{rich_join_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">put_assoc</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{put_assoc_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Preloading -->
      <%= if @active_tab == "preloading" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Associations are NOT loaded automatically — they are <code>%Ecto.Association.NotLoaded{}</code> until preloaded. Always preload before accessing.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{preload_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Nested Changesets</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{nested_changeset_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">N+1 Problem</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{n_plus_one_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Associations Example</h4>
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
  defp tab_label("has_many"), do: "has_many / has_one"
  defp tab_label("many_to_many"), do: "many_to_many"
  defp tab_label("preloading"), do: "Preloading"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("belongs_to"), do: "belongs_to"
  defp topic_label("has_one"), do: "has_one"
  defp topic_label("not_loaded"), do: "NotLoaded"

  defp assoc_type_rows do
    [
      %{macro: "belongs_to :user, User",
        desc: "Adds :user_id FK to this schema's table. Provides user() helper.",
        example: "post.user_id  # => 42"},
      %{macro: "has_one :profile, Profile",
        desc: "One child record. FK lives on the Profile table.",
        example: "user.profile  # => %Profile{} after preload"},
      %{macro: "has_many :posts, Post",
        desc: "Multiple child records. FK lives on the Post table.",
        example: "user.posts  # => [%Post{}, ...] after preload"},
      %{macro: "many_to_many :tags, Tag, join_through: \"post_tags\"",
        desc: "Join table relationship. Ecto manages the join table.",
        example: "post.tags  # => [%Tag{}, ...] after preload"}
    ]
  end

  defp overview_code("belongs_to") do
    """
    defmodule MyApp.Blog.Post do
      use Ecto.Schema

      schema "posts" do
        field :title, :string
        field :body,  :text

        # belongs_to adds :author_id column AND :author virtual field
        belongs_to :author, MyApp.Accounts.User

        timestamps()
      end
    end

    # belongs_to adds:
    # - author_id field (integer FK) to the struct
    # - author association (requires preloading)

    # After preload:
    post = Repo.get!(Post, 1) |> Repo.preload(:author)
    post.author_id   # => 42
    post.author      # => %User{id: 42, ...}\
    """
    |> String.trim()
  end

  defp overview_code("has_one") do
    """
    defmodule MyApp.Accounts.User do
      use Ecto.Schema

      schema "users" do
        field :email, :string

        # has_one: expects profiles.user_id FK
        has_one :profile, MyApp.Accounts.Profile

        # has_many: expects posts.author_id FK
        has_many :posts, MyApp.Blog.Post,
          foreign_key: :author_id

        timestamps()
      end
    end

    # has_one / has_many do NOT add columns to users.
    # The FK lives on the child table (profiles, posts).

    user = Repo.get!(User, 1) |> Repo.preload([:profile, :posts])
    user.profile  # => %Profile{} or nil
    user.posts    # => [%Post{}, ...]\
    """
    |> String.trim()
  end

  defp overview_code("not_loaded") do
    """
    # Without preloading, associations are NotLoaded:
    user = Repo.get!(User, 1)
    user.posts
    # => %Ecto.Association.NotLoaded{
    #      __field__: :posts,
    #      __owner__: MyApp.Accounts.User
    #    }

    # Accessing NotLoaded raises in templates.
    # Always preload before using associations.

    # Check if loaded:
    Ecto.assoc_loaded?(user.posts)  # => false

    # After preloading:
    user = Repo.preload(user, :posts)
    Ecto.assoc_loaded?(user.posts)  # => true
    user.posts  # => [%Post{}, ...]\
    """
    |> String.trim()
  end

  defp has_many_code do
    """
    defmodule MyApp.Accounts.User do
      use Ecto.Schema

      schema "users" do
        field :email,    :string
        field :username, :string

        has_many :posts, MyApp.Blog.Post,
          foreign_key: :author_id   # default would be :user_id

        has_many :comments, MyApp.Blog.Comment

        # has_many through another association:
        has_many :liked_posts, through: [:likes, :post]

        timestamps()
      end
    end

    defmodule MyApp.Blog.Post do
      use Ecto.Schema

      schema "posts" do
        field :title, :string
        field :body,  :text

        belongs_to :author, MyApp.Accounts.User

        has_many :comments, MyApp.Blog.Comment

        timestamps()
      end
    end

    # Migration for posts table:
    create table(:posts) do
      add :title,     :string, null: false
      add :body,      :text
      add :author_id, references(:users, on_delete: :delete_all)
      timestamps()
    end\
    """
    |> String.trim()
  end

  defp has_one_code do
    """
    # has_one: one child record (like belongs_to but reversed)

    defmodule MyApp.Accounts.User do
      use Ecto.Schema

      schema "users" do
        field :email, :string

        # expects profiles.user_id
        has_one :profile, MyApp.Accounts.Profile
      end
    end

    defmodule MyApp.Accounts.Profile do
      use Ecto.Schema

      schema "profiles" do
        field :bio,    :text
        field :avatar, :string

        belongs_to :user, MyApp.Accounts.User
      end
    end

    # The FK (user_id) lives in the profiles table.
    # has_one just says "expect at most one profile for this user".\
    """
    |> String.trim()
  end

  defp on_delete_code do
    """
    # on_delete in migration controls DB behavior
    # when the parent record is deleted:

    add :user_id, references(:users,
      on_delete: :nothing)      # default — FK error

    add :user_id, references(:users,
      on_delete: :delete_all)   # cascade delete child records

    add :user_id, references(:users,
      on_delete: :nilify_all)   # set FK to NULL

    add :user_id, references(:users,
      on_delete: :restrict)     # prevent parent delete

    # In schema (Ecto-level, for cascade without DB support):
    has_many :posts, Post, on_delete: :delete_all

    # DB-level on_delete is preferred — safer and faster.\
    """
    |> String.trim()
  end

  defp has_many_through_code do
    """
    # has_many :through follows a chain of associations

    defmodule User do
      schema "users" do
        has_many :memberships, Membership
        has_many :groups, through: [:memberships, :group]
      end
    end

    defmodule Membership do
      schema "memberships" do
        belongs_to :user,  User
        belongs_to :group, Group
      end
    end

    defmodule Group do
      schema "groups" do
        field :name, :string
        has_many :memberships, Membership
      end
    end

    # Usage:
    user = Repo.get!(User, 1) |> Repo.preload(:groups)
    user.groups  # => [%Group{}, ...]\
    """
    |> String.trim()
  end

  defp many_to_many_code do
    """
    # Posts <-> Tags via a join table

    defmodule MyApp.Blog.Post do
      use Ecto.Schema

      schema "posts" do
        field :title, :string

        many_to_many :tags, MyApp.Blog.Tag,
          join_through: "post_tags",
          on_replace: :delete   # remove old join rows on update

        timestamps()
      end
    end

    defmodule MyApp.Blog.Tag do
      use Ecto.Schema

      schema "tags" do
        field :name, :string

        many_to_many :posts, MyApp.Blog.Post,
          join_through: "post_tags"
      end
    end

    # Migration for the join table:
    create table(:post_tags, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all)
      add :tag_id,  references(:tags,  on_delete: :delete_all)
    end

    create unique_index(:post_tags, [:post_id, :tag_id])\
    """
    |> String.trim()
  end

  defp rich_join_code do
    """
    # When the join table has extra fields, use a schema:

    defmodule MyApp.UserRole do
      use Ecto.Schema

      schema "user_roles" do
        field :granted_at, :utc_datetime
        belongs_to :user, MyApp.Accounts.User
        belongs_to :role, MyApp.Accounts.Role
      end
    end

    # In User:
    has_many :user_roles, UserRole
    has_many :roles, through: [:user_roles, :role]

    # Or with join_through pointing to the module:
    many_to_many :roles, Role,
      join_through: UserRole

    # Migration:
    create table(:user_roles) do
      add :user_id,    references(:users)
      add :role_id,    references(:roles)
      add :granted_at, :utc_datetime
      timestamps()
    end\
    """
    |> String.trim()
  end

  defp put_assoc_code do
    """
    # put_assoc: replace an entire association at once
    # (commonly used for many_to_many tag assignment)

    # Fetch the tags you want to associate:
    tags = Repo.all(from t in Tag,
      where: t.id in ^tag_ids)

    # Build changeset with put_assoc:
    post = Repo.get!(Post, id) |> Repo.preload(:tags)

    changeset = post
    |> Ecto.Changeset.cast(attrs, [:title, :body])
    |> Ecto.Changeset.put_assoc(:tags, tags)

    Repo.update(changeset)
    # Ecto manages the join table automatically.

    # on_replace: :delete (in schema) ensures old
    # join rows are removed when tags change.\
    """
    |> String.trim()
  end

  defp preload_code do
    """
    alias MyApp.Repo

    # After fetching, preload one association:
    user = Repo.get!(User, 1)
    user = Repo.preload(user, :posts)
    user.posts  # => [%Post{}, ...]

    # Preload multiple at once:
    user = Repo.preload(user, [:posts, :profile, :comments])

    # Nested preloads (posts and their comments):
    user = Repo.preload(user, posts: :comments)
    user.posts |> hd() |> Map.get(:comments)  # loaded!

    # Deep nesting:
    user = Repo.preload(user,
      posts: [comments: :author])

    # In the query (one round-trip):
    import Ecto.Query
    user = Repo.one(
      from u in User,
        where: u.id == ^id,
        preload: [posts: :comments]
    )

    # Preload only published posts:
    published = from p in Post, where: p.status == "published"
    user = Repo.preload(user, posts: published)\
    """
    |> String.trim()
  end

  defp nested_changeset_code do
    """
    # cast_assoc: validate nested has_many data from params

    def post_changeset(post, attrs) do
      post
      |> cast(attrs, [:title, :body])
      |> validate_required([:title])
      |> cast_assoc(:comments,
           with: &Comment.changeset/2)
    end

    # Usage with nested params:
    attrs = %{
      "title" => "Hello",
      "comments" => [
        %{"body" => "Great post!"},
        %{"body" => "Thanks!"}
      ]
    }

    post = %Post{} |> Post.post_changeset(attrs)
    # Validates both post and comment changesets.
    # Errors bubble up to post.changes.comments.\
    """
    |> String.trim()
  end

  defp n_plus_one_code do
    """
    # N+1 PROBLEM — avoid this:
    posts = Repo.all(Post)
    # 1 query for posts

    Enum.each(posts, fn post ->
      IO.puts post.author.name  # BOOM - not loaded!
      # Would need 1 query per post = N+1 queries
    end)

    # SOLUTION 1: Preload in one shot
    posts = Repo.all(from p in Post, preload: :author)
    # 2 queries total (posts + authors)

    # SOLUTION 2: Join preload (1 query)
    posts = Repo.all(
      from p in Post,
        join: u in assoc(p, :author),
        preload: [author: u]
    )

    # Rule: always preload before iterating over associations.\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # User has_many Posts, Post belongs_to User
    # Post has_many Tags via many_to_many

    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      schema "users" do
        field :email,    :string
        field :username, :string
        has_many :posts,    MyApp.Blog.Post,    foreign_key: :author_id
        has_one  :profile,  MyApp.Accounts.Profile
        timestamps()
      end
    end

    defmodule MyApp.Blog.Post do
      use Ecto.Schema
      import Ecto.Changeset
      schema "posts" do
        field :title,  :string
        field :body,   :text
        field :status, :string, default: "draft"
        belongs_to :author,   MyApp.Accounts.User
        has_many   :comments, MyApp.Blog.Comment
        many_to_many :tags,   MyApp.Blog.Tag,
          join_through: "post_tags",
          on_replace: :delete
        timestamps()
      end

      def changeset(post, attrs) do
        post
        |> cast(attrs, [:title, :body, :status])
        |> validate_required([:title, :body])
      end
    end

    defmodule MyApp.Blog do
      alias MyApp.{Repo, Blog.Post, Blog.Tag}
      import Ecto.Query

      def create_post(author, attrs, tag_ids \\\\ []) do
        tags = Repo.all(from t in Tag,
          where: t.id in ^tag_ids)

        %Post{author_id: author.id}
        |> Post.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:tags, tags)
        |> Repo.insert()
      end

      def get_post_with_author_and_tags!(id) do
        Repo.get!(Post, id)
        |> Repo.preload([:author, :tags, :comments])
      end

      def list_posts_with_authors do
        from(p in Post,
          join: u in assoc(p, :author),
          where: p.status == "published",
          order_by: [desc: p.inserted_at],
          preload: [author: u])
        |> Repo.all()
      end
    end\
    """
    |> String.trim()
  end
end
