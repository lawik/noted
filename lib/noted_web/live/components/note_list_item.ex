defmodule NotedWeb.Live.Components.NoteListItem do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <li class="flex bg-white p-3 pl-14 border-b border-b-gray-400 relative" id="note-<%= @note.id %>" x-data="{ show_delete: false }">
      <div class="flex-auto">
        <h2 class="text-2xl">
            <%= @note.title %>
        </h2>

        <div class="my-3">
        <%= for tag <- @note.tags do %>
          <span>#<%= tag.name %></span>
        <% end %>
        </div>
      </div>
    <!--        <div x-show="show_delete">
          <p>Confirm delete?</p>
          <button
            class="px-2 py-1 text-sm bg-red-600"
            phx-value-note="<%= @note.id %>"
            phx-click="delete_note"
            >Yes, delete</button>
        </div>-->
        <a href="<%= Routes.note_path(@socket, :index, @note.id) %>"
          class="block flex-none w-8 text-gray-400"
          phx-value-note="<%= @note.id %>"
          phx-click="edit_note"
          title="Edit note">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </a>



        <input type="checkbox"
          phx-value-selected="<%= @note.id %>"
          value="selected"
          class="appearance-none absolute top-4 left-4 block w-6 h-6 border border-gray-400 rounded-full checked:border-0 checked:bg-blue-400"
          <%= if assigns[:selected][@note.id] do %>checked="checked" <% end %> />

    <!--
        <button
          class="text-gray-300 w-6 absolute top-4 right-4"
          @click="show_delete = !show_delete" title="Delete">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
        -->
    </li>
    """
  end
end
