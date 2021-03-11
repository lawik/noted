defmodule NotedWeb.Live.Components.NoteListItem do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <li id="note-list-item-<%= @note.id %>" class="flex relative p-3 pl-14 border-b border-b-gray-400 last:border-0" id="note-<%= @note.id %>">
      <div class="flex-auto truncate">
        <h2 class="text-2xl text-gray-800 truncate">
            <%= @note.title %>
        </h2>

        <div class="my-3">
          <span class="text-gray-400">
          <%= Timex.format!(@note.inserted_at, "{relative}", :relative) %>
          </span>

          <span>
          <%= for tag <- @note.tags do %>
            <span class="text-gray-800 ml-2">#<%= tag.name %></span>
          <% end %>
          </span>
        </div>
      </div>

      <a href="<%= Routes.note_path(@socket, :index, @note.id) %>"
        class="block flex-none w-8 text-gray-400"
        phx-value-note="<%= @note.id %>"
        phx-click="edit_note"
        title="Edit note">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
      </a>

      <label class="absolute block top-4 left-4 w-6 h-6" title="Check for bulk actions">
        <input type="checkbox"
          @change="
          let id = <%= @note.id %>;
          if (checked_ids.includes(id)) {
            checked_ids = checked_ids.filter(jd => { jd != id });
          } else {
            checked_ids.push(id)
          }
          confirmDelete = false;
          "
          phx-value-selected="<%= @note.id %>"
          value="selected"
          class="appearance-none block w-6 h-6
                border border-gray-400 rounded-full
                checked:bg-gray-800 checked:border-0
                focus:outline-none"
          />
        <svg class="absolute top-1 left-1 text-white w-4" x-show="checked_ids.includes(<%= @note.id %>)" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
      </label>
    </li>
    """
  end
end
