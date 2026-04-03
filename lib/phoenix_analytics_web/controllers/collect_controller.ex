defmodule PhoenixAnalyticsWeb.CollectController do
  use PhoenixAnalyticsWeb, :controller

  alias PhoenixAnalytics.Analytics

  require Ash.Query

  @doc """
  POST /api/collect

  Accepteert pageview (pv) en event (ev) payloads van de tracker snippet.
  Session hashing: IP + UA, dagelijks geroteerd via Date.utc_today() -- nooit raw IP opslaan.
  """
  def preflight(conn, _params), do: send_resp(conn, 204, "")

  def create(conn, params) do
    with {:ok, site} <- find_site(params["s"]),
         session_hash <- build_session_hash(conn, params["vid"]),
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
    case Analytics.Site
         |> Ash.Query.filter(token == ^token and active == true)
         |> Ash.read_one(domain: Analytics) do
      {:ok, nil} -> {:error, :site_not_found}
      {:ok, site} -> {:ok, site}
      {:error, _} -> {:error, :site_not_found}
    end
  end

  # Privacy by design: IP wordt NOOIT opgeslagen.
  # Vid (localStorage) is stabiel per bezoeker -- correct terugkerende bezoekers tellen.
  # Fallback: IP + UA + dagelijkse zout als localStorage niet beschikbaar is.
  defp build_session_hash(_conn, vid) when is_binary(vid) and byte_size(vid) > 4 do
    :crypto.hash(:sha256, "vid:#{vid}")
    |> Base.encode16(case: :lower)
  end

  defp build_session_hash(conn, _) do
    ip = real_ip_string(conn)
    ua = get_req_header(conn, "user-agent") |> List.first("") |> String.slice(0, 100)
    date = Date.utc_today() |> Date.to_string()

    :crypto.hash(:sha256, "#{ip}|#{ua}|#{date}")
    |> Base.encode16(case: :lower)
  end

  # Op Fly.io zit de echte client-IP in de fly-client-ip header.
  # Fallback naar x-forwarded-for, dan conn.remote_ip.
  defp real_ip(conn) do
    case real_ip_string(conn) do
      ip when is_binary(ip) ->
        case :inet.parse_address(String.to_charlist(ip)) do
          {:ok, tuple} -> tuple
          _ -> conn.remote_ip
        end

      _ ->
        conn.remote_ip
    end
  end

  defp real_ip_string(conn) do
    get_req_header(conn, "fly-client-ip")
    |> List.first(nil)
    |> case do
      nil ->
        get_req_header(conn, "x-forwarded-for")
        |> List.first("")
        |> String.split(",")
        |> List.first("")
        |> String.trim()
        |> case do
          "" -> conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
          ip -> ip
        end

      ip ->
        ip
    end
  end

  defp process_event(conn, site, session_hash, %{"t" => "pv"} = params) do
    ua = get_req_header(conn, "user-agent") |> List.first("")
    ip = real_ip(conn)
    {country, city, region} = lookup_geo(ip)

    Analytics.Pageview
    |> Ash.Changeset.for_create(:record, %{
      site_id: site.id,
      session_hash: session_hash,
      url: params["u"],
      referrer: params["r"],
      device_type: classify_device(params["w"]),
      browser: extract_browser(ua),
      os: extract_os(ua),
      country: country,
      city: city,
      region: region
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

  defp extract_browser(ua) when is_binary(ua) and ua != "" do
    cond do
      String.contains?(ua, "Firefox") -> "Firefox"
      String.contains?(ua, "Edg/") -> "Edge"
      String.contains?(ua, "OPR/") or String.contains?(ua, "Opera") -> "Opera"
      String.contains?(ua, "Chrome") -> "Chrome"
      String.contains?(ua, "Safari") -> "Safari"
      true -> "Other"
    end
  end

  defp extract_browser(_), do: "Other"

  defp extract_os(ua) when is_binary(ua) and ua != "" do
    cond do
      String.contains?(ua, "iPhone") or String.contains?(ua, "iPad") -> "iOS"
      String.contains?(ua, "Android") -> "Android"
      String.contains?(ua, "Windows") -> "Windows"
      String.contains?(ua, "Macintosh") or String.contains?(ua, "Mac OS X") -> "macOS"
      String.contains?(ua, "Linux") -> "Linux"
      true -> "Other"
    end
  end

  defp extract_os(_), do: "Other"

  # Geo lookup via ip-api.com (gratis, 45 req/min, geen auth)
  # Lokale/private IPs worden overgeslagen — geeft {country, city, region}
  defp lookup_geo({127, _, _, _}), do: {nil, nil, nil}
  defp lookup_geo({10, _, _, _}), do: {nil, nil, nil}
  defp lookup_geo({192, 168, _, _}), do: {nil, nil, nil}
  defp lookup_geo({172, b, _, _}) when b in 16..31, do: {nil, nil, nil}

  defp lookup_geo({0, 0, 0, 0, 0, 65535, a, b}) do
    lookup_geo({div(a, 256), rem(a, 256), div(b, 256), rem(b, 256)})
  end

  defp lookup_geo({0, 0, 0, 0, 0, 0, 0, 1}), do: {nil, nil, nil}

  defp lookup_geo(remote_ip) when tuple_size(remote_ip) == 4 do
    ip = remote_ip |> Tuple.to_list() |> Enum.join(".")
    fetch_geo(ip)
  end

  defp lookup_geo(remote_ip) when tuple_size(remote_ip) == 8 do
    ip =
      remote_ip
      |> Tuple.to_list()
      |> Enum.map(&Integer.to_string(&1, 16))
      |> Enum.join(":")
      |> String.downcase()

    fetch_geo(ip)
  end

  defp lookup_geo(_), do: {nil, nil, nil}

  defp fetch_geo(ip) do
    case Req.get("http://ip-api.com/json/#{ip}?fields=countryCode,city,regionName",
           receive_timeout: 2000
         ) do
      {:ok, %{status: 200, body: body}} ->
        country = if is_binary(body["countryCode"]), do: body["countryCode"], else: nil
        city = if is_binary(body["city"]) and body["city"] != "", do: body["city"], else: nil

        region =
          if is_binary(body["regionName"]) and body["regionName"] != "",
            do: body["regionName"],
            else: nil

        {country, city, region}

      _ ->
        {nil, nil, nil}
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
