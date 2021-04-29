defmodule Noted.Telegram.Bot do
  use GenServer
  require Logger

  alias Noted.Telegram.Auth
  alias Noted.Accounts

  @default_file_path "/tmp/telegram_bot_files"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl GenServer
  def init(opts) do
    {key, _opts} = Keyword.pop!(opts, :bot_key)
    telegram_module = Keyword.get(opts, :telegram_module, Noted.Telegram)
    # Authenticate the bot to allow replies and such
    # Match an OK response to make sure we're up and running
    # and store some identifiers
    {:ok, %{"id" => id, "username" => bot_name} = me} = telegram_module.get_me(key)
    Auth.register_bot(bot_name)
    Phoenix.PubSub.subscribe(Noted.PubSub, "telegram_bot_update:#{id}")

    state = %{
      id: id,
      me: me,
      name: bot_name,
      bot_key: key,
      telegram_module: telegram_module
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:update, update}, state) do
    handle_update(update, state)
    {:noreply, state}
  end

  # An auth text message from the /start command
  def handle_update(
        %{
          "message" => %{
            "from" => user,
            "text" => "/start auth-" <> key
          }
        } = update,
        state
      ) do
    case Auth.confirm_authentication(key, user) do
      {:ok, user_account} ->
        simple_reply(update, "Welcome", state)
        get_photo_if_missing(state, update, user_account)

      {:error, error} ->
        simple_reply(update, "An error occurred: #{inspect(error)}", state)
    end
  end

  # A normal text message update
  def handle_update(
        %{
          "message" => %{
            "message_id" => _message_id,
            "text" => text
          }
        } = update,
        state
      ) do
    with {:ok, user_id} <- user_or_error(update) do
      user = Accounts.get_user!(user_id)
      get_photo_if_missing(state, update, user)
      Noted.Notes.ingest_note(user_id, text)
      simple_reply(update, "Got it", state)
    end
  end

  def handle_update(
        %{
          "message" =>
            %{
              "document" => file
            } = message
        } = update,
        state
      ) do
    %{"file_id" => file_id, "file_unique_id" => file_unique_id, "mime_type" => mimetype} = file

    path = download_file!(state, file_id)
    caption = Map.get(message, "caption", "Unnamed file (#{file_unique_id})")

    with {:ok, user_id} <- user_or_error(update) do
      {:ok, note} = Noted.Notes.ingest_note(user_id, caption)

      {:ok, _file} =
        Noted.Notes.create_file(%{
          note_id: note.id,
          mimetype: mimetype,
          path: path,
          size: file["file_size"]
        })

      simple_reply(update, "Filed that away", state)
    end
  end

  def handle_update(
        %{
          "message" =>
            %{
              "photo" => files
            } = message
        } = update,
        state
      ) do
    %{"file_id" => file_id, "file_unique_id" => file_unique_id} = file_meta = get_largest(files)
    path = download_file!(state, file_id)
    caption = Map.get(message, "caption", "Unnamed image (#{file_unique_id})")

    mimetype =
      case Path.extname(path) do
        ".jpg" -> "image/jpeg"
        ".jpeg" -> "image/jpeg"
        ".gif" -> "image/gif"
        ".png" -> "image/png"
      end

    with {:ok, user_id} <- user_or_error(update) do
      {:ok, note} = Noted.Notes.ingest_note(user_id, caption)

      {:ok, _file} =
        Noted.Notes.create_file(%{
          note_id: note.id,
          mimetype: mimetype,
          path: path,
          size: file_meta["file_size"]
        })

      simple_reply(update, "Got the picture", state)
    end
  end

  # Anything else
  def handle_update(update, state) do
    Logger.warn("Unmatched message: #{inspect(update)}")
    simple_reply(update, "I don't get it", state)
  end

  defp simple_reply(%{"message" => %{"chat" => %{"id" => chat_id}}}, message, state) do
    state.telegram_module.send_message(state.bot_key, chat_id: chat_id, text: message)
  end

  defp user_or_error(%{"message" => %{"from" => %{"id" => user_identifier}}}) do
    case Noted.Accounts.get_user_by_telegram_id(user_identifier) do
      nil ->
        Logger.error("Received ingest message from non-existant user.",
          telegram_user_identifier: user_identifier
        )

        {:error, :no_user}

      %{id: user_id} ->
        {:ok, user_id}
    end
  end

  defp get_photo_if_missing(
         %{bot_key: key} = state,
         %{"message" => %{"from" => %{"id" => user_id}}},
         %{photo_path: path} = user
       ) do
    path =
      case path do
        nil ->
          nil

        path ->
          case File.stat(path) do
            {:ok, _} -> path
            {:error, _} -> nil
          end
      end

    if is_nil(path) do
      case state.telegram_module.get_user_profile_photos(key, user_id: user_id) do
        {:ok, %{"photos" => [photos | _]}} ->
          case get_largest(photos) do
            %{"file_id" => file_id} ->
              path = download_file!(state, file_id)
              Accounts.update_user(user, %{photo_path: path})

            _ ->
              nil
          end

        _ ->
          nil
      end
    end
  end

  defp get_largest(files) do
    Enum.reduce(files, nil, fn file, largest ->
      if is_nil(largest) or file["file_size"] > largest["file_size"] do
        file
      else
        largest
      end
    end)
  end

  defp download_file!(state, file_id) do
    {:ok, %{"file_path" => file_path}} =
      state.telegram_module.get_file(state.bot_key, file_id: file_id)

    ext = Path.extname(file_path)

    {:ok, file_data} = state.telegram_module.download_file(state.bot_key, file_path)
    dir = Noted.Env.expect("FILE_STORAGE_DIR", @default_file_path)
    File.mkdir_p!(dir)
    path = Path.join(dir, file_id <> ext)
    File.write!(path, file_data)
    path
  end
end
