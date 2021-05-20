defmodule Noted.Repo.Migrations.FileAddFilename do
  use Ecto.Migration

  def change do
    alter table(:files) do
      add :filename, :text
    end
  end
end
