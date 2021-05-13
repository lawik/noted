defmodule Noted.Notes.NotesTags do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes_tags" do
    belongs_to :note, Noted.Notes.Note, primary_key: true
    belongs_to :tag, Noted.Notes.Tag, primary_key: true

    timestamps()
  end

  @doc false
  @required [:note_id, :tag_id]
  def changeset(note, attrs) do
    note
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
