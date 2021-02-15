defmodule NotedWeb.Router do
  use NotedWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NotedWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  scope "/", NotedWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/note/:note_id", NoteLive, :index
    get "/user-session/:auth_key", SessionController, :session_redirect
  end

  # Other scopes may use custom stacks.
  # scope "/api", NotedWeb do
  #   pipe_through :api

  #   post "/session", SessionController, :set
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: NotedWeb.Telemetry
    end
  end
end
