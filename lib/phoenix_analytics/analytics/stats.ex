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

  # Raw Ecto queries verwachten binary UUIDs -- converteer string UUIDs altijd eerst
  defp to_binary_uuid(id) when is_binary(id) and byte_size(id) == 16, do: id
  defp to_binary_uuid(id), do: Ecto.UUID.dump!(id)

  def pageview_count(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.one(
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        select: count(p.id)
    ) || 0
  end

  def unique_visitors(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.one(
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        select: count(p.session_hash, :distinct)
    ) || 0
  end

  def bounce_rate(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    total =
      Repo.one(
        from p in "pageviews",
          where: p.site_id == ^sid and p.inserted_at >= ^since,
          select: count(p.session_hash, :distinct)
      ) || 0

    bounced_subq =
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        group_by: p.session_hash,
        having: count(p.id) == 1,
        select: %{session_hash: p.session_hash}

    bounced = Repo.one(from s in subquery(bounced_subq), select: count()) || 0

    if total > 0, do: Float.round(bounced / total * 100, 1), else: 0.0
  end

  def top_pages(site_id, period, limit \\ 10) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        group_by: p.url,
        order_by: [desc: count(p.id)],
        limit: ^limit,
        select: %{url: p.url, count: count(p.id)}
    )
  end

  def top_referrers(site_id, period, limit \\ 10) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where:
          p.site_id == ^sid and
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
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        group_by: p.device_type,
        order_by: [desc: count(p.id)],
        select: %{device: p.device_type, count: count(p.id)}
    )
  end

  def os_breakdown(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        group_by: p.os,
        order_by: [desc: count(p.id)],
        select: %{os: p.os, count: count(p.id)}
    )
  end

  def country_breakdown(site_id, period, limit \\ 10) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where:
          p.site_id == ^sid and
            p.inserted_at >= ^since and
            not is_nil(p.country),
        group_by: p.country,
        order_by: [desc: count(p.id)],
        limit: ^limit,
        select: %{country: p.country, count: count(p.id)}
    )
  end

  def city_breakdown(site_id, period, limit \\ 10) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where:
          p.site_id == ^sid and
            p.inserted_at >= ^since and
            not is_nil(p.city),
        group_by: [p.city, p.country],
        order_by: [desc: count(p.id)],
        limit: ^limit,
        select: %{city: p.city, country: p.country, count: count(p.id)}
    )
  end

  def new_vs_returning(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    period_sessions =
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        select: p.session_hash,
        distinct: true

    total = Repo.one(from s in subquery(period_sessions), select: count()) || 0

    # Terugkerend = sessies die op meer dan 1 dag bezochten (ooit)
    multi_day =
      from p in "pageviews",
        where: p.site_id == ^sid,
        group_by: p.session_hash,
        having: count(fragment("DISTINCT DATE(inserted_at)")) > 1,
        select: p.session_hash

    returning =
      Repo.one(
        from s in subquery(period_sessions),
          where: s.session_hash in subquery(multi_day),
          select: count()
      ) || 0

    %{new: max(total - returning, 0), returning: returning, total: total}
  end

  def section_views(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from e in "events",
        where:
          e.site_id == ^sid and
            e.event_name == "section_view" and
            e.inserted_at >= ^since,
        select: e.metadata
    )
    |> Enum.group_by(& &1["section"])
    |> Enum.map(fn {section, rows} -> %{section: section, count: length(rows)} end)
    |> Enum.filter(& &1.section)
    |> Enum.sort_by(& &1.count, :desc)
  end

  def top_events(site_id, period, limit \\ 10) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from e in "events",
        where:
          e.site_id == ^sid and
            e.inserted_at >= ^since and
            e.event_name != "heatmap_click" and
            e.event_name != "time_on_page",
        group_by: e.event_name,
        order_by: [desc: count(e.id)],
        limit: ^limit,
        select: %{event_name: e.event_name, count: count(e.id)}
    )
  end

  def avg_time_on_page(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    result =
      Repo.one(
        from e in "events",
          where:
            e.site_id == ^sid and
              e.event_name == "time_on_page" and
              e.inserted_at >= ^since,
          select: avg(fragment("(metadata->>'seconds')::numeric"))
      )

    if result, do: result |> Decimal.to_float() |> Float.round(0) |> trunc(), else: 0
  end

  def heatmap_clicks(site_id, period, url) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from e in "events",
        where:
          e.site_id == ^sid and
            e.event_name == "heatmap_click" and
            e.inserted_at >= ^since and
            e.url == ^url,
        select: e.metadata
    )
  end

  def pageviews_for_export(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        order_by: [desc: p.inserted_at],
        select: %{
          date: p.inserted_at,
          url: p.url,
          referrer: p.referrer,
          device_type: p.device_type,
          browser: p.browser,
          os: p.os,
          country: p.country,
          city: p.city,
          region: p.region,
          utm_source: p.utm_source,
          utm_medium: p.utm_medium,
          utm_campaign: p.utm_campaign
        }
    )
  end

  def combined_timeline(org_ids, period) do
    since = period_start(period)
    binary_ids = Enum.map(org_ids, &Ecto.UUID.dump!/1)
    site_ids_q = from s in "sites", where: s.org_id in ^binary_ids, select: s.id

    Repo.all(
      from p in "pageviews",
        where: p.site_id in subquery(site_ids_q) and p.inserted_at >= ^since,
        group_by: fragment("DATE(inserted_at)"),
        order_by: fragment("DATE(inserted_at)"),
        select: %{date: fragment("DATE(inserted_at)"), count: count(p.id)}
    )
  end

  def sites_pageview_counts(org_ids, period) do
    since = period_start(period)
    binary_ids = Enum.map(org_ids, &Ecto.UUID.dump!/1)
    site_ids_q = from s in "sites", where: s.org_id in ^binary_ids, select: s.id

    Repo.all(
      from p in "pageviews",
        where: p.site_id in subquery(site_ids_q) and p.inserted_at >= ^since,
        group_by: p.site_id,
        select: %{
          site_id: type(p.site_id, Ecto.UUID),
          pageviews: count(p.id),
          visitors: count(p.session_hash, :distinct)
        }
    )
    |> Map.new(&{&1.site_id, &1})
  end

  def pageviews_timeline(site_id, period) do
    since = period_start(period)
    sid = to_binary_uuid(site_id)

    Repo.all(
      from p in "pageviews",
        where: p.site_id == ^sid and p.inserted_at >= ^since,
        group_by: fragment("DATE(inserted_at)"),
        order_by: fragment("DATE(inserted_at)"),
        select: %{
          date: fragment("DATE(inserted_at)"),
          count: count(p.id)
        }
    )
  end
end
