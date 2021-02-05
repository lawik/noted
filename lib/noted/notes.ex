defmodule Noted.Notes do
  @file_extension ".md"
  @category_pattern ~r/([a-z]+): (.+)/

  def ingest_note(user_identifier, message_id, full_text) do
    {category, text} = parse_text(full_text)
    filename = "note-#{message_id}#{@file_extension}"
    dir = Path.join(notes_directory(user_identifier), category)
    File.mkdir_p!(dir)
    path = Path.join([dir, filename])

    File.write!(path, text)
  end

  defp parse_text(full_text) do
    case Regex.run(@category_pattern, full_text) do
      nil -> {"", full_text}
      [_, category, text] ->
      {category, text}
    end
  end


  defp notes_directory(user_identifier) do
    dir = Path.join(System.get_env("NOTES_DIRECTORY", "/tmp/notes"), Integer.to_string(user_identifier))
    File.mkdir_p!(dir)
    dir
  end
end
