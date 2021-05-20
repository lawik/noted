defmodule NotedWeb.FileController do
  use NotedWeb, :controller

  def serve(conn, %{"id" => id}) do
    user_id = get_session(conn, "user_id")
    file = Noted.Notes.get_file!(id)
    note = Noted.Notes.get_note!(file.note_id)

    # Check user owns the file
    if note.user_id == user_id do
      filename = file.filename || Path.basename(file.path)
      send_download(conn, {:file, file.path}, filename: filename)
    else
      put_status(conn, :not_found)
    end
  end

  def serve_user(conn, %{"id" => user_id}) do
    auth_user_id = get_session(conn, "user_id")
    user = Noted.Accounts.get_user!(user_id)

    # Check user owns the file
    if auth_user_id == user.id do
      send_download(conn, {:file, user.photo_path}, filename: Path.basename(user.photo_path))
    else
      put_status(conn, :not_found)
    end
  end
end
