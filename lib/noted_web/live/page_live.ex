defmodule NotedWeb.PageLive do
  use NotedWeb, :live_view

  alias Noted.Telegram.Auth
  alias Noted.Notes

  @impl true
  def mount(_params, session, socket) do
    bot_name = default_bot_name()

    user = Auth.get_user(session)

    {notes, {link, command}} =
      if user do
        Phoenix.PubSub.subscribe(Noted.PubSub, "note-update:#{user.id}")
        {Notes.list_notes(user.id), {"", ""}}
      else
        # Get link/command for starting authentication flow
        {[], Auth.generate_auth_link(bot_name)}
      end

    {:ok,
     assign(socket,
       user: user.telegram_data,
       user_id: user.id,
       auth_link: link,
       auth_command: command,
       bot_name: bot_name,
       notes: notes,
       edit_note: nil
     )}
  end

  @impl true
  def handle_info({:authenticated, _user, key}, socket) do
    # Redirect to update the user session to maintain user outside LiveView
    {:noreply, redirect(socket, to: "/user-session/#{key}")}
  end

  @impl true
  def handle_info({:notes_updated, user_id}, socket) do
    notes = Notes.list_notes(user_id)
    {:noreply, assign(socket, notes: notes)}
  end

  @impl true
  def handle_event("edit_note", %{"note" => note_id}, socket) do
    edit_note = Notes.get_note!(note_id)
    {:noreply, assign(socket, edit_note: edit_note)}
  end

  @impl true
  def handle_event("save_note", %{"edit" => %{"title" => title, "body" => body}}, socket) do
    Notes.update_note(socket.assigns.edit_note.id, title: title, body: body)
    {:noreply, assign(socket, edit_note: nil)}
  end

  @impl true
  def handle_event("close_note", _, socket) do
    {:noreply, assign(socket, edit_note: nil)}
  end

  defp default_bot_name do
    System.get_env("TELEGRAM_BOT_NAME")
  end
end
