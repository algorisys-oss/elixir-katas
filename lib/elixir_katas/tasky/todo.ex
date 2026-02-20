defmodule ElixirKatas.Tasky.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :is_complete, :boolean, default: false
    field :is_favorite, :boolean, default: false
    field :category, :string
    field :priority, :string, default: "medium"
    field :due_date, :date

    belongs_to :user, ElixirKatas.Accounts.User
    has_many :subtasks, ElixirKatas.Tasky.Subtask, on_delete: :delete_all
    has_many :comments, ElixirKatas.Tasky.Comment, on_delete: :delete_all
    has_many :attachments, ElixirKatas.Tasky.Attachment, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :is_complete, :is_favorite, :category, :priority, :due_date])
    |> validate_required([:title])
    |> validate_inclusion(:priority, ["low", "medium", "high"])
    |> validate_due_date()
  end

  defp validate_due_date(changeset) do
    case get_change(changeset, :due_date) do
      nil -> changeset
      due_date ->
        today = Date.utc_today()
        if Date.compare(due_date, today) == :lt do
          add_error(changeset, :due_date, "cannot be in the past")
        else
          changeset
        end
    end
  end
end
