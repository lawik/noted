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
  def handle_event("validate", %{"note" => params}, socket) do
    changeset = Notes.validate_insert_note(socket.assigns.note, params)
    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("save", %{"note" => params}, socket) do
    consume_uploaded_entries(socket, :images, fn %{path: path}, %{client_type: mime, client_size: size} ->
      dest = Notes.file_storage_path(Path.basename(path))
      File.cp!(path, dest)
      {:ok, _file} = Notes.create_file(%{
        mimetype: mime,
        path: dest,
        size: size,
        note_id: socket.assigns.note.id
      })
    end)
    consume_uploaded_entries(socket, :files, fn %{path: path}, %{client_type: mime, client_size: size} ->
      dest = Notes.file_storage_path(Path.basename(path))
      File.cp!(path, dest)
      {:ok, _file} = Notes.create_file(%{
        mimetype: mime,
        path: dest,
        size: size,
        note_id: socket.assigns.note.id
      })
    end)
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
end
