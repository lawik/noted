defmodule NotedWeb.Live.Components.NoteList do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <ul role="list">
    <%= for note <- @notes do %>
    <%= live_component @socket, NotedWeb.Live.Components.NoteListItem, note: note %>
    <% end %>
    </ul>
    """
  end
end
