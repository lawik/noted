defmodule NotedWeb.Live do
  alias Phoenix.LiveView
  alias Noted.Telegram.Auth
  alias Noted.Env

  def mount_auth(socket, session) do
    user = Auth.get_user_from_session(session)
    bot_name = default_bot_name()

    {link, command} =
      if user do
        {"", ""}
      else
        # Get link/command for starting authentication flow
        Auth.generate_auth_link(bot_name)
      end

    LiveView.assign(socket,
      auth: %{
        user: user,
        link: link,
        command: command,
        bot_name: bot_name
      }
    )
  end

  def is_authed?(socket) do
    case socket.assigns[:auth] do
      %{user: %{id: id}} when is_integer(id) -> true
      _ -> false
    end
  end

  def handle_authentication(socket, key) do
    LiveView.redirect(socket, to: "/user-session/#{key}")
  end

  @doc """
  Assign keys to socket if authenticated, otherwise assign nil keys
  """
  def assign_authed(socket, assigns) do
    assigns =
      if is_authed?(socket) do
        assigns
      else
        Enum.map(assigns, fn {key, _} ->
          {key, nil}
        end)
      end

    LiveView.assign(socket, assigns)
  end

  @doc """
  """
  def on_authed(socket, callback, else_callback \\ nil) when is_function(callback) do
    if is_authed?(socket) do
      callback.(socket)
    else
      if else_callback do
        else_callback.(socket)
      else
        socket
      end
    end
  end

  defp default_bot_name do
    Env.require("TELEGRAM_BOT_NAME")
  end
end
