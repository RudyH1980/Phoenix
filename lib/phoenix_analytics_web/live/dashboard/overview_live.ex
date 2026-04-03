defmodule PhoenixAnalyticsWeb.Live.Dashboard.OverviewLive do
  use PhoenixAnalyticsWeb, :live_view

  import Ecto.Query
  import PhoenixAnalyticsWeb.ChartComponents

  alias PhoenixAnalytics.{Accounts, Repo}
  alias PhoenixAnalytics.Analytics.Stats

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    org_ids = Accounts.user_org_ids(user_id)
    memberships = Accounts.user_orgs(user_id)

    socket =
      socket
      |> assign(org_ids: org_ids, memberships: memberships, page_title: "Dashboard", period: "7d")
      |> load_overview("7d")

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"period" => period}, _uri, socket)
      when period in ~w(today 7d 30d 90d) do
    {:noreply,
     socket
     |> assign(period: period)
     |> load_overview(period)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  defp load_overview(socket, period) do
    org_ids = socket.assigns.org_ids
    sites = load_sites(org_ids)
    counts = Stats.sites_pageview_counts(org_ids, period)
    timeline = Stats.combined_timeline(org_ids, period)
    yesterday_counts = Stats.yesterday_pageview_counts(org_ids)
    sparklines = Stats.sites_sparklines(org_ids)

    total_pageviews = Enum.reduce(counts, 0, fn {_, v}, acc -> acc + v.pageviews end)
    total_visitors = Enum.reduce(counts, 0, fn {_, v}, acc -> acc + v.visitors end)

    sites_with_counts =
      Enum.map(sites, fn site ->
        stats = Map.get(counts, site.id, %{pageviews: 0, visitors: 0})
        yesterday_pv = Map.get(yesterday_counts, site.id, 0)
        sparkline = Map.get(sparklines, site.id, [])
        trend = calc_trend(stats.pageviews, yesterday_pv)

        site
        |> Map.merge(stats)
        |> Map.put(:trend, trend)
        |> Map.put(:sparkline, sparkline)
      end)
      |> Enum.sort_by(& &1.pageviews, :desc)

    # Trend vs gisteren voor totalen
    total_yesterday = Enum.reduce(yesterday_counts, 0, fn {_, v}, acc -> acc + v end)
    total_trend = calc_trend(total_pageviews, total_yesterday)

    assign(socket,
      sites: sites_with_counts,
      timeline: timeline,
      total_pageviews: total_pageviews,
      total_visitors: total_visitors,
      total_trend: total_trend
    )
  end

  defp calc_trend(current, yesterday) do
    cond do
      yesterday == 0 and current == 0 -> 0
      yesterday == 0 -> 100
      true -> round((current - yesterday) / yesterday * 100)
    end
  end

  defp load_sites([]), do: []

  defp load_sites(org_ids) do
    binary_ids = Enum.map(org_ids, &Ecto.UUID.dump!/1)

    Repo.all(
      from s in "sites",
        where: s.org_id in ^binary_ids and s.active == true,
        order_by: [asc: s.name],
        select: %{
          id: type(s.id, Ecto.UUID),
          name: s.name,
          domain: s.domain,
          org_id: type(s.org_id, Ecto.UUID),
          tags: s.tags
        }
    )
  end

  defp tag_color("Prod"), do: "green"
  defp tag_color("Test"), do: "yellow"
  defp tag_color("Staging"), do: "blue"
  defp tag_color(_), do: "default"

  defp format_number(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  defp format_number(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}k"
  defp format_number(n), do: to_string(n)

  # Genereer een avatar kleur op basis van een hash van de sitenaam
  defp avatar_color(name) do
    colors = [
      "#0ea5e9",
      "#8b5cf6",
      "#f59e0b",
      "#10b981",
      "#ef4444",
      "#ec4899",
      "#14b8a6",
      "#f97316"
    ]

    idx = :erlang.phash2(name, length(colors))
    Enum.at(colors, idx)
  end

  defp avatar_initials(name) do
    name
    |> String.split(~r/[\s\-_\.]+/)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end

  defp trend_class(t) when t > 0, do: "pa-stat-trend pa-stat-trend--up"
  defp trend_class(t) when t < 0, do: "pa-stat-trend pa-stat-trend--down"
  defp trend_class(_), do: "pa-stat-trend pa-stat-trend--neutral"

  defp trend_label(t) when t > 0, do: "+#{t}% vs. gisteren"
  defp trend_label(t) when t < 0, do: "#{t}% vs. gisteren"
  defp trend_label(_), do: "0% vs. gisteren"

  # Bouw een inline SVG sparkline polyline van ~80x24px op basis van dagelijkse counts
  defp sparkline_points(data) when data == [], do: nil

  defp sparkline_points(data) do
    w = 80
    h = 24
    pad = 2
    n = length(data)
    max_v = data |> Enum.max_by(& &1.count) |> Map.get(:count) |> max(1)

    data
    |> Enum.with_index()
    |> Enum.map_join(" ", fn {pt, i} ->
      x = if n == 1, do: w / 2, else: pad + i / (n - 1) * (w - 2 * pad)
      y = pad + (1 - pt.count / max_v) * (h - 2 * pad)
      "#{Float.round(x, 1)},#{Float.round(y, 1)}"
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <header class="pa-header">
        <div class="pa-header-brand">
          <h1>Phoenix Analytics</h1>
          <p>Cookieloze analytics en A/B testing</p>
        </div>
        <nav class="pa-header-nav">
          <%= for m <- @memberships do %>
            <.link navigate={~p"/dashboard/orgs/#{m.org_id}"} class="pa-btn pa-btn--ghost">
              {m.org.name}
            </.link>
          <% end %>
          <.link href={~p"/auth/logout"} method="delete" class="pa-btn pa-btn--ghost">
            Uitloggen
          </.link>
        </nav>
      </header>

      <%!-- Periode tabs --%>
      <div class="pa-period-tabs">
        <%= for period <- ~w(today 7d 30d 90d) do %>
          <.link
            patch={~p"/dashboard?period=#{period}"}
            class={"pa-tab#{if @period == period, do: " active"}"}
          >
            {period}
          </.link>
        <% end %>
      </div>

      <%!-- Totaal statistieken --%>
      <div class="pa-stats-grid" style="margin-bottom:1.5rem;">
        <div class="pa-stat-card pa-stat-card--icon">
          <span class="pa-stat-icon">👁️</span>
          <span class="pa-stat-label">Totaal paginaweergaven</span>
          <span class="pa-stat-value">{format_number(@total_pageviews)}</span>
          <span class={trend_class(@total_trend)}>{trend_label(@total_trend)}</span>
        </div>
        <div class="pa-stat-card pa-stat-card--icon">
          <span class="pa-stat-icon">👤</span>
          <span class="pa-stat-label">Totaal unieke bezoekers</span>
          <span class="pa-stat-value">{format_number(@total_visitors)}</span>
        </div>
        <div class="pa-stat-card pa-stat-card--icon">
          <span class="pa-stat-icon">🌐</span>
          <span class="pa-stat-label">Websites</span>
          <span class="pa-stat-value">{length(@sites)}</span>
        </div>
      </div>

      <%!-- Gecombineerde tijdlijn --%>
      <%= if not Enum.empty?(@timeline) do %>
        <div class="pa-card" style="margin-bottom:1.5rem;">
          <h3>Alle bezoeken over tijd</h3>
          <.line_chart data={@timeline} height={140} />
        </div>
      <% end %>

      <%!-- Website lijst met aantallen --%>
      <section>
        <div class="pa-sites-section-header">
          <h2>Websites</h2>
          <.link navigate={~p"/dashboard/sites/new"} class="pa-btn pa-btn--primary">
            + Website toevoegen
          </.link>
        </div>

        <%= if Enum.empty?(@sites) do %>
          <div style="background: var(--pa-surface); border: 1px dashed var(--pa-border); border-radius: var(--pa-radius-lg); padding: 3rem 2rem; text-align: center;">
            <p style="color: var(--pa-text-muted); margin: 0 0 1.25rem; font-size: 0.95rem;">
              Nog geen websites toegevoegd.
            </p>
            <.link navigate={~p"/dashboard/sites/new"} class="pa-btn pa-btn--primary">
              + Eerste website toevoegen
            </.link>
          </div>
        <% else %>
          <ul class="pa-site-list pa-site-list--stats">
            <%= for site <- @sites do %>
              <li>
                <.link navigate={~p"/dashboard/sites/#{site.id}"}>
                  <%!-- Avatar --%>
                  <div
                    class="pa-site-avatar"
                    style={"background: #{avatar_color(site.name)}"}
                    aria-hidden="true"
                  >
                    {avatar_initials(site.name)}
                  </div>
                  <div class="pa-site-info">
                    <strong>{site.name}</strong>
                    <span class="pa-site-domain">{site.domain}</span>
                    <%= if site.tags && site.tags != [] do %>
                      <span style="display:flex; gap:0.25rem; flex-wrap:wrap; margin-top:0.2rem;">
                        <%= for tag <- site.tags do %>
                          <span class={"pa-tag pa-tag--#{tag_color(tag)} pa-tag--sm"}>{tag}</span>
                        <% end %>
                      </span>
                    <% end %>
                  </div>
                  <div class="pa-site-counts">
                    <span class="pa-site-stat">
                      <span class="pa-site-stat-value">{format_number(site.pageviews)}</span>
                      <span class="pa-site-stat-label">views</span>
                    </span>
                    <span class="pa-site-stat">
                      <span class="pa-site-stat-value">{format_number(site.visitors)}</span>
                      <span class="pa-site-stat-label">bezoekers</span>
                    </span>
                    <%!-- Trend badge --%>
                    <%= if site.trend != 0 do %>
                      <span class={trend_class(site.trend)} style="font-size:0.7rem;">
                        {trend_label(site.trend)}
                      </span>
                    <% end %>
                    <%!-- Sparkline --%>
                    <%= if sparkline_points(site.sparkline) do %>
                      <svg
                        width="80"
                        height="24"
                        viewBox="0 0 80 24"
                        class="pa-sparkline"
                        aria-hidden="true"
                      >
                        <polyline
                          points={sparkline_points(site.sparkline)}
                          class="pa-sparkline-line"
                          style="filter: drop-shadow(0 0 3px #00d4b8)"
                        />
                      </svg>
                    <% end %>
                    <span class="pa-site-arrow">›</span>
                  </div>
                </.link>
              </li>
            <% end %>
          </ul>
        <% end %>
      </section>
    </div>
    """
  end
end
