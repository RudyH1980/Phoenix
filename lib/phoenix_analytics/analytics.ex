defmodule PhoenixAnalytics.Analytics do
  use Ash.Domain

  resources do
    resource PhoenixAnalytics.Analytics.Site
    resource PhoenixAnalytics.Analytics.Pageview
    resource PhoenixAnalytics.Analytics.Event
  end
end
