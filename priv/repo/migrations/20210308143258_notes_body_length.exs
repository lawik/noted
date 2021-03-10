defmodule Noted.Repo.Migrations.NotesBodyLength do
  use Ecto.Migration

  def change do
    alter table(:notes) do
      modify :body, :text
    end
  end
end
