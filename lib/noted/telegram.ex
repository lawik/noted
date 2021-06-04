defmodule Noted.Telegram do
  def get_me(key) do
    Telegram.Api.request(key, "getMe")
  end

  def get_updates(key, params) do
    Telegram.Api.request(key, "getUpdates", params)
  end

  def send_message(key, params) do
    Telegram.Api.request(key, "sendMessage", params)
  end

  def get_user_profile_photos(key, params) do
    Telegram.Api.request(key, "getUserProfilePhotos", params)
  end

  def get_file(key, params) do
    Telegram.Api.request(key, "getFile", params)
  end

  def download_file(key, file_path) do
    Telegram.Api.file(key, file_path)
  end
end
