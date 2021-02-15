defmodule NotedWeb.PageLive do
  use NotedWeb, :live_view

  alias NotedWeb.Live
  alias Noted.Notes

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> Live.mount_auth(session)
      |> Live.on_authed(fn socket ->
        %{assigns: %{auth: %{user: user}}} = socket
        Phoenix.PubSub.subscribe(Noted.PubSub, "note-update:#{user.id}")
        notes = Notes.list_notes(user.id)
        assign(socket, notes: notes, edit_note: nil)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_info({:authenticated, _user, key}, socket) do
    {:noreply, Live.handle_authentication(socket, key)}
  end

  @impl true
  def handle_info({:notes_updated, user_id}, socket) do
    notes = Notes.list_notes(user_id)
    {:noreply, Live.assign_authed(socket, notes: notes)}
  end

  @impl true
  def handle_event("edit_note", %{"note" => note_id}, socket) do
    note = Notes.get_note!(note_id)
    changeset = Notes.change_note(note)
    {:noreply, assign(socket, edit_note: changeset)}
  end

  @impl true
  def handle_event("validate", %{"note" => params}, socket) do
    note = Notes.get_note!(socket.assigns.edit_note.data.id)
    changeset = Notes.validate_insert_note(note, params)
    {:noreply, assign(socket, edit_note: changeset)}
  end

  @impl true
  def handle_event("save", %{"note" => params}, socket) do
    note = Notes.get_note!(socket.assigns.edit_note.data.id)

    case Notes.update_note(note, params) do
      {:error, changeset} ->
        {:noreply, assign(socket, edit_note: changeset)}

      {:ok, note} ->
        {:noreply, assign(socket, last_edited_note: note.id, edit_note: nil)}
    end
  end

  @impl true
  def handle_event("close_note", _, socket) do
    {:noreply, assign(socket, edit_note: nil)}
  end
end
