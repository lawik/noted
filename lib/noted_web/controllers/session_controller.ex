defmodule NotedWeb.SessionController do
  use NotedWeb, :controller
  alias Noted.Telegram.Auth

  def session_redirect(conn, %{"auth_key" => auth_key}) do
    user = Auth.load_user_data(auth_key)

    conn
    |> put_session("user_id", user.id)
    |> redirect(to: "/")
  end

  def logout(conn, _) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
