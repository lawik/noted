defmodule Noted.Telegram.BotSupervisor do
  use Supervisor

  def start_link(key) do
    Supervisor.start_link(__MODULE__, key)
  end

  @impl true
  def init(key) do
    children = [
      {Noted.Telegram.Bot, bot_key: key},
      {Noted.Telegram.BotPoller, bot_key: key}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
