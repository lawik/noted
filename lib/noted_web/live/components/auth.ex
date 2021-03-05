defmodule NotedWeb.Live.Components.Auth do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="text-center m-4 mb-12 text-xl text-gray-200">
    <%= if @auth.user do %>
      <!-- user dohickey -->
      <div class="flex items-center mx-auto md:block">
        <%= if @auth.user.photo_path do %>
        <div class="mr-2 md:mr-0 md:mb-2">
        <img src="<%= Routes.file_path(@socket, :serve_user, @auth.user.id) %>"
             class="rounded-full w-10 border-2 border-gray-400 mx-auto"
        />
        </div>
        <% end %>
        <div class="">
        <%= @auth.user.telegram_data["first_name"] || @auth.user.telegram_data["username"] %> <%= @auth.user.telegram_data["last_name"] || "" %>
        </div>
      </div>
    <% else %>
      <p><a href="<%= @auth.link %>" target="_blank">Authenticate via Telegram</a></p>
      <p>or send this message</p>
      <pre class="font-bold"><%= @auth.command %></pre>
      <p>to @<%= @auth.bot_name %>.</p>
    <% end %>
    </section>
    """
  end
end
