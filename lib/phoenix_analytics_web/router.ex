defmodule PhoenixAnalyticsWeb.Router do
  use PhoenixAnalyticsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixAnalyticsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PhoenixAnalyticsWeb.Plugs.CspNonce
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PhoenixAnalyticsWeb.Plugs.RateLimit
  end

  pipeline :require_auth do
    plug PhoenixAnalyticsWeb.Plugs.RequireAuth
  end

  # Publieke collect API -- geen auth, rate limiting via plug
  scope "/api", PhoenixAnalyticsWeb do
    pipe_through :api

    post "/collect", CollectController, :create
  end

  # Publieke routes
  scope "/", PhoenixAnalyticsWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/login", Live.Auth.LoginLive, :index
    get "/auth/verify", AuthController, :verify
    delete "/auth/logout", AuthController, :logout
  end

  # Beveiligde dashboard routes
  scope "/", PhoenixAnalyticsWeb do
    pipe_through [:browser, :require_auth]

    live "/dashboard", Live.Dashboard.OverviewLive, :index
    live "/dashboard/sites/new", Live.Dashboard.NewSiteLive, :index
    live "/dashboard/sites/:site_id", Live.Dashboard.SiteLive, :index
    live "/dashboard/sites/:site_id/experiments", Live.Dashboard.ExperimentsLive, :index
    live "/dashboard/sites/:site_id/experiments/new", Live.Dashboard.NewExperimentLive, :index
    live "/dashboard/sites/:site_id/experiments/:id", Live.Dashboard.ExperimentDetailLive, :index
    live "/dashboard/sites/:site_id/heatmap", Live.Dashboard.HeatmapLive, :index
    get "/dashboard/sites/:site_id/export", ExportController, :csv
    live "/dashboard/orgs/:org_id", Live.Dashboard.OrgSettingsLive, :index
    live "/dashboard/orgs/:org_id/invite", Live.Dashboard.InviteLive, :index
  end

  if Application.compile_env(:phoenix_analytics, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PhoenixAnalyticsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
