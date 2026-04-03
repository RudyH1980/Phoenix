defmodule PhoenixAnalytics.DemoSeeder do
  @moduledoc "Maakt idempotent een demo account aan met 6 maanden gesimuleerde data."

  require Logger
  require Ash.Query

  import Ecto.Query

  alias PhoenixAnalytics.{Repo, Accounts, Analytics}
  alias PhoenixAnalytics.Accounts.User
  alias PhoenixAnalytics.Experiments.{Experiment, Variant}

  @demo_email "demo@neo-analytics.app"

  def demo_email, do: @demo_email

  @doc "Idempotent: vindt of maakt demo user + org + sites + alle data."
  def ensure_demo_account do
    case find_demo_user() do
      {:ok, user} ->
        ensure_demo_extras(user)
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

  # Voeg heatmap + experimenten toe aan bestaand demo account als die ontbreken
  defp ensure_demo_extras(user) do
    org_ids = Accounts.user_org_ids(user.id)
    sites = get_demo_sites(org_ids)
    configs = demo_site_configs()

    Enum.each(Enum.zip(sites, configs), fn {site, config} ->
      unless has_heatmap_data?(site), do: insert_heatmap_clicks(site, config)
      unless has_experiments?(site), do: insert_demo_experiment(site, config)
    end)
  end

  defp get_demo_sites(org_ids) do
    Analytics.Site
    |> Ash.Query.filter(org_id in ^org_ids)
    |> Ash.read!()
    |> Enum.sort_by(& &1.name)
  end

  defp has_heatmap_data?(site) do
    site_id_bin = Ecto.UUID.dump!(site.id)

    Repo.one(
      from e in "events",
        where: e.site_id == ^site_id_bin and e.event_name == "heatmap_click",
        select: count(e.id),
        limit: 1
    ) > 0
  end

  defp has_experiments?(site) do
    site_id_bin = Ecto.UUID.dump!(site.id)

    Repo.one(
      from e in "experiments",
        where: e.site_id == ^site_id_bin,
        select: count(e.id),
        limit: 1
    ) > 0
  end

  # ── aanmaken ──────────────────────────────────────────────────────────────

  defp create_full_demo_account do
    with {:ok, user} <- create_demo_user(),
         {:ok, org} <- Accounts.create_org_with_owner("Demo Organisatie", user.id) do
      for config <- demo_site_configs() do
        {:ok, site} =
          Analytics.Site
          |> Ash.Changeset.for_create(:create, %{
            name: config.name,
            domain: config.domain,
            org_id: org.id
          })
          |> Ash.create()

        insert_pageviews_for_site(site, config)
        insert_heatmap_clicks(site, config)
        insert_demo_experiment(site, config)
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
        generate_pageview_rows(site_id_bin, config, date, count)
      end)

    rows
    |> Enum.chunk_every(500)
    |> Enum.each(&Repo.insert_all("pageviews", &1))
  end

  defp daily_count(date, config) do
    day_of_week = Date.day_of_week(date)
    is_weekend = day_of_week in [6, 7]
    today = Date.utc_today()
    days_ago = Date.diff(today, date)
    growth = 1.0 - days_ago / 180.0 * 0.4
    base = if is_weekend, do: config.weekend_base, else: config.weekday_base
    jitter_range = max(1, div(base, 5))
    jitter = :rand.uniform(jitter_range * 2 + 1) - jitter_range - 1
    max(1, trunc(base * growth) + jitter)
  end

  defp generate_pageview_rows(site_id_bin, config, date, count) do
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

  # ── heatmap clicks ────────────────────────────────────────────────────────

  defp insert_heatmap_clicks(site, config) do
    site_id_bin = Ecto.UUID.dump!(site.id)
    today = Date.utc_today()

    rows =
      config.pages
      |> Enum.flat_map(fn page ->
        # 90 dagen aan klik-data per pagina
        Date.range(Date.add(today, -90), today)
        |> Enum.flat_map(fn date ->
          clicks_per_day = :rand.uniform(8) + 2
          for _ <- 1..clicks_per_day, do: heatmap_row(site_id_bin, page, date)
        end)
      end)

    rows
    |> Enum.chunk_every(500)
    |> Enum.each(&Repo.insert_all("events", &1))
  end

  defp heatmap_row(site_id_bin, url, date) do
    {x, y} = random_click_position()
    ts = random_ts(date)

    %{
      id: Ecto.UUID.bingenerate(),
      site_id: site_id_bin,
      session_hash: Base.encode16(:crypto.strong_rand_bytes(12), case: :lower),
      event_name: "heatmap_click",
      url: url,
      metadata: %{"x" => x, "y" => y},
      inserted_at: ts,
      updated_at: ts
    }
  end

  # Klik-posities gegroepeerd in realistische zones
  defp random_click_position do
    zone = Enum.random([:nav, :hero, :content, :cta, :footer])

    case zone do
      # Navigatie bovenaan
      :nav ->
        {gaussian(50, 35, 5, 95), gaussian(4, 3, 1, 12)}

      # Hero / boven de vouw — meeste clicks
      :hero ->
        {gaussian(50, 25, 10, 90), gaussian(25, 12, 8, 45)}

      # Midden-content
      :content ->
        {gaussian(48, 22, 5, 95), gaussian(55, 18, 30, 75)}

      # Call-to-action zones
      :cta ->
        {gaussian(50, 18, 20, 80), gaussian(38, 10, 20, 58)}

      # Footer
      :footer ->
        {gaussian(45, 30, 5, 95), gaussian(90, 6, 78, 100)}
    end
  end

  # Benader een normale verdeling met 3 uniform samples (centrale limietstelling)
  defp gaussian(mean, std, min_val, max_val) do
    noise = (:rand.uniform() + :rand.uniform() + :rand.uniform() - 1.5) * std
    round(mean + noise) |> max(min_val) |> min(max_val)
  end

  # ── A/B experimenten ─────────────────────────────────────────────────────

  defp insert_demo_experiment(site, config) do
    exp_config = config.experiment

    # Experiment via Ash aanmaken (site_id via force_change_attribute)
    {:ok, experiment} =
      Experiment
      |> Ash.Changeset.for_create(:create, %{
        name: exp_config.name,
        description: exp_config.description,
        goal_event: exp_config.goal_event
      })
      |> Ash.Changeset.force_change_attribute(:site_id, site.id)
      |> Ash.Changeset.force_change_attribute(:status, :running)
      |> Ash.create()

    # Varianten
    {:ok, variant_a} =
      Variant
      |> Ash.Changeset.for_create(:create, %{
        name: exp_config.variant_a.name,
        weight: 50
      })
      |> Ash.Changeset.force_change_attribute(:experiment_id, experiment.id)
      |> Ash.create()

    {:ok, variant_b} =
      Variant
      |> Ash.Changeset.for_create(:create, %{
        name: exp_config.variant_b.name,
        weight: 50
      })
      |> Ash.Changeset.force_change_attribute(:experiment_id, experiment.id)
      |> Ash.create()

    exp_id_bin = Ecto.UUID.dump!(experiment.id)
    var_a_bin = Ecto.UUID.dump!(variant_a.id)
    var_b_bin = Ecto.UUID.dump!(variant_b.id)
    site_id_bin = Ecto.UUID.dump!(site.id)

    insert_assignments_and_conversions(
      exp_id_bin,
      var_a_bin,
      variant_a.name,
      var_b_bin,
      variant_b.name,
      exp_config,
      site_id_bin
    )
  end

  defp insert_assignments_and_conversions(
         exp_id_bin,
         var_a_bin,
         var_a_name,
         var_b_bin,
         var_b_name,
         exp_config,
         site_id_bin
       ) do
    now = NaiveDateTime.utc_now()
    today = Date.utc_today()

    # Genereer sessies voor variant A
    sessions_a =
      for _ <- 1..exp_config.variant_a.visitors do
        Base.encode16(:crypto.strong_rand_bytes(12), case: :lower)
      end

    # Genereer sessies voor variant B
    sessions_b =
      for _ <- 1..exp_config.variant_b.visitors do
        Base.encode16(:crypto.strong_rand_bytes(12), case: :lower)
      end

    # Assignments bulk insert
    assignments =
      Enum.map(sessions_a, fn hash ->
        %{
          id: Ecto.UUID.bingenerate(),
          experiment_id: exp_id_bin,
          variant_id: var_a_bin,
          session_hash: hash,
          inserted_at: now,
          updated_at: now
        }
      end) ++
        Enum.map(sessions_b, fn hash ->
          %{
            id: Ecto.UUID.bingenerate(),
            experiment_id: exp_id_bin,
            variant_id: var_b_bin,
            session_hash: hash,
            inserted_at: now,
            updated_at: now
          }
        end)

    Repo.insert_all("assignments", assignments)

    # Conversie events voor een subset van de sessies
    conv_a = Enum.take(Enum.shuffle(sessions_a), exp_config.variant_a.conversions)
    conv_b = Enum.take(Enum.shuffle(sessions_b), exp_config.variant_b.conversions)

    conv_events =
      Enum.map(conv_a, fn hash ->
        ts = random_ts(Date.add(today, -:rand.uniform(90)))

        %{
          id: Ecto.UUID.bingenerate(),
          site_id: site_id_bin,
          experiment_id: exp_id_bin,
          session_hash: hash,
          event_name: exp_config.goal_event,
          variant_name: var_a_name,
          url: "/",
          metadata: %{},
          inserted_at: ts,
          updated_at: ts
        }
      end) ++
        Enum.map(conv_b, fn hash ->
          ts = random_ts(Date.add(today, -:rand.uniform(90)))

          %{
            id: Ecto.UUID.bingenerate(),
            site_id: site_id_bin,
            experiment_id: exp_id_bin,
            session_hash: hash,
            event_name: exp_config.goal_event,
            variant_name: var_b_name,
            url: "/",
            metadata: %{},
            inserted_at: ts,
            updated_at: ts
          }
        end)

    Repo.insert_all("events", conv_events)
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
        referrers: [nil, nil, "google.com", "instagram.com", "facebook.com", "tripadvisor.nl"],
        experiment: %{
          name: "Reserveringsknop kleur",
          description:
            "Test of een groene CTA-knop meer reserveringen oplevert dan de standaard blauwe",
          goal_event: "reservering_click",
          variant_a: %{name: "A — Blauw (controle)", visitors: 400, conversions: 80},
          variant_b: %{name: "B — Groen (variant)", visitors: 400, conversions: 120}
        }
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
        ],
        experiment: %{
          name: "Productpagina layout",
          description: "Lijst-indeling versus grid-indeling op de productoverzicht pagina",
          goal_event: "add_to_cart",
          variant_a: %{name: "A — Lijst (controle)", visitors: 300, conversions: 36},
          variant_b: %{name: "B — Grid (variant)", visitors: 300, conversions: 45}
        }
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
        ],
        experiment: %{
          name: "Nieuwsbrief CTA positie",
          description: "Sidebar-plaatsing versus inline in het artikel voor hogere aanmeldrate",
          goal_event: "nieuwsbrief_aanmelding",
          variant_a: %{name: "A — Sidebar (controle)", visitors: 500, conversions: 40},
          variant_b: %{name: "B — Inline artikel (variant)", visitors: 500, conversions: 70}
        }
      }
    ]
  end

  # ── willekeurige data helpers ─────────────────────────────────────────────

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

  defp random_ts(date) do
    hour = :rand.uniform(24) - 1
    minute = :rand.uniform(60) - 1
    second = :rand.uniform(60) - 1
    NaiveDateTime.new!(date, Time.new!(hour, minute, second, 0))
  end
end
