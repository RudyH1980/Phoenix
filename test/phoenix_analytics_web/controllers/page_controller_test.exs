defmodule PhoenixAnalyticsWeb.PageControllerTest do
  use PhoenixAnalyticsWeb.ConnCase

  test "GET / redirects to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/login"
  end
end
