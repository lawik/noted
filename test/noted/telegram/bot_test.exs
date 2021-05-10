defmodule Noted.Telegram.BotTest do
  use ExUnit.Case
  use Noted.DataCase

  require Logger

  alias Noted.Accounts

  @user_attrs %{telegram_data: %{}, telegram_id: 42}
  @file_attrs %{mimetype: "mimetype", path: "/tmp/telegram_bot_files", size: 1}
  @note_attrs %{body: "a body", title: "a title"}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@user_attrs)
      |> Accounts.create_user()

    user
  end

  def note_fixture(user_id, attrs \\ %{}) do
    {:ok, note} =
      attrs
      |> Enum.into(@note_attrs)
      |> Enum.into(%{user_id: user_id})
      |> Noted.Notes.create_note()

    note
  end

  def file_fixture(note_id, attrs \\ %{}) do
    {:ok, file} =
      attrs
      |> Enum.into(@file_attrs)
      |> Enum.into(%{note_id: note_id})
      |> Noted.Notes.create_file()

    file
  end

  defmodule TestTelegramSimpleMessage do
    def get_me(key) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", :get_me)
      {:ok, %{"id" => 101, "username" => "test_bot"}}
    end

    def send_message(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:send_message, params})
      :ok
    end

    def get_user_profile_photos(key, params) do
      Phoenix.PubSub.broadcast!(
        Noted.PubSub,
        "test-telegram:#{key}",
        {:get_user_profile_photos, params}
      )
    end
  end

  defmodule TestTelegramFileMessage do
    def get_me(key) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", :get_me)
      {:ok, %{"id" => 101, "username" => "test_bot"}}
    end

    def send_message(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:send_message, params})
      :ok
    end

    def get_user_profile_photos(key, params) do
      Phoenix.PubSub.broadcast!(
        Noted.PubSub,
        "test-telegram:#{key}",
        {:get_user_profile_photos, params}
      )
    end

    def get_file(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:get_file, params})

      {:ok, %{"file_path" => "/tmp/telegram_bot_files/file.txt"}}
    end

    def download_file(key, file_path) do
      # create file and mimic download file api
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:download_file, file_path})

      File.touch!(file_path)
      file = File.read!(file_path)

      {:ok, file}
    end
  end

  defmodule TestTelegramPhotoMessage do
    def get_me(key) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", :get_me)
      {:ok, %{"id" => 101, "username" => "test_bot"}}
    end

    def send_message(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:send_message, params})
      :ok
    end

    def get_user_profile_photos(key, params) do
      Phoenix.PubSub.broadcast!(
        Noted.PubSub,
        "test-telegram:#{key}",
        {:get_user_profile_photos, params}
      )
    end

    def get_file(key, params) do
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:get_file, params})

      {:ok, %{"file_path" => "/tmp/telegram_bot_files/file.png"}}
    end

    def download_file(key, file_path) do
      # create file and mimic download file api
      Phoenix.PubSub.broadcast!(Noted.PubSub, "test-telegram:#{key}", {:download_file, file_path})

      File.touch!(file_path)
      file = File.read!(file_path)

      {:ok, file}
    end
  end

  # Tests to implement
  # - Basic starting (get_me)
  # - Each different handle_update
  # TODO: Skip auth text for now
  # - File message
  # - Photo message
  # - unmatched message

  defp send_update(id, update) do
    Phoenix.PubSub.broadcast!(
      Noted.PubSub,
      "telegram_bot_update:#{id}",
      {:update, update}
    )
  end

  test "normal text message" do
    key = "bot_normal"
    id = 101
    user_fixture()
    Phoenix.PubSub.subscribe(Noted.PubSub, "test-telegram:#{key}")

    assert {:ok, pid} =
             Noted.Telegram.Bot.start_link(
               bot_key: key,
               telegram_module: TestTelegramSimpleMessage
             )

    assert_receive :get_me

    update = %{
      "message" => %{
        "from" => %{"id" => 42},
        "chat" => %{"id" => 999},
        "message_id" => 1,
        "text" => "My message goes here"
      }
    }

    note_count = Noted.Repo.all(Noted.Notes.Note) |> Enum.count()
    send_update(id, update)
    assert_receive {:get_user_profile_photos, [user_id: 42]}
    assert_receive {:send_message, [chat_id: 999, text: "Got it"]}
    assert Noted.Repo.all(Noted.Notes.Note) |> Enum.count() == note_count + 1
    GenServer.stop(pid, :normal)
  end

  @tag capture_log: true
  test "file message" do
    key = "bot_file_message"
    id = "101"
    user_fixture()

    Phoenix.PubSub.subscribe(Noted.PubSub, "test-telegram:#{key}")

    assert {:ok, pid} =
             Noted.Telegram.Bot.start_link(
               bot_key: key,
               telegram_module: TestTelegramFileMessage
             )

    assert_receive :get_me

    update = %{
      "message" => %{
        "from" => %{"id" => 42},
        "chat" => %{"id" => 999},
        "message_id" => 1,
        "document" => %{
          "file_id" => "1",
          "file_unique_id" => 10002,
          "mime_type" => "mimetype",
          "file_size" => 0
        }
      }
    }

    send_update(id, update)

    assert_receive {:get_file, [file_id: "1"]}
    assert_receive {:download_file, "/tmp/telegram_bot_files/file.txt"}

    assert_receive {:send_message, [chat_id: 999, text: "Filed that away"]}
    GenServer.stop(pid, :normal)
  end

  @tag capture_log: true
  test "photo message" do
    key = "bot_file_message"
    id = "101"
    user_fixture()

    Phoenix.PubSub.subscribe(Noted.PubSub, "test-telegram:#{key}")

    assert {:ok, pid} =
             Noted.Telegram.Bot.start_link(
               bot_key: key,
               telegram_module: TestTelegramPhotoMessage
             )

    assert_receive :get_me

    update = %{
      "message" => %{
        "from" => %{"id" => 42},
        "chat" => %{"id" => 999},
        "message_id" => 1,
        "photo" => [
          %{
            "file_id" => "1",
            "file_unique_id" => 10002,
            "mime_type" => "image/png",
            "file_size" => 100
          },
          %{
            "file_id" => "1",
            "file_unique_id" => 10002,
            "mime_type" => "image/png",
            "file_size" => 200
          }
        ]
      }
    }

    send_update(id, update)
    assert_receive {:get_file, [file_id: "1"]}
    assert_receive {:download_file, "/tmp/telegram_bot_files/file.png"}
    assert_receive {:send_message, [chat_id: 999, text: "Got the picture"]}
    GenServer.stop(pid, :normal)
  end

  @tag capture_log: true
  test "unmatched message" do
    key = "bot_unmatched"
    id = 101
    user_fixture()
    Phoenix.PubSub.subscribe(Noted.PubSub, "test-telegram:#{key}")

    assert {:ok, pid} =
             Noted.Telegram.Bot.start_link(
               bot_key: key,
               telegram_module: TestTelegramSimpleMessage
             )

    assert_receive :get_me

    update = %{
      "message" => %{
        "from" => %{"id" => 42},
        "chat" => %{"id" => 999}
      }
    }

    send_update(id, update)
    assert_receive {:send_message, [chat_id: 999, text: "I don't get it"]}
    GenServer.stop(pid, :normal)
  end
end
