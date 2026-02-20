defmodule ElixirKatas.Tasky do
  @moduledoc """
  The Tasky context.
  """

  import Ecto.Query, warn: false
  alias ElixirKatas.Repo

  alias ElixirKatas.Tasky.Todo
  @topic "tasky"

  def subscribe do
    Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
  end

  defp broadcast({:ok, todo}, event) do
    Phoenix.PubSub.broadcast(ElixirKatas.PubSub, @topic, {event, todo})
    {:ok, todo}
  end
  defp broadcast({:error, _} = error, _event), do: error

  @doc """
  Returns the list of todos.
  
  Supports pagination options: `page` (default 1) and `per_page` (default 5).
  Requires `user_id` to scope todos to a specific user.
  """
  def list_todos(user_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 5)
    offset = (page - 1) * per_page

    search = Keyword.get(opts, :search)
    category = Keyword.get(opts, :category)
    priority = Keyword.get(opts, :priority)
    due_date_filter = Keyword.get(opts, :due_date_filter)
    
    base_query = from t in Todo, where: t.user_id == ^user_id
    
    # Apply search filter
    query = if search && search != "" do
      search_term = "%#{search}%"
      from t in base_query, where: ilike(t.title, ^search_term)
    else
      base_query
    end

    # Apply category filter
    query = if category && category != "" do
      from t in query, where: t.category == ^category
    else
      query
    end

    # Apply priority filter
    query = if priority && priority != "" do
      from t in query, where: t.priority == ^priority
    else
      query
    end

    # Apply due date filter
    query = case due_date_filter do
      "overdue" ->
        today = Date.utc_today()
        from t in query, where: not is_nil(t.due_date) and t.due_date < ^today
      "today" ->
        today = Date.utc_today()
        from t in query, where: t.due_date == ^today
      "week" ->
        today = Date.utc_today()
        week_end = Date.add(today, 7)
        from t in query, where: not is_nil(t.due_date) and t.due_date >= ^today and t.due_date <= ^week_end
      "no_date" ->
        from t in query, where: is_nil(t.due_date)
      _ ->
        query
    end

    # Apply pagination and ordering
    query = from t in query,
      limit: ^per_page,
      offset: ^offset,
      order_by: [desc: t.inserted_at]
    
    # Count query with same filters
    count_query = base_query
    
    count_query = if search && search != "" do
      search_term = "%#{search}%"
      from t in count_query, where: ilike(t.title, ^search_term)
    else
      count_query
    end

    count_query = if category && category != "" do
      from t in count_query, where: t.category == ^category
    else
      count_query
    end

    count_query = if priority && priority != "" do
      from t in count_query, where: t.priority == ^priority
    else
      count_query
    end

    count_query = case due_date_filter do
      "overdue" ->
        today = Date.utc_today()
        from t in count_query, where: not is_nil(t.due_date) and t.due_date < ^today
      "today" ->
        today = Date.utc_today()
        from t in count_query, where: t.due_date == ^today
      "week" ->
        today = Date.utc_today()
        week_end = Date.add(today, 7)
        from t in count_query, where: not is_nil(t.due_date) and t.due_date >= ^today and t.due_date <= ^week_end
      "no_date" ->
        from t in count_query, where: is_nil(t.due_date)
      _ ->
        count_query
    end

    total_count = Repo.aggregate(count_query, :count, :id)
    entries = Repo.all(query)
    total_pages = ceil(total_count / per_page)
    
    %{
      entries: entries,
      page_number: page,
      page_size: per_page,
      total_pages: total_pages,
      total_entries: total_count
    }
  end

  @doc """
  Returns the total count of todos, optionally filtered by search.
  Requires `user_id` to scope todos to a specific user.
  """
  def count_todos(user_id, search \\ nil) do
    query = if search && search != "" do
        search_term = "%#{search}%"
        from t in Todo, where: t.user_id == ^user_id and ilike(t.title, ^search_term)
    else
        from t in Todo, where: t.user_id == ^user_id
    end
    Repo.aggregate(query, :count, :id)
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id) do
    Repo.get!(Todo, id)
    |> Repo.preload([:subtasks, comments: [:user], attachments: []])
  end

  @doc """
  Creates a todo for a specific user.
  """
  def create_todo(user_id, attrs) do
    %Todo{user_id: user_id}
    |> Todo.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:todo_created)
  end

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{field: new_value})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
    |> broadcast(:todo_updated)
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
    |> broadcast(:todo_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changeset{data: %Todo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Returns a list of unique categories for a user's todos.
  """
  def list_categories(user_id) do
    query = from t in Todo,
      where: t.user_id == ^user_id and not is_nil(t.category),
      distinct: true,
      select: t.category,
      order_by: t.category

    Repo.all(query)
  end

  @doc """
  Returns the count of overdue todos for a user.
  """
  def get_overdue_count(user_id) do
    today = Date.utc_today()
    query = from t in Todo,
      where: t.user_id == ^user_id and not is_nil(t.due_date) and t.due_date < ^today

    Repo.aggregate(query, :count, :id)
  end
  alias ElixirKatas.Tasky.Subtask
  alias ElixirKatas.Tasky.Comment
  alias ElixirKatas.Tasky.Attachment

  # ... Subtasks ...
  def list_subtasks(todo_id) do
    Repo.all(from s in Subtask, where: s.todo_id == ^todo_id, order_by: [asc: s.inserted_at])
  end

  def create_subtask(attrs) do
    %Subtask{}
    |> Subtask.changeset(attrs)
    |> Repo.insert()
  end

  def update_subtask(%Subtask{} = subtask, attrs) do
    subtask
    |> Subtask.changeset(attrs)
    |> Repo.update()
  end

  def delete_subtask(%Subtask{} = subtask) do
    Repo.delete(subtask)
  end

  def change_subtask(%Subtask{} = subtask, attrs \\ %{}) do
    Subtask.changeset(subtask, attrs)
  end

  # ... Comments ...
  def list_comments(todo_id) do
    Repo.all(from c in Comment, where: c.todo_id == ^todo_id, preload: [:user], order_by: [asc: c.inserted_at])
  end

  def create_comment(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  # ... Attachments ...
  def list_attachments(todo_id) do
    Repo.all(from a in Attachment, where: a.todo_id == ^todo_id, order_by: [desc: a.inserted_at])
  end

  def create_attachment(attrs) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
  end

  def delete_attachment(%Attachment{} = attachment) do
    Repo.delete(attachment)
  end
end
