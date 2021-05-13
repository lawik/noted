defmodule Noted.Repo do
  use Ecto.Repo,
    otp_app: :noted,
    adapter: Ecto.Adapters.SQLite3
end
