defmodule NotedWeb.Live.Components.NoteList do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <form phx-change="selection">
      <ul role="list" class="bg-white p-b-4 md:rounded-b-md">
      <%= for note <- @notes do %>
        <%= live_component @socket, NotedWeb.Live.Components.NoteListItem, note: note, checked_ids: @checked_ids %>
      <% end %>
      </ul>
    </form>
    """
  end
end
