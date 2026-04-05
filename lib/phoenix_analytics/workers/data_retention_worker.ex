defmodule PhoenixAnalytics.Workers.DataRetentionWorker do
  @moduledoc """
  AVG-conforme data retentie per organisatie:
  - Pageviews en events ouder dan de org-specifieke retentieperiode worden verwijderd.
  - Fallback: 13 maanden (395 dagen) als de org geen instelling heeft.
  Draait dagelijks om 04:00 via Oban Cron.
  """
  use Oban.Worker, queue: :default

  import Ecto.Query

  @default_retention_days 395

  @impl Oban.Worker
  def perform(_job) do
    orgs =
      PhoenixAnalytics.Repo.all(
        from o in "organizations",
          select: %{id: o.id, data_retention_months: o.data_retention_months}
      )

    totals =
      Enum.reduce(orgs, %{pageviews_deleted: 0, events_deleted: 0}, fn org, acc ->
        retention_days = retention_days_for(org.data_retention_months)
        cutoff = DateTime.add(DateTime.utc_now(), -retention_days * 24 * 60 * 60, :second)

        site_ids_q = from s in "sites", where: s.org_id == ^org.id, select: s.id

        {pv_count, _} =
          PhoenixAnalytics.Repo.delete_all(
            from p in "pageviews",
              where: p.site_id in subquery(site_ids_q) and p.inserted_at < ^cutoff
          )

        {ev_count, _} =
          PhoenixAnalytics.Repo.delete_all(
            from e in "events",
              where: e.site_id in subquery(site_ids_q) and e.inserted_at < ^cutoff
          )

        %{
          pageviews_deleted: acc.pageviews_deleted + pv_count,
          events_deleted: acc.events_deleted + ev_count
        }
      end)

    {:ok, totals}
  end

  defp retention_days_for(nil), do: @default_retention_days
  defp retention_days_for(months) when is_integer(months) and months > 0, do: months * 30
  defp retention_days_for(_), do: @default_retention_days
end
