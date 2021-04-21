defmodule Noted.NotesTest do
  use Noted.DataCase

  alias Noted.Notes

  describe "notes" do
    alias Noted.Notes.Note

    @valid_attrs %{body: "some body", title: "some title"}
    @update_attrs %{body: "some updated body", title: "some updated title"}
    @invalid_attrs %{body: nil, title: nil}

    def note_fixture(attrs \\ %{}) do
      {:ok, note} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notes.create_note()

      note
    end

    test "list_notes/1 returns all notes" do
      note = note_fixture()
      user_id = System.unique_integer([:positive])
      assert Notes.list_notes(user_id) == [note]
    end

    test "get_note!/1 returns the note with given id" do
      note = note_fixture()
      assert Notes.get_note!(note.id) == note
    end

    test "create_note/1 with valid data creates a note" do
      assert {:ok, %Note{} = note} = Notes.create_note(@valid_attrs)
      assert note.body == "some body"
      assert note.title == "some title"
    end

    test "create_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(@invalid_attrs)
    end

    test "update_note/2 with valid data updates the note" do
      note = note_fixture()
      assert {:ok, %Note{} = note} = Notes.update_note(note, @update_attrs)
      assert note.body == "some updated body"
      assert note.title == "some updated title"
    end

    test "update_note/2 with invalid data returns error changeset" do
      note = note_fixture()
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(note, @invalid_attrs)
      assert note == Notes.get_note!(note.id)
    end

    test "delete_note/1 deletes the note" do
      note = note_fixture()
      assert {:ok, %Note{}} = Notes.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(note.id) end
    end

    test "change_note/1 returns a note changeset" do
      note = note_fixture()
      assert %Ecto.Changeset{} = Notes.change_note(note)
    end
  end

  describe "tags" do
    alias Noted.Notes.Tag
    alias Noted.Accounts
    alias Noted.Notes.Note
    alias Noted.Notes.NotesTags

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notes.create_tag!()

      tag
    end

    def get_notes_tags(note, tag) do
      Repo.one!(from n in NotesTags, where: n.note_id == ^note.id and n.tag_id == ^tag.id)
    end

    test "add_tag/3 add the tag to a note" do
      telegram_id = System.unique_integer([:positive])
      {:ok, user} = Accounts.create_user(%{telegram_id: telegram_id, telegram_data: %{}})

      {:ok, note} = Notes.create_note(user.id, "test title", "test body", [])

      tag_name = "test#{System.unique_integer([:positive])}"
      {:ok, notes_tags} = Notes.add_tag(user.id, note.id, tag_name)

      tag = Repo.get(Tag, notes_tags.tag_id)

      assert notes_tags.tag_id == tag.id
    end

    test "add_tag/3 is idempotent" do
      telegram_id = System.unique_integer([:positive])
      {:ok, user} = Accounts.create_user(%{telegram_id: telegram_id, telegram_data: %{}})
      {:ok, note} = Notes.create_note(user.id, "test title", "test body", [])
      tag_name = "test#{System.unique_integer([:positive])}"

      Notes.add_tag(user.id, note.id, tag_name)

      assert Notes.add_tag(user.id, note.id, tag_name) == nil
    end

    test "remove_tag/3 delete the tag from a note" do
      telegram_id = System.unique_integer([:positive])
      {:ok, user} = Accounts.create_user(%{telegram_id: telegram_id, telegram_data: %{}})
      {:ok, note} = Notes.create_note(user.id, "test title", "test body", [])

      tag_name = "test#{System.unique_integer([:positive])}"

      tag = Repo.get_by(Tag, name: tag_name, user_id: user.id)

      Notes.add_tag(user.id, note.id, tag_name)


      assert :ok = Notes.remove_tag(user.id, note.id, tag_name)
      assert_raise Ecto.NoResultsError, fn -> get_notes_tags(note, tag) end
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Notes.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Notes.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Notes.create_tag(@valid_attrs)
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{} = tag} = Notes.update_tag(tag, @update_attrs)
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Notes.update_tag(tag, @invalid_attrs)
      assert tag == Notes.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Notes.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Notes.change_tag(tag)
    end
  end

  describe "files" do
    alias Noted.Notes.File

    @valid_attrs %{mimetype: "some mimetype", path: "some path", size: 42}
    @update_attrs %{mimetype: "some updated mimetype", path: "some updated path", size: 43}
    @invalid_attrs %{mimetype: nil, path: nil, size: nil}

    def file_fixture(attrs \\ %{}) do
      {:ok, file} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notes.create_file()

      file
    end

    test "list_files/0 returns all files" do
      file = file_fixture()
      assert Notes.list_files() == [file]
    end

    test "get_file!/1 returns the file with given id" do
      file = file_fixture()
      assert Notes.get_file!(file.id) == file
    end

    test "create_file/1 with valid data creates a file" do
      assert {:ok, %File{} = file} = Notes.create_file(@valid_attrs)
      assert file.mimetype == "some mimetype"
      assert file.path == "some path"
      assert file.size == 42
    end

    test "create_file/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_file(@invalid_attrs)
    end

    test "update_file/2 with valid data updates the file" do
      file = file_fixture()
      assert {:ok, %File{} = file} = Notes.update_file(file, @update_attrs)
      assert file.mimetype == "some updated mimetype"
      assert file.path == "some updated path"
      assert file.size == 43
    end

    test "update_file/2 with invalid data returns error changeset" do
      file = file_fixture()
      assert {:error, %Ecto.Changeset{}} = Notes.update_file(file, @invalid_attrs)
      assert file == Notes.get_file!(file.id)
    end

    test "delete_file/1 deletes the file" do
      file = file_fixture()
      assert {:ok, %File{}} = Notes.delete_file(file)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_file!(file.id) end
    end

    test "change_file/1 returns a file changeset" do
      file = file_fixture()
      assert %Ecto.Changeset{} = Notes.change_file(file)
    end
  end
end
