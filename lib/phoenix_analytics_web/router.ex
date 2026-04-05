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
    plug PhoenixAnalyticsWeb.Plugs.Cors
    plug PhoenixAnalyticsWeb.Plugs.RateLimit
  end

  pipeline :require_auth do
    plug PhoenixAnalyticsWeb.Plugs.RequireAuth
  end

  # Publieke collect API -- geen auth, rate limiting via plug
  scope "/api", PhoenixAnalyticsWeb do
    pipe_through :api

    post "/collect", CollectController, :create
    options "/collect", CollectController, :preflight
  end

  # Publieke routes
  scope "/", PhoenixAnalyticsWeb do
    pipe_through :browser

    live "/", Live.Marketing.LandingLive, :index
    live "/demo", Live.Demo.DemoLive, :index
    live "/login", Live.Auth.LoginLive, :index
    get "/auth/verify", AuthController, :verify
    get "/auth/verify_password", AuthController, :verify_password
    get "/auth/demo", AuthController, :demo
    delete "/auth/logout", AuthController, :logout
  end

  # Beveiligde dashboard routes
  scope "/", PhoenixAnalyticsWeb do
    pipe_through [:browser, :require_auth]

    get "/dashboard/sites/:site_id/export", ExportController, :csv

    live_session :require_auth,
      on_mount: [{PhoenixAnalyticsWeb.LiveAuth, :ensure_authenticated}] do
      live "/dashboard", Live.Dashboard.OverviewLive, :index
      live "/dashboard/sites/new", Live.Dashboard.NewSiteLive, :index
      live "/dashboard/sites/:site_id", Live.Dashboard.SiteLive, :index
      live "/dashboard/sites/:site_id/edit", Live.Dashboard.EditSiteLive, :index
      live "/dashboard/sites/:site_id/experiments", Live.Dashboard.ExperimentsLive, :index
      live "/dashboard/sites/:site_id/experiments/new", Live.Dashboard.NewExperimentLive, :index

      live "/dashboard/sites/:site_id/experiments/:id",
           Live.Dashboard.ExperimentDetailLive,
           :index

      live "/dashboard/sites/:site_id/funnels", Live.Dashboard.FunnelLive, :index
      live "/dashboard/sites/:site_id/heatmap", Live.Dashboard.HeatmapLive, :index
      live "/dashboard/orgs/:org_id", Live.Dashboard.OrgSettingsLive, :index
      live "/dashboard/orgs/:org_id/invite", Live.Dashboard.InviteLive, :index
      live "/dashboard/account", Live.Auth.PasskeyLive, :index
    end
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
