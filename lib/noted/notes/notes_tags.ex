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
    |> foreign_key_constraint(:note_id)
    |> foreign_key_constraint(:tag_id)
    |> unique_constraint([:note, :tag], name: :note_tag_unique, message: "ALREADY_EXISTS")
  end
end
