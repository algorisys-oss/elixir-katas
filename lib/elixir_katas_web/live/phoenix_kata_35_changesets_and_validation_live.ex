defmodule ElixirKatasWeb.PhoenixKata35ChangesetsAndValidationLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :email,                 :string
        field :username,              :string
        field :role,                  :string, default: "member"
        field :age,                   :integer
        field :password_hash,         :string
        field :password,              :string, virtual: true
        field :password_confirmation, :string, virtual: true
        timestamps()
      end

      # For new registrations:
      def registration_changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :username, :age,
                        :password, :password_confirmation])
        |> validate_required([:email, :username, :password])
        |> validate_format(:email, ~r/^[^\\s]+@[^\\s]+$/)
        |> validate_length(:username, min: 2, max: 30)
        |> validate_length(:password, min: 8)
        |> validate_confirmation(:password, required: true)
        |> hash_password()
        |> unique_constraint(:email)
      end

      # For profile updates (no password required):
      def profile_changeset(user, attrs) do
        user
        |> cast(attrs, [:username, :age])
        |> validate_required([:username])
        |> validate_length(:username, min: 2, max: 30)
        |> validate_number(:age, greater_than_or_equal_to: 13)
      end

      # For admin updates (allows role change):
      def admin_changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :username, :role, :age])
        |> validate_required([:email, :username])
        |> validate_inclusion(:role, ["admin", "editor", "member"])
        |> unique_constraint(:email)
      end

      # Custom validator:
      defp hash_password(%{valid?: true,
                           changes: %{password: pw}} = cs) do
        put_change(cs, :password_hash, Bcrypt.hash_pwd_salt(pw))
      end
      defp hash_password(cs), do: cs
    end

    # Usage:
    changeset = User.registration_changeset(%User{}, %{
      email: "alice@example.com",
      username: "alice",
      password: "secret123",
      password_confirmation: "secret123"
    })

    changeset.valid?   # => true
    changeset.errors   # => []
    changeset.changes  # => %{email: "alice@...", ...}
    Repo.insert(changeset)
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
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Changesets & Validation</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Changesets are the heart of Ecto validation: they cast, filter, and validate data before it touches the database. Errors are collected and returned without raising exceptions.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "cast", "validators", "custom", "code"]}
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
            <button :for={topic <- ["what", "pipeline", "errors"]}
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
              <p class="text-sm font-semibold text-emerald-700 dark:text-emerald-300 mb-1">cast/4</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Filters and type-converts incoming params. Only permitted fields are accepted.</p>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">validate_*</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Add validation rules. Errors accumulate in <code>changeset.errors</code> — no exceptions thrown.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">valid?</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Check <code>changeset.valid?</code> to know if all validations passed before persisting.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- cast/4 -->
      <%= if @active_tab == "cast" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <code>cast/4</code> is the entry point. It takes a struct or changeset, a map of params, and a list of permitted fields. Unknown fields are silently dropped.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{cast_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">cast_assoc / cast_embed</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{cast_assoc_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">put_change / force_change</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{put_change_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Built-in Validators -->
      <%= if @active_tab == "validators" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Ecto provides many built-in validation functions. They all take and return a changeset, so they compose with the pipe operator.
          </p>

          <div class="overflow-x-auto">
            <table class="w-full text-sm text-left">
              <thead class="bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
                <tr>
                  <th class="px-4 py-2 font-semibold">Function</th>
                  <th class="px-4 py-2 font-semibold">Purpose</th>
                  <th class="px-4 py-2 font-semibold">Example</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                <%= for row <- validator_rows() do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                    <td class="px-4 py-2 font-mono text-emerald-600 dark:text-emerald-400 text-xs">{row.fn}</td>
                    <td class="px-4 py-2 text-gray-600 dark:text-gray-300 text-xs">{row.purpose}</td>
                    <td class="px-4 py-2 font-mono text-blue-600 dark:text-blue-400 text-xs">{row.example}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{validators_code()}</div>
        </div>
      <% end %>

      <!-- Custom validators -->
      <%= if @active_tab == "custom" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Custom validators are plain functions that take a changeset and return a changeset. Use <code>validate_change/3</code> to add errors manually, or <code>add_error/4</code> for direct error injection.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{custom_validator_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">DB Constraints</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{db_constraints_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Reading Errors</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{reading_errors_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Multiple Changeset Functions</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              You can have multiple changeset functions for different contexts — one for registration (requires password), one for profile updates (no password needed), one for admin edits (allows role changes). This is idiomatic Ecto.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Changeset Example</h4>
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
  defp tab_label("cast"), do: "cast/4"
  defp tab_label("validators"), do: "Built-in Validators"
  defp tab_label("custom"), do: "Custom Validators"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("what"), do: "What is a Changeset?"
  defp topic_label("pipeline"), do: "Pipe Pipeline"
  defp topic_label("errors"), do: "Error Handling"

  defp validator_rows do
    [
      %{fn: "validate_required/3", purpose: "Field must be present and not blank", example: "validate_required(cs, [:email, :name])"},
      %{fn: "validate_format/4", purpose: "Field matches regex pattern", example: "validate_format(cs, :email, ~r/@/)"},
      %{fn: "validate_length/3", purpose: "String or list length bounds", example: "validate_length(cs, :name, min: 2, max: 50)"},
      %{fn: "validate_number/3", purpose: "Numeric comparisons", example: "validate_number(cs, :age, greater_than: 0)"},
      %{fn: "validate_inclusion/3", purpose: "Value must be in a list", example: "validate_inclusion(cs, :role, [\"admin\", \"user\"])"},
      %{fn: "validate_exclusion/3", purpose: "Value must NOT be in a list", example: "validate_exclusion(cs, :name, [\"admin\", \"root\"])"},
      %{fn: "validate_acceptance/3", purpose: "Boolean must be true (terms checkbox)", example: "validate_acceptance(cs, :terms)"},
      %{fn: "validate_confirmation/3", purpose: "Two fields must match", example: "validate_confirmation(cs, :password)"},
      %{fn: "unique_constraint/3", purpose: "DB-level uniqueness check", example: "unique_constraint(cs, :email)"},
      %{fn: "foreign_key_constraint/3", purpose: "FK integrity check from DB", example: "foreign_key_constraint(cs, :user_id)"},
      %{fn: "validate_change/3", purpose: "Custom validation with function", example: "validate_change(cs, :zip, &check_zip/2)"}
    ]
  end

  defp overview_code("what") do
    """
    # A changeset tracks changes to a struct and
    # accumulates validation errors.
    # It does NOT hit the database.

    import Ecto.Changeset

    user = %MyApp.Accounts.User{}
    attrs = %{email: "alice@example.com", username: "alice"}

    changeset = user
    |> cast(attrs, [:email, :username, :age])
    |> validate_required([:email, :username])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:username, min: 2, max: 30)

    changeset.valid?   # => true or false
    changeset.errors   # => [] or [{:email, {"is invalid", []}}]
    changeset.changes  # => %{email: "alice@example.com", ...}\
    """
    |> String.trim()
  end

  defp overview_code("pipeline") do
    """
    # Changeset functions form a pipeline.
    # Each function takes a changeset and returns a changeset.

    def registration_changeset(user, attrs) do
      user
      |> cast(attrs, [:email, :username, :password])
      |> validate_required([:email, :username, :password])
      |> validate_format(:email, ~r/@/)
      |> validate_length(:username, min: 2, max: 30)
      |> validate_length(:password, min: 8)
      |> hash_password()         # custom step
      |> unique_constraint(:email)
    end

    # Validations SHORT-CIRCUIT on field error:
    # If :email fails validate_required,
    # validate_format on :email is skipped.
    # But OTHER fields continue to validate.\
    """
    |> String.trim()
  end

  defp overview_code("errors") do
    """
    # Reading errors from a changeset:
    changeset.errors
    # => [email: {"has already been taken", [constraint: :unique, ...]},
    #     username: {"can't be blank", [validation: :required]}]

    # Check a specific field:
    changeset.errors[:email]
    # => {"has already been taken", [...]}

    # Translate to a map for APIs:
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{" <> to_string(key) <> "}", to_string(value))
      end)
    end)
    # => %{email: ["has already been taken"]}

    # In Phoenix, use translate_errors from CoreComponents
    # or errors_on/1 from your factory in tests.\
    """
    |> String.trim()
  end

  defp cast_code do
    """
    import Ecto.Changeset

    # cast/4 signature:
    # cast(data_or_changeset, params, permitted_fields, opts \\ [])

    user = %User{}
    params = %{
      "email"    => "alice@example.com",
      "username" => "alice",
      "role"     => "admin",    # NOT in permitted list
      "unknown"  => "ignored"   # NOT in schema at all
    }

    changeset = cast(user, params, [:email, :username])
    # Only :email and :username are accepted.
    # :role and :unknown are silently dropped.

    changeset.changes
    # => %{email: "alice@example.com", username: "alice"}

    # cast also type-converts:
    params = %{"age" => "25"}  # string from form
    cs = cast(user, params, [:age])
    cs.changes  # => %{age: 25}  (integer, cast from string)\
    """
    |> String.trim()
  end

  defp cast_assoc_code do
    """
    # cast_assoc: cast nested association data
    def changeset(post, attrs) do
      post
      |> cast(attrs, [:title, :body])
      |> cast_assoc(:comments,
           with: &Comment.changeset/2)
    end

    # cast_embed: cast embedded schema data
    def changeset(user, attrs) do
      user
      |> cast(attrs, [:name])
      |> cast_embed(:address,
           with: &Address.changeset/2,
           required: true)
    end

    # Both validate nested data recursively
    # and propagate errors up to the parent.\
    """
    |> String.trim()
  end

  defp put_change_code do
    """
    # put_change: set a field directly (bypasses cast)
    changeset = put_change(changeset, :slug, "my-post")

    # force_change: set even if value hasn't changed
    # (useful to trigger DB triggers)
    changeset = force_change(changeset, :updated_at,
                  DateTime.utc_now())

    # get_field: read a field from changeset or struct
    email = get_field(changeset, :email)
    # Returns the changed value if in changeset.changes,
    # otherwise falls back to the original struct value.

    # get_change: only returns the change, not original
    get_change(changeset, :email)  # nil if unchanged\
    """
    |> String.trim()
  end

  defp validators_code do
    """
    def user_changeset(user, attrs) do
      user
      |> cast(attrs, [:email, :username, :age, :role,
                      :password, :password_confirmation, :terms])

      # Required fields:
      |> validate_required([:email, :username])

      # Email format:
      |> validate_format(:email, ~r/^[^\\s]+@[^\\s]+$/,
           message: "must be a valid email address")

      # String length:
      |> validate_length(:username, min: 2, max: 30)
      |> validate_length(:password, min: 8, max: 72)

      # Numeric bounds:
      |> validate_number(:age,
           greater_than_or_equal_to: 13,
           less_than: 120)

      # Value in set:
      |> validate_inclusion(:role, ["admin", "editor", "viewer"])

      # Blocked values:
      |> validate_exclusion(:username, ["admin", "root", "system"])

      # Must match another field (e.g. confirm password):
      |> validate_confirmation(:password, required: true)

      # Terms checkbox:
      |> validate_acceptance(:terms)

      # DB-backed uniqueness (checked at insert time):
      |> unique_constraint(:email)
    end\
    """
    |> String.trim()
  end

  defp custom_validator_code do
    """
    # Method 1: validate_change/3
    def changeset(user, attrs) do
      user
      |> cast(attrs, [:username])
      |> validate_change(:username, fn :username, value ->
        if String.contains?(value, " ") do
          [username: "cannot contain spaces"]
        else
          []  # no errors
        end
      end)
    end

    # Method 2: private function returning changeset
    defp validate_password_strength(changeset) do
      validate_change(changeset, :password, fn _, pw ->
        cond do
          String.length(pw) < 8 ->
            [password: "must be at least 8 characters"]
          not String.match?(pw, ~r/[0-9]/) ->
            [password: "must contain a number"]
          true ->
            []
        end
      end)
    end

    # Method 3: add_error/4 after your own check
    defp maybe_add_error(changeset) do
      username = get_field(changeset, :username)
      if reserved?(username) do
        add_error(changeset, :username, "is reserved")
      else
        changeset
      end
    end\
    """
    |> String.trim()
  end

  defp db_constraints_code do
    """
    # Constraints are checked at the DB level.
    # They convert DB errors to changeset errors.
    # Must have a matching constraint in migration!

    # unique_constraint (for unique index):
    |> unique_constraint(:email)
    |> unique_constraint([:user_id, :post_id],
         name: :user_post_likes_pkey)

    # foreign_key_constraint (for FK violation):
    |> foreign_key_constraint(:user_id)

    # check_constraint (for CHECK constraint in DB):
    |> check_constraint(:age,
         name: :age_must_be_positive,
         message: "must be positive")

    # no_assoc_constraint (can't delete if children exist):
    |> no_assoc_constraint(:posts,
         message: "user still has posts")\
    """
    |> String.trim()
  end

  defp reading_errors_code do
    """
    # After Repo.insert/update, errors from DB constraints
    # are also on the changeset:

    case Repo.insert(changeset) do
      {:ok, user} ->
        # Success!
        user

      {:error, changeset} ->
        # changeset.errors has all validation errors
        changeset.errors
        # => [email: {"has already been taken", [
        #      constraint: :unique,
        #      constraint_name: "users_email_index"
        #    ]}]

        changeset.valid?  # => false
    end

    # Traverse errors to a flat map:
    errors = Ecto.Changeset.traverse_errors(
      changeset, fn {msg, opts} ->
        Regex.replace(~r"%\{(\w+)}", msg, fn _, key ->
          opts
          |> Keyword.get(String.to_existing_atom(key), key)
          |> to_string()
        end)
      end)
    # => %{email: ["has already been taken"]}\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :email,                 :string
        field :username,              :string
        field :role,                  :string, default: "member"
        field :age,                   :integer
        field :password_hash,         :string
        field :password,              :string, virtual: true
        field :password_confirmation, :string, virtual: true
        timestamps()
      end

      # For new registrations:
      def registration_changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :username, :age,
                        :password, :password_confirmation])
        |> validate_required([:email, :username, :password])
        |> validate_format(:email, ~r/^[^\\s]+@[^\\s]+$/)
        |> validate_length(:username, min: 2, max: 30)
        |> validate_length(:password, min: 8)
        |> validate_confirmation(:password, required: true)
        |> hash_password()
        |> unique_constraint(:email)
      end

      # For profile updates (no password required):
      def profile_changeset(user, attrs) do
        user
        |> cast(attrs, [:username, :age])
        |> validate_required([:username])
        |> validate_length(:username, min: 2, max: 30)
        |> validate_number(:age,
             greater_than_or_equal_to: 13)
      end

      # For admin updates (allows role change):
      def admin_changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :username, :role, :age])
        |> validate_required([:email, :username])
        |> validate_inclusion(:role, ["admin", "editor", "member"])
        |> unique_constraint(:email)
      end

      defp hash_password(%{valid?: true,
                           changes: %{password: pw}} = cs) do
        put_change(cs, :password_hash, hash(pw))
      end
      defp hash_password(cs), do: cs

      defp hash(pw), do: :crypto.hash(:sha256, pw)
                        |> Base.encode16()
    end

    # Usage:
    changeset = User.registration_changeset(%User{}, %{
      email: "alice@example.com",
      username: "alice",
      password: "secret123",
      password_confirmation: "secret123"
    })

    changeset.valid?   # => true
    Repo.insert(changeset)\
    """
    |> String.trim()
  end
end
