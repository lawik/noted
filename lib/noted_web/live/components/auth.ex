defmodule NotedWeb.Live.Components.Auth do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="text-center m-4 mb-12 text-xl text-gray-200">
    <%= if @auth.user do %>
      <!-- user dohickey -->
      <div class="flex items-center mx-auto cursor-pointer md:block" x-data="{showMore: false}" @click="showMore = !showMore">
        <%= if @auth.user.photo_path do %>
        <div class="mr-2 md:mr-0 md:mb-2">
        <img src="<%= Routes.file_path(@socket, :serve_user, @auth.user.id) %>"
             class="rounded-full w-10 border-2 border-gray-400 mx-auto hover:border-gray-100"
        />
        </div>
        <% end %>
        <div class="hover:text-white">
        <%= @auth.profile["first_name"] || @auth.profile["username"] %> <%= @auth.profile["last_name"] || "" %>
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
