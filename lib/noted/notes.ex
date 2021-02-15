defmodule Noted.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  alias Noted.Repo

  alias Noted.Notes.Note

  def ingest_note(user_id, _message_id, full_text) do
    create_note(user_id, full_text, "")

    Phoenix.PubSub.broadcast!(
      Noted.PubSub,
      "note-update:#{user_id}",
      {:notes_updated, user_id}
    )
  end

  @doc """
  Returns the list of notes for a given user.

  ## Examples

      iex> list_notes(user_id)
      [%Note{}, ...]

  """
  def list_notes(user_id) do
    Repo.all(Note, where: [user_id: user_id])
  end

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(id), do: Repo.get!(Note, id)

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(%{field: value})
      {:ok, %Note{}}

      iex> create_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
  end

  def create_note(user_id, title, body) do
    create_note(%{user_id: user_id, title: title, body: body})
  end

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, note} ->
        Phoenix.PubSub.broadcast!(
          Noted.PubSub,
          "note-update:#{note.user_id}",
          {:notes_updated, note.user_id}
        )

        {:ok, note}

      error ->
        error
    end
  end

  def update_note(note_id, attrs) when is_integer(note_id) and is_list(attrs) do
    attrs = Enum.into(attrs, %{})
    result = update_note(%Note{id: note_id}, attrs)
    result
  end

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{data: %Note{}}

  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  def validate_insert_note(note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Map.put(:action, :insert)
  end
end
