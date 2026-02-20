defmodule ElixirKatas.Repo.Migrations.CreateUserKatas do
  use Ecto.Migration

  def change do
    create table(:user_katas) do
      add :kata_name, :string
      add :source_code, :text
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_katas, [:user_id, :kata_name])
  end
end
