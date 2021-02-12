defmodule Noted.Telegram.BotPoller do
  @moduledoc """
  Responsible for checking a specific bot for updates.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl GenServer
  def init(opts) do
    {key, _opts} = Keyword.pop!(opts, :bot_key)

    # Get connected and verify that we can make calls with
    # the Bot API
    {:ok, %{"id" => id} = me} = Telegram.Api.request(key, "getMe")

    state = %{
      id: id,
      me: me,
      name: me["username"],
      bot_key: key,
      last_seen: -2
    }

    next_loop()
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:start, %{bot_key: key, last_seen: last_seen} = state) do
    # getUpdates
    state =
      case Telegram.Api.request(key, "getUpdates", offset: last_seen + 1, timeout: 30) do
        {:ok, []} ->
          state

        {:ok, updates} ->
          last_seen =
            Enum.map(updates, fn update ->
              Phoenix.PubSub.broadcast!(
                Noted.PubSub,
                "telegram_bot_update:#{state.id}",
                {:update, update}
              )

              # Map down to IDs
              update["update_id"]
            end)
            |> Enum.max(fn -> last_seen end)

          # Update offset to move beyond any message we've already handled
          %{state | last_seen: last_seen}

        other ->
          Logger.error("Unexpected response getting updates.", response: other)
          :timer.sleep(2000)
          state
      end

    # Resume listening
    next_loop()
    {:noreply, state}
  end

  defp next_loop() do
    Process.send_after(self(), :start, 0)
  end
end
