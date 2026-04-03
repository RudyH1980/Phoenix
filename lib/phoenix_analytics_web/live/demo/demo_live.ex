defmodule PhoenixAnalyticsWeb.Live.Demo.DemoLive do
  @moduledoc "Publieke demo pagina — toont realistische data van drie fictieve websites."
  use PhoenixAnalyticsWeb, :live_view

  import PhoenixAnalyticsWeb.ChartComponents

  alias PhoenixAnalytics.DemoData

  @realtime_interval 3_500

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :tick_realtime, @realtime_interval)
    end

    {:ok,
     socket
     |> assign(
       sites: DemoData.sites(),
       selected_site: "technews",
       period: "30d",
       realtime_count: 0,
       table_limits: %{},
       page_title: "Demo — Neo Analytics"
     )
     |> load_stats("technews", "30d")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    site_id =
      if DemoData.valid_site_id?(params["site"]),
        do: params["site"],
        else: socket.assigns.selected_site

    period =
      if params["period"] in ~w(7d 30d 90d 365d),
        do: params["period"],
        else: socket.assigns.period

    {:noreply,
     socket
     |> assign(selected_site: site_id, period: period, realtime_count: 0)
     |> load_stats(site_id, period)}
  end

  @impl true
  def handle_info(:tick_realtime, socket) do
    Process.send_after(self(), :tick_realtime, @realtime_interval)
    site_id = socket.assigns.selected_site
    # Simuleer een nieuwe pageview met gewicht op drukkere sites
    bump =
      case site_id do
        "fashionstore" -> :rand.uniform(3)
        "technews" -> :rand.uniform(2)
        _ -> if :rand.uniform(3) == 1, do: 1, else: 0
      end

    {:noreply, update(socket, :realtime_count, &(&1 + bump))}
  end

  @impl true
  def handle_event("set_limit", %{"table" => table, "limit" => limit}, socket) do
    parsed = if limit == "all", do: :all, else: String.to_integer(limit)
    {:noreply, assign(socket, table_limits: Map.put(socket.assigns.table_limits, table, parsed))}
  end

  defp load_stats(socket, site_id, period) do
    stats = DemoData.stats(site_id, period)
    site = DemoData.site(site_id)
    assign(socket, Map.merge(stats, %{site: site, table_limits: %{}}))
  end

  # ── helpers ──────────────────────────────────────────────────────────────

  defp table_rows(data, limits, key, default \\ 10) do
    limit = Map.get(limits, key, default)
    if limit == :all, do: data, else: Enum.take(data, limit)
  end

  defp format_number(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  defp format_number(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}k"
  defp format_number(n), do: to_string(n)

  defp truncate_url(url) when byte_size(url) > 48, do: String.slice(url, 0, 45) <> "..."
  defp truncate_url(url), do: url

  defp format_duration(0), do: "—"
  defp format_duration(s) when s < 60, do: "#{s}s"
  defp format_duration(s), do: "#{div(s, 60)}m #{rem(s, 60)}s"

  defp os_icon("iOS"), do: "🍎"
  defp os_icon("macOS"), do: "🍎"
  defp os_icon("Android"), do: "🤖"
  defp os_icon("Windows"), do: "🪟"
  defp os_icon("Linux"), do: "🐧"
  defp os_icon(_), do: "💻"

  defp flag(nil), do: "🌐"

  defp flag(code) when byte_size(code) == 2 do
    code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 + 127_397))
    |> List.to_string()
  end

  defp flag(_), do: "🌐"

  attr :table, :string, required: true
  attr :limits, :map, required: true
  attr :total, :integer, required: true

  defp limit_bar(assigns) do
    current = Map.get(assigns.limits, assigns.table, 10)
    assigns = assign(assigns, current: current)

    ~H"""
    <%= if @total > 10 do %>
      <div class="pa-limit-bar">
        <span class="pa-limit-label">{@total} rijen</span>
        <%= for opt <- [10, 25, 50, :all] do %>
          <button
            phx-click="set_limit"
            phx-value-table={@table}
            phx-value-limit={if opt == :all, do: "all", else: to_string(opt)}
            class={"pa-limit-btn#{if @current == opt, do: " active"}"}
          >
            {if opt == :all, do: "Alle", else: opt}
          </button>
        <% end %>
      </div>
    <% end %>
    """
  end

  # ── render ───────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <%!-- Demo banner --%>
      <div class="pa-demo-banner">
        <div class="pa-demo-banner-left">
          <span class="pa-demo-badge">LIVE DEMO</span>
          <span>
            Dit zijn voorbeeldwebsites met gesimuleerde data — zo ziet jouw dashboard eruit.
          </span>
        </div>
        <.link navigate={~p"/login"} class="pa-btn pa-btn--primary pa-btn--sm">
          Start gratis →
        </.link>
      </div>

      <%!-- Header --%>
      <header class="pa-header" style="margin-bottom: 1.5rem;">
        <div class="pa-header-brand">
          <h1>Neo Analytics</h1>
          <p>Cookieloze analytics &amp; A/B testing</p>
        </div>
        <nav class="pa-header-nav">
          <.link navigate={~p"/login"} class="pa-btn pa-btn--ghost">Inloggen</.link>
        </nav>
      </header>

      <%!-- Site switcher --%>
      <div class="pa-demo-sites">
        <%= for s <- @sites do %>
          <.link
            patch={~p"/demo?site=#{s.id}&period=#{@period}"}
            class={"pa-demo-site-tab#{if @selected_site == s.id, do: " active"}"}
          >
            <strong>{s.name}</strong>
            <span class="pa-demo-site-domain">{s.domain}</span>
          </.link>
        <% end %>
      </div>

      <%!-- Periode tabs --%>
      <div class="pa-period-tabs" style="margin-bottom: 1.5rem;">
        <%= for p <- ~w(7d 30d 90d 365d) do %>
          <.link
            patch={~p"/demo?site=#{@selected_site}&period=#{p}"}
            class={"pa-tab#{if @period == p, do: " active"}"}
          >
            {if p == "365d", do: "1 jaar", else: p}
          </.link>
        <% end %>
      </div>

      <%!-- Statistieken --%>
      <div class="pa-stats-grid" style="margin-bottom: 1.5rem;">
        <div class="pa-stat-card">
          <div class="pa-stat-body">
            <span class="pa-stat-label">Paginaweergaven</span>
            <span class="pa-stat-value">{format_number(@pageviews)}</span>
          </div>
          <div class="pa-stat-icon-wrap">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="28"
              height="28"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
            </svg>
          </div>
        </div>
        <div class="pa-stat-card">
          <div class="pa-stat-body">
            <span class="pa-stat-label">Unieke bezoekers</span>
            <span class="pa-stat-value">{format_number(@visitors)}</span>
          </div>
          <div class="pa-stat-icon-wrap">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="28"
              height="28"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
            </svg>
          </div>
        </div>
        <div class="pa-stat-card">
          <div class="pa-stat-body">
            <span class="pa-stat-label">Bouncepercentage</span>
            <span class="pa-stat-value">{@bounce_rate}%</span>
          </div>
          <div class="pa-stat-icon-wrap">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="28"
              height="28"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" /><polyline points="16 7 22 7 22 13" />
            </svg>
          </div>
        </div>
        <div class="pa-stat-card">
          <div class="pa-stat-body">
            <span class="pa-stat-label">Gem. tijd op pagina</span>
            <span class="pa-stat-value">{format_duration(@avg_time)}</span>
          </div>
          <div class="pa-stat-icon-wrap">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="28"
              height="28"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />
            </svg>
          </div>
        </div>
      </div>

      <%!-- Realtime badge + tijdlijn --%>
      <div class="pa-card" style="margin-bottom: 1.5rem;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
          <h3 style="margin:0;">Pageviews over tijd</h3>
          <%= if @realtime_count > 0 do %>
            <span class="pa-realtime-badge">
              <span class="pa-realtime-dot"></span> +{@realtime_count} live
            </span>
          <% end %>
        </div>
        <.line_chart data={@timeline} height={140} id={"demo-chart-#{@selected_site}"} />
      </div>

      <%!-- Top pagina's + verwijzers --%>
      <div class="pa-two-col" style="margin-bottom: 1.5rem;">
        <section class="pa-card">
          <h3>Top pagina's</h3>
          <ul class="pa-data-list">
            <%= for page <- table_rows(@top_pages, @table_limits, "pages") do %>
              <li>
                <span class="pa-url" title={page.url}>{truncate_url(page.url)}</span>
                <span class="pa-count">{format_number(page.count)}</span>
              </li>
            <% end %>
          </ul>
          <.limit_bar table="pages" limits={@table_limits} total={length(@top_pages)} />
        </section>

        <section class="pa-card">
          <h3>Verwijzers</h3>
          <ul class="pa-data-list">
            <%= for ref <- table_rows(@top_referrers, @table_limits, "referrers") do %>
              <li>
                <span class="pa-url">{truncate_url(ref.referrer)}</span>
                <span class="pa-count">{format_number(ref.count)}</span>
              </li>
            <% end %>
          </ul>
          <.limit_bar table="referrers" limits={@table_limits} total={length(@top_referrers)} />
        </section>
      </div>

      <%!-- Nieuwe vs terugkerende bezoekers --%>
      <section class="pa-card" style="margin-bottom: 1.5rem;">
        <h3>Nieuwe vs terugkerende bezoekers</h3>
        <ul class="pa-data-list">
          <li>
            <span>🆕 Nieuw</span>
            <span class="pa-count">{format_number(@visitor_types.new)}</span>
          </li>
          <li>
            <span>🔄 Terugkerend</span>
            <span class="pa-count">{format_number(@visitor_types.returning)}</span>
          </li>
        </ul>
      </section>

      <%!-- Apparaten + OS + Landen + Steden --%>
      <div class="pa-two-col" style="margin-bottom: 1.5rem;">
        <section class="pa-card">
          <h3>Apparaten</h3>
          <ul class="pa-data-list">
            <%= for d <- @device_breakdown do %>
              <li>
                <span>{d.device}</span>
                <span class="pa-count">{format_number(d.count)}</span>
              </li>
            <% end %>
          </ul>
        </section>

        <section class="pa-card">
          <h3>Besturingssysteem</h3>
          <ul class="pa-data-list">
            <%= for o <- @os_breakdown do %>
              <li>
                <span>{os_icon(o.os)} {o.os}</span>
                <span class="pa-count">{format_number(o.count)}</span>
              </li>
            <% end %>
          </ul>
        </section>

        <section class="pa-card">
          <h3>Landen</h3>
          <ul class="pa-data-list">
            <%= for c <- @country_breakdown do %>
              <li>
                <span>{flag(c.country)} {c.country}</span>
                <span class="pa-count">{format_number(c.count)}</span>
              </li>
            <% end %>
          </ul>
        </section>

        <section class="pa-card">
          <h3>Steden</h3>
          <ul class="pa-data-list">
            <%= for c <- @city_breakdown do %>
              <li>
                <span>{flag(c.country)} {c.city}</span>
                <span class="pa-count">{format_number(c.count)}</span>
              </li>
            <% end %>
          </ul>
        </section>
      </div>

      <%!-- CTA onderaan --%>
      <div class="pa-demo-cta">
        <h2>Overtuigd?</h2>
        <p>
          Voeg jouw website toe en zie binnen 5 minuten echte bezoekersdata —
          zonder cookies, zonder cookiebanner.
        </p>
        <.link navigate={~p"/login"} class="pa-btn pa-btn--primary">
          Maak een gratis account →
        </.link>
      </div>
    </div>
    """
  end
end
