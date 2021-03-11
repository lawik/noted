defmodule Noted.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:telegram_data, :string)
    field(:telegram_id, :integer)
    field(:photo_path, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:telegram_id, :telegram_data, :photo_path])
    |> validate_required([:telegram_id, :telegram_data])
    |> unique_constraint(:unique_telegram_id, name: :users_unique_telegram_id)
  end
end
