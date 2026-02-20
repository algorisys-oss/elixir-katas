defmodule ElixirKatas.Repo.Migrations.AddOrganizationFieldsToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :category, :string
      add :priority, :string, default: "medium"
      add :due_date, :date
    end

    create index(:todos, [:category])
    create index(:todos, [:priority])
    create index(:todos, [:due_date])
  end
end
