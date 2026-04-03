defmodule PhoenixAnalytics.DemoSeeder do
  @moduledoc "Maakt idempotent een demo account aan met 6 maanden gesimuleerde data."

  require Logger
  require Ash.Query

  alias PhoenixAnalytics.{Repo, Accounts, Analytics}
  alias PhoenixAnalytics.Accounts.User

  @demo_email "demo@neo-analytics.app"

  def demo_email, do: @demo_email

  @doc "Idempotent: vindt of maakt demo user + org + sites + pageviews."
  def ensure_demo_account do
    case find_demo_user() do
      {:ok, user} ->
        {:ok, user}

      :not_found ->
        Logger.info("DemoSeeder: demo account aanmaken...")
        result = create_full_demo_account()
        Logger.info("DemoSeeder: klaar.")
        result
    end
  end

  # ── vinden ────────────────────────────────────────────────────────────────

  defp find_demo_user do
    case User
         |> Ash.Query.filter(email == ^@demo_email)
         |> Ash.read_one() do
      {:ok, nil} -> :not_found
      {:ok, user} -> {:ok, user}
      {:error, _} -> :not_found
    end
  end

  # ── aanmaken ──────────────────────────────────────────────────────────────

  defp create_full_demo_account do
    with {:ok, user} <- create_demo_user(),
         {:ok, org} <- Accounts.create_org_with_owner("Demo Organisatie", user.id) do
      site_configs = demo_site_configs()

      for config <- site_configs do
        {:ok, site} =
          Analytics.Site
          |> Ash.Changeset.for_create(:create, %{
            name: config.name,
            domain: config.domain,
            org_id: org.id
          })
          |> Ash.create()

        insert_pageviews_for_site(site, config)
      end

      {:ok, user}
    end
  end

  defp create_demo_user do
    User
    |> Ash.Changeset.for_create(:create, %{email: @demo_email, name: "Demo Account"})
    |> Ash.create()
  end

  # ── pageview bulk insert ──────────────────────────────────────────────────

  defp insert_pageviews_for_site(site, config) do
    site_id_bin = Ecto.UUID.dump!(site.id)
    today = Date.utc_today()
    start_date = Date.add(today, -180)

    rows =
      Date.range(start_date, today)
      |> Enum.flat_map(fn date ->
        count = daily_count(date, config)
        generate_rows(site_id_bin, config, date, count)
      end)

    rows
    |> Enum.chunk_every(500)
    |> Enum.each(&Repo.insert_all("pageviews", &1))
  end

  defp daily_count(date, config) do
    day_of_week = Date.day_of_week(date)
    is_weekend = day_of_week in [6, 7]

    # Groei-trend: oudere data is minder druk (60% -> 100%)
    today = Date.utc_today()
    days_ago = Date.diff(today, date)
    growth = 1.0 - days_ago / 180.0 * 0.4

    base = if is_weekend, do: config.weekend_base, else: config.weekday_base
    jitter_range = max(1, div(base, 5))
    jitter = :rand.uniform(jitter_range * 2 + 1) - jitter_range - 1

    max(1, trunc(base * growth) + jitter)
  end

  defp generate_rows(site_id_bin, config, date, count) do
    for _ <- 1..count do
      {device, browser, os} = random_device()
      {country, city} = random_location()
      hour = :rand.uniform(24) - 1
      minute = :rand.uniform(60) - 1
      second = :rand.uniform(60) - 1
      ts = NaiveDateTime.new!(date, Time.new!(hour, minute, second, 0))

      %{
        id: Ecto.UUID.bingenerate(),
        site_id: site_id_bin,
        session_hash: Base.encode16(:crypto.strong_rand_bytes(12), case: :lower),
        url: Enum.random(config.pages),
        referrer: random_referrer(config),
        device_type: device,
        browser: browser,
        os: os,
        country: country,
        city: city,
        duration_seconds: :rand.uniform(240) + 10,
        inserted_at: ts,
        updated_at: ts
      }
    end
  end

  # ── demo site configuraties ───────────────────────────────────────────────

  defp demo_site_configs do
    [
      %{
        name: "Café de Hoek",
        domain: "demo-cafedehoek.nl",
        weekday_base: 45,
        weekend_base: 95,
        pages: [
          "/",
          "/menu",
          "/reservering",
          "/contact",
          "/over-ons",
          "/evenementen",
          "/galerij"
        ],
        referrers: [nil, nil, "google.com", "instagram.com", "facebook.com", "tripadvisor.nl"]
      },
      %{
        name: "BakeNow Webshop",
        domain: "demo-bakenow.nl",
        weekday_base: 110,
        weekend_base: 75,
        pages: [
          "/",
          "/producten",
          "/producten/taarten",
          "/producten/brood",
          "/producten/koekjes",
          "/winkelwagen",
          "/afrekenen",
          "/over-ons"
        ],
        referrers: [
          nil,
          nil,
          "google.com",
          "google.com",
          "bing.com",
          "facebook.com",
          "instagram.com"
        ]
      },
      %{
        name: "TechBlog NL",
        domain: "demo-techblognl.nl",
        weekday_base: 80,
        weekend_base: 30,
        pages: [
          "/",
          "/artikel/elixir-tips-2025",
          "/artikel/ai-en-privacy",
          "/artikel/remote-werk-2026",
          "/artikel/passkeys-uitgelegd",
          "/artikel/react-vs-vue",
          "/over",
          "/archief"
        ],
        referrers: [
          nil,
          nil,
          "google.com",
          "google.com",
          "twitter.com",
          "hackernews.com",
          "linkedin.com",
          "reddit.com"
        ]
      }
    ]
  end

  # ── willekeurige data ─────────────────────────────────────────────────────

  defp random_device do
    Enum.random([
      {"Mobile", "Safari", "iOS"},
      {"Mobile", "Safari", "iOS"},
      {"Mobile", "Safari", "iOS"},
      {"Mobile", "Chrome", "Android"},
      {"Mobile", "Chrome", "Android"},
      {"Desktop", "Chrome", "Windows"},
      {"Desktop", "Chrome", "Windows"},
      {"Desktop", "Chrome", "Windows"},
      {"Desktop", "Firefox", "Windows"},
      {"Desktop", "Firefox", "Linux"},
      {"Desktop", "Safari", "macOS"},
      {"Desktop", "Safari", "macOS"},
      {"Desktop", "Edge", "Windows"},
      {"Tablet", "Safari", "iOS"},
      {"Tablet", "Chrome", "Android"}
    ])
  end

  defp random_location do
    Enum.random([
      {"NL", "Amsterdam"},
      {"NL", "Amsterdam"},
      {"NL", "Rotterdam"},
      {"NL", "Rotterdam"},
      {"NL", "Den Haag"},
      {"NL", "Utrecht"},
      {"NL", "Eindhoven"},
      {"NL", "Groningen"},
      {"NL", "Tilburg"},
      {"NL", "Nijmegen"},
      {"BE", "Brussel"},
      {"BE", "Antwerpen"},
      {"BE", "Gent"},
      {"DE", "Berlin"},
      {"DE", "Hamburg"},
      {"GB", "London"},
      {"FR", "Paris"},
      {nil, nil}
    ])
  end

  defp random_referrer(config) do
    case Enum.random(config.referrers) do
      nil -> nil
      ref -> "https://#{ref}"
    end
  end
end
