defmodule Noted.Telegram.Bot do
  use GenServer
  require Logger

  alias Noted.Telegram.Auth

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl GenServer
  def init(opts) do
    {key, _opts} = Keyword.pop!(opts, :bot_key)

    # Authenticate the bot to allow replies and such
    # Match an OK response to make sure we're up and running
    # and store some identifiers
    {:ok, %{"id" => id, "username" => bot_name} = me} = Telegram.Api.request(key, "getMe")
    Auth.register_bot(bot_name)
    Phoenix.PubSub.subscribe(Noted.PubSub, "telegram_bot_update:#{id}")

    state = %{
      id: id,
      me: me,
      name: bot_name,
      bot_key: key
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:update, update}, state) do
    handle_update(update, state)
    {:noreply, state}
  end

  # An auth text message from the /start command
  def handle_update(
        %{
          "message" => %{
            "from" => user,
            "text" => "/start auth-" <> key
          }
        } = update,
        state
      ) do
    Auth.confirm_authentication(key, user)
    simple_reply(update, "Welcome", state)
  end

  # A normal text message update
  def handle_update(
        %{
          "message" => %{
            "from" => %{"id" => user_identifier},
            "message_id" => message_id,
            "text" => text
          }
        } = update,
        state
      ) do
    case Noted.Accounts.get_user_by_telegram_id(user_identifier) do
      nil ->
        Logger.error("Received ingest message from non-existant user.",
          telegram_user_identifier: user_identifier
        )

      %{id: user_id} ->
        Noted.Notes.ingest_note(user_id, text)
        simple_reply(update, "Got it", state)
    end
  end

  # Anything else
  def handle_update(update, state) do
    Logger.warn("Unmatched message: #{inspect(update)}")
    simple_reply(update, "I don't get it", state)
  end

  defp simple_reply(%{"message" => %{"chat" => %{"id" => chat_id}}}, message, state) do
    Telegram.Api.request(state.bot_key, "sendMessage",
      chat_id: chat_id,
      text: message
    )
  end
end
