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

  defp status_label(:draft), do: "Concept"
  defp status_label(:running), do: "Actief"
  defp status_label(:stopped), do: "Gestopt"
  defp status_label(:archived), do: "Gearchiveerd"
  defp status_label(other), do: to_string(other)

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
        <div class="pa-experiment-empty">
          <h3 style="font-size:1.15rem; font-weight:700; margin:0 0 0.75rem;">
            Test wat werkt voor jouw bezoekers
          </h3>
          <ul>
            <li>Vergelijk twee versies van een knop, tekst of pagina</li>
            <li>Deterministisch toegewezen — geen cookie nodig</li>
            <li>Statistisch significant resultaat via chi-square test</li>
          </ul>
          <.link
            navigate={~p"/dashboard/sites/#{@site.id}/experiments/new"}
            class="pa-btn pa-btn--primary"
          >
            Eerste experiment aanmaken →
          </.link>
        </div>
      <% else %>
        <ul class="pa-experiment-list">
          <%= for exp <- @experiments do %>
            <li>
              <.link navigate={~p"/dashboard/sites/#{@site.id}/experiments/#{exp.id}"}>
                <strong>{exp.name}</strong>
                <span class={"pa-badge pa-badge--#{exp.status}"} aria-label={"Status: #{exp.status}"}>
                  {status_label(exp.status)}
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
