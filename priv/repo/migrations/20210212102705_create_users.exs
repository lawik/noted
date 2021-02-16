defmodule Noted.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :telegram_id, :integer
      add :telegram_data, :map

      timestamps()
    end

    create unique_index(:users, [:telegram_id], name: :users_unique_telegram_id)
  end
end
