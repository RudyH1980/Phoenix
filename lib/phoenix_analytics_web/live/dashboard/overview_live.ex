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
      total_trend: total_trend,
      website_count: length(sites_with_counts)
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
          <h1>Neo Analytics</h1>
          <p>Cookieloze analytics en A/B testing</p>
        </div>
        <nav class="pa-header-nav">
          <%= for m <- @memberships do %>
            <.link navigate={~p"/dashboard/orgs/#{m.org_id}"} class="pa-btn pa-btn--ghost">
              {m.org.name}
            </.link>
          <% end %>
          <.link navigate={~p"/dashboard/account"} class="pa-btn pa-btn--ghost">
            Mijn account
          </.link>
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
        <div class="pa-stat-card">
          <div class="pa-stat-body">
            <span class="pa-stat-label">TOTAAL PAGINAWEERGAVEN</span>
            <span class="pa-stat-value">{format_number(@total_pageviews)}</span>
            <span class={trend_class(@total_trend)}>{trend_label(@total_trend)}</span>
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
            <span class="pa-stat-label">TOTAAL UNIEKE BEZOEKERS</span>
            <span class="pa-stat-value">{format_number(@total_visitors)}</span>
            <span class={trend_class(@total_trend)}>{trend_label(@total_trend)}</span>
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
            <span class="pa-stat-label">WEBSITES</span>
            <span class="pa-stat-value">{@website_count}</span>
            <span class={trend_class(@total_trend)}>{trend_label(@total_trend)}</span>
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
              <rect x="2" y="3" width="20" height="14" rx="2" ry="2" /><line
                x1="8"
                y1="21"
                x2="16"
                y2="21"
              /><line x1="12" y1="17" x2="12" y2="21" />
            </svg>
          </div>
        </div>
      </div>

      <%!-- Gecombineerde tijdlijn --%>
      <%= if not Enum.empty?(@timeline) do %>
        <div class="pa-card" style="margin-bottom:1.5rem;">
          <.line_chart data={@timeline} height={140} />
        </div>
      <% end %>

      <%!-- Website lijst met aantallen --%>
      <section>
        <div class="pa-sites-section-header">
          <h2 class="pa-section-title">WEBSITES</h2>
          <.link navigate={~p"/dashboard/sites/new"} class="pa-btn pa-btn--primary pa-btn--sm">
            + Add website
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
                <.link navigate={~p"/dashboard/sites/#{site.id}"} class="pa-site-row">
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
                  </div>
                  <div class="pa-site-col">
                    <span class="pa-site-col-value">{format_number(site.pageviews)}</span>
                    <span class="pa-site-col-label">VIEWS</span>
                  </div>
                  <div class="pa-site-col">
                    <span class="pa-site-col-value">
                      {format_number(site.visitors)}
                      <%= if site.trend != 0 do %>
                        <span
                          class={trend_class(site.trend)}
                          style="font-size:0.75rem; margin-left:0.25rem;"
                        >
                          {if site.trend > 0, do: "+#{site.trend}%", else: "#{site.trend}%"}
                        </span>
                      <% end %>
                    </span>
                    <span class="pa-site-col-label">BEZOEKERS</span>
                  </div>
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
