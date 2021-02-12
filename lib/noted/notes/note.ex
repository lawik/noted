defmodule Noted.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:body, :string)
    field(:title, :string)

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :body])
    |> validate_required([:title])
  end
end
