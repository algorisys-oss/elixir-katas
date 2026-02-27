defmodule ElixirKatasWeb.PhoenixKata40ContextFunctionsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # Standard CRUD patterns in a Phoenix context module

    defmodule MyApp.Blog do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Blog.{Post, Comment}

      # --- Reads ---
      def list_posts do
        from(p in Post, order_by: [desc: p.inserted_at])
        |> Repo.all()
      end

      def list_published_posts do
        from(p in Post,
          where: p.published == true,
          order_by: [desc: p.published_at],
          preload: [:author])
        |> Repo.all()
      end

      def get_post!(id), do: Repo.get!(Post, id)
      def get_post(id), do: Repo.get(Post, id)

      def get_post_by_slug(slug) do
        Repo.get_by(Post, slug: slug)
      end

      # --- Writes ---
      def create_post(attrs \\\\ %{}) do
        %Post{}
        |> Post.changeset(attrs)
        |> Repo.insert()
      end

      def update_post(%Post{} = post, attrs) do
        post
        |> Post.changeset(attrs)
        |> Repo.update()
      end

      def delete_post(%Post{} = post) do
        Repo.delete(post)
      end

      # --- Change (returns changeset for forms, no DB call) ---
      def change_post(%Post{} = post, attrs \\\\ %{}) do
        Post.changeset(post, attrs)
      end

      # --- Domain-specific ---
      def publish_post(%Post{} = post) do
        update_post(post, %{
          published: true,
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
      end
    end

    # Controller usage:
    def create(conn, %{"post" => post_params}) do
      case Blog.create_post(post_params) do
        {:ok, post} ->
          conn |> put_flash(:info, "Post created.") |> redirect(to: ~p"/posts/\#{post.id}")
        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end

    # LiveView form handler:
    def handle_event("validate", %{"post" => params}, socket) do
      changeset =
        socket.assigns.post
        |> Blog.change_post(params)
        |> Map.put(:action, :validate)
      {:noreply, assign(socket, form: to_form(changeset))}
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "overview", selected_topic: "list")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Context Functions</h2>
      <p class="text-gray-600 dark:text-gray-300">
        The standard CRUD patterns used in Phoenix context modules:
        list, get, create, update, delete, and the change helper for forms.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["overview", "reads", "writes", "errors", "code"]}
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
            <button :for={topic <- ["list", "get", "create", "update", "delete"]}
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

          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <div :for={func <- crud_functions()} class="p-3 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 border border-indigo-200 dark:border-indigo-800">
              <p class="text-xs font-semibold font-mono text-indigo-700 dark:text-indigo-300">{func.name}</p>
              <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">{func.desc}</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Reads -->
      <%= if @active_tab == "reads" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Read functions fetch data from the database. The naming convention signals whether they raise or return nil on missing records.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{reads_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Bang vs non-bang</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{bang_vs_nonbang_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Filtered queries</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{filtered_reads_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <p class="text-sm font-semibold text-blue-700 dark:text-blue-300 mb-1">Preloading associations</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{preload_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Writes -->
      <%= if @active_tab == "writes" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Write functions (create, update, delete) return <code>&#123;:ok, struct&#125;</code> or <code>&#123;:error, changeset&#125;</code>,
            letting callers pattern-match on success or failure.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{writes_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Controller usage</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{controller_write_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">change_* for forms</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{change_function_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Ecto.Multi for atomic operations</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{multi_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Errors -->
      <%= if @active_tab == "errors" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Phoenix contexts use standard Elixir error tuples. Understanding what each function returns helps you handle errors correctly throughout your app.
          </p>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{error_patterns_code()}</div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
              <p class="text-sm font-semibold text-green-700 dark:text-green-300 mb-2">Changeset errors in forms</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{changeset_errors_code()}</div>
            </div>
            <div class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <p class="text-sm font-semibold text-red-700 dark:text-red-300 mb-2">Custom error tuples</p>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{custom_error_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
            <p class="text-sm font-semibold text-purple-700 dark:text-purple-300 mb-1">Translating errors for the UI</p>
            <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{translate_errors_code()}</div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Blog Context</h4>
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
  defp tab_label("reads"), do: "Read Functions"
  defp tab_label("writes"), do: "Write Functions"
  defp tab_label("errors"), do: "Error Handling"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("list"), do: "list_*"
  defp topic_label("get"), do: "get_*"
  defp topic_label("create"), do: "create_*"
  defp topic_label("update"), do: "update_*"
  defp topic_label("delete"), do: "delete_*"

  defp crud_functions do
    [
      %{name: "list_posts()", desc: "Returns all records as a list"},
      %{name: "get_post!(id)", desc: "Returns one record, raises if missing"},
      %{name: "get_post(id)", desc: "Returns one record or nil"},
      %{name: "create_post(attrs)", desc: "Inserts; returns {:ok, _} or {:error, _}"},
      %{name: "update_post(post, attrs)", desc: "Updates; returns {:ok, _} or {:error, _}"},
      %{name: "delete_post(post)", desc: "Deletes; returns {:ok, _} or {:error, _}"},
      %{name: "change_post(post, attrs)", desc: "Returns a changeset for use in forms"}
    ]
  end

  defp overview_code("list") do
    """
    # list_* returns all records (optionally filtered)
    def list_posts do
      Repo.all(Post)
    end

    # With ordering:
    def list_posts do
      Post
      |> order_by([p], desc: p.inserted_at)
      |> Repo.all()
    end

    # With scope (only published):
    def list_published_posts do
      Post
      |> where([p], p.published == true)
      |> order_by([p], desc: p.published_at)
      |> Repo.all()
    end

    # With pagination:
    def list_posts(opts \\\\ []) do
      page = Keyword.get(opts, :page, 1)
      per_page = Keyword.get(opts, :per_page, 20)
      offset = (page - 1) * per_page

      Post
      |> order_by([p], desc: p.inserted_at)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
    end\
    """
    |> String.trim()
  end

  defp overview_code("get") do
    """
    # get_*! raises Ecto.NoResultsError if not found
    # Use in contexts where missing record = programmer error
    def get_post!(id), do: Repo.get!(Post, id)

    # get_* returns nil if not found
    # Use when nil is a valid expected result
    def get_post(id), do: Repo.get(Post, id)

    # get_*_by fetches by arbitrary fields
    def get_post_by_slug(slug) do
      Repo.get_by(Post, slug: slug)
    end

    # With preloads:
    def get_post_with_comments!(id) do
      Post
      |> Repo.get!(id)
      |> Repo.preload(:comments)
    end

    # With custom query:
    def get_post_for_user!(id, user_id) do
      Repo.get_by!(Post, id: id, user_id: user_id)
    end\
    """
    |> String.trim()
  end

  defp overview_code("create") do
    """
    # create_* inserts a new record
    # Returns {:ok, struct} or {:error, changeset}
    def create_post(attrs \\\\ %{}) do
      %Post{}
      |> Post.changeset(attrs)
      |> Repo.insert()
    end

    # Usage in a controller:
    case Blog.create_post(attrs) do
      {:ok, post} ->
        redirect(conn, to: ~p"/posts/\#{post.id}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end

    # With additional setup:
    def create_post_for_user(attrs, user) do
      attrs_with_owner = Map.put(attrs, "user_id", user.id)

      %Post{}
      |> Post.changeset(attrs_with_owner)
      |> Repo.insert()
    end\
    """
    |> String.trim()
  end

  defp overview_code("update") do
    """
    # update_* updates an existing record
    # Takes the current struct + new attrs
    # Returns {:ok, struct} or {:error, changeset}
    def update_post(%Post{} = post, attrs) do
      post
      |> Post.changeset(attrs)
      |> Repo.update()
    end

    # Usage — load first, then update:
    post = Blog.get_post!(id)
    case Blog.update_post(post, params) do
      {:ok, post} ->
        redirect(conn, to: ~p"/posts/\#{post.id}")
      {:error, changeset} ->
        render(conn, :edit, post: post, changeset: changeset)
    end

    # The pattern: always pass the loaded struct, not just an ID.
    # This prevents accidentally overwriting fields you didn't intend to touch.\
    """
    |> String.trim()
  end

  defp overview_code("delete") do
    """
    # delete_* removes a record
    # Returns {:ok, struct} or {:error, changeset}
    def delete_post(%Post{} = post) do
      Repo.delete(post)
    end

    # Usage — load first, then delete:
    post = Blog.get_post!(id)
    case Blog.delete_post(post) do
      {:ok, _post} ->
        redirect(conn, to: ~p"/posts")
      {:error, changeset} ->
        # Deletion can fail if there are constraint violations
        # e.g. foreign key constraints with on_delete: :restrict
        put_flash(conn, :error, "Could not delete post.")
        redirect(conn, to: ~p"/posts/\#{post.id}")
    end

    # Soft delete (mark as deleted, don't remove row):
    def soft_delete_post(%Post{} = post) do
      update_post(post, %{deleted_at: DateTime.utc_now()})\
    end
    """
    |> String.trim()
  end

  defp reads_code do
    """
    defmodule MyApp.Blog do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Blog.Post

      # Fetch all — always returns a list (empty if none)
      def list_posts do
        Repo.all(Post)
      end

      # Fetch with filter
      def list_published_posts do
        from(p in Post, where: p.published == true,
          order_by: [desc: p.published_at])
        |> Repo.all()
      end

      # Fetch one — raises Ecto.NoResultsError if not found
      def get_post!(id), do: Repo.get!(Post, id)

      # Fetch one — returns nil if not found
      def get_post(id), do: Repo.get(Post, id)

      # Fetch by arbitrary field
      def get_post_by_slug(slug) do
        Repo.get_by(Post, slug: slug)
      end

      # Fetch with association preloaded
      def get_post_with_author!(id) do
        Post
        |> Repo.get!(id)
        |> Repo.preload(:author)
      end

      # Count records
      def count_posts do
        Repo.aggregate(Post, :count)
      end
    end\
    """
    |> String.trim()
  end

  defp bang_vs_nonbang_code do
    """
    # Use get_post!(id) when:
    # - You expect the record to always exist
    # - A missing record is a programming error
    # - You want a 500 error (not a redirect) on miss
    post = Blog.get_post!(id)
    # Raises Ecto.NoResultsError if not found
    # Phoenix converts this to a 404 page by default

    # Use get_post(id) when:
    # - nil is a valid expected result
    # - You want to decide what to do on nil
    case Blog.get_post(id) do
      nil -> redirect(conn, to: ~p"/posts")
      post -> render(conn, :show, post: post)
    end\
    """
    |> String.trim()
  end

  defp filtered_reads_code do
    """
    # Common filter patterns in context read functions:

    # Filter by field value
    def list_posts_by_author(author_id) do
      from(p in Post, where: p.author_id == ^author_id)
      |> Repo.all()
    end

    # Text search
    def search_posts(query) do
      like = "%\#{query}%"
      from(p in Post,
        where: ilike(p.title, ^like) or ilike(p.body, ^like))
      |> Repo.all()
    end

    # Date range
    def list_posts_since(date) do
      from(p in Post, where: p.inserted_at >= ^date)
      |> Repo.all()
    end\
    """
    |> String.trim()
  end

  defp preload_code do
    """
    # Preload after fetch (two queries):
    def get_post_with_comments!(id) do
      Post
      |> Repo.get!(id)
      |> Repo.preload(:comments)
    end

    # Preload in query (one query with join):
    def get_post_with_comments!(id) do
      from(p in Post,
        where: p.id == ^id,
        preload: [:comments, :author])
      |> Repo.one!()
    end

    # Preload nested:
    def list_posts_with_details do
      Post
      |> Repo.all()
      |> Repo.preload([comments: :author, author: :profile])
    end\
    """
    |> String.trim()
  end

  defp writes_code do
    """
    defmodule MyApp.Blog do
      # Create: insert a new record
      def create_post(attrs \\\\ %{}) do
        %Post{}
        |> Post.changeset(attrs)
        |> Repo.insert()
      end

      # Update: modify an existing record
      def update_post(%Post{} = post, attrs) do
        post
        |> Post.changeset(attrs)
        |> Repo.update()
      end

      # Delete: remove a record
      def delete_post(%Post{} = post) do
        Repo.delete(post)
      end

      # Change: return a changeset for a form (no DB call)
      def change_post(%Post{} = post, attrs \\\\ %{}) do
        Post.changeset(post, attrs)
      end

      # Upsert (insert or update on conflict):
      def upsert_post(attrs) do
        %Post{}
        |> Post.changeset(attrs)
        |> Repo.insert(
          on_conflict: {:replace, [:title, :body, :updated_at]},
          conflict_target: :slug
        )
      end
    end\
    """
    |> String.trim()
  end

  defp controller_write_code do
    """
    # create action
    def create(conn, %{"post" => post_params}) do
      case Blog.create_post(post_params) do
        {:ok, post} ->
          conn
          |> put_flash(:info, "Post created.")
          |> redirect(to: ~p"/posts/\#{post.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end

    # update action
    def update(conn, %{"id" => id, "post" => post_params}) do
      post = Blog.get_post!(id)

      case Blog.update_post(post, post_params) do
        {:ok, post} ->
          conn
          |> put_flash(:info, "Post updated.")
          |> redirect(to: ~p"/posts/\#{post.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, post: post, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp change_function_code do
    """
    # change_* returns a changeset for use in forms.
    # Does NOT touch the database.
    def change_post(%Post{} = post, attrs \\\\ %{}) do
      Post.changeset(post, attrs)
    end

    # In a controller new/edit action:
    def new(conn, _params) do
      changeset = Blog.change_post(%Post{})
      render(conn, :new, changeset: changeset)
    end

    def edit(conn, %{"id" => id}) do
      post = Blog.get_post!(id)
      changeset = Blog.change_post(post)
      render(conn, :edit, post: post, changeset: changeset)
    end

    # In a LiveView mount:
    def mount(%{"id" => id}, _session, socket) do
      post = Blog.get_post!(id)
      changeset = Blog.change_post(post)
      {:ok, assign(socket, post: post, form: to_form(changeset))}
    end\
    """
    |> String.trim()
  end

  defp multi_code do
    """
    # Ecto.Multi groups multiple DB operations atomically:
    def create_post_with_tags(attrs, tag_names) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:post,
          Post.changeset(%Post{}, attrs))
      |> Ecto.Multi.run(:tags, fn _repo, %{post: post} ->
          tags = Enum.map(tag_names, &find_or_create_tag/1)
          {:ok, tags}
        end)
      |> Ecto.Multi.run(:post_tags, fn _repo,
                                        %{post: post, tags: tags} ->
          insert_post_tags(post, tags)
        end)
      |> Repo.transaction()
    end

    # Returns {:ok, %{post: post, tags: tags, post_tags: ...}}
    # or {:error, failed_step, changeset, changes_so_far}\
    """
    |> String.trim()
  end

  defp error_patterns_code do
    """
    # Standard context return values:

    # Reads (never error tuple):
    Blog.list_posts()          # => [%Post{}, ...]  (always a list)
    Blog.get_post!(id)         # => %Post{}  OR  raises
    Blog.get_post(id)          # => %Post{}  OR  nil

    # Writes (always ok/error tuple):
    Blog.create_post(attrs)    # => {:ok, %Post{}}
                               #    {:error, %Ecto.Changeset{}}

    Blog.update_post(p, attrs) # => {:ok, %Post{}}
                               #    {:error, %Ecto.Changeset{}}

    Blog.delete_post(post)     # => {:ok, %Post{}}
                               #    {:error, %Ecto.Changeset{}}

    # Changeset has errors:
    {:error, changeset} = Blog.create_post(%{title: nil})
    changeset.valid?      # => false
    changeset.errors      # => [title: {"can't be blank", [...]}]\
    """
    |> String.trim()
  end

  defp changeset_errors_code do
    """
    # Extracting errors from a changeset:
    # (Phoenix.HTML helpers do this automatically for forms)

    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{" <> to_string(key) <> "}", to_string(value))
      end)
    end)
    # => %{title: ["can't be blank"], email: ["has already been taken"]}

    # In HEEx templates with Phoenix.HTML:
    # <.input field={@form[:title]} label="Title" />
    # Validation errors are shown automatically\
    """
    |> String.trim()
  end

  defp custom_error_code do
    """
    # Custom error tuples for non-changeset failures:
    def authenticate_user(email, password) do
      case get_user_by_email(email) do
        nil ->
          Bcrypt.no_user_verify()  # constant-time to prevent timing attacks
          {:error, :not_found}

        user ->
          if Bcrypt.verify_pass(password, user.hashed_password) do
            {:ok, user}
          else
            {:error, :invalid_password}
          end
      end
    end

    # Caller pattern-matches on the reason:
    case Accounts.authenticate_user(email, password) do
      {:ok, user}               -> log_in_user(conn, user)
      {:error, :not_found}      -> put_flash(conn, :error, "No account found.")
      {:error, :invalid_password} -> put_flash(conn, :error, "Wrong password.")
    end\
    """
    |> String.trim()
  end

  defp translate_errors_code do
    """
    # Phoenix generates a translate_errors helper in CoreComponents:
    # (from mix phx.gen.auth or mix phx.new)

    def translate_error({msg, opts}) do
      if count = opts[:count] do
        Gettext.dngettext(MyAppWeb.Gettext,
          "errors", msg, msg, count, opts)
      else
        Gettext.dgettext(MyAppWeb.Gettext, "errors", msg, opts)
      end
    end

    # In a LiveView form handler:
    def handle_event("validate", %{"post" => params}, socket) do
      changeset =
        socket.assigns.post
        |> Blog.change_post(params)
        |> Map.put(:action, :validate)  # shows errors immediately

      {:noreply, assign(socket, form: to_form(changeset))}
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    # lib/my_app/blog/post.ex
    defmodule MyApp.Blog.Post do
      use Ecto.Schema
      import Ecto.Changeset

      schema "posts" do
        field :title, :string
        field :body, :text
        field :slug, :string
        field :published, :boolean, default: false
        field :published_at, :utc_datetime
        belongs_to :author, MyApp.Accounts.User
        has_many :comments, MyApp.Blog.Comment
        timestamps()
      end

      @required [:title, :body, :author_id]
      @optional [:slug, :published, :published_at]

      @doc false
      def changeset(post, attrs) do
        post
        |> cast(attrs, @required ++ @optional)
        |> validate_required(@required)
        |> validate_length(:title, min: 3, max: 200)
        |> maybe_generate_slug()
        |> unique_constraint(:slug)
      end

      defp maybe_generate_slug(changeset) do
        case get_change(changeset, :title) do
          nil -> changeset
          title -> put_change(changeset, :slug, slugify(title))
        end
      end

      defp slugify(str) do
        str
        |> String.downcase()
        |> String.replace(~r/[^a-z0-9]+/, "-")
        |> String.trim("-")
      end
    end

    # lib/my_app/blog.ex
    defmodule MyApp.Blog do
      import Ecto.Query, warn: false
      alias MyApp.Repo
      alias MyApp.Blog.{Post, Comment}

      # --- Reads ---
      def list_posts do
        from(p in Post, order_by: [desc: p.inserted_at])
        |> Repo.all()
      end

      def list_published_posts do
        from(p in Post,
          where: p.published == true,
          order_by: [desc: p.published_at],
          preload: [:author])
        |> Repo.all()
      end

      def get_post!(id), do: Repo.get!(Post, id)
      def get_post(id), do: Repo.get(Post, id)

      def get_post_by_slug(slug) do
        Repo.get_by(Post, slug: slug)
      end

      # --- Writes ---
      def create_post(attrs \\\\ %{}) do
        %Post{}
        |> Post.changeset(attrs)
        |> Repo.insert()
      end

      def update_post(%Post{} = post, attrs) do
        post
        |> Post.changeset(attrs)
        |> Repo.update()
      end

      def delete_post(%Post{} = post) do
        Repo.delete(post)
      end

      def change_post(%Post{} = post, attrs \\\\ %{}) do
        Post.changeset(post, attrs)
      end

      def publish_post(%Post{} = post) do
        update_post(post, %{
          published: true,
          published_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
      end
    end\
    """
    |> String.trim()
  end
end
