defmodule PhoenixAnalyticsWeb.Plugs.CspNonce do
  @moduledoc """
  Genereert een cryptografisch veilige nonce per request en stelt
  de Content-Security-Policy header in. Geen unsafe-inline.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    nonce = Base.encode64(:crypto.strong_rand_bytes(16))

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header("content-security-policy", csp(nonce))
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header("permissions-policy", "camera=(), microphone=(), geolocation=()")
  end

  defp csp(nonce) do
    [
      "default-src 'self'",
      "script-src 'self' 'nonce-#{nonce}'",
      "style-src 'self' 'nonce-#{nonce}'",
      "img-src 'self' data:",
      "font-src 'self'",
      "connect-src 'self' ws: wss:",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ]
    |> Enum.join("; ")
  end
end
