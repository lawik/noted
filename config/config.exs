# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :noted,
  ecto_repos: [Noted.Repo]

# Configures the endpoint
config :noted, NotedWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "sXENA3HLiLRTkVsnHFd4m5OQKAqNl02XlbefRV8xhGKMIqbhXrzFsfIUbBWUoDoG",
  render_errors: [view: NotedWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Noted.PubSub,
  live_view: [signing_salt: "GiWKcR6g"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.0.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/style.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
