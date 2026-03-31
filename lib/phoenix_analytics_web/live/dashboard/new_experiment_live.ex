defmodule PhoenixAnalyticsWeb.Live.Dashboard.NewExperimentLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.{Analytics, Experiments}

  @impl true
  def mount(%{"site_id" => site_id}, _session, socket) do
    site = Ash.get!(Analytics.Site, site_id)

    {:ok,
     assign(socket,
       site: site,
       form: to_form(%{"name" => "", "description" => "", "goal_event" => "", "webhook_url" => ""}),
       variants: [%{name: "Controle", weight: 50}, %{name: "Variant B", weight: 50}],
       page_title: "Nieuw experiment"
     )}
  end

  @impl true
  def handle_event(
        "submit",
        %{"name" => name, "description" => desc, "goal_event" => goal} = params,
        socket
      ) do
    webhook_url = params["webhook_url"] |> to_string() |> String.trim()
    webhook_url = if webhook_url == "", do: nil, else: webhook_url

    case Experiments.Experiment
         |> Ash.Changeset.for_create(:create, %{
           site_id: socket.assigns.site.id,
           name: name,
           description: desc,
           goal_event: goal,
           webhook_url: webhook_url
         })
         |> Ash.create() do
      {:ok, experiment} ->
        Enum.each(socket.assigns.variants, fn v ->
          Experiments.Variant
          |> Ash.Changeset.for_create(:create, %{
            experiment_id: experiment.id,
            name: v.name,
            weight: v.weight
          })
          |> Ash.create()
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Experiment aangemaakt.")
         |> push_navigate(
           to: ~p"/dashboard/sites/#{socket.assigns.site.id}/experiments/#{experiment.id}"
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link> /
        <.link navigate={~p"/dashboard/sites/#{@site.id}"}>{@site.name}</.link> /
        <.link navigate={~p"/dashboard/sites/#{@site.id}/experiments"}>Experimenten</.link> /
        <strong>Nieuw</strong>
      </nav>

      <h2>Nieuw A/B experiment</h2>

      <.form for={@form} phx-submit="submit" class="pa-form">
        <div class="pa-field">
          <label for="name">Naam experiment</label>
          <input type="text" id="name" name="name" value={@form[:name].value}
            placeholder="Homepage CTA test" required />
        </div>
        <div class="pa-field">
          <label for="goal_event">Conversiedoel (event naam)</label>
          <input type="text" id="goal_event" name="goal_event" value={@form[:goal_event].value}
            placeholder="cta_klik" required />
          <span class="pa-hint">Dit is de data-pa-event waarde die als conversie telt</span>
        </div>
        <div class="pa-field">
          <label for="description">Beschrijving (optioneel)</label>
          <textarea id="description" name="description"
            placeholder="Wat testen we en wat verwachten we?"
          >{@form[:description].value}</textarea>
        </div>

        <div class="pa-field">
          <label for="webhook_url">Webhook URL (optioneel)</label>
          <input type="url" id="webhook_url" name="webhook_url" value={@form[:webhook_url].value}
            placeholder="https://jouwapp.nl/webhooks/ab-resultaat" />
          <span class="pa-hint">Ontvangt een HTTP POST zodra het experiment statistisch significant is</span>
        </div>

        <div class="pa-variants-section">
          <h3>Varianten (50/50 standaard)</h3>
          <%= for variant <- @variants do %>
            <div class="pa-variant-row">
              <span class="pa-variant-name">{variant.name}</span>
              <span class="pa-variant-weight">{variant.weight}%</span>
            </div>
          <% end %>
        </div>

        <button type="submit" class="pa-btn pa-btn--primary">Experiment aanmaken</button>
      </.form>
    </div>
    """
  end
end
