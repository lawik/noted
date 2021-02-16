defmodule NotedWeb.PageLive do
  use NotedWeb, :live_view

  alias NotedWeb.Live
  alias Noted.Notes
  import NotedWeb.Router.Helpers, only: [note_path: 3]

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
    {:noreply, redirect(socket, to: note_path(socket, :index, note_id))}
  end

  @impl true
  def handle_event("validate", %{"note" => params}, socket) do
    note = Notes.get_note!(socket.assigns.edit_note.data.id)
    changeset = Notes.validate_insert_note(note, params)
    {:noreply, assign(socket, edit_note: changeset)}
  end
end
