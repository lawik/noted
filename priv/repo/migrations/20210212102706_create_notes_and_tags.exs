defmodule Noted.Repo.Migrations.CreateNotesAndTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string
      add :user_id, references(:users)

      timestamps()
    end

    create unique_index(:tags, [:name, :user_id], name: :tag_unique_by_user)

    create table(:notes) do
      add :title, :string
      add :body, :text

      timestamps()
      add :user_id, references(:users)
    end

    create table(:notes_tags) do
      add :note_id, references(:notes, on_delete: :delete_all), primary_key: true
      add :tag_id, references(:tags, on_delete: :delete_all), primary_key: true

      timestamps()
    end

    create unique_index(:notes_tags, [:note_id, :tag_id], name: :note_tag_unique)
    create index(:notes_tags, [:note_id])
    create index(:notes_tags, [:tag_id])
  end
end
