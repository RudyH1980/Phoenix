defmodule PhoenixAnalyticsWeb.CollectController do
  use PhoenixAnalyticsWeb, :controller

  alias PhoenixAnalytics.Analytics

  @doc """
  POST /api/collect

  Accepteert pageview (pv) en event (ev) payloads van de tracker snippet.
  Session hashing: IP + UA, dagelijks geroteerd via Date.utc_today() -- nooit raw IP opslaan.
  """
  def create(conn, params) do
    with {:ok, site} <- find_site(params["s"]),
         session_hash <- build_session_hash(conn),
         :ok <- process_event(conn, site, session_hash, params) do
      send_resp(conn, 204, "")
    else
      {:error, :site_not_found} ->
        send_resp(conn, 404, "")

      _ ->
        send_resp(conn, 204, "")
    end
  end

  defp find_site(nil), do: {:error, :site_not_found}

  defp find_site(token) do
    case Ash.read_one(Analytics.Site, filter: [token: token, active: true]) do
      {:ok, nil} -> {:error, :site_not_found}
      {:ok, site} -> {:ok, site}
      {:error, _} -> {:error, :site_not_found}
    end
  end

  # Privacy by design: IP wordt NOOIT opgeslagen.
  # Hash combineert IP + UA + dagelijkse zout -- uniek per dag, onherleidbaar.
  defp build_session_hash(conn) do
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
    ua = get_req_header(conn, "user-agent") |> List.first("") |> String.slice(0, 100)
    date = Date.utc_today() |> Date.to_string()

    :crypto.hash(:sha256, "#{ip}|#{ua}|#{date}")
    |> Base.encode16(case: :lower)
  end

  defp process_event(conn, site, session_hash, %{"t" => "pv"} = params) do
    Analytics.Pageview
    |> Ash.Changeset.for_create(:record, %{
      site_id: site.id,
      session_hash: session_hash,
      url: params["u"],
      referrer: params["r"],
      device_type: classify_device(params["w"]),
      browser: extract_browser(params),
      country: lookup_country(conn.remote_ip)
    })
    |> Ash.create()
    |> case do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(
          PhoenixAnalytics.PubSub,
          "site:#{site.id}",
          {:pageview, %{session_hash: session_hash, url: params["u"]}}
        )

        :ok

      {:error, _} ->
        :ok
    end
  end

  defp process_event(_conn, site, session_hash, %{"t" => "ev"} = params) do
    Analytics.Event
    |> Ash.Changeset.for_create(:record, %{
      site_id: site.id,
      session_hash: session_hash,
      event_name: params["n"] || "click",
      url: params["u"],
      metadata: params["m"] || %{},
      experiment_id: params["eid"],
      variant_name: params["vn"]
    })
    |> Ash.create()
    |> case do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  end

  defp process_event(_conn, _site, _session_hash, _params), do: :ok

  defp extract_browser(%{"ua" => ua}) when is_binary(ua) do
    cond do
      String.contains?(ua, "Firefox") -> "Firefox"
      String.contains?(ua, "Edg") -> "Edge"
      String.contains?(ua, "Chrome") -> "Chrome"
      String.contains?(ua, "Safari") -> "Safari"
      true -> "Other"
    end
  end

  defp extract_browser(_), do: "Other"

  # Landen lookup via ip-api.com (gratis, 45 req/min, geen auth)
  # Lokale/private IPs worden overgeslagen
  defp lookup_country({127, _, _, _}), do: nil
  defp lookup_country({10, _, _, _}), do: nil
  defp lookup_country({192, 168, _, _}), do: nil
  defp lookup_country({172, b, _, _}) when b in 16..31, do: nil

  defp lookup_country(remote_ip) do
    ip = remote_ip |> Tuple.to_list() |> Enum.join(".")

    case Req.get("http://ip-api.com/json/#{ip}?fields=countryCode", receive_timeout: 1000) do
      {:ok, %{status: 200, body: %{"countryCode" => code}}} -> code
      _ -> nil
    end
  end

  defp classify_device(nil), do: "unknown"

  defp classify_device(width) when is_binary(width) do
    classify_device(String.to_integer(width))
  end

  defp classify_device(width) when width < 768, do: "mobile"
  defp classify_device(width) when width < 1024, do: "tablet"
  defp classify_device(_), do: "desktop"
end
