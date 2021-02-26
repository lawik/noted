defmodule Noted.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :path, :string
      add :size, :integer
      add :mimetype, :string
      add :note_id, references(:notes, on_delete: :delete_all)

      timestamps()
    end

    create index(:files, [:note_id])
  end
end
