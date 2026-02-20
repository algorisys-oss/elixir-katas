defmodule ElixirKatas.Repo.Migrations.AddBlueBeltTables do
  use Ecto.Migration

  def change do
    create table(:subtasks) do
      add :title, :string
      add :is_complete, :boolean, default: false, null: false
      add :todo_id, references(:todos, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:subtasks, [:todo_id])

    create table(:comments) do
      add :content, :text
      add :todo_id, references(:todos, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:todo_id])
    create index(:comments, [:user_id])

    create table(:attachments) do
      add :filename, :string
      add :content_type, :string
      add :path, :string
      add :size, :integer
      add :todo_id, references(:todos, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:attachments, [:todo_id])
  end
end
