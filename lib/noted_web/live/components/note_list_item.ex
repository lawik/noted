defmodule NotedWeb.Live.Components.NoteListItem do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <li class="my-2 p-2 bg-gray-200 rounded-lg" x-data="{ expand: false, show_delete: false }">
      <div class="flex">
        <h2 class="flex-grow cursor-pointer"
            @click="expand = !expand">
            <%= @note.title %>
        </h2>

        <div class="flex-grow-0">
          <div class="flex">
            <button
              class="px-2 py-1 text-sm bg-gray-300 flex-grow-0"
              @click="show_delete = !show_delete">
            Delete
            </button>
            <a href="<%= Routes.note_path(@socket, :index, @note.id) %>"
              class="button px-2 py-1 text-sm flex-grow-0"
              phx-value-note="<%= @note.id %>"
              phx-click="edit_note">
            Edit
            </a>
          </div>
          <div x-show="show_delete">
            <p>Confirm delete?</p>
            <button
              class="px-2 py-1 text-sm bg-red-600"
              phx-value-note="<%= @note.id %>"
              phx-click="delete_note"
              >Yes, delete</button>
          </div>
        </div>

      </div>
      <template x-if="expand">
        <%= if @note.body do %>
        <div class="markdown">
          <%= Noted.Notes.format_body(@note.body) %>
        </div>
        <% else %>
        <div class="markdown">
        - empty -
        </div>
        <% end %>
      </template>
      <div>
        <%= for tag <- @note.tags do %>
          <span>#<%= tag.name %></span>
        <% end %>
      </div>
    </li>
    """
  end
end
