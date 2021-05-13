defmodule Noted.Notes.File do
  use Ecto.Schema
  import Ecto.Changeset

  schema "files" do
    field :mimetype, :string
    field :path, :string
    field :size, :integer

    belongs_to :note, Noted.Notes.Note

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:path, :size, :mimetype, :note_id])
    |> validate_required([:path, :size, :mimetype, :note_id])
  end
end
