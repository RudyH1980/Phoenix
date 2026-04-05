defmodule PhoenixAnalyticsWeb.Live.Dashboard.SiteLive do
  use PhoenixAnalyticsWeb, :live_view

  import PhoenixAnalyticsWeb.ChartComponents

  alias PhoenixAnalytics.Analytics
  alias PhoenixAnalytics.Analytics.Stats

  @impl true
  def mount(%{"site_id" => site_id}, _session, socket) do
    case Ash.get(Analytics.Site, site_id) do
      {:ok, site} when not is_nil(site) ->
        if site.org_id in socket.assigns.current_org_ids do
          {:ok, mount_authorized(socket, site, site_id)}
        else
          {:ok,
           socket
           |> put_flash(:error, "Geen toegang tot deze website.")
           |> push_navigate(to: ~p"/dashboard")}
        end

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Website niet gevonden.")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_params(%{"period" => period}, _uri, socket)
      when period in ~w(today 7d 30d 90d) do
    site_id = socket.assigns.site.id

    {:noreply,
     socket
     |> assign(
       period: period,
       filters: %{},
       available_countries: Stats.available_countries(site_id, period),
       available_devices: Stats.available_devices(site_id, period)
     )
     |> load_stats(period)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:pageview, _payload}, socket) do
    {:noreply, update(socket, :realtime_count, &(&1 + 1))}
  end

  def handle_info(:refresh_realtime, socket) do
    Process.send_after(self(), :refresh_realtime, 30_000)
    {:noreply, load_realtime(socket)}
  end

  defp mount_authorized(socket, site, site_id) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PhoenixAnalytics.PubSub, "site:#{site_id}")
      Process.send_after(self(), :refresh_realtime, 30_000)
    end

    socket
    |> assign(
      site: site,
      period: "7d",
      page_title: site.name,
      realtime_count: 0,
      realtime_visitors: 0,
      realtime_pages: [],
      table_limits: %{},
      filters: %{},
      available_countries: Stats.available_countries(site_id, "7d"),
      available_devices: Stats.available_devices(site_id, "7d")
    )
    |> load_stats("7d")
    |> load_realtime()
  end

  @impl true
  def handle_event("set_limit", %{"table" => table, "limit" => limit}, socket) do
    parsed = if limit == "all", do: :all, else: String.to_integer(limit)
    limits = Map.put(socket.assigns.table_limits, table, parsed)
    {:noreply, assign(socket, table_limits: limits)}
  end

  @impl true
  def handle_event("set_device_filter", %{"value" => value}, socket) do
    filters =
      if value == "",
        do: Map.delete(socket.assigns.filters, :device),
        else: Map.put(socket.assigns.filters, :device, value)

    {:noreply, socket |> assign(filters: filters) |> reload_stats()}
  end

  @impl true
  def handle_event("set_country_filter", %{"value" => value}, socket) do
    filters =
      if value == "",
        do: Map.delete(socket.assigns.filters, :country),
        else: Map.put(socket.assigns.filters, :country, value)

    {:noreply, socket |> assign(filters: filters) |> reload_stats()}
  end

  @impl true
  def handle_event("clear_filters", _, socket) do
    {:noreply, socket |> assign(filters: %{}) |> reload_stats()}
  end

  defp reload_stats(socket) do
    load_stats(socket, socket.assigns.period)
  end

  defp load_stats(socket, period) do
    site_id = socket.assigns.site.id
    filters = Map.get(socket.assigns, :filters, %{})

    assign(socket,
      pageviews: Stats.pageview_count(site_id, period, filters),
      visitors: Stats.unique_visitors(site_id, period, filters),
      bounce_rate: Stats.bounce_rate(site_id, period, filters),
      avg_time: Stats.avg_time_on_page(site_id, period),
      visitor_types: Stats.new_vs_returning(site_id, period),
      top_pages: Stats.top_pages(site_id, period, 10, filters),
      top_referrers: Stats.top_referrers(site_id, period, 10, filters),
      top_events: Stats.top_events(site_id, period),
      section_views: Stats.section_views(site_id, period),
      device_breakdown: Stats.device_breakdown(site_id, period),
      os_breakdown: Stats.os_breakdown(site_id, period),
      country_breakdown: Stats.country_breakdown(site_id, period),
      city_breakdown: Stats.city_breakdown(site_id, period),
      timeline: Stats.pageviews_timeline(site_id, period)
    )
  end

  defp load_realtime(socket) do
    site_id = socket.assigns.site.id

    assign(socket,
      realtime_visitors: Stats.realtime_visitors(site_id),
      realtime_pages: Stats.realtime_pages(site_id)
    )
  end

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
          <.link navigate={~p"/dashboard/sites/#{@site.id}/edit"} class="pa-btn pa-btn--ghost">
            Bewerken
          </.link>
          <.link navigate={~p"/dashboard/sites/#{@site.id}/heatmap"} class="pa-btn pa-btn--ghost">
            Heatmap
          </.link>
          <.link navigate={~p"/dashboard/sites/#{@site.id}/funnels"} class="pa-btn pa-btn--ghost">
            Funnels
          </.link>
          <%= if !@is_demo do %>
            <.link
              navigate={~p"/dashboard/sites/#{@site.id}/experiments"}
              class="pa-btn pa-btn--ghost"
            >
              A/B Experimenten
            </.link>
          <% end %>
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

      <div class="pa-filter-bar">
        <select phx-change="set_device_filter" name="value" class="pa-select pa-select--sm">
          <option value="">Alle apparaten</option>
          <option value="mobile" selected={@filters[:device] == "mobile"}>Mobiel</option>
          <option value="tablet" selected={@filters[:device] == "tablet"}>Tablet</option>
          <option value="desktop" selected={@filters[:device] == "desktop"}>Desktop</option>
        </select>

        <select phx-change="set_country_filter" name="value" class="pa-select pa-select--sm">
          <option value="">Alle landen</option>
          <%= for c <- @available_countries do %>
            <option value={c} selected={@filters[:country] == c}>{c}</option>
          <% end %>
        </select>

        <%= if map_size(@filters) > 0 do %>
          <button phx-click="clear_filters" class="pa-btn pa-btn--ghost pa-btn--sm">
            &times; Filters wissen
          </button>
        <% end %>
      </div>

      <div class="pa-realtime-widget">
        <div class="pa-realtime-dot"></div>
        <span class="pa-realtime-count">{@realtime_visitors}</span>
        <span class="pa-realtime-label">nu actief</span>
        <%= if length(@realtime_pages) > 0 do %>
          <div class="pa-realtime-pages">
            <%= for {url, count} <- @realtime_pages do %>
              <span class="pa-realtime-page">{url} <em>{count}</em></span>
            <% end %>
          </div>
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
        <%= if Enum.empty?(@section_views) do %>
          <div class="pa-stat-card">
            <span class="pa-stat-label">Bouncepercentage</span>
            <span class="pa-stat-value">{@bounce_rate}%</span>
          </div>
        <% else %>
          <%= for s <- Enum.take(@section_views, 1) do %>
            <div class="pa-stat-card">
              <span class="pa-stat-label">Sectie "{s.section}"</span>
              <span class="pa-stat-value">{format_number(s.count)} views</span>
            </div>
          <% end %>
        <% end %>
        <div class="pa-stat-card">
          <span class="pa-stat-label">Gem. tijd op pagina</span>
          <span class="pa-stat-value">{format_duration(@avg_time)}</span>
        </div>
      </div>

      <div class="pa-card">
        <h3>Pageviews over tijd</h3>
        <.line_chart data={@timeline} height={120} />
      </div>

      <div class="pa-two-col">
        <section class="pa-card">
          <h3>Top pagina's</h3>
          <%= if Enum.empty?(@top_pages) do %>
            <p class="pa-empty">Nog geen data voor deze periode.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for page <- table_rows(@top_pages, @table_limits, "pages") do %>
                <li>
                  <span class="pa-url" title={page.url}>{truncate_url(page.url)}</span>
                  <span class="pa-count">{format_number(page.count)}</span>
                </li>
              <% end %>
            </ul>
            <.limit_bar table="pages" limits={@table_limits} total={length(@top_pages)} />
          <% end %>
        </section>

        <section class="pa-card">
          <h3>Verwijzers</h3>
          <%= if Enum.empty?(@top_referrers) do %>
            <p class="pa-empty">Nog geen verwijzers voor deze periode.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for ref <- table_rows(@top_referrers, @table_limits, "referrers") do %>
                <li>
                  <span class="pa-url">{truncate_url(ref.referrer)}</span>
                  <span class="pa-count">{format_number(ref.count)}</span>
                </li>
              <% end %>
            </ul>
            <.limit_bar table="referrers" limits={@table_limits} total={length(@top_referrers)} />
          <% end %>
        </section>
      </div>

      <section class="pa-card">
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

      <div class="pa-two-col">
        <section class="pa-card">
          <h3>Apparaten</h3>
          <%= if Enum.empty?(@device_breakdown) do %>
            <p class="pa-empty">Nog geen data.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for d <- table_rows(@device_breakdown, @table_limits, "devices") do %>
                <li>
                  <span>{d.device || "onbekend"}</span>
                  <span class="pa-count">{format_number(d.count)}</span>
                </li>
              <% end %>
            </ul>
            <.limit_bar table="devices" limits={@table_limits} total={length(@device_breakdown)} />
          <% end %>
        </section>

        <section class="pa-card">
          <h3>Besturingssysteem</h3>
          <%= if Enum.empty?(@os_breakdown) do %>
            <p class="pa-empty">Nog geen data.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for o <- table_rows(@os_breakdown, @table_limits, "os") do %>
                <li>
                  <span>{os_icon(o.os)} {o.os || "Onbekend"}</span>
                  <span class="pa-count">{format_number(o.count)}</span>
                </li>
              <% end %>
            </ul>
            <.limit_bar table="os" limits={@table_limits} total={length(@os_breakdown)} />
          <% end %>
        </section>

        <section class="pa-card">
          <h3>Landen</h3>
          <%= if Enum.empty?(@country_breakdown) do %>
            <p class="pa-empty">Nog geen data.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for c <- table_rows(@country_breakdown, @table_limits, "countries") do %>
                <li>
                  <span>{flag(c.country)} {c.country || "Onbekend"}</span>
                  <span class="pa-count">{format_number(c.count)}</span>
                </li>
              <% end %>
            </ul>
            <.limit_bar table="countries" limits={@table_limits} total={length(@country_breakdown)} />
          <% end %>
        </section>

        <section class="pa-card">
          <h3>Steden</h3>
          <%= if Enum.empty?(@city_breakdown) do %>
            <p class="pa-empty">Nog geen data.</p>
          <% else %>
            <ul class="pa-data-list">
              <%= for c <- table_rows(@city_breakdown, @table_limits, "cities") do %>
                <li>
                  <span>{flag(c.country)} {c.city}</span>
                  <span class="pa-count">{format_number(c.count)}</span>
                </li>
              <% end %>
            </ul>
            <.limit_bar table="cities" limits={@table_limits} total={length(@city_breakdown)} />
          <% end %>
        </section>
      </div>

      <%= if not Enum.empty?(@section_views) do %>
        <section class="pa-card">
          <h3>Secties bereikt</h3>
          <ul class="pa-data-list">
            <%= for s <- table_rows(@section_views, @table_limits, "sections") do %>
              <li>
                <span>{s.section}</span>
                <span class="pa-count">{format_number(s.count)}</span>
              </li>
            <% end %>
          </ul>
          <.limit_bar table="sections" limits={@table_limits} total={length(@section_views)} />
        </section>
      <% end %>

      <section class="pa-card">
        <h3>Klikken &amp; events</h3>
        <%= if Enum.empty?(@top_events) do %>
          <p class="pa-empty">
            Nog geen events. Zorg dat de tracker draait en bezoekers op knoppen klikken.
          </p>
        <% else %>
          <ul class="pa-data-list">
            <%= for ev <- table_rows(@top_events, @table_limits, "events") do %>
              <li>
                <span class="pa-url" title={ev.event_name}>{truncate_url(ev.event_name)}</span>
                <span class="pa-count">{format_number(ev.count)}</span>
              </li>
            <% end %>
          </ul>
          <.limit_bar table="events" limits={@table_limits} total={length(@top_events)} />
        <% end %>
      </section>

      <div class="pa-snippet-box">
        <h3>Tracker snippet</h3>
        <pre class="pa-code"><code>&lt;script async src="{PhoenixAnalyticsWeb.Endpoint.url()}/js/pa.js" data-site="{@site.token}"&gt;&lt;/script&gt;</code></pre>
      </div>
    </div>
    """
  end

  defp table_rows(data, limits, key, default \\ 10) do
    limit = Map.get(limits, key, default)
    if limit == :all, do: data, else: Enum.take(data, limit)
  end

  defp format_number(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  defp format_number(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}k"
  defp format_number(n), do: to_string(n)

  defp truncate_url(url) when byte_size(url) > 50, do: String.slice(url, 0, 47) <> "..."
  defp truncate_url(url), do: url

  defp os_icon("iOS"), do: "🍎"
  defp os_icon("macOS"), do: "🍎"
  defp os_icon("Android"), do: "🤖"
  defp os_icon("Windows"), do: "🪟"
  defp os_icon("Linux"), do: "🐧"
  defp os_icon(_), do: "💻"

  defp format_duration(0), do: "—"
  defp format_duration(s) when s < 60, do: "#{s}s"
  defp format_duration(s), do: "#{div(s, 60)}m #{rem(s, 60)}s"

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
