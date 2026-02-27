defmodule ElixirKatasWeb.PhoenixKata36RepoBasicsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule MyApp.Accounts do
      alias MyApp.{Repo, Accounts.User}
      import Ecto.Query

      # CREATE
      def create_user(attrs) do
        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
      end

      # READ - single
      def get_user(id), do: Repo.get(User, id)
      def get_user!(id), do: Repo.get!(User, id)

      def get_user_by_email(email) do
        Repo.get_by(User, email: email)
      end

      # READ - collection
      def list_users do
        Repo.all(User)
      end

      def list_admins do
        from(u in User, where: u.role == "admin")
        |> Repo.all()
      end

      # UPDATE
      def update_user(%User{} = user, attrs) do
        user
        |> User.profile_changeset(attrs)
        |> Repo.update()
      end

      # DELETE
      def delete_user(%User{} = user) do
        Repo.delete(user)
      end

      # UPSERT
      def upsert_user(attrs) do
        case get_user_by_email(attrs.email) do
          nil  -> %User{} |> User.registration_changeset(attrs)
          user -> User.profile_changeset(user, attrs)
        end
        |> Repo.insert_or_update()
      end
    end

    # Transactions with Ecto.Multi:
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, user_changeset)
    |> Ecto.Multi.run(:profile, fn repo, %{user: user} ->
         profile_cs = Profile.changeset(%Profile{}, %{user_id: user.id})
         repo.insert(profile_cs)
       end)
    |> Repo.transaction()
    # => {:ok, %{user: user, profile: profile}}
    # => {:error, :user, changeset, %{}}

    # Bulk operations (no changesets):
    Repo.insert_all(User, [%{email: "a@x.com", ...}, ...])
    Repo.update_all(from(u in User, where: u.role == "member"), set: [verified: true])
    Repo.delete_all(from(u in User, where: u.verified == false))
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
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Repo Basics</h2>
      <p class="text-gray-600 dark:text-gray-300">
        <code>Repo</code> is the gateway to your database. All inserts, reads, updates, and deletes go through it. It wraps the database adapter and gives you a clean API for CRUD operations.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "insert", "read", "update_delete", "code"]}
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
            <button :for={topic <- ["what", "bang", "transaction"]}
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

          <div class="overflow-x-auto">
            <table class="w-full text-sm text-left">
              <thead class="bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
                <tr>
                  <th class="px-4 py-2 font-semibold">Function</th>
                  <th class="px-4 py-2 font-semibold">Returns</th>
                  <th class="px-4 py-2 font-semibold">Bang Version</th>
                  <th class="px-4 py-2 font-semibold">Description</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                <%= for row <- repo_function_rows() do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                    <td class="px-4 py-2 font-mono text-emerald-600 dark:text-emerald-400 text-xs">{row.fn}</td>
                    <td class="px-4 py-2 font-mono text-blue-600 dark:text-blue-400 text-xs">{row.returns}</td>
                    <td class="px-4 py-2 font-mono text-purple-600 dark:text-purple-400 text-xs">{row.bang}</td>
                    <td class="px-4 py-2 text-gray-600 dark:text-gray-300 text-xs">{row.desc}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>

      <!-- Insert -->
      <%= if @active_tab == "insert" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>Repo.insert/2</code> persists a changeset or struct to the database. It returns <code>&#123;:ok, struct&#125;</code> on success or <code>&#123;:error, changeset&#125;</code> on failure.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{insert_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">insert_all</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{insert_all_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">insert_or_update</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{insert_or_update_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Read -->
      <%= if @active_tab == "read" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Ecto provides several functions for fetching records. Use <code>get/3</code> for single records by primary key, <code>get_by/3</code> for other fields, and <code>all/2</code> for collections.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{read_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">one / one!</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{one_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">aggregate</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{aggregate_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Update / Delete -->
      <%= if @active_tab == "update_delete" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Updates require a changeset built from an existing struct. Deletes take a struct or changeset. Both return <code>&#123;:ok, struct&#125;</code> or <code>&#123;:error, changeset&#125;</code>.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{update_delete_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">update_all / delete_all</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{bulk_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Transactions</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{transaction_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Optimistic Locking</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{optimistic_lock_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete CRUD Context Example</h4>
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
  defp tab_label("insert"), do: "Insert"
  defp tab_label("read"), do: "Read"
  defp tab_label("update_delete"), do: "Update & Delete"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("what"), do: "What is Repo?"
  defp topic_label("bang"), do: "Bang Functions"
  defp topic_label("transaction"), do: "Transactions"

  defp repo_function_rows do
    [
      %{fn: "Repo.insert/2", returns: "{:ok, struct} | {:error, cs}", bang: "insert!/2", desc: "Insert a changeset or struct"},
      %{fn: "Repo.insert_all/3", returns: "{count, nil | rows}", bang: "—", desc: "Bulk insert without changesets"},
      %{fn: "Repo.get/3", returns: "struct | nil", bang: "get!/3", desc: "Find by primary key"},
      %{fn: "Repo.get_by/3", returns: "struct | nil", bang: "get_by!/3", desc: "Find by field/value pairs"},
      %{fn: "Repo.all/2", returns: "list of structs", bang: "—", desc: "Return all matching records"},
      %{fn: "Repo.one/2", returns: "struct | nil", bang: "one!/2", desc: "Exactly one result or nil"},
      %{fn: "Repo.update/2", returns: "{:ok, struct} | {:error, cs}", bang: "update!/2", desc: "Update a changeset"},
      %{fn: "Repo.update_all/3", returns: "{count, nil | rows}", bang: "—", desc: "Bulk update without changesets"},
      %{fn: "Repo.delete/2", returns: "{:ok, struct} | {:error, cs}", bang: "delete!/2", desc: "Delete a struct or changeset"},
      %{fn: "Repo.delete_all/2", returns: "{count, nil | rows}", bang: "—", desc: "Bulk delete by query"},
      %{fn: "Repo.exists?/2", returns: "boolean", bang: "—", desc: "Returns true if any record matches"},
      %{fn: "Repo.aggregate/4", returns: "term | nil", bang: "—", desc: "count, sum, avg, min, max"},
      %{fn: "Repo.transaction/2", returns: "{:ok, result} | {:error, failed, value, changes}", bang: "—", desc: "Wrap multiple ops in a transaction"}
    ]
  end

  defp overview_code("what") do
    """
    # Repo is configured in config/dev.exs:
    config :my_app, MyApp.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "my_app_dev"

    # Defined in lib/my_app/repo.ex:
    defmodule MyApp.Repo do
      use Ecto.Repo,
        otp_app: :my_app,
        adapter: Ecto.Adapters.Postgres
    end

    # Started in lib/my_app/application.ex:
    children = [
      MyApp.Repo,  # started as a supervised process
      ...
    ]

    # Use from anywhere in your app:
    alias MyApp.{Repo, Accounts.User}

    user = Repo.get!(User, 42)
    Repo.insert(%User{email: "alice@example.com"})\
    """
    |> String.trim()
  end

  defp overview_code("bang") do
    """
    # Safe versions return {:ok, result} or {:error, reason}:
    case Repo.insert(changeset) do
      {:ok, user}        -> "Success!"
      {:error, changeset} -> "Validation failed"
    end

    # Bang versions raise on failure:
    user = Repo.insert!(changeset)  # raises on error
    user = Repo.get!(User, 42)      # raises Ecto.NoResultsError if nil
    user = Repo.one!(query)         # raises if 0 or >1 result

    # When to use bang:
    # - In seeds / migrations / scripts (crash is OK)
    # - When failure is genuinely unexpected
    # - In tests with factories

    # When to use safe versions:
    # - In controllers / contexts (handle failure gracefully)
    # - When dealing with user-supplied IDs\
    """
    |> String.trim()
  end

  defp overview_code("transaction") do
    """
    # Repo.transaction/2 wraps ops in a DB transaction.
    # If the function returns {:error, ...} or raises,
    # the transaction is rolled back automatically.

    Repo.transaction(fn ->
      {:ok, user} = Repo.insert(user_changeset)
      {:ok, _log} = Repo.insert(log_changeset)
      user  # return value becomes {:ok, user}
    end)

    # Multi (Ecto.Multi) for named, structured transactions:
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, user_changeset)
    |> Ecto.Multi.insert(:profile, fn %{user: user} ->
         Profile.changeset(%Profile{}, %{user_id: user.id})
       end)
    |> Repo.transaction()
    # => {:ok, %{user: user, profile: profile}}
    # => {:error, :user, failed_changeset, %{}}\
    """
    |> String.trim()
  end

  defp insert_code do
    """
    alias MyApp.{Repo, Accounts.User}
    import Ecto.Changeset

    # Insert via changeset (recommended):
    changeset = User.registration_changeset(%User{}, %{
      email: "alice@example.com",
      username: "alice"
    })

    case Repo.insert(changeset) do
      {:ok, user} ->
        IO.inspect(user.id)  # => auto-generated integer
        user

      {:error, changeset} ->
        IO.inspect(changeset.errors)  # validation failures
        nil
    end

    # Insert a bare struct (no validation):
    {:ok, user} = Repo.insert(%User{email: "bob@example.com"})

    # insert! raises on error:
    user = Repo.insert!(changeset)

    # Returning specific fields on insert:
    {:ok, user} = Repo.insert(changeset,
      returning: [:id, :inserted_at])\
    """
    |> String.trim()
  end

  defp insert_all_code do
    """
    # insert_all bypasses changesets — fast bulk insert
    Repo.insert_all(User, [
      %{email: "a@x.com", username: "a",
        inserted_at: ~N[2024-01-01 00:00:00],
        updated_at: ~N[2024-01-01 00:00:00]},
      %{email: "b@x.com", username: "b",
        inserted_at: ~N[2024-01-01 00:00:00],
        updated_at: ~N[2024-01-01 00:00:00]}
    ])
    # => {2, nil}  ({count, returning})

    # With RETURNING clause:
    {2, users} = Repo.insert_all(User, rows,
      returning: [:id, :email])

    # On conflict options:
    Repo.insert_all(User, rows,
      on_conflict: :nothing)       # skip duplicates
    Repo.insert_all(User, rows,
      on_conflict: :replace_all)   # upsert\
    """
    |> String.trim()
  end

  defp insert_or_update_code do
    """
    # insert_or_update: insert if new, update if persisted
    # Checks changeset.data.__meta__.state

    changeset =
      case Repo.get_by(User, email: "alice@example.com") do
        nil  -> User.changeset(%User{}, attrs)
        user -> User.changeset(user, attrs)
      end

    {:ok, user} = Repo.insert_or_update(changeset)
    # Inserts if changeset.data is a new struct,
    # updates if it was fetched from the DB.

    # Shorthand for upsert by key:
    Repo.insert(changeset,
      on_conflict: {:replace, [:username, :updated_at]},
      conflict_target: :email)\
    """
    |> String.trim()
  end

  defp read_code do
    """
    alias MyApp.{Repo, Accounts.User}

    # Get by primary key:
    user = Repo.get(User, 42)     # nil if not found
    user = Repo.get!(User, 42)    # raises Ecto.NoResultsError

    # Get by field value:
    user = Repo.get_by(User, email: "alice@example.com")
    user = Repo.get_by(User, [email: "a@x.com", role: "admin"])
    user = Repo.get_by!(User, email: "a@x.com")  # raises if nil

    # Get all records:
    users = Repo.all(User)  # SELECT * FROM users

    # All matching a query (see Kata 37 for queries):
    import Ecto.Query, only: [from: 2]

    query = from u in User,
      where: u.role == "admin",
      order_by: [asc: u.username]

    admins = Repo.all(query)

    # Reload from DB:
    user = Repo.reload(user)
    user = Repo.reload!(user)\
    """
    |> String.trim()
  end

  defp one_code do
    """
    import Ecto.Query

    # one/2: expects exactly 0 or 1 result
    query = from u in User,
      where: u.email == "alice@example.com"

    user = Repo.one(query)
    # nil if 0 results
    # raises Ecto.MultipleResultsError if >1

    user = Repo.one!(query)
    # raises Ecto.NoResultsError if 0 results
    # raises Ecto.MultipleResultsError if >1

    # exists?/2:
    has_admin = Repo.exists?(
      from u in User, where: u.role == "admin"
    )
    # => true or false\
    """
    |> String.trim()
  end

  defp aggregate_code do
    """
    import Ecto.Query

    # Count all users:
    count = Repo.aggregate(User, :count)

    # Count with query:
    count = Repo.aggregate(
      from(u in User, where: u.verified == true),
      :count
    )

    # Sum / average / min / max:
    total  = Repo.aggregate(Order, :sum, :total_cents)
    avg    = Repo.aggregate(Product, :avg, :price)
    oldest = Repo.aggregate(User, :min, :inserted_at)

    # Count a specific field (non-nil):
    count = Repo.aggregate(User, :count, :email)\
    """
    |> String.trim()
  end

  defp update_delete_code do
    """
    alias MyApp.{Repo, Accounts.User}

    # UPDATE: always goes through a changeset
    user = Repo.get!(User, 42)

    changeset = User.profile_changeset(user, %{
      username: "alice_updated"
    })

    case Repo.update(changeset) do
      {:ok, updated_user}  -> updated_user
      {:error, changeset}  -> changeset.errors
    end

    # update! raises on error:
    updated = Repo.update!(changeset)

    # DELETE: takes a struct (fetched from DB)
    user = Repo.get!(User, 42)

    case Repo.delete(user) do
      {:ok, deleted_user}  -> "Deleted"
      {:error, changeset}  -> "Constraint violation"
    end

    # delete! raises on error:
    Repo.delete!(user)\
    """
    |> String.trim()
  end

  defp bulk_code do
    """
    import Ecto.Query

    # update_all: bulk update by query
    # Returns {count, nil} or {count, rows}
    {count, _} = Repo.update_all(
      from(u in User, where: u.role == "member"),
      set: [verified: true]
    )
    # => {42, nil}

    # Update using DB expressions:
    Repo.update_all(Post,
      inc: [view_count: 1]   # view_count = view_count + 1
    )

    # delete_all: bulk delete by query
    {count, _} = Repo.delete_all(
      from u in User,
        where: u.verified == false
          and u.inserted_at < ^cutoff
    )

    # Caution: no changeset validation, no callbacks\
    """
    |> String.trim()
  end

  defp transaction_code do
    """
    alias MyApp.Repo

    # Simple transaction:
    Repo.transaction(fn ->
      {:ok, user} = Repo.insert(user_cs)
      {:ok, _log} = Repo.insert(audit_cs)
      user  # return value
    end)
    # => {:ok, user}

    # On error — auto rollback:
    Repo.transaction(fn ->
      Repo.insert!(bad_changeset)  # raises => rollback
    end)
    # => {:error, exception}

    # Ecto.Multi (structured transactions):
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, user_changeset)
    |> Ecto.Multi.run(:profile, fn repo, %{user: user} ->
         profile_cs = Profile.changeset(%Profile{},
           %{user_id: user.id})
         repo.insert(profile_cs)
       end)
    |> Repo.transaction()
    # => {:ok, %{user: user, profile: profile}}
    # => {:error, :user, changeset, %{}}\
    """
    |> String.trim()
  end

  defp optimistic_lock_code do
    """
    # Optimistic locking with lock_version:
    schema "documents" do
      field :content,      :text
      field :lock_version, :integer, default: 0
    end

    # In changeset:
    |> optimistic_lock(:lock_version)

    # On concurrent update:
    case Repo.update(changeset) do
      {:ok, doc}           -> doc
      {:error, :stale}     ->
        # Another process updated first
        # Reload and retry
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyApp.Accounts do
      alias MyApp.{Repo, Accounts.User}
      import Ecto.Query

      # CREATE
      def create_user(attrs) do
        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
      end

      # READ - single
      def get_user(id), do: Repo.get(User, id)
      def get_user!(id), do: Repo.get!(User, id)

      def get_user_by_email(email) do
        Repo.get_by(User, email: email)
      end

      # READ - collection
      def list_users do
        Repo.all(User)
      end

      def list_admins do
        from(u in User, where: u.role == "admin")
        |> Repo.all()
      end

      # UPDATE
      def update_user(%User{} = user, attrs) do
        user
        |> User.profile_changeset(attrs)
        |> Repo.update()
      end

      # DELETE
      def delete_user(%User{} = user) do
        Repo.delete(user)
      end

      # UPSERT
      def upsert_user(attrs) do
        case get_user_by_email(attrs.email) do
          nil  -> %User{} |> User.registration_changeset(attrs)
          user -> User.profile_changeset(user, attrs)
        end
        |> Repo.insert_or_update()
      end
    end

    # Usage in a controller:
    def create(conn, %{"user" => user_params}) do
      case MyApp.Accounts.create_user(user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "User created!")
          |> redirect(to: ~p"/users/\#{user.id}")

        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end
end
