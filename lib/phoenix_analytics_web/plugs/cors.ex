defmodule PhoenixAnalyticsWeb.Plugs.Cors do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "POST, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type")
  end
end
