defmodule NotedWeb.Live.Components.Auth do
  use NotedWeb, :live_component

  def render(assigns) do
    ~L"""
    <%= if @auth.user do %>
      <p>
      Welcome <%= @auth.user.telegram_data["first_name"] || @auth.user.telegram_data["username"] %> <%= @auth.user.telegram_data["last_name"] || "" %>
      </p>
    <% else %>
      <a href="<%= @auth.link %>" target="_blank">Authenticate via Telegram</a> or send <br /><code><%= @auth.command %></code> <br />to @<%= @auth.bot_name %>.
    <% end %>
    """
  end
end
