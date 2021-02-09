defmodule NotedWeb.SessionController do
  use NotedWeb, :controller
  alias Noted.Telegram.Auth

  def session_redirect(conn, %{"auth_key" => auth_key}) do
    user = Auth.load_user_data(auth_key)

    conn
    |> put_session("user", user)
    |> redirect(to: "/")
  end
end
