defmodule Noted.Repo do
  use Ecto.Repo,
    otp_app: :noted,
    # adapter: Ecto.Adapters.Postgres
    adapter: Ecto.Adapters.Exqlite
end
