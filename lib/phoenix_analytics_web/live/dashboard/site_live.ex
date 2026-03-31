defmodule PhoenixAnalyticsWeb.Live.Dashboard.SiteLive do
  use PhoenixAnalyticsWeb, :live_view

  import PhoenixAnalyticsWeb.ChartComponents

  alias PhoenixAnalytics.Analytics
  alias PhoenixAnalytics.Analytics.Stats

  @impl true
  def mount(%{"site_id" => site_id}, _session, socket) do
    site = Ash.get!(Analytics.Site, site_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(PhoenixAnalytics.PubSub, "site:#{site_id}")
    end

    socket =
      socket
      |> assign(site: site, period: "7d", page_title: site.name, realtime_count: 0)
      |> load_stats("7d")

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"period" => period}, _uri, socket)
      when period in ~w(today 7d 30d 90d) do
    {:noreply,
     socket
     |> assign(period: period)
     |> load_stats(period)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:pageview, _payload}, socket) do
    {:noreply, update(socket, :realtime_count, &(&1 + 1))}
  end

  defp load_stats(socket, period) do
    site_id = socket.assigns.site.id

    assign(socket,
      pageviews: Stats.pageview_count(site_id, period),
      visitors: Stats.unique_visitors(site_id, period),
      bounce_rate: Stats.bounce_rate(site_id, period),
      top_pages: Stats.top_pages(site_id, period),
      top_referrers: Stats.top_referrers(site_id, period),
      device_breakdown: Stats.device_breakdown(site_id, period),
      country_breakdown: Stats.country_breakdown(site_id, period),
      timeline: Stats.pageviews_timeline(site_id, period)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link> / <strong>{@site.name}</strong>
      </nav>

      <div class="pa-page-header">
        <h2>{@site.domain}</h2>
        <div class="pa-header-actions">
          <%= if @realtime_count > 0 do %>
            <span class="pa-realtime-badge">
              <span class="pa-realtime-dot"></span>
              {@realtime_count} nieuwe views
            </span>
          <% end %>
          <.link navigate={~p"/dashboard/sites/#{@site.id}/heatmap"} class="pa-btn pa-btn--ghost">
            Heatmap
          </.link>
          <.link navigate={~p"/dashboard/sites/#{@site.id}/experiments"} class="pa-btn pa-btn--ghost">
            A/B Experimenten
          </.link>
          <.link
            href={~p"/dashboard/sites/#{@site.id}/export?period=#{@period}"}
            class="pa-btn pa-btn--ghost"
          >
            CSV exporteren
          </.link>
        </div>
      </div>

      <div class="pa-period-tabs">
        <%= for period <- ~w(today 7d 30d 90d) do %>
          <.link
            patch={~p"/dashboard/sites/#{@site.id}?period=#{period}"}
            class={"pa-tab#{if @period == period, do: " active"}"}
          >
            {period}
          </.link>
        <% end %>
      </div>

      <div class="pa-stats-grid">
        <div class="pa-stat-card">
          <span class="pa-stat-label">Paginaweergaven</span>
          <span class="pa-stat-value">{format_number(@pageviews)}</span>
        </div>
        <div class="pa-stat-card">
          <span class="pa-stat-label">Unieke bezoekers</span>
          <span class="pa-stat-value">{format_number(@visitors)}</span>
        </div>
        <div class="pa-stat-card">
          <span class="pa-stat-label">Bouncepercentage</span>
          <span class="pa-stat-value">{@bounce_rate}%</span>
        </div>
      </div>

      <div class="pa-card">
        <h3>Pageviews over tijd</h3>
        <.bar_chart data={@timeline} height={120} />
      </div>

      <div class="pa-two-col">
        <section class="pa-card">
          <h3>Top pagina's</h3>
          <%= if Enum.empty?(@top_pages) do %>
            <p class="pa-empty">Nog geen data voor deze periode.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for page <- @top_pages do %>
                <li>
                  <span class="pa-url" title={page.url}>{truncate_url(page.url)}</span>
                  <span class="pa-count">{format_number(page.count)}</span>
                </li>
              <% end %>
            </ul>
          <% end %>
        </section>

        <section class="pa-card">
          <h3>Verwijzers</h3>
          <%= if Enum.empty?(@top_referrers) do %>
            <p class="pa-empty">Nog geen verwijzers voor deze periode.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for ref <- @top_referrers do %>
                <li>
                  <span class="pa-url">{truncate_url(ref.referrer)}</span>
                  <span class="pa-count">{format_number(ref.count)}</span>
                </li>
              <% end %>
            </ul>
          <% end %>
        </section>
      </div>

      <div class="pa-two-col">
        <section class="pa-card">
          <h3>Apparaten</h3>
          <%= if Enum.empty?(@device_breakdown) do %>
            <p class="pa-empty">Nog geen data.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for d <- @device_breakdown do %>
                <li>
                  <span>{d.device || "onbekend"}</span>
                  <span class="pa-count">{format_number(d.count)}</span>
                </li>
              <% end %>
            </ul>
          <% end %>
        </section>

        <section class="pa-card">
          <h3>Landen</h3>
          <%= if Enum.empty?(@country_breakdown) do %>
            <p class="pa-empty">Nog geen data.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for c <- @country_breakdown do %>
                <li>
                  <span>{flag(c.country)} {c.country || "Onbekend"}</span>
                  <span class="pa-count">{format_number(c.count)}</span>
                </li>
              <% end %>
            </ul>
          <% end %>
        </section>
      </div>

      <div class="pa-snippet-box">
        <h3>Tracker snippet</h3>
        <pre class="pa-code"><code>&lt;script async src="https://yourdomain.com/js/pa.js" data-site="{@site.token}"&gt;&lt;/script&gt;</code></pre>
      </div>
    </div>
    """
  end

  defp format_number(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  defp format_number(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}k"
  defp format_number(n), do: to_string(n)

  defp truncate_url(url) when byte_size(url) > 50, do: String.slice(url, 0, 47) <> "..."
  defp truncate_url(url), do: url

  # Landvlag emoji via country code (NL -> 🇳🇱)
  defp flag(nil), do: "🌐"

  defp flag(code) when byte_size(code) == 2 do
    code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 + 127_397))
    |> List.to_string()
  end

  defp flag(_), do: "🌐"
end
