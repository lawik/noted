defmodule NotedWeb.NoteLive do
  use NotedWeb, :live_view

  alias NotedWeb.Live
  alias Noted.Notes

  @impl true
  def mount(%{"note_id" => note_id}, session, socket) do
    socket =
      socket
      |> Live.mount_auth(session)
      |> Live.on_authed(fn socket ->
        note = Notes.get_note!(note_id)
        changeset = Notes.change_note(note)

        socket
        |> assign(images: filter_images(note.files))
        |> assign(files: filter_files(note.files))
        |> assign(changeset: changeset, note: note)
        |> allow_upload(:images, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10)
        |> allow_upload(:files, accept: :any, max_entries: 10)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_info({:authenticated, _user, key}, socket) do
    {:noreply, Live.handle_authentication(socket, key)}
  end

  @impl true
  def handle_event("add_tag", %{"tag" => %{"tag_name" => tag_name}}, socket) do
    user_id = socket.assigns.auth.user.id
    note_id = socket.assigns.note.id

    Notes.add_tag(user_id, note_id, tag_name)
    note = Notes.get_note!(note_id)
    {:noreply, assign(socket, note: note)}
  end

  @impl true
  def handle_event("remove_tag", %{"tag_name" => tag_name}, socket) do
    user_id = socket.assigns.auth.user.id
    note_id = socket.assigns.note.id

    Notes.remove_tag(user_id, note_id, tag_name)
    note = Notes.get_note!(note_id)
    {:noreply, assign(socket, note: note)}
  end

  @impl true
  def handle_event("remove_file", %{"file_id" => file_id}, socket) do
    file = Notes.get_file!(file_id)
    Notes.delete_file(file)

    note = Notes.get_note!(socket.assigns.note.id)

    files = filter_files(note.files)

    {:noreply, assign(socket, files: files)}
  end

  @impl true
  def handle_event("remove_image", %{"image_id" => image_id}, socket) do
    image = Notes.get_file!(image_id)
    Notes.delete_file(image)

    note = Notes.get_note!(socket.assigns.note.id)

    images = filter_images(note.files)

    {:noreply, assign(socket, images: images)}
  end

  @impl true
  def handle_event("validate", %{"note" => params}, socket) do
    changeset = Notes.validate_insert_note(socket.assigns.note, params)
    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("validate_upload", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload_images", _params, socket) do
    consume_uploaded_entries(socket, :images, fn %{path: path}, upload ->
      %{
        client_type: mime,
        client_size: size,
        client_name: filename
      } = upload

      dest = Notes.file_storage_path(Path.basename(path))
      File.cp!(path, dest)

      {:ok, _file} =
        Notes.create_file(%{
          filename: filename,
          mimetype: mime,
          path: dest,
          size: size,
          note_id: socket.assigns.note.id
        })
    end)

    note = Notes.get_note!(socket.assigns.note.id)
    images = filter_images(note.files)

    {:noreply, assign(socket, note: note, images: images)}
  end

  @impl true
  def handle_event("upload_files", _params, socket) do
    consume_uploaded_entries(socket, :files, fn %{path: path}, upload ->
      %{
        client_type: mime,
        client_size: size,
        client_name: filename
      } = upload

      dest = Notes.file_storage_path(Path.basename(path))
      File.cp!(path, dest)

      {:ok, _file} =
        Notes.create_file(%{
          filename: filename,
          mimetype: mime,
          path: dest,
          size: size,
          note_id: socket.assigns.note.id
        })
    end)

    note = Notes.get_note!(socket.assigns.note.id)
    files = filter_files(note.files)

    {:noreply, assign(socket, note: note, files: files)}
  end

  @impl true
  def handle_event("save", %{"note" => params}, socket) do
    case Notes.update_note(socket.assigns.note, params) do
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:ok, _note} ->
        note = Notes.get_note!(socket.assigns.note.id)
        changeset = Notes.change_note(note)
        {:noreply, assign(socket, note: note, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, redirect(socket, to: "/")}
  end

  defp filter_files(files) do
    files
    |> Enum.reject(&String.starts_with?(&1.mimetype, "image/"))
  end

  defp filter_images(images) do
    images
    |> Enum.filter(&String.starts_with?(&1.mimetype, "image/"))
  end
end
