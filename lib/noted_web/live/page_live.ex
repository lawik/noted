defmodule NotedWeb.PageLive do
  use NotedWeb, :live_view

  alias Noted.Telegram.Auth
  alias Noted.Notes

  @impl true
  def mount(_params, session, socket) do
    bot_name = default_bot_name()

    user = Auth.get_user(session)

    {files, {link, command}} =
      if user do
        user_id = user["id"]
        Phoenix.PubSub.subscribe(Noted.PubSub, "note-update:#{user_id}")
        {Notes.list(user_id), {"", ""}}
      else
        # Get link/command for starting authentication flow
        {[], Auth.generate_auth_link(bot_name)}
      end

    {:ok,
     assign(socket,
       user: user,
       auth_link: link,
       auth_command: command,
       bot_name: bot_name,
       files: files,
       edit_file: nil
     )}
  end

  @impl true
  def handle_info({:authenticated, _user, key}, socket) do
    # Redirect to update the user session to maintain user outside LiveView
    {:noreply, redirect(socket, to: "/user-session/#{key}")}
  end

  @impl true
  def handle_info({:notes_updated, user_id}, socket) do
    files = Notes.list(user_id)
    {:noreply, assign(socket, files: files)}
  end

  @impl true
  def handle_event("edit_file", %{"filename" => filename}, socket) do
    edit_file = Notes.load(socket.assigns.user["id"], filename)
    {:noreply, assign(socket, edit_file: edit_file)}
  end

  @impl true
  def handle_event("save_file", %{"edit" => %{"content" => content}}, socket) do
    Notes.save(socket.assigns.user["id"], socket.assigns.edit_file.filename, content)
    {:noreply, assign(socket, edit_file: nil)}
  end

  @impl true
  def handle_event("close_file", _, socket) do
    {:noreply, assign(socket, edit_file: nil)}
  end

  defp default_bot_name do
    System.get_env("TELEGRAM_BOT_NAME")
  end
end
