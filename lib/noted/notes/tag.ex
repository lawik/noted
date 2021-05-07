defmodule Noted.Notes.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Noted.Notes.NotesTags

  schema "tags" do
    field :name, :string
    many_to_many :notes, Noted.Notes.Note, join_through: NotesTags

    belongs_to :user, Noted.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
  end
end
