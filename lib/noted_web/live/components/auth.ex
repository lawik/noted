defmodule NotedWeb.Live.Components.Auth do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="text-center my-8 text-4xl text-gray-200">
    <%= if @auth.user do %>
      <div class="mx-auto w-max">
        <%= if @auth.user.photo_path do %>
        <div class="text-center m-4">
        <img src="<%= Routes.file_path(@socket, :serve_user, @auth.user.id) %>"
             class="rounded-full w-16 border-2 border-gray-400 mx-auto"
        />
        </div>
        <% end %>
        <div>
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
