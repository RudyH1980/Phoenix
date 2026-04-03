defmodule PhoenixAnalyticsWeb.ChartComponents do
  @moduledoc false
  use Phoenix.Component

  @doc """
  SVG bar chart voor pageview tijdlijn.
  Verwacht een lijst van %{date: ~D[], count: integer} maps.
  """
  attr :data, :list, required: true
  attr :height, :integer, default: 120
  attr :class, :string, default: ""

  def bar_chart(assigns) do
    assigns = prepare_chart(assigns)

    ~H"""
    <div class={["pa-chart", @class]}>
      <%= if Enum.empty?(@data) do %>
        <p class="pa-chart-empty">Nog geen data</p>
      <% else %>
        <svg
          viewBox={"0 0 #{@width} #{@height}"}
          preserveAspectRatio="none"
          class="pa-chart-svg"
          aria-label="Pageview tijdlijn"
        >
          <%= for {bar, _i} <- Enum.with_index(@bars) do %>
            <rect x={bar.x} y={bar.y} width={bar.w} height={bar.h} rx="2" class="pa-chart-bar">
              <title>{bar.label}: {bar.count}</title>
            </rect>
          <% end %>
        </svg>
        <div class="pa-chart-labels">
          <span>{@first_label}</span>
          <span>{@last_label}</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp prepare_chart(assigns) do
    data = assigns.data
    height = assigns.height
    width = 600
    bar_count = length(data)

    if bar_count == 0 do
      assign(assigns, bars: [], width: width, first_label: "", last_label: "")
    else
      max_count = Enum.max_by(data, & &1.count).count |> max(1)
      gap = 2
      bar_w = max(1, div(width - gap * bar_count, bar_count))
      padding_top = 8

      bars =
        data
        |> Enum.with_index()
        |> Enum.map(fn {point, i} ->
          bar_h = max(2, round(point.count / max_count * (height - padding_top)))
          x = i * (bar_w + gap)
          y = height - bar_h

          %{
            x: x,
            y: y,
            w: bar_w,
            h: bar_h,
            count: point.count,
            label: format_date(point.date)
          }
        end)

      first_label = format_date(List.first(data).date)
      last_label = format_date(List.last(data).date)

      assign(assigns, bars: bars, width: width, first_label: first_label, last_label: last_label)
    end
  end

  @doc """
  SVG line chart met area-fill voor gecombineerde tijdlijn.
  Verwacht een lijst van %{date: date, count: integer} maps.
  """
  attr :data, :list, required: true
  attr :height, :integer, default: 140
  attr :class, :string, default: ""
  attr :color, :string, default: "var(--pa-teal)"
  attr :id, :string, default: "line-chart"

  def line_chart(assigns) do
    assigns = prepare_line_chart(assigns)

    ~H"""
    <div class={["pa-chart", @class]} phx-hook="LineChart" id={@id}>
      <%= if Enum.empty?(@data) do %>
        <p class="pa-chart-empty">Nog geen data</p>
      <% else %>
        <p class="pa-chart-title">Alle bezoeken over tijd</p>
        <svg
          viewBox={"0 0 #{@width} #{@height}"}
          preserveAspectRatio="none"
          class="pa-chart-svg"
          aria-label="Bezoeken tijdlijn"
          data-points={
            Jason.encode!(
              Enum.map(@dot_points, &%{x: &1.x, y: &1.y, count: &1.count, label: &1.label})
            )
          }
        >
          <defs>
            <linearGradient id="line-fill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color={@color} stop-opacity="0.25" />
              <stop offset="100%" stop-color={@color} stop-opacity="0.02" />
            </linearGradient>
          </defs>
          <path d={@fill_path} fill="url(#line-fill)" />
          <path
            d={@smooth_path}
            fill="none"
            stroke={@color}
            stroke-width="2.5"
            stroke-linejoin="round"
            stroke-linecap="round"
            style="filter: drop-shadow(0 0 8px #00d4b8)"
          />
          <%= for pt <- @dot_points do %>
            <circle cx={pt.x} cy={pt.y} r="3" fill={@color}>
              <title>{pt.label}: {pt.count}</title>
            </circle>
          <% end %>
        </svg>
        <div class="pa-chart-labels">
          <span>{@first_label}</span>
          <span>{@last_label}</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp prepare_line_chart(%{data: []} = assigns) do
    assign(assigns,
      smooth_path: "",
      fill_path: "",
      dot_points: [],
      width: 600,
      first_label: "",
      last_label: ""
    )
  end

  defp prepare_line_chart(assigns) do
    data = assigns.data
    height = assigns.height
    width = 600
    points = build_line_points(data, height, width)
    smooth_path = build_smooth_path(points)
    first = List.first(points)
    last = List.last(points)

    # Build fill path: start at bottom-left, trace the curve, close at bottom-right
    curve_without_m =
      case smooth_path do
        "M " <> rest ->
          case String.split(rest, " ", parts: 2) do
            [_start_point, remainder] -> remainder
            _ -> ""
          end

        _ ->
          ""
      end

    fill_path =
      "M #{first.x},#{height} L #{first.x},#{first.y} #{curve_without_m} L #{last.x},#{height} Z"

    assign(assigns,
      smooth_path: smooth_path,
      fill_path: fill_path,
      dot_points: points,
      width: width,
      first_label: format_date(List.first(data).date),
      last_label: format_date(List.last(data).date)
    )
  end

  defp build_smooth_path([]), do: ""

  defp build_smooth_path([p | _] = points) do
    segments =
      points
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [p1, p2] ->
        dx = (p2.x - p1.x) * 0.4

        "C #{Float.round(p1.x + dx, 1)},#{p1.y} #{Float.round(p2.x - dx, 1)},#{p2.y} #{p2.x},#{p2.y}"
      end)

    "M #{p.x},#{p.y} " <> Enum.join(segments, " ")
  end

  defp build_line_points(data, height, width) do
    n = length(data)
    max_count = data |> Enum.max_by(& &1.count) |> Map.get(:count) |> max(1)
    pad_top = 10
    pad_bottom = 4

    data
    |> Enum.with_index()
    |> Enum.map(fn {pt, i} ->
      x = if n == 1, do: div(width, 2), else: round(i / (n - 1) * width)
      y = round(pad_top + (1 - pt.count / max_count) * (height - pad_top - pad_bottom))
      %{x: x, y: y, count: pt.count, label: format_date(pt.date)}
    end)
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b")

  defp format_date(date) when is_binary(date),
    do: String.slice(date, 5, 5) |> String.replace("-", "/")

  defp format_date(_), do: ""
end
