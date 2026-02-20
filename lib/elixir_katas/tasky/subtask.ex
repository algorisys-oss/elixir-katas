defmodule ElixirKatas.Tasky.Subtask do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subtasks" do
    field :title, :string
    field :is_complete, :boolean, default: false

    belongs_to :todo, ElixirKatas.Tasky.Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subtask, attrs) do
    subtask
    |> cast(attrs, [:title, :is_complete, :todo_id])
    |> validate_required([:title, :todo_id])
  end
end
