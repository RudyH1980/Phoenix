defmodule PhoenixAnalyticsWeb.Live.Dashboard.ExperimentsLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.{Analytics, Experiments}

  @impl true
  def mount(%{"site_id" => site_id}, _session, socket) do
    case Ash.get(Analytics.Site, site_id) do
      {:ok, site} when not is_nil(site) ->
        if site.org_id in socket.assigns.current_org_ids do
          experiments = Ash.read!(Experiments.Experiment, filter: [site_id: site_id])

          {:ok,
           assign(socket,
             site: site,
             experiments: experiments,
             page_title: "A/B Experimenten"
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
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link>
        / <.link navigate={~p"/dashboard/sites/#{@site.id}"}>{@site.name}</.link>
        / <strong>Experimenten</strong>
      </nav>

      <div class="pa-section-header">
        <h2 style="font-size:1.375rem; font-weight:700;">A/B Experimenten</h2>
        <.link
          navigate={~p"/dashboard/sites/#{@site.id}/experiments/new"}
          class="pa-btn pa-btn--primary"
        >
          + Nieuw experiment
        </.link>
      </div>

      <%= if Enum.empty?(@experiments) do %>
        <div style="background: var(--pa-surface); border: 1px dashed var(--pa-border); border-radius: var(--pa-radius-lg); padding: 3rem 2rem; text-align: center;">
          <p style="color: var(--pa-text-muted); margin: 0 0 1.25rem; font-size: 0.95rem;">
            Nog geen experimenten aangemaakt voor <strong style="color:var(--pa-text);">{@site.name}</strong>.
          </p>
          <.link
            navigate={~p"/dashboard/sites/#{@site.id}/experiments/new"}
            class="pa-btn pa-btn--primary"
          >
            + Eerste experiment aanmaken
          </.link>
        </div>
      <% else %>
        <ul class="pa-experiment-list">
          <%= for exp <- @experiments do %>
            <li>
              <.link navigate={~p"/dashboard/sites/#{@site.id}/experiments/#{exp.id}"}>
                <strong>{exp.name}</strong>
                <span class={"pa-badge pa-badge--#{exp.status}"} aria-label={"Status: #{exp.status}"}>
                  {exp.status}
                </span>
                <span class="pa-goal">Doel: {exp.goal_event}</span>
                <span style="margin-left:auto; color:var(--pa-text-faint);">›</span>
              </.link>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end
end
