defmodule Noted.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Noted.Repo

  alias Noted.Notes.Note
  alias Noted.Notes.Tag
  alias Noted.Notes.NotesTags

  @tag_pattern ~r/#([a-z]+)/
  @default_file_path "/tmp/noted_files_uploads"

  def format_body(nil) do
    {:safe, ""}
  end

  def format_body(body) do
    case Earmark.as_html(body) do
      {:ok, html, []} ->
        {:safe, html}

      {:ok, html, warnings} ->
        Logger.warn("Warnings from markdown parsing", warnings: warnings)
        {:safe, html}

      error ->
        Logger.error("Error in markdown parsing", error: error)
        {:safe, ""}
    end
  end

  def ingest_note(user_id, full_text) do
    parts =
      full_text
      |> String.split("\n", parts: 2)
      |> Enum.map(&String.trim/1)

    {title, body} =
      case parts do
        [title, body] -> {title, body}
        [title] -> {title, ""}
        _ -> {String.trim(full_text), ""}
      end

    tags =
      @tag_pattern
      |> Regex.scan(full_text)
      |> Enum.map(fn item ->
        case item do
          [_, tag] -> tag
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> ensure_tags(user_id)

    {:ok, note} = create_note(user_id, title, body, tags)

    Phoenix.PubSub.broadcast!(
      Noted.PubSub,
      "note-update:#{user_id}",
      {:notes_updated, user_id}
    )

    {:ok, note}
  end

  @doc """
  Returns the list of notes for a given user.

  ## Examples

      iex> list_notes(user_id)
      [%Note{}, ...]

  """
  def list_notes(user_id) do
    query =
      from n in Note,
        where: [user_id: ^user_id],
        preload: [:tags, :files]

    Repo.all(query)
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
  def get_note!(id) do
    Note
    |> Repo.get!(id)
    |> Repo.preload(:tags)
    |> Repo.preload(:files)
  end

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(%{field: value})
      {:ok, %Note{}}

      iex> create_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(attrs \\ %{}) do
    result =
      %Note{}
      |> Note.changeset(attrs)
      |> Repo.insert()

    with {:ok, note} <- result do
      note =
        note
        |> Repo.preload(:tags)
        |> Repo.preload(:files)

      {:ok, note}
    end
  end

  def create_note(user_id, title, body, tags) do
    base = %{user_id: user_id, title: title, body: body}

    %Note{}
    |> Note.changeset(base)
    |> Note.add_tags(tags)
    |> Repo.insert()
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
    note = get_note!(note.id)

    Enum.each(note.files, fn file ->
      delete_file(file)
    end)

    Repo.delete(note)
  end

  def delete_note(note_id) do
    Repo.delete(%Note{id: note_id})
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

  def ensure_tags([], _) do
    []
  end

  def ensure_tags(tag_names, user_id) do
    tag_names = Enum.map(tag_names, &String.downcase/1)

    transaction =
      Repo.transaction(fn ->
        existing_tags =
          Tag
          |> where([t], t.user_id == ^user_id)
          |> where([t], t.name in ^tag_names)
          |> Repo.all()

        created_tags =
          tag_names
          |> Enum.reject(fn name ->
            Enum.any?(existing_tags, fn tag ->
              tag.name == name
            end)
          end)
          |> Enum.map(fn name ->
            create_tag(%{name: name, user_id: user_id})
          end)

        existing_tags ++ created_tags
      end)

    case transaction do
      {:ok, tags} ->
        tags

      {:error, _} ->
        Repo.rollback(:rollback)
    end
  end

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  def get_tag_by_name(tag_name, user_id) do
    tag = Repo.get_by(Tag, name: tag_name, user_id: user_id)
    {:ok, tag}
  end

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs) do
    attrs = %{attrs | name: String.downcase(attrs.name)}

    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  def add_tag(user_id, note_id, tag_name) do
    tag_name = String.downcase(tag_name)
    {:ok, tag} = get_tag_by_name(tag_name, user_id)

    if is_nil(tag) or empty_notes_tags?(note_id, tag.id) do
      transaction =
        Repo.transaction(fn ->
          result =
            case tag do
              nil ->
                %Tag{}
                |> Tag.changeset(%{name: tag_name, user_id: user_id})
                |> Repo.insert()

              tag ->
                {:ok, tag}
            end

          case result do
            {:ok, tag} ->
              %NotesTags{}
              |> NotesTags.changeset(%{note_id: note_id, tag_id: tag.id})
              |> Repo.insert()
          end
        end)

      case transaction do
        {:ok, tags} ->
          tags

        {:error, _} ->
          Repo.rollback(:rollback)
      end
    else
      :ok
    end
  end

  defp empty_notes_tags?(note_id, tag_id) do
    Repo.all(from nt in NotesTags, where: nt.note_id == ^note_id and nt.tag_id == ^tag_id) == []
  end

  def remove_tag(user_id, note_id, tag_name) do
    tag = Repo.get_by(Tag, name: tag_name, user_id: user_id)

    case tag do
      nil ->
        :ok

      tag ->
        query =
          from(n in NotesTags,
            where:
              n.note_id == ^note_id and
                n.tag_id == ^tag.id
          )

        Repo.delete_all(query)
        :ok
    end
  end

  alias Noted.Notes.File, as: FFile

  def file_storage_path(path) do
    basepath = Noted.Env.expect("FILE_STORAGE_DIR", @default_file_path)
    File.mkdir_p!(basepath)
    Path.join(basepath, path)
  end

  @doc """
  Returns the list of files.

  ## Examples

      iex> list_files()
      [%File{}, ...]

  """
  def list_files do
    Repo.all(FFile)
  end

  @doc """
  Gets a single file.

  Raises `Ecto.NoResultsError` if the File does not exist.

  ## Examples

      iex> get_file!(123)
      %File{}

      iex> get_file!(456)
      ** (Ecto.NoResultsError)

  """
  def get_file!(id), do: Repo.get!(FFile, id)

  @doc """
  Creates a file.

  ## Examples

      iex> create_file(%{field: value})
      {:ok, %File{}}

      iex> create_file(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_file(attrs \\ %{}) do
    %FFile{}
    |> FFile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a file.

  ## Examples

      iex> update_file(file, %{field: new_value})
      {:ok, %File{}}

      iex> update_file(file, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_file(%FFile{} = file, attrs) do
    file
    |> FFile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a file.

  ## Examples

      iex> delete_file(file)
      {:ok, %File{}}

      iex> delete_file(file)
      {:error, %Ecto.Changeset{}}

  """
  def delete_file(%FFile{} = file) do
    File.rm!(file.path)
    Repo.delete(file)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking file changes.

  ## Examples

      iex> change_file(file)
      %Ecto.Changeset{data: %File{}}

  """
  def change_file(%FFile{} = file, attrs \\ %{}) do
    FFile.changeset(file, attrs)
  end
end
