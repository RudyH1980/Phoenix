defmodule PhoenixAnalyticsWeb.ExportController do
  use PhoenixAnalyticsWeb, :controller

  alias PhoenixAnalytics.Analytics
  alias PhoenixAnalytics.Analytics.Stats

  def csv(conn, %{"site_id" => site_id} = params) do
    case Ash.get(Analytics.Site, site_id) do
      {:ok, site} when not is_nil(site) ->
        if site.org_id in conn.assigns.current_org_ids do
          do_csv(conn, site, params)
        else
          conn
          |> put_flash(:error, "Geen toegang tot deze website.")
          |> redirect(to: ~p"/dashboard")
          |> halt()
        end

      _ ->
        conn
        |> put_flash(:error, "Website niet gevonden.")
        |> redirect(to: ~p"/dashboard")
        |> halt()
    end
  end

  defp do_csv(conn, site, params) do
    period = Map.get(params, "period", "30d")
    rows = Stats.pageviews_for_export(site.id, period)

    filename = "#{site.domain}_pageviews_#{period}_#{Date.utc_today()}.csv"

    header =
      "date,url,referrer,device_type,browser,os,country,city,region,utm_source,utm_medium,utm_campaign\n"

    body =
      Enum.map_join(rows, "", fn row ->
        [
          format_dt(row.date),
          escape_csv(row.url),
          escape_csv(row.referrer),
          escape_csv(row.device_type),
          escape_csv(row.browser),
          escape_csv(row.os),
          escape_csv(row.country),
          escape_csv(Map.get(row, :city)),
          escape_csv(Map.get(row, :region)),
          escape_csv(row.utm_source),
          escape_csv(row.utm_medium),
          escape_csv(row.utm_campaign)
        ]
        |> Enum.join(",")
        |> Kernel.<>("\n")
      end)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, header <> body)
  end

  defp escape_csv(nil), do: ""

  defp escape_csv(val) do
    str = to_string(val)

    if String.contains?(str, [",", "\"", "\n"]) do
      "\"#{String.replace(str, "\"", "\"\"")}\""
    else
      str
    end
  end

  defp format_dt(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  defp format_dt(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_dt(nil), do: ""
end
