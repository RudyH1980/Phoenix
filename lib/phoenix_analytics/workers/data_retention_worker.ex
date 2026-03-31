defmodule PhoenixAnalytics.Workers.DataRetentionWorker do
  @moduledoc """
  AVG-conforme data retentie:
  - Pageviews en events ouder dan 13 maanden worden verwijderd.
  Draait dagelijks om 04:00 via Oban Cron.
  """
  use Oban.Worker, queue: :default

  import Ecto.Query

  @retention_days 395

  @impl Oban.Worker
  def perform(_job) do
    cutoff = DateTime.add(DateTime.utc_now(), -@retention_days * 24 * 60 * 60, :second)

    {pv_count, _} =
      PhoenixAnalytics.Repo.delete_all(from(p in "pageviews", where: p.inserted_at < ^cutoff))

    {ev_count, _} =
      PhoenixAnalytics.Repo.delete_all(from(e in "events", where: e.inserted_at < ^cutoff))

    {:ok, %{pageviews_deleted: pv_count, events_deleted: ev_count}}
  end
end
