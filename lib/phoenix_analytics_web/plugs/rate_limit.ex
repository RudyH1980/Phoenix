defmodule PhoenixAnalyticsWeb.Plugs.RateLimit do
  @moduledoc """
  Rate limit plug voor de collect API.
  60 requests per minuut per IP.
  """
  import Plug.Conn

  @limit 60
  @scale_ms 60_000

  def init(opts), do: opts

  def call(conn, _opts) do
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

    case PhoenixAnalytics.RateLimiter.hit("collect:#{ip}", @scale_ms, @limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{error: "too_many_requests"}))
        |> halt()
    end
  end
end
