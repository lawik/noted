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

        socket
        |> assign(edit_note: nil, search: "")
        |> refresh_notes()
      end)

    {:ok, socket}
  end

  @impl true
  def handle_info({:authenticated, _user, key}, socket) do
    {:noreply, Live.handle_authentication(socket, key)}
  end

  @impl true
  def handle_info({:notes_updated, _user_id}, socket) do
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("edit_note", %{"note" => note_id}, socket) do
    {:noreply, redirect(socket, to: note_path(socket, :index, note_id))}
  end

  @impl true
  def handle_event("delete_note", %{"note" => note_id}, socket) do
    socket =
      case Notes.delete_note(String.to_integer(note_id)) do
        {:ok, _} ->
          socket
          |> refresh_notes()
          |> put_flash(:info, "Note deleted")

        {:error, _reason} ->
          put_flash(socket, :error, "Delete failed.")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"create" => %{"body" => body}}, socket) do
    user_id = socket.assigns.auth.user.id
    Notes.ingest_note(user_id, body)

    socket =
      socket
      |> refresh_notes()
      |> put_flash(:info, "Note saved")

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => %{"text" => q}}, socket) do
    socket =
      socket
      |> assign(search: q)
      |> refresh_notes()

    {:noreply, socket}
  end

  defp filter_by_search(%{assigns: %{search: q, notes: notes}} = socket) do
    found_notes =
      case q do
        "" ->
          notes

        q ->
          words = q |> String.downcase() |> String.split()

          notes
          |> Enum.filter(fn note ->
            tag_text =
              note.tags
              |> Enum.map(fn tag -> tag.name end)
              |> Enum.join(" ")

            text =
              [
                Map.get(note, :title, ""),
                Map.get(note, :body, ""),
                tag_text
              ]
              |> Enum.join(" ")
              |> String.downcase()

            Enum.all?(words, fn word ->
              String.contains?(text, word)
            end)
          end)
      end

    Live.assign_authed(socket, found_notes: found_notes)
  end

  defp refresh_notes(socket) do
    notes =
      socket.assigns.auth.user.id
      |> Notes.list_notes()
      |> Enum.reverse()

    socket
    |> Live.assign_authed(notes: notes)
    |> filter_by_search()
  end
end
