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
        assign(socket, changeset: changeset, note: note)
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
    case Notes.update_note(socket.assigns.note, params) do
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:ok, _note} ->
        {:noreply, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, redirect(socket, to: "/")}
  end
end
