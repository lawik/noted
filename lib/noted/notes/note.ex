defmodule Noted.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:body, :string)
    field(:title, :string)

    belongs_to :user, Noted.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:user_id, :title, :body])
    |> validate_required([:title])
    |> validate_length(:title, min: 1)
  end
end
