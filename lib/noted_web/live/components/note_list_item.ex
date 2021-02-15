defmodule NotedWeb.Live.Components.NoteListItem do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <li class="text-lg"><%= @note.title %><button class="px-2 py-1 text-sm" phx-value-note="<%= @note.id %>" phx-click="edit_note">Edit</button></li>
    """
  end
end
