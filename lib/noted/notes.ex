defmodule Noted.Notes do
  @file_extension ".md"
  @category_pattern ~r/([a-z]+): (.+)/

  def ingest_note(user_identifier, message_id, full_text) do
    timestamp =
      "Etc/UTC"
      |> DateTime.now!()
      |> DateTime.to_iso8601(:basic)
      |> String.replace("T", "")
      |> String.split_at(12)
      |> IO.inspect()
      |> elem(0)

    filename = "#{timestamp}-#{message_id}#{@file_extension}"
    dir = notes_directory(user_identifier)
    File.mkdir_p!(dir)
    path = Path.join([dir, filename])

    File.write!(path, full_text)

    Phoenix.PubSub.broadcast!(
      Noted.PubSub,
      "note-update:#{user_identifier}",
      {:notes_updated, user_identifier}
    )
  end

  def load(user_identifier, filename) do
    data = File.read!(Path.join(notes_directory(user_identifier), filename))
    %{filename: filename, content: data}
  end

  def save(user_identifier, filename, content) do
    data = File.write!(Path.join(notes_directory(user_identifier), filename), content)
  end

  def list(user_identifier) do
    user_identifier
    |> notes_directory()
    |> File.ls!()
    |> Enum.sort()
  end

  defp parse_text(full_text) do
    case Regex.run(@category_pattern, full_text) do
      nil ->
        {"", full_text}

      [_, category, text] ->
        {category, text}
    end
  end

  defp notes_directory(user_identifier) do
    dir =
      Path.join(
        System.get_env("NOTES_DIRECTORY", "/tmp/notes"),
        Integer.to_string(user_identifier)
      )

    File.mkdir_p!(dir)
    dir
  end
end
