defmodule PhoenixAnalyticsWeb.Live.Dashboard.ExperimentDetailLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.{Analytics, Experiments}
  alias PhoenixAnalytics.Experiments.Stats

  @impl true
  def mount(%{"site_id" => site_id, "id" => experiment_id}, _session, socket) do
    case Ash.get(Analytics.Site, site_id) do
      {:ok, site} when not is_nil(site) ->
        if site.org_id in socket.assigns.current_org_ids do
          experiment =
            Ash.get!(Experiments.Experiment, experiment_id, load: [:variants, :assignments])

          variant_stats = Stats.variant_stats(experiment)
          significance = Stats.significance(variant_stats)
          winner = find_winner(variant_stats, significance)

          total_visitors = Enum.sum(Enum.map(variant_stats, & &1.visitors))

          {:ok,
           assign(socket,
             site: site,
             experiment: experiment,
             variant_stats: variant_stats,
             significance: significance,
             winner: winner,
             total_visitors: total_visitors,
             page_title: experiment.name
           )}
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
  def handle_event("start", _params, socket) do
    {:ok, exp} = Ash.update(socket.assigns.experiment, action: :start)
    {:noreply, assign(socket, experiment: exp)}
  end

  def handle_event("stop", _params, socket) do
    {:ok, exp} = Ash.update(socket.assigns.experiment, action: :stop)
    {:noreply, assign(socket, experiment: exp)}
  end

  defp find_winner(variant_stats, :significant) when variant_stats != [] do
    variant_stats
    |> Enum.max_by(& &1.rate)
    |> Map.get(:variant)
    |> Map.get(:name)
  end

  defp find_winner(_, _), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link>
        / <.link navigate={~p"/dashboard/sites/#{@site.id}"}>{@site.name}</.link>
        / <.link navigate={~p"/dashboard/sites/#{@site.id}/experiments"}>Experimenten</.link>
        / <strong>{@experiment.name}</strong>
      </nav>

      <div class="pa-experiment-header">
        <div>
          <h2 style="font-size:1.375rem; font-weight:700;">{@experiment.name}</h2>
          <p class="pa-goal-label">Doel: <strong>{@experiment.goal_event}</strong></p>
        </div>
        <div class="pa-experiment-actions">
          <span
            class={"pa-badge pa-badge--#{@experiment.status}"}
            aria-label={"Status: #{@experiment.status}"}
          >
            {@experiment.status}
          </span>
          <%= if @experiment.status == :draft do %>
            <button phx-click="start" phx-disable-with="Starten..." class="pa-btn pa-btn--primary">
              ▶ Start experiment
            </button>
          <% end %>
          <%= if @experiment.status == :running do %>
            <button phx-click="stop" phx-disable-with="Stoppen..." class="pa-btn pa-btn--danger">
              ■ Stop experiment
            </button>
          <% end %>
        </div>
      </div>

      <div class="pa-variants-grid">
        <%= for stat <- @variant_stats do %>
          <div class={"pa-variant-card#{if @winner == stat.variant.name, do: " pa-variant-card--winner"}"}>
            <h3>
              {stat.variant.name}
              <%= if @winner == stat.variant.name do %>
                <span class="pa-winner-badge">🏆 Winnaar</span>
              <% end %>
            </h3>
            <div class="pa-variant-stats">
              <div class="pa-stat">
                <span>Gewicht</span>
                <strong>{stat.variant.weight}%</strong>
              </div>
              <div class="pa-stat">
                <span>Bezoekers</span>
                <strong>{stat.visitors}</strong>
              </div>
              <div class="pa-stat">
                <span>Conversies</span>
                <strong>{stat.conversions}</strong>
              </div>
              <div class="pa-stat pa-stat--highlight">
                <span>Conversieratio</span>
                <strong>{stat.rate}%</strong>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @experiment.webhook_url do %>
        <div class="pa-card" style="margin-top:1rem;">
          <h3>Webhook</h3>
          <p class="pa-hint">
            Notificatie wordt verstuurd naar <code>{@experiment.webhook_url}</code>
            zodra het resultaat significant is.
            <%= if @experiment.webhook_notified_at do %>
              Laatste notificatie:
              <strong>{Calendar.strftime(@experiment.webhook_notified_at, "%d-%m-%Y %H:%M")}</strong>
            <% else %>
              Nog geen notificatie verstuurd.
            <% end %>
          </p>
        </div>
      <% end %>

      <div class="pa-significance-card">
        <h3>Statistische significantie</h3>
        <%= case @significance do %>
          <% :significant -> %>
            <div class="pa-alert pa-alert--success">
              <strong>Significant resultaat (p &lt; 0.05)</strong>
              — je kunt een winnaar kiezen.
              <%= if @winner do %>
                <div style="margin-top:0.5rem; font-size:1.05rem; color:var(--pa-teal); font-weight:600;">
                  Winnende variant: {@winner}
                </div>
              <% end %>
            </div>
          <% :not_significant -> %>
            <div class="pa-alert pa-alert--warning">
              Nog geen significant resultaat. Laat het experiment langer lopen.
              <p class="pa-progress-note">
                Nog {max(0, 200 - @total_visitors)} bezoekers nodig
              </p>
            </div>
          <% :insufficient_data -> %>
            <div class="pa-alert pa-alert--info">
              Onvoldoende data. Minimaal 200 bezoekers en 20 conversies nodig.
              Nu: <strong>{@total_visitors} bezoekers</strong>
              en <strong>{Enum.sum(Enum.map(@variant_stats, & &1.conversions))} conversies</strong>.
            </div>
        <% end %>
      </div>
    </div>
    """
  end
end
