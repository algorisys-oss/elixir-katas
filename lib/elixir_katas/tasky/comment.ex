defmodule ElixirKatas.Tasky.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string

    belongs_to :todo, ElixirKatas.Tasky.Todo
    belongs_to :user, ElixirKatas.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :todo_id, :user_id])
    |> validate_required([:content, :todo_id, :user_id])
  end
end
