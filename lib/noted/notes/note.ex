defmodule Noted.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  alias Noted.Notes.NotesTags

  schema "notes" do
    field(:body, :string)
    field(:title, :string)

    belongs_to :user, Noted.Accounts.User

    many_to_many :tags, Noted.Notes.Tag, join_through: NotesTags
    has_many :files, Noted.Notes.File
    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:user_id, :title, :body])

    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 200)
  end

  def add_tags(note, tags) do
    put_assoc(note, :tags, tags)
  end
end
