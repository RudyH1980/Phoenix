defmodule PhoenixAnalyticsWeb.PageControllerTest do
  use PhoenixAnalyticsWeb.ConnCase

  test "GET / toont de landingspagina", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Neo Analytics"
  end
end
