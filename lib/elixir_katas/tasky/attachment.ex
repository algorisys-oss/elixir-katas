defmodule ElixirKatas.Tasky.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "attachments" do
    field :filename, :string
    field :content_type, :string
    field :path, :string
    field :size, :integer

    belongs_to :todo, ElixirKatas.Tasky.Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:filename, :content_type, :path, :size, :todo_id])
    |> validate_required([:filename, :path, :todo_id])
  end
end
