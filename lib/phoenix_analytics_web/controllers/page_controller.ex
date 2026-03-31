defmodule PhoenixAnalyticsWeb.PageController do
  use PhoenixAnalyticsWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/login")
  end
end
