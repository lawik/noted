defmodule Noted.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Noted.Repo,
      # Start the Telemetry supervisor
      NotedWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Noted.PubSub},
      # Start the Endpoint (http/https)
      NotedWeb.Endpoint,
      # Start a worker by calling: Noted.Worker.start_link(arg)
      # {Noted.Worker, arg}
      {Noted.Bot, bot_key: System.get_env("TELEGRAM_BOT_SECRET")}
    ]

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
end
