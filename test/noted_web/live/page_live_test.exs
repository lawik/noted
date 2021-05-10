defmodule NotedWeb.PageLiveTest do
  use NotedWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Authenticate via Telegram"
    assert render(page_live) =~ "Authenticate via Telegram"
  end
end
