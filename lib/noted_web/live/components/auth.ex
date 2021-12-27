defmodule NotedWeb.Live.Components.Auth do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="absolute top-1 right-1 md:top-5 md:right-2 text-xl text-gray-300">
    <%= if @auth.user do %>
      <!-- user dohickey -->
      <div class="inline-block mx-auto cursor-pointer" x-data="{showMore: false}" @click="showMore = !showMore;">
        <%= if @auth.user.photo_path do %>
          <span class="mr-2 md:mr-0 md:mb-2">
            <img src="<%= Routes.file_path(@socket, :serve_user, @auth.user.id) %>"
              class="rounded-full w-10 border-2 border-gray-400 mx-auto hover:border-gray-100"
            />
          </span>
        <% end %>
        <div class="hidden absolute top-1 right-0 block w-full hover:text-white text-center opacity-50">
        <%= (@auth.profile["first_name"] || @auth.profile["username"]) <> " " <> (@auth.profile["last_name"] || "") |> String.split(" ") |> Enum.map(&String.slice(&1, 0, 1)) |> Enum.join("") %>
        </div>
        <div x-show="showMore" class="absolute right-0 bg-gray-100 text-gray-900 w-40 my-2 p-2 px-4 rounded-md"><a href="<%= Routes.session_path(@socket, :logout) %>">Log out</a></div>
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
