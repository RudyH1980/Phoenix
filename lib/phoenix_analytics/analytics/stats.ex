defmodule PhoenixAnalytics.Analytics.Stats do
  @moduledoc """
  Query helpers voor dashboard statistieken.
  Alle queries zijn Ash-based met periode-filter.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Repo

  def period_start("today"),
    do:
      DateTime.truncate(DateTime.utc_now(), :second)
      |> DateTime.to_date()
      |> DateTime.new!(~T[00:00:00])

  def period_start("7d"), do: DateTime.add(DateTime.utc_now(), -7 * 86_400, :second)
  def period_start("30d"), do: DateTime.add(DateTime.utc_now(), -30 * 86_400, :second)
  def period_start("90d"), do: DateTime.add(DateTime.utc_now(), -90 * 86_400, :second)
  def period_start(_), do: period_start("7d")

  def pageview_count(site_id, period) do
    since = period_start(period)

    Repo.one(
      from p in "pageviews",
        where: p.site_id == ^site_id and p.inserted_at >= ^since,
        select: count(p.id)
    ) || 0
  end

  def unique_visitors(site_id, period) do
    since = period_start(period)

    Repo.one(
      from p in "pageviews",
        where: p.site_id == ^site_id and p.inserted_at >= ^since,
        select: count(p.session_hash, :distinct)
    ) || 0
  end

  def bounce_rate(site_id, period) do
    since = period_start(period)

    total =
      Repo.one(
        from p in "pageviews",
          where: p.site_id == ^site_id and p.inserted_at >= ^since,
          select: count(p.session_hash, :distinct)
      ) || 0

    bounced =
      Repo.one(
        from p in "pageviews",
          where: p.site_id == ^site_id and p.inserted_at >= ^since,
          group_by: p.session_hash,
          having: count(p.id) == 1,
          select: count(p.session_hash)
      ) || 0

    if total > 0, do: Float.round(bounced / total * 100, 1), else: 0.0
  end

  def top_pages(site_id, period, limit \\ 10) do
    since = period_start(period)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^site_id and p.inserted_at >= ^since,
        group_by: p.url,
        order_by: [desc: count(p.id)],
        limit: ^limit,
        select: %{url: p.url, count: count(p.id)}
    )
  end

  def top_referrers(site_id, period, limit \\ 10) do
    since = period_start(period)

    Repo.all(
      from p in "pageviews",
        where:
          p.site_id == ^site_id and
            p.inserted_at >= ^since and
            not is_nil(p.referrer) and
            p.referrer != "",
        group_by: p.referrer,
        order_by: [desc: count(p.id)],
        limit: ^limit,
        select: %{referrer: p.referrer, count: count(p.id)}
    )
  end

  def device_breakdown(site_id, period) do
    since = period_start(period)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^site_id and p.inserted_at >= ^since,
        group_by: p.device_type,
        order_by: [desc: count(p.id)],
        select: %{device: p.device_type, count: count(p.id)}
    )
  end

  def country_breakdown(site_id, period, limit \\ 10) do
    since = period_start(period)

    Repo.all(
      from p in "pageviews",
        where:
          p.site_id == ^site_id and
            p.inserted_at >= ^since and
            not is_nil(p.country),
        group_by: p.country,
        order_by: [desc: count(p.id)],
        limit: ^limit,
        select: %{country: p.country, count: count(p.id)}
    )
  end

  def heatmap_clicks(site_id, period, url) do
    since = period_start(period)

    Repo.all(
      from e in "events",
        where:
          e.site_id == ^site_id and
            e.event_name == "heatmap_click" and
            e.inserted_at >= ^since and
            e.url == ^url,
        select: e.metadata
    )
  end

  def pageviews_for_export(site_id, period) do
    since = period_start(period)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^site_id and p.inserted_at >= ^since,
        order_by: [desc: p.inserted_at],
        select: %{
          date: p.inserted_at,
          url: p.url,
          referrer: p.referrer,
          device_type: p.device_type,
          browser: p.browser,
          os: p.os,
          country: p.country,
          utm_source: p.utm_source,
          utm_medium: p.utm_medium,
          utm_campaign: p.utm_campaign
        }
    )
  end

  def pageviews_timeline(site_id, period) do
    since = period_start(period)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^site_id and p.inserted_at >= ^since,
        group_by: fragment("DATE(inserted_at)"),
        order_by: fragment("DATE(inserted_at)"),
        select: %{
          date: fragment("DATE(inserted_at)"),
          count: count(p.id)
        }
    )
  end
end
