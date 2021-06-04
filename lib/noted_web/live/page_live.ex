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
        |> assign(edit_note: nil, search: "", tags: [])
        |> assign(checked_ids: [])
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
  def handle_event("delete", %{"checked_ids" => note_ids}, socket) do
    note_ids = String.to_charlist(note_ids)

    success_count =
      Enum.filter(note_ids, fn note_id ->
        case Notes.delete_note(note_id) do
          {:ok, _} -> true
          {:error, _} -> false
        end
      end)
      |> Enum.count()

    socket =
      if success_count > 0 do
        put_flash(socket, :info, "Deleted #{success_count} notes")
      else
        put_flash(socket, :error, "No notes deleted")
      end
      |> refresh_notes()

    {:noreply, assign(socket, checked_ids: [])}
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

  @impl true
  def handle_event("bulktag", %{"bulktag" => %{"text" => tags}}, socket) do
    tags =
      tags
      |> String.downcase()
      |> String.split([" ", ","], trim: true)
      |> Enum.uniq()

    {:noreply, assign(socket, tags: tags)}
  end

  @impl true
  def handle_event("noop", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_tag", %{"value" => note_ids}, socket) do
    tags = socket.assigns.tags

    note_ids =
      note_ids
      |> :binary.bin_to_list()

    user_id = socket.assigns.auth.user.id

    Enum.each(note_ids, fn note_id ->
      Enum.each(tags, fn tag ->
        Notes.add_tag(user_id, note_id, tag)
      end)
    end)

    socket = assign(socket, tags: [], checked_ids: [])

    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("remove_tag", %{"value" => note_ids}, socket) do
    tags = socket.assigns.tags

    note_ids =
      note_ids
      |> :binary.bin_to_list()

    user_id = socket.assigns.auth.user.id

    Enum.each(note_ids, fn note_id ->
      Enum.each(tags, fn tag ->
        Notes.remove_tag(user_id, note_id, tag)
      end)
    end)

    socket = assign(socket, tags: [], checked_ids: [])

    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("selection", params, socket) do
    checked_ids =
      params
      |> Enum.filter(fn {key, value} ->
        String.starts_with?(key, "note-") and value == "selected"
      end)
      |> Enum.map(fn {"note-" <> id_string, _value} ->
        String.to_integer(id_string)
      end)

    {:noreply, assign(socket, checked_ids: checked_ids)}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    socket =
      socket
      |> assign(checked_ids: [])
      |> assign(tags: [])

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
