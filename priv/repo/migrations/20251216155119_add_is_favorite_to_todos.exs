defmodule ElixirKatas.Repo.Migrations.AddIsFavoriteToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :is_favorite, :boolean, default: false, null: false
    end
  end
end
