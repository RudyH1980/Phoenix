defmodule PhoenixAnalyticsWeb.ExportController do
  use PhoenixAnalyticsWeb, :controller

  alias PhoenixAnalytics.Analytics
  alias PhoenixAnalytics.Analytics.Stats

  def csv(conn, %{"site_id" => site_id} = params) do
    site = Ash.get!(Analytics.Site, site_id)
    period = Map.get(params, "period", "30d")
    rows = Stats.pageviews_for_export(site.id, period)

    filename = "#{site.domain}_pageviews_#{period}_#{Date.utc_today()}.csv"

    header =
      "date,url,referrer,device_type,browser,os,country,utm_source,utm_medium,utm_campaign\n"

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
