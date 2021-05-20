defmodule NotedWeb.Live.Components.Auth do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="text-center m-4 mb-12 text-xl text-gray-200">
    <%= if @auth.user do %>
      <!-- user dohickey -->
      <div class="flex items-center mx-auto cursor-pointer md:block" x-data="{showMore: false}">
        <%= if @auth.user.photo_path do %>
        <a href="/" title="Home">
          <div class="mr-2 md:mr-0 md:mb-2">
            <img src="<%= Routes.file_path(@socket, :serve_user, @auth.user.id) %>"
              class="rounded-full w-10 border-2 border-gray-400 mx-auto hover:border-gray-100"
            />
          </div>
        </a>
        <% end %>
        <div class="hover:text-white">
        <%= @auth.profile["first_name"] || @auth.profile["username"] %> <%= @auth.profile["last_name"] || "" %>
          <button @click="showMore = !showMore;" title="Show account menu" class="h-6">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
            </svg>
          </button>
        </div>
        <div x-show="showMore"><a href="<%= Routes.session_path(@socket, :logout) %>">Log out</a></div>
      </div>
    <% else %>
      <div class="m-4 my-16 py-16 bg-gray-400 rounded-md text-white">
        <p class="my-8 mb-12"><a class="p-4 px-8 bg-gray-700 rounded-full hover:bg-gray-600" href="<%= @auth.link %>" target="_blank">Authenticate via Telegram</a></p>
        <p class="text-gray-700">or send this message</p>
        <div class="font-mono my-8 py-4 bg-gray-700"><%= @auth.command %></div>
        <p class="text-gray-700">to @<%= @auth.bot_name %>.</p>
      </div>
    <% end %>
    </section>
    """
  end
end
