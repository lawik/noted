defmodule NotedWeb.Live.Components.Auth do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="text-center my-8 text-4xl text-gray-200">
    <%= if @auth.user do %>
      <p>
      <%= @auth.user.telegram_data["first_name"] || @auth.user.telegram_data["username"] %> <%= @auth.user.telegram_data["last_name"] || "" %>
      </p>
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
