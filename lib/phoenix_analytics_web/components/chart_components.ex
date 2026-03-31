defmodule PhoenixAnalyticsWeb.ChartComponents do
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
            <rect
              x={bar.x}
              y={bar.y}
              width={bar.w}
              height={bar.h}
              rx="2"
              class="pa-chart-bar"
            >
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
          bar_h = max(2, round((point.count / max_count) * (height - padding_top)))
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

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b")
  defp format_date(date) when is_binary(date), do: String.slice(date, 5, 5) |> String.replace("-", "/")
  defp format_date(_), do: ""
end
