defmodule Noted.Bot do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl GenServer
  def init(opts) do
    {key, _opts} = Keyword.pop!(opts, :bot_key)

    {:ok, me} = Telegram.Api.request(key, "getMe") |> IO.inspect(label: "me")

    state = %{
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
          IO.inspect(updates, label: "updates")

          last_seen =
            Enum.map(updates, fn update ->
              handle_update(update)
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

    # handle updates
    next_loop()
    {:noreply, state}
  end

  def handle_update(%{"message" => %{"from" => %{"id" => user_identifier}, "message_id" => message_id, "text" => text}} = _update) do
    Noted.Notes.ingest_note(user_identifier, message_id, text)
  end

  def handle_update(update) do
    Logger.warn("Unmatched message: #{inspect(update)}")
  end

  defp next_loop() do
    Process.send_after(self(), :start, 0)
  end

end
