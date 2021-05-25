# Noted [![Elixir CI](https://github.com/m13m/noted/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/m13m/noted/actions/workflows/elixir.yml)

To get started:

  * Install dependencies with `mix deps.get`
  * Set up a Postgres database on your machine with a username and password matching the things in `config/dev.exs`.
  * Create and migrate your database with `mix ecto.setup`.
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Create a Telegram bot as [instructed here](https://core.telegram.org/bots#6-botfather).
  * Make sure to set environment variables: TELEGRAM_BOT_SECRET and TELEGRAM_BOT_NAME to the respective values for your bot.
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

You will be able to log in by sending the /start message with the relevant auth data to the bot.

Then any message you send the bot will be ingested and turned into a note. Including files and pictures.
