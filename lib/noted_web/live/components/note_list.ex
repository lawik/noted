defmodule NotedWeb.Live.Components.NoteList do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <ul role="list" class="bg-white p-b-4 md:rounded-b-md">
    <%= for note <- @notes do %>
      <%= live_component @socket, NotedWeb.Live.Components.NoteListItem, note: note %>
    <% end %>
    </ul>
    """
  end
end
