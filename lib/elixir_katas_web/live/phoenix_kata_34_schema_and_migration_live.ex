defmodule ElixirKatasWeb.PhoenixKata34SchemaAndMigrationLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # 1. Schema: lib/my_app/accounts/user.ex
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :email,    :string
        field :username, :string
        field :role,     :string, default: "member"
        field :verified, :boolean, default: false
        timestamps()
      end

      def changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :username, :role])
        |> validate_required([:email, :username])
        |> validate_format(:email, ~r/@/)
        |> unique_constraint(:email)
      end
    end

    # 2. Migration: priv/repo/migrations/..._create_users.exs
    defmodule MyApp.Repo.Migrations.CreateUsers do
      use Ecto.Migration

      def change do
        create table(:users) do
          add :email,    :string,  null: false
          add :username, :string,  null: false
          add :role,     :string,  default: "member"
          add :verified, :boolean, default: false
          timestamps()
        end

        create unique_index(:users, [:email])
        create index(:users, [:username])
      end
    end

    # 3. Alter existing table:
    defmodule MyApp.Repo.Migrations.AddBioToUsers do
      use Ecto.Migration

      def change do
        alter table(:users) do
          add    :bio,       :text
          add    :avatar,    :string
          modify :username,  :string, size: 100
          remove :old_field
        end
      end
    end

    # 4. Mix commands:
    # mix ecto.gen.migration create_users
    # mix ecto.migrate
    # mix ecto.rollback
    # mix ecto.reset      (drop + create + migrate + seeds)
    # mix ecto.migrations  (show migration status)
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "schema")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Schema & Migration</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Ecto schemas define how Elixir structs map to database tables. Migrations version-control your database structure using <code>mix ecto.gen.migration</code>.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "schema", "migration", "field_types", "code"]}
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
            <button :for={topic <- ["schema", "migration", "workflow"]}
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

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
              <p class="text-sm font-semibold text-emerald-700 dark:text-emerald-300 mb-1">Schema</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Maps Elixir structs to DB tables. Defines field names, types, and associations.</p>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Migration</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">SQL DDL wrapped in Elixir. Versioned, reversible database changes tracked in <code>schema_migrations</code>.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Repo</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">The gateway to the database. Applies migrations with <code>mix ecto.migrate</code>.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Schema -->
      <%= if @active_tab == "schema" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            An Ecto schema defines the struct shape and DB column mappings. Use <code>schema/2</code> to declare table name and fields.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{schema_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Embedded Schema</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{embedded_schema_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Schema Options</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{schema_options_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">timestamps/1</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              <code>timestamps()</code> adds <code>inserted_at</code> and <code>updated_at</code> columns automatically. Ecto sets them on insert/update. Use <code>timestamps(type: :utc_datetime)</code> for UTC-aware datetimes.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Migration -->
      <%= if @active_tab == "migration" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Migrations describe how to change the database schema. Generate one with <code>mix ecto.gen.migration create_users</code>.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{migration_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Migration Commands</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{migration_commands_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Alter Table</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{alter_table_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <p class="text-sm font-semibold text-rose-700 dark:text-rose-300 mb-1">Migration Versioning</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Each migration file is prefixed with a UTC timestamp (e.g. <code>20240115120000_create_users.exs</code>). The <code>schema_migrations</code> table records which migrations have been applied. Never edit a migration that has been run in production — create a new one.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Field Types -->
      <%= if @active_tab == "field_types" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Ecto maps Elixir types to database column types. Each database adapter may support additional types.
          </p>

          <div class="overflow-x-auto">
            <table class="w-full text-sm text-left">
              <thead class="bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
                <tr>
                  <th class="px-4 py-2 font-semibold">Ecto Type</th>
                  <th class="px-4 py-2 font-semibold">Elixir Type</th>
                  <th class="px-4 py-2 font-semibold">Postgres Column</th>
                  <th class="px-4 py-2 font-semibold">Notes</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                <%= for row <- field_type_rows() do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                    <td class="px-4 py-2 font-mono text-emerald-600 dark:text-emerald-400">{row.ecto}</td>
                    <td class="px-4 py-2 font-mono text-blue-600 dark:text-blue-400">{row.elixir}</td>
                    <td class="px-4 py-2 font-mono text-purple-600 dark:text-purple-400">{row.pg}</td>
                    <td class="px-4 py-2 text-gray-600 dark:text-gray-300">{row.note}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{field_types_code()}</div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Schema & Migration Example</h4>
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
  defp tab_label("schema"), do: "Schema"
  defp tab_label("migration"), do: "Migration"
  defp tab_label("field_types"), do: "Field Types"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("schema"), do: "Schema"
  defp topic_label("migration"), do: "Migration"
  defp topic_label("workflow"), do: "Workflow"

  defp field_type_rows do
    [
      %{ecto: ":id", elixir: "integer", pg: "bigserial", note: "Primary key (auto)"},
      %{ecto: ":string", elixir: "String.t()", pg: "varchar(255)", note: "UTF-8 text"},
      %{ecto: ":text", elixir: "String.t()", pg: "text", note: "Unlimited length text"},
      %{ecto: ":integer", elixir: "integer", pg: "integer", note: "32-bit integer"},
      %{ecto: ":bigint", elixir: "integer", pg: "bigint", note: "64-bit integer"},
      %{ecto: ":float", elixir: "float", pg: "float", note: "Double precision"},
      %{ecto: ":decimal", elixir: "Decimal.t()", pg: "decimal", note: "Arbitrary precision"},
      %{ecto: ":boolean", elixir: "boolean", pg: "boolean", note: "true/false"},
      %{ecto: ":date", elixir: "Date.t()", pg: "date", note: "YYYY-MM-DD"},
      %{ecto: ":time", elixir: "Time.t()", pg: "time", note: "HH:MM:SS"},
      %{ecto: ":naive_datetime", elixir: "NaiveDateTime.t()", pg: "timestamp", note: "No timezone"},
      %{ecto: ":utc_datetime", elixir: "DateTime.t()", pg: "timestamptz", note: "UTC timezone"},
      %{ecto: ":map", elixir: "map", pg: "jsonb", note: "JSON document"},
      %{ecto: ":array", elixir: "list", pg: "array", note: "e.g. {:array, :string}"},
      %{ecto: ":binary_id", elixir: "binary", pg: "uuid", note: "UUID primary key"}
    ]
  end

  defp overview_code("schema") do
    """
    # An Ecto schema defines the mapping between
    # an Elixir struct and a database table.

    defmodule MyApp.Accounts.User do
      use Ecto.Schema

      schema "users" do
        field :email,      :string
        field :username,   :string
        field :age,        :integer
        field :verified,   :boolean, default: false
        field :bio,        :text

        timestamps()   # adds inserted_at, updated_at
      end
    end

    # Usage:
    %MyApp.Accounts.User{}
    # => %User{id: nil, email: nil, username: nil, ...}\
    """
    |> String.trim()
  end

  defp overview_code("migration") do
    """
    # A migration changes the database schema.
    # Generate with: mix ecto.gen.migration create_users

    defmodule MyApp.Repo.Migrations.CreateUsers do
      use Ecto.Migration

      def change do
        create table(:users) do
          add :email,    :string,  null: false
          add :username, :string,  null: false
          add :age,      :integer
          add :verified, :boolean, default: false

          timestamps()
        end

        create unique_index(:users, [:email])
      end
    end

    # Apply with: mix ecto.migrate
    # Roll back with: mix ecto.rollback\
    """
    |> String.trim()
  end

  defp overview_code("workflow") do
    """
    # Typical schema + migration workflow:

    # 1. Generate migration file:
    mix ecto.gen.migration create_users

    # 2. Edit the migration file in priv/repo/migrations/

    # 3. Apply to database:
    mix ecto.migrate

    # 4. Define the schema in lib/my_app/accounts/user.ex

    # 5. Write changesets for validation

    # 6. Use Repo to interact with data

    # To reset everything (dev only!):
    mix ecto.reset
    # (runs drop + create + migrate + seeds)

    # Check migration status:
    mix ecto.migrations\
    """
    |> String.trim()
  end

  defp schema_code do
    """
    defmodule MyApp.Blog.Post do
      use Ecto.Schema
      import Ecto.Changeset

      # Customize primary key (default is :id, :integer, autogenerate: true)
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id

      schema "posts" do
        field :title,      :string
        field :body,       :text
        field :status,     :string,  default: "draft"
        field :view_count, :integer, default: 0
        field :published_at, :utc_datetime
        field :tags,       {:array, :string}, default: []

        # Virtual fields (not persisted to DB):
        field :word_count, :integer, virtual: true

        # Associations defined separately (see Kata 38):
        belongs_to :author, MyApp.Accounts.User

        timestamps(type: :utc_datetime)
      end

      def changeset(post, attrs) do
        post
        |> cast(attrs, [:title, :body, :status, :tags])
        |> validate_required([:title, :body])
      end
    end\
    """
    |> String.trim()
  end

  defp embedded_schema_code do
    """
    # Embedded schemas have no DB table.
    # Used for nested data, forms, JSON columns.

    defmodule MyApp.Address do
      use Ecto.Schema
      import Ecto.Changeset

      embedded_schema do
        field :street,  :string
        field :city,    :string
        field :country, :string
        field :zip,     :string
      end

      def changeset(addr, attrs) do
        addr
        |> cast(attrs, [:street, :city, :country, :zip])
        |> validate_required([:street, :city])
      end
    end

    # Use in a parent schema:
    embeds_one :address, Address\
    """
    |> String.trim()
  end

  defp schema_options_code do
    """
    # Custom source (table name differs from module):
    schema "legacy_user_tbl", source: "users" do
      ...
    end

    # No primary key:
    @primary_key false
    schema "join_table" do
      belongs_to :user, User
      belongs_to :role, Role
    end

    # UUID primary key:
    @primary_key {:id, :binary_id, autogenerate: true}

    # Prefix (schema in Postgres):
    schema "users" do
      @schema_prefix "audit"
      ...
    end

    # Custom timestamps columns:
    timestamps(
      inserted_at: :created_at,
      updated_at: :modified_at,
      type: :utc_datetime
    )\
    """
    |> String.trim()
  end

  defp migration_code do
    """
    defmodule MyApp.Repo.Migrations.CreatePosts do
      use Ecto.Migration

      def change do
        create table(:posts) do
          add :title,        :string,  null: false
          add :body,         :text,    null: false
          add :status,       :string,  default: "draft"
          add :view_count,   :integer, default: 0
          add :published_at, :utc_datetime
          add :tags,         {:array, :string}, default: []

          # Foreign key reference:
          add :author_id, references(:users,
            on_delete: :restrict,
            type: :bigint)

          timestamps()
        end

        create index(:posts, [:author_id])
        create index(:posts, [:status])
        create unique_index(:posts, [:title])
      end
    end\
    """
    |> String.trim()
  end

  defp migration_commands_code do
    """
    # Generate a new migration:
    mix ecto.gen.migration create_users
    mix ecto.gen.migration add_bio_to_users
    mix ecto.gen.migration create_posts_index

    # Run pending migrations:
    mix ecto.migrate

    # Roll back last migration:
    mix ecto.rollback

    # Roll back N migrations:
    mix ecto.rollback --step 3

    # Run all migrations from scratch:
    mix ecto.reset

    # Show migration status:
    mix ecto.migrations

    # Migrate to specific version:
    mix ecto.migrate --to 20240115120000\
    """
    |> String.trim()
  end

  defp alter_table_code do
    """
    # Altering an existing table:
    defmodule MyApp.Repo.Migrations.AddBioToUsers do
      use Ecto.Migration

      def change do
        alter table(:users) do
          add    :bio,       :text
          add    :avatar,    :string
          modify :username,  :string, size: 100
          remove :old_field
        end
      end
    end

    # Rename column (Postgres):
    defmodule MyApp.Repo.Migrations.RenameField do
      use Ecto.Migration

      def change do
        rename table(:users), :old_name,
          to: :new_name
      end
    end\
    """
    |> String.trim()
  end

  defp field_types_code do
    """
    # Common field type examples in a schema:

    schema "products" do
      field :name,          :string         # varchar(255)
      field :description,   :text           # text
      field :price,         :decimal        # decimal
      field :stock,         :integer        # integer
      field :weight,        :float          # float
      field :active,        :boolean        # boolean
      field :thumbnail,     :binary         # bytea
      field :metadata,      :map            # jsonb
      field :categories,    {:array, :string}  # text[]
      field :launched_on,   :date           # date
      field :closes_at,     :utc_datetime   # timestamptz
      field :internal_id,   :binary_id      # uuid

      # Custom/parameterized types:
      field :status,  Ecto.Enum,
        values: [:draft, :published, :archived]
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # 1. Schema: lib/my_app/accounts/user.ex
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :email,    :string
        field :username, :string
        field :role,     :string, default: "member"
        field :verified, :boolean, default: false
        timestamps()
      end

      def changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :username, :role])
        |> validate_required([:email, :username])
        |> validate_format(:email, ~r/@/)
        |> unique_constraint(:email)
      end
    end

    # 2. Migration: priv/repo/migrations/..._create_users.exs
    defmodule MyApp.Repo.Migrations.CreateUsers do
      use Ecto.Migration

      def change do
        create table(:users) do
          add :email,    :string,  null: false
          add :username, :string,  null: false
          add :role,     :string,  default: "member"
          add :verified, :boolean, default: false
          timestamps()
        end

        create unique_index(:users, [:email])
        create index(:users, [:username])
      end
    end

    # 3. Mix commands:
    # mix ecto.gen.migration create_users
    # mix ecto.migrate
    # mix ecto.rollback   (to undo)

    # 4. Usage in IEx:
    alias MyApp.{Repo, Accounts.User}
    Repo.insert!(%User{email: "alice@example.com", username: "alice"})\
    """
    |> String.trim()
  end
end
