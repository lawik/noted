defmodule Noted.Repo.Migrations.AddPhotoPathToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :photo_path, :string, null: true
    end
  end
end
