defmodule PhoenixAnalyticsWeb.IntroController do
  use PhoenixAnalyticsWeb, :controller

  def reset(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_resp(200, """
    <script>
      localStorage.removeItem('pa-intro-skip');
      window.location.href = '/';
    </script>
    """)
  end
end
