defmodule NotedWeb.FileController do
  use NotedWeb, :controller

  def serve(conn, %{"id" => id}) do
    user_id = get_session(conn, "user_id")
    file = Noted.Notes.get_file!(id)
    note = Noted.Notes.get_note!(file.note_id)

    # Check user owns the file
    if note.user_id == user_id do
      send_download(conn, {:file, file.path}, filename: Path.basename(file.path))
    else
      put_status(conn, :not_found)
    end
  end
end
