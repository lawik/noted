defmodule Noted.Telegram.Auth do
  require Logger

  def child_spec(_options \\ []) do
    Registry.child_spec(keys: :unique, name: Noted.Telegram.AuthRegistry)
  end

  def register_bot(bot_name) do
    Registry.register(Noted.Telegram.AuthRegistry, "bot-#{bot_name}", :ok)
  end

  def reconfirm(pid, user_information) do
    send(pid, {:authenticated, user_information})
  end

  def generate_auth_payload() do
    key = 32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

    Registry.register(
      Noted.Telegram.AuthRegistry,
      "auth-#{key}",
      {:erlang.monotonic_time(:seconds), nil}
    )

    key
  end

  def save_user_data(key, telegram_user_id) do
    Registry.register(
      Noted.Telegram.AuthRegistry,
      "authed-#{key}",
      {:erlang.monotonic_time(:seconds), telegram_user_id}
    )
  end

  def load_user_data(key) do
    case Registry.lookup(Noted.Telegram.AuthRegistry, "authed-#{key}") do
      [{_, {_, telegram_user_id}} | _] -> Noted.Accounts.get_user_by_telegram_id(telegram_user_id)
      _ -> nil
    end
  end

  def generate_auth_link(nil), do: raise("Not bot name set for auth. Can't do it.")

  def generate_auth_link(bot_name) do
    key = generate_auth_payload()
    {"https://t.me/#{bot_name}?start=auth-#{key}", "/start auth-#{key}"}
  end

  def confirm_authentication(auth_key, %{"id" => telegram_user_id} = user_information) do
    case Registry.lookup(Noted.Telegram.AuthRegistry, "auth-#{auth_key}") do
      [] ->
        {:error, :auth_failed}

      [{pid, _} | _] ->
        save_user_data(auth_key, telegram_user_id)

        result =
          case Noted.Accounts.get_user_by_telegram_id(telegram_user_id) do
            nil ->
              Noted.Accounts.create_user(%{
                telegram_id: telegram_user_id,
                telegram_data: user_information
              })

            user ->
              Noted.Accounts.update_user(user, %{telegram_data: user_information})
          end

        send(pid, {:authenticated, user_information, auth_key})
        result
    end
  end

  def get_user_from_session(session) do
    case session["user_id"] do
      user_id when is_integer(user_id) -> Noted.Accounts.get_user(user_id)
      nil -> nil
      _ -> nil
    end
  end
end
