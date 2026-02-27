defmodule ElixirKatasWeb.PhoenixKata37EctoQueriesLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    import Ecto.Query

    # --- Keyword syntax ---
    from u in User,
      where: u.role == ^role and u.verified == true,
      order_by: [desc: u.inserted_at],
      limit: 20,
      offset: ^offset,
      select: %{id: u.id, email: u.email}

    # --- Pipe syntax (composable) ---
    User
    |> where([u], u.verified == true)
    |> where([u], u.age >= ^min_age)
    |> order_by([u], asc: u.username)
    |> limit(20)
    |> Repo.all()

    # --- Filtering ---
    from u in User, where: u.age > 18
    from u in User, where: u.role in ["admin", "editor"]
    from u in User, where: is_nil(u.deleted_at)
    from u in User, where: like(u.username, "%alice%")
    from u in User, where: ilike(u.email, "%@example.com")

    # --- Joins ---
    from p in Post,
      join: u in assoc(p, :author),
      where: u.verified == true,
      preload: [author: u]

    from p in Post,
      left_join: u in User, on: u.id == p.author_id,
      select: %{title: p.title, author: u.username}

    # --- Aggregates & grouping ---
    from p in Post,
      group_by: p.author_id,
      having: count(p.id) > 5,
      select: {p.author_id, count(p.id)}

    # --- Dynamic queries ---
    conditions = dynamic([u], u.verified == true)
    conditions = dynamic([u], ^conditions and u.age > ^age)
    from(u in User, where: ^conditions) |> Repo.all()

    # --- Fragments (raw SQL, safely parameterized) ---
    from u in User,
      where: fragment("lower(?)", u.email) == ^email

    # --- Subqueries ---
    sub = from(p in Post, where: p.status == "published", limit: 10)
    from(p in subquery(sub)) |> Repo.all()
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "from")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Queries with Ecto.Query</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Ecto.Query provides a composable, type-safe DSL for building SQL queries. Queries are data structures — they are not executed until passed to <code>Repo</code>.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "filtering", "joins", "advanced", "code"]}
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
            <button :for={topic <- ["from", "keyword", "pipe"]}
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
              <p class="text-sm font-semibold text-emerald-700 dark:text-emerald-300 mb-1">Composable</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Queries are data. Build them incrementally, combine them, pass them around before executing.</p>
            </div>
            <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
              <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">SQL Injection Safe</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Variables pinned with <code>^</code> are parameterized — never interpolated directly into SQL.</p>
            </div>
            <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
              <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Lazy Execution</p>
              <p class="text-sm text-gray-600 dark:text-gray-300">Nothing hits the database until you call <code>Repo.all/one/one!</code> etc.</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Filtering -->
      <%= if @active_tab == "filtering" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            The most common query clauses: <code>where</code>, <code>select</code>, <code>order_by</code>, <code>limit</code>, <code>offset</code>, and <code>group_by</code>.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{filtering_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Dynamic Queries</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{dynamic_query_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Fragments</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{fragment_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Joins -->
      <%= if @active_tab == "joins" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Ecto supports all SQL join types. Use <code>join</code> with <code>on:</code>, or <code>assoc/2</code> to join via defined associations.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{join_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Join Types</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{join_types_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Preload via Join</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{preload_join_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Advanced -->
      <%= if @active_tab == "advanced" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Advanced patterns: subqueries, CTEs, window functions via fragments, and named bindings.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{advanced_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Named Bindings</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{named_bindings_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Grouping & Having</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{group_having_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Query Cheat Sheet</h4>
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
  defp tab_label("filtering"), do: "Filtering & Sorting"
  defp tab_label("joins"), do: "Joins"
  defp tab_label("advanced"), do: "Advanced"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("from"), do: "from/2"
  defp topic_label("keyword"), do: "Keyword Syntax"
  defp topic_label("pipe"), do: "Pipe Syntax"

  defp overview_code("from") do
    """
    import Ecto.Query

    # from/2 starts a query.
    # First argument: the schema module or table name.
    # Second: keyword list of clauses.

    query = from u in User,
      where: u.role == "admin",
      order_by: [asc: u.username],
      limit: 10

    # Execute against the DB:
    Repo.all(query)

    # The variable name after `in` is the binding:
    query = from p in Post,
      where: p.user_id == ^user_id,  # ^ pins Elixir variable
      select: p.title

    # Binding is just a local alias — not a string\
    """
    |> String.trim()
  end

  defp overview_code("keyword") do
    """
    import Ecto.Query

    # Keyword query syntax — all in one expression:
    from u in User,
      where: u.verified == true and u.age >= 18,
      order_by: [asc: u.username],
      limit: 20,
      offset: 40,
      select: %{id: u.id, name: u.username}

    # Lock for update:
    from u in User,
      where: u.id == ^id,
      lock: "FOR UPDATE"

    # Preload associations inline:
    from p in Post,
      where: p.status == "published",
      preload: [:author, :comments]\
    """
    |> String.trim()
  end

  defp overview_code("pipe") do
    """
    import Ecto.Query

    # Pipe syntax — build incrementally:
    User
    |> where([u], u.verified == true)
    |> where([u], u.age >= ^min_age)
    |> order_by([u], asc: u.username)
    |> limit(20)
    |> Repo.all()

    # Composable — add clauses conditionally:
    base_query = User |> where([u], u.verified == true)

    filtered =
      if params["role"] do
        where(base_query, [u], u.role == ^params["role"])
      else
        base_query
      end

    Repo.all(filtered)\
    """
    |> String.trim()
  end

  defp filtering_code do
    """
    import Ecto.Query

    # WHERE with comparison operators:
    from u in User, where: u.age > 18
    from u in User, where: u.age >= 18 and u.verified == true
    from u in User, where: u.role in ["admin", "editor"]
    from u in User, where: is_nil(u.deleted_at)
    from u in User, where: not is_nil(u.email)

    # String matching:
    from u in User, where: like(u.username, "%alice%")
    from u in User, where: ilike(u.email, "%@example.com")

    # SELECT specific columns:
    from u in User, select: u.email
    # => ["alice@example.com", "bob@example.com"]

    from u in User, select: {u.id, u.email}
    # => [{1, "alice@example.com"}, ...]

    from u in User, select: %{id: u.id, email: u.email}
    # => [%{id: 1, email: "alice@example.com"}, ...]

    # ORDER BY:
    from u in User, order_by: [asc: u.username]
    from u in User, order_by: [desc: u.inserted_at, asc: u.id]

    # LIMIT and OFFSET (pagination):
    from u in User,
      order_by: [asc: u.id],
      limit: 20,
      offset: (page - 1) * 20\
    """
    |> String.trim()
  end

  defp dynamic_query_code do
    """
    import Ecto.Query

    # Dynamic/4 builds query conditions at runtime
    # without unsafe string concatenation.

    def list_users(filters) do
      conditions = build_conditions(filters)
      from(u in User, where: ^conditions)
      |> Repo.all()
    end

    defp build_conditions(filters) do
      Enum.reduce(filters, dynamic(true), fn
        {:role, role}, acc ->
          dynamic([u], ^acc and u.role == ^role)
        {:verified, v}, acc ->
          dynamic([u], ^acc and u.verified == ^v)
        {:min_age, age}, acc ->
          dynamic([u], ^acc and u.age >= ^age)
        _, acc ->
          acc
      end)
    end\
    """
    |> String.trim()
  end

  defp fragment_code do
    """
    import Ecto.Query

    # fragment/1 injects raw SQL safely
    # (parameters still use ? for safety):

    from u in User,
      where: fragment("lower(?)", u.email) ==
             ^String.downcase(email)

    # PostgreSQL-specific functions:
    from p in Post,
      order_by: fragment("? DESC NULLS LAST",
                         p.published_at)

    # Array operations (Postgres):
    from p in Post,
      where: fragment("? @> ARRAY[?]",
                      p.tags, ^"elixir")

    # JSON access (Postgres jsonb):
    from u in User,
      where: fragment("?->>'city' = ?",
                      u.metadata, ^"London")\
    """
    |> String.trim()
  end

  defp join_code do
    """
    import Ecto.Query

    # INNER JOIN using assoc/2 (follows defined associations):
    from p in Post,
      join: u in assoc(p, :author),
      where: u.role == "admin",
      select: p

    # Manual JOIN with on:
    from p in Post,
      join: u in User, on: u.id == p.author_id,
      where: u.verified == true,
      select: {p.title, u.username}

    # LEFT JOIN (include posts with no author):
    from p in Post,
      left_join: u in User, on: u.id == p.author_id,
      select: %{title: p.title, author: u.username}

    # Multiple joins:
    from p in Post,
      join: u in assoc(p, :author),
      join: c in assoc(p, :category),
      where: c.name == "Elixir",
      select: %{title: p.title, author: u.username}\
    """
    |> String.trim()
  end

  defp join_types_code do
    """
    # join (INNER JOIN):
    join: u in User, on: u.id == p.author_id

    # left_join (LEFT OUTER JOIN):
    left_join: c in Comment, on: c.post_id == p.id

    # right_join (RIGHT OUTER JOIN):
    right_join: p in Post, on: p.user_id == u.id

    # cross_join (CROSS JOIN):
    cross_join: s in Size

    # inner_lateral_join (PostgreSQL LATERAL):
    inner_lateral_join: latest in subquery(
      from c in Comment,
        where: c.post_id == parent_as(:post).id,
        order_by: [desc: c.inserted_at],
        limit: 1
    ), on: true\
    """
    |> String.trim()
  end

  defp preload_join_code do
    """
    import Ecto.Query

    # Preload associations using join
    # (single query instead of N+1):
    from p in Post,
      join: u in assoc(p, :author),
      preload: [author: u]

    # Preload with conditions on the association:
    from u in User,
      left_join: p in assoc(u, :posts),
      on: p.status == "published",
      preload: [posts: p]

    # Preload multiple levels:
    from u in User,
      preload: [posts: [:comments, :tags]]

    # Preload in one shot after fetch:
    user = Repo.get!(User, id)
    user = Repo.preload(user, [:posts, :profile])\
    """
    |> String.trim()
  end

  defp advanced_code do
    """
    import Ecto.Query

    # Subquery:
    latest_posts = from p in Post,
      where: p.status == "published",
      order_by: [desc: p.published_at],
      limit: 5

    from p in subquery(latest_posts),
      join: u in User, on: u.id == p.author_id,
      select: %{title: p.title, author: u.username}

    # SELECT DISTINCT:
    from u in User,
      distinct: u.role,
      select: u.role

    # Count distinct:
    from p in Post,
      select: count(p.author_id, :distinct)

    # COALESCE / NULL handling:
    from u in User,
      select: coalesce(u.display_name, u.username)\
    """
    |> String.trim()
  end

  defp named_bindings_code do
    """
    import Ecto.Query

    # Named bindings let you refer to joins
    # in later pipe stages:
    query =
      from p in Post, as: :post
    query =
      from [post: p] in query,
        join: u in User, as: :author,
          on: u.id == p.author_id

    # Add where clause using named binding:
    query =
      from [author: u] in query,
        where: u.verified == true

    # Useful for building queries across function boundaries:
    def with_author(query) do
      from [post: p] in query,
        join: u in User, as: :author,
          on: u.id == p.author_id
    end

    def active_authors(query) do
      from [author: u] in query,
        where: u.verified == true
    end

    Post
    |> with_author()
    |> active_authors()
    |> Repo.all()\
    """
    |> String.trim()
  end

  defp group_having_code do
    """
    import Ecto.Query

    # GROUP BY:
    from p in Post,
      group_by: p.author_id,
      select: {p.author_id, count(p.id)}

    # HAVING (filter on aggregates):
    from p in Post,
      group_by: p.author_id,
      having: count(p.id) > 5,
      select: {p.author_id, count(p.id)}

    # Multiple aggregates:
    from o in Order,
      group_by: o.status,
      select: %{
        status:    o.status,
        count:     count(o.id),
        total:     sum(o.total_cents),
        avg:       avg(o.total_cents)
      }

    # With join:
    from p in Post,
      join: u in assoc(p, :author),
      group_by: [u.id, u.username],
      select: {u.username, count(p.id)}\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # Ecto.Query cheat sheet
    import Ecto.Query

    # Basic select:
    from(u in User) |> Repo.all()
    from(u in User, select: u.email) |> Repo.all()

    # Filter:
    from u in User,
      where: u.role == ^role and u.verified == true

    # Dynamic pin (safe from injection):
    email = "alice@example.com"
    from u in User, where: u.email == ^email

    # Sorting & pagination:
    from u in User,
      order_by: [desc: u.inserted_at],
      limit: 20,
      offset: ^offset

    # Aggregates:
    from(u in User, select: count(u.id)) |> Repo.one()
    Repo.aggregate(User, :count)

    # Grouping:
    from p in Post,
      group_by: p.author_id,
      select: {p.author_id, count(p.id)}

    # Join:
    from p in Post,
      join: u in assoc(p, :author),
      where: u.verified == true,
      preload: [author: u]

    # Fragment (raw SQL):
    from u in User,
      where: fragment("lower(?)", u.email) == ^email

    # Dynamic conditions:
    conditions = dynamic([u], u.verified == true)
    conditions = dynamic([u], ^conditions and u.age > ^age)
    from(u in User, where: ^conditions) |> Repo.all()

    # Subquery:
    sub = from(p in Post,
      where: p.status == "published",
      limit: 10)
    from(p in subquery(sub)) |> Repo.all()

    # Composing queries:
    base = from(u in User, where: u.active == true)
    with_role = from u in base, where: u.role == ^role
    Repo.all(with_role)\
    """
    |> String.trim()
  end
end
