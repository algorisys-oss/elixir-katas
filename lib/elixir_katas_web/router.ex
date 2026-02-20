defmodule ElixirKatasWeb.Router do
  use ElixirKatasWeb, :router

  import ElixirKatasWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElixirKatasWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElixirKatasWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/exports/csv", ExportController, :csv
    post "/exports/pdf", ExportController, :pdf
    
    live "/usecases", UseCasesIndexLive
    
    live_session :default, layout: {ElixirKatasWeb.Layouts, :app} do
      live "/katas", KatasIndexLive
      # Specific routes for katas with extra path segments
      live "/katas/42-path-params/:id", KataHostLive, :kata_42

      # Catch-all for all other katas
      live "/katas/01-hello-world", KataHostLive, :kata_01
      live "/katas/02-counter", KataHostLive, :kata_02
      live "/katas/:slug", KataHostLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElixirKatasWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:elixir_katas, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElixirKatasWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ElixirKatasWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :use_cases,
      layout: {ElixirKatasWeb.Layouts, :use_case},
      root_layout: false,
      on_mount: [{ElixirKatasWeb.UserAuth, :require_authenticated}] do
      live "/usecases/tasky", TaskyLive.Index
    end

    live_session :require_authenticated_user,
      layout: {ElixirKatasWeb.Layouts, :app},
      on_mount: [{ElixirKatasWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", ElixirKatasWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ElixirKatasWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
