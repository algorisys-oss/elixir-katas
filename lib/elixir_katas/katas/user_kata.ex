defmodule ElixirKatas.Katas.UserKata do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_katas" do
    field :kata_name, :string
    field :source_code, :string
    belongs_to :user, ElixirKatas.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_kata, attrs) do
    user_kata
    |> cast(attrs, [:kata_name, :source_code, :user_id])
    |> validate_required([:kata_name, :source_code, :user_id])
    |> unique_constraint([:user_id, :kata_name])
  end
end
