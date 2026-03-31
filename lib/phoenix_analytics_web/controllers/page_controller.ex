defmodule PhoenixAnalyticsWeb.PageController do
  use PhoenixAnalyticsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
