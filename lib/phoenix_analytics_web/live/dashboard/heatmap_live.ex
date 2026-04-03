defmodule PhoenixAnalyticsWeb.Live.Dashboard.HeatmapLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Analytics
  alias PhoenixAnalytics.Analytics.Stats

  # 20x20 raster: elke cel = 5% van de pagina
  @grid_size 20
  @cell_size 100 / @grid_size

  @impl true
  def mount(%{"site_id" => site_id}, _session, socket) do
    case Ash.get(Analytics.Site, site_id) do
      {:ok, site} when not is_nil(site) ->
        if site.org_id in socket.assigns.current_org_ids do
          top_pages = Stats.top_pages(site_id, "7d", 20)

          socket =
            assign(socket,
              site: site,
              period: "7d",
              top_pages: top_pages,
              selected_url: nil,
              grid_cells: [],
              total_clicks: 0,
              max_density: 1,
              page_title: "Heatmap - #{site.name}"
            )

          {:ok, socket}
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
  def handle_params(params, _uri, socket) do
    period = Map.get(params, "period", socket.assigns.period)
    period = if period in ~w(today 7d 30d 90d), do: period, else: "7d"
    url = Map.get(params, "url")

    socket =
      assign(socket,
        period: period,
        top_pages: Stats.top_pages(socket.assigns.site.id, period, 20)
      )

    socket =
      if url do
        load_heatmap(socket, url, period)
      else
        assign(socket, selected_url: nil, grid_cells: [], total_clicks: 0, max_density: 1)
      end

    {:noreply, socket}
  end

  defp load_heatmap(socket, url, period) do
    site_id = socket.assigns.site.id
    clicks = Stats.heatmap_clicks(site_id, period, url)
    total = length(clicks)
    {cells, max} = build_grid_cells(clicks)

    assign(socket,
      selected_url: url,
      grid_cells: cells,
      total_clicks: total,
      max_density: max
    )
  end

  defp build_grid_cells([]), do: {[], 1}

  defp build_grid_cells(clicks) do
    counts =
      Enum.reduce(clicks, %{}, fn meta, acc ->
        x_cell = clamp(trunc((meta["x"] || 0) / @cell_size), 0, @grid_size - 1)
        y_cell = clamp(trunc((meta["y"] || 0) / @cell_size), 0, @grid_size - 1)
        Map.update(acc, {x_cell, y_cell}, 1, &(&1 + 1))
      end)

    max = counts |> Map.values() |> Enum.max()

    cells =
      Enum.map(counts, fn {{xc, yc}, density} ->
        %{
          x: Float.round(xc * @cell_size, 2),
          y: Float.round(yc * @cell_size, 2),
          w: @cell_size,
          h: @cell_size,
          color: heatmap_color(density, max),
          opacity: Float.round(min(density / max * 0.85 + 0.15, 1.0), 3)
        }
      end)

    {cells, max}
  end

  defp clamp(v, min_v, max_v), do: max(min_v, min(v, max_v))

  # Interpoleer blauw (koud) -> geel -> rood (warm)
  defp heatmap_color(density, max) when max > 0 do
    ratio = density / max

    {r, g, b} =
      if ratio < 0.5 do
        t = ratio * 2
        {trunc(37 + t * (255 - 37)), trunc(99 + t * (165 - 99)), trunc(235 + t * (0 - 235))}
      else
        t = (ratio - 0.5) * 2
        {trunc(255), trunc(165 - t * 165), 0}
      end

    "rgb(#{r},#{g},#{b})"
  end

  defp heatmap_color(_, _), do: "rgb(37,99,235)"

  defp truncate_url(url) when byte_size(url) > 36, do: String.slice(url, 0, 33) <> "..."
  defp truncate_url(url), do: url

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link>
        / <.link navigate={~p"/dashboard/sites/#{@site.id}"}>{@site.name}</.link>
        / <strong>Heatmap</strong>
      </nav>

      <div class="pa-page-header">
        <h2>Klik-heatmap</h2>
        <div class="pa-period-tabs">
          <%= for period <- ~w(today 7d 30d 90d) do %>
            <.link
              patch={
                if @selected_url,
                  do: ~p"/dashboard/sites/#{@site.id}/heatmap?url=#{@selected_url}&period=#{period}",
                  else: ~p"/dashboard/sites/#{@site.id}/heatmap?period=#{period}"
              }
              class={"pa-tab#{if @period == period, do: " active"}"}
            >
              {period}
            </.link>
          <% end %>
        </div>
      </div>

      <div class="pa-two-col">
        <section class="pa-card" style="min-width:200px;max-width:260px;">
          <h3>Pagina's</h3>
          <ul class="pa-data-list">
            <%= for page <- @top_pages do %>
              <li>
                <.link
                  patch={~p"/dashboard/sites/#{@site.id}/heatmap?url=#{page.url}&period=#{@period}"}
                  class={"pa-url#{if @selected_url == page.url, do: " active", else: ""}"}
                  title={page.url}
                >
                  {truncate_url(page.url)}
                </.link>
                <span class="pa-count">{page.count}</span>
              </li>
            <% end %>
          </ul>
        </section>

        <section class="pa-card" style="flex:1;">
          <%= if @selected_url do %>
            <h3>
              {@total_clicks} klikken — <code>{@selected_url}</code>
            </h3>
            <%= if @total_clicks == 0 do %>
              <p class="pa-empty">
                Nog geen heatmap-data voor deze pagina en periode. Zorg dat de tracker draait en klik-tracking is ingeschakeld.
              </p>
            <% else %>
              <div class="pa-heatmap-wrap">
                <svg
                  viewBox="0 0 100 100"
                  preserveAspectRatio="none"
                  class="pa-heatmap-svg"
                  role="img"
                  aria-label="Klik-heatmap"
                >
                  <%= for cell <- @grid_cells do %>
                    <rect
                      x={cell.x}
                      y={cell.y}
                      width={cell.w}
                      height={cell.h}
                      fill={cell.color}
                      opacity={cell.opacity}
                    />
                  <% end %>
                </svg>
              </div>
              <p class="pa-heatmap-legend">
                <span style="display:inline-block;width:80px;height:8px;background:linear-gradient(to right,rgb(37,99,235),rgb(255,165,0),rgb(255,0,0));vertical-align:middle;border-radius:4px;">
                </span>
                &nbsp;koud &rarr; warm &nbsp;|&nbsp; max {@max_density} klikken per cel
              </p>
            <% end %>
          <% else %>
            <p class="pa-empty">Selecteer een pagina om de klik-heatmap te bekijken.</p>
          <% end %>
        </section>
      </div>
    </div>
    """
  end
end
