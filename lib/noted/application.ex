defmodule Noted.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Noted.Env

  def start(_type, _args) do
    Env.require("TELEGRAM_BOT_NAME")

    children =
      [
        # Start the Ecto repository
        Noted.Repo,
        # Start the Telemetry supervisor
        NotedWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: Noted.PubSub},
        # Start the Endpoint (http/https)
        NotedWeb.Endpoint,
        # Telegram bot stuff
        Noted.Telegram.Auth
      ] ++ load_bots()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Noted.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NotedWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp load_bots do
    # Load any keys you like, I load a single one from an environment variable
    # Generate a list of bots from that
    [Env.expect("TELEGRAM_BOT_SECRET")]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn key ->
      {Noted.Telegram.BotSupervisor, key}
    end)
  end
end
