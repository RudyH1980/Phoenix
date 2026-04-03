defmodule PhoenixAnalytics.DemoData do
  @moduledoc "Statische demo data voor de publieke demo pagina — geen database nodig."

  @today Date.utc_today()

  @sites [
    %{
      id: "technews",
      name: "TechBlog NL",
      domain: "techblog.nl",
      base_daily: 420,
      pattern: :content,
      growth: 0.45
    },
    %{
      id: "fashionstore",
      name: "FashionStore",
      domain: "fashionstore.nl",
      base_daily: 980,
      pattern: :ecommerce,
      growth: 0.30
    },
    %{
      id: "saasify",
      name: "SaaSify",
      domain: "saasify.io",
      base_daily: 210,
      pattern: :saas,
      growth: 0.80
    }
  ]

  def sites, do: @sites
  def site(id), do: Enum.find(@sites, &(&1.id == id)) || hd(@sites)
  def valid_site_id?(id), do: Enum.any?(@sites, &(&1.id == id))

  def stats(site_id, period) do
    site = site(site_id)
    tl = timeline(site, period)
    total_pv = Enum.sum(Enum.map(tl, & &1.count))

    %{
      pageviews: total_pv,
      visitors: round(total_pv * visitor_ratio(site_id)),
      bounce_rate: bounce_rate(site_id),
      avg_time: avg_time(site_id),
      timeline: tl,
      top_pages: top_pages(site_id),
      top_referrers: top_referrers(site_id),
      device_breakdown: device_breakdown(site_id),
      os_breakdown: os_breakdown(),
      country_breakdown: country_breakdown(site_id),
      city_breakdown: city_breakdown(site_id),
      visitor_types: visitor_types(site_id, total_pv)
    }
  end

  defp timeline(site, period) do
    days =
      case period do
        "7d" -> 7
        "30d" -> 30
        "90d" -> 90
        "365d" -> 365
        _ -> 30
      end

    Enum.map((days - 1)..0, fn i ->
      date = Date.add(@today, -i)
      %{date: date, count: daily_count(site, date, days)}
    end)
  end

  defp daily_count(site, date, total_days) do
    days_ago = Date.diff(@today, date)
    growth = 1.0 - days_ago / max(total_days, 365) * site.growth
    dow = Date.day_of_week(date)
    wf = week_factor(site.pattern, dow)
    mf = month_factor(site.id, date.month)
    noise = 1.0 + (:erlang.phash2({site.id, date.year, date.month, date.day}, 100) - 50) / 200.0

    round(site.base_daily * growth * wf * mf * noise) |> max(10)
  end

  defp week_factor(:content, dow) when dow in [6, 7], do: 0.55
  defp week_factor(:content, dow) when dow in [1, 5], do: 1.0
  defp week_factor(:content, _), do: 1.15
  defp week_factor(:ecommerce, dow) when dow in [6, 7], do: 1.45
  defp week_factor(:ecommerce, 5), do: 1.2
  defp week_factor(:ecommerce, _), do: 0.85
  defp week_factor(:saas, dow) when dow in [6, 7], do: 0.2
  defp week_factor(:saas, dow) when dow in [1, 5], do: 1.0
  defp week_factor(:saas, _), do: 1.2

  defp month_factor("fashionstore", m) when m in [11, 12], do: 1.8
  defp month_factor("fashionstore", m) when m in [6, 7], do: 1.4
  defp month_factor("fashionstore", m) when m in [1, 2], do: 0.6
  defp month_factor("technews", m) when m in [1, 9, 10], do: 1.3
  defp month_factor("technews", m) when m in [7, 8], do: 0.7
  defp month_factor(_, _), do: 1.0

  defp visitor_ratio("technews"), do: 0.72
  defp visitor_ratio("fashionstore"), do: 0.58
  defp visitor_ratio("saasify"), do: 0.65
  defp visitor_ratio(_), do: 0.65

  defp bounce_rate("technews"), do: 68.4
  defp bounce_rate("fashionstore"), do: 42.1
  defp bounce_rate("saasify"), do: 35.7
  defp bounce_rate(_), do: 50.0

  defp avg_time("technews"), do: 187
  defp avg_time("fashionstore"), do: 245
  defp avg_time("saasify"), do: 312
  defp avg_time(_), do: 180

  defp top_pages("technews") do
    [
      %{url: "/", count: 12_400},
      %{url: "/blog/best-laptops-2025", count: 8_920},
      %{url: "/blog/ai-tools-2025", count: 7_650},
      %{url: "/reviews/macbook-pro-m4", count: 5_430},
      %{url: "/blog", count: 4_280},
      %{url: "/reviews", count: 3_190},
      %{url: "/blog/linux-vs-windows", count: 2_840},
      %{url: "/about", count: 1_920},
      %{url: "/blog/javascript-frameworks-2025", count: 1_780},
      %{url: "/contact", count: 890},
      %{url: "/newsletter", count: 650},
      %{url: "/sitemap", count: 310}
    ]
  end

  defp top_pages("fashionstore") do
    [
      %{url: "/", count: 28_600},
      %{url: "/collectie/dames", count: 18_400},
      %{url: "/sale", count: 14_200},
      %{url: "/collectie/heren", count: 11_800},
      %{url: "/nieuw", count: 9_400},
      %{url: "/product/zomerjurk-boho", count: 7_200},
      %{url: "/product/sneakers-wit", count: 6_800},
      %{url: "/mijn-account", count: 5_400},
      %{url: "/winkelwagen", count: 4_900},
      %{url: "/checkout", count: 3_200},
      %{url: "/blog/stijltips-zomer", count: 2_800},
      %{url: "/klantenservice", count: 1_900}
    ]
  end

  defp top_pages("saasify") do
    [
      %{url: "/dashboard", count: 6_800},
      %{url: "/", count: 4_200},
      %{url: "/dashboard/reports", count: 3_900},
      %{url: "/settings", count: 2_800},
      %{url: "/integrations", count: 2_400},
      %{url: "/docs/getting-started", count: 1_900},
      %{url: "/billing", count: 1_600},
      %{url: "/team", count: 1_400},
      %{url: "/docs/api", count: 1_200},
      %{url: "/pricing", count: 980}
    ]
  end

  defp top_pages(_), do: top_pages("technews")

  defp top_referrers("technews") do
    [
      %{referrer: "google.com", count: 18_400},
      %{referrer: "twitter.com", count: 4_200},
      %{referrer: "hn.algolia.com", count: 3_800},
      %{referrer: "reddit.com", count: 2_900},
      %{referrer: "linkedin.com", count: 1_800},
      %{referrer: "nieuwsbrief", count: 1_400},
      %{referrer: "dev.to", count: 980}
    ]
  end

  defp top_referrers("fashionstore") do
    [
      %{referrer: "google.com", count: 32_400},
      %{referrer: "instagram.com", count: 12_800},
      %{referrer: "facebook.com", count: 8_400},
      %{referrer: "pinterest.com", count: 6_200},
      %{referrer: "tiktok.com", count: 4_800},
      %{referrer: "bol.com", count: 2_100},
      %{referrer: "e-mail nieuwsbrief", count: 1_800}
    ]
  end

  defp top_referrers("saasify") do
    [
      %{referrer: "google.com", count: 4_800},
      %{referrer: "producthunt.com", count: 2_400},
      %{referrer: "linkedin.com", count: 1_900},
      %{referrer: "twitter.com", count: 1_400},
      %{referrer: "g2.com", count: 980},
      %{referrer: "capterra.com", count: 780}
    ]
  end

  defp top_referrers(_), do: top_referrers("technews")

  defp device_breakdown("fashionstore") do
    [
      %{device: "Mobile", count: 48_400},
      %{device: "Desktop", count: 18_200},
      %{device: "Tablet", count: 8_400}
    ]
  end

  defp device_breakdown("saasify") do
    [
      %{device: "Desktop", count: 14_800},
      %{device: "Mobile", count: 4_200},
      %{device: "Tablet", count: 900}
    ]
  end

  defp device_breakdown(_) do
    [
      %{device: "Desktop", count: 24_800},
      %{device: "Mobile", count: 18_400},
      %{device: "Tablet", count: 4_200}
    ]
  end

  defp os_breakdown do
    [
      %{os: "Windows", count: 18_400},
      %{os: "iOS", count: 14_200},
      %{os: "macOS", count: 12_800},
      %{os: "Android", count: 9_800},
      %{os: "Linux", count: 2_400}
    ]
  end

  defp country_breakdown("technews") do
    [
      %{country: "NL", count: 24_800},
      %{country: "BE", count: 8_400},
      %{country: "DE", count: 6_200},
      %{country: "US", count: 4_800},
      %{country: "GB", count: 3_200},
      %{country: "FR", count: 2_100}
    ]
  end

  defp country_breakdown("fashionstore") do
    [
      %{country: "NL", count: 58_400},
      %{country: "BE", count: 14_200},
      %{country: "DE", count: 4_800},
      %{country: "GB", count: 1_800},
      %{country: "US", count: 980}
    ]
  end

  defp country_breakdown("saasify") do
    [
      %{country: "US", count: 8_400},
      %{country: "NL", count: 4_200},
      %{country: "GB", count: 3_800},
      %{country: "DE", count: 2_900},
      %{country: "CA", count: 1_800},
      %{country: "AU", count: 1_400},
      %{country: "FR", count: 980}
    ]
  end

  defp country_breakdown(_), do: country_breakdown("technews")

  defp city_breakdown("technews") do
    [
      %{city: "Amsterdam", country: "NL", count: 9_800},
      %{city: "Rotterdam", country: "NL", count: 4_200},
      %{city: "Den Haag", country: "NL", count: 3_800},
      %{city: "Utrecht", country: "NL", count: 3_400},
      %{city: "Brussel", country: "BE", count: 2_900},
      %{city: "Eindhoven", country: "NL", count: 2_400},
      %{city: "Hamburg", country: "DE", count: 1_800},
      %{city: "Antwerpen", country: "BE", count: 1_600}
    ]
  end

  defp city_breakdown("fashionstore") do
    [
      %{city: "Amsterdam", country: "NL", count: 18_400},
      %{city: "Rotterdam", country: "NL", count: 9_800},
      %{city: "Den Haag", country: "NL", count: 7_400},
      %{city: "Utrecht", country: "NL", count: 6_800},
      %{city: "Brussel", country: "BE", count: 5_400},
      %{city: "Antwerpen", country: "BE", count: 4_200},
      %{city: "Eindhoven", country: "NL", count: 3_800},
      %{city: "Breda", country: "NL", count: 2_900}
    ]
  end

  defp city_breakdown("saasify") do
    [
      %{city: "New York", country: "US", count: 2_800},
      %{city: "San Francisco", country: "US", count: 2_400},
      %{city: "Amsterdam", country: "NL", count: 1_900},
      %{city: "London", country: "GB", count: 1_800},
      %{city: "Berlin", country: "DE", count: 1_400},
      %{city: "Toronto", country: "CA", count: 980}
    ]
  end

  defp city_breakdown(_), do: city_breakdown("technews")

  defp visitor_types(site_id, total_pv) do
    total = round(total_pv * visitor_ratio(site_id))

    new_ratio =
      case site_id do
        "technews" -> 0.68
        "fashionstore" -> 0.55
        "saasify" -> 0.42
        _ -> 0.60
      end

    new_v = round(total * new_ratio)
    %{new: new_v, returning: total - new_v, total: total}
  end
end
