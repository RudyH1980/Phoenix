defmodule PhoenixAnalyticsWeb.Live.Dashboard.FunnelLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Analytics
  alias PhoenixAnalytics.Analytics.{Funnel, Stats}

  @impl true
  def mount(%{"site_id" => site_id}, _session, socket) do
    case Ash.get(Analytics.Site, site_id) do
      {:ok, site} when not is_nil(site) ->
        if site.org_id in socket.assigns.current_org_ids do
          funnels = Ash.read!(Funnel, filter: [site_id: site_id])

          {:ok,
           assign(socket,
             site: site,
             funnels: funnels,
             selected_funnel: nil,
             funnel_results: [],
             period: "30d",
             form: to_form(%{"name" => "", "steps" => ""}),
             page_title: "Funnels — #{site.name}"
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "Geen toegang.")
           |> push_navigate(to: ~p"/dashboard")}
        end

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Niet gevonden.")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_event("select_funnel", %{"id" => id}, socket) do
    funnel = Enum.find(socket.assigns.funnels, &(&1.id == id))
    results = Stats.funnel_steps(socket.assigns.site.id, funnel.steps, socket.assigns.period)
    {:noreply, assign(socket, selected_funnel: funnel, funnel_results: results)}
  end

  def handle_event("create_funnel", %{"name" => name, "steps" => steps_raw}, socket) do
    steps =
      steps_raw
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case Ash.create(Funnel, %{name: name, steps: steps, site_id: socket.assigns.site.id}) do
      {:ok, funnel} ->
        {:noreply,
         assign(socket,
           funnels: socket.assigns.funnels ++ [funnel],
           selected_funnel: funnel,
           funnel_results:
             Stats.funnel_steps(socket.assigns.site.id, funnel.steps, socket.assigns.period),
           form: to_form(%{"name" => "", "steps" => ""})
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Kon funnel niet aanmaken.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link>
        / <.link navigate={~p"/dashboard/sites/#{@site.id}"}>{@site.name}</.link>
        / <strong>Funnels</strong>
      </nav>
      <h2>Conversion Funnels — {@site.name}</h2>

      <div class="pa-funnel-layout">
        <div class="pa-funnel-sidebar">
          <h3>Funnels</h3>
          <%= for funnel <- @funnels do %>
            <button
              class={"pa-funnel-item#{if @selected_funnel && @selected_funnel.id == funnel.id, do: " active"}"}
              phx-click="select_funnel"
              phx-value-id={funnel.id}
            >
              {funnel.name}
            </button>
          <% end %>

          <div class="pa-funnel-create">
            <h4>Nieuwe funnel</h4>
            <.form for={@form} phx-submit="create_funnel">
              <input type="text" name="name" placeholder="Naam" class="pa-input" required />
              <textarea
                name="steps"
                placeholder="Stappen (één URL per regel):\n/\n/product\n/bedankt"
                class="pa-input pa-funnel-steps-input"
                rows="5"
                required
              ></textarea>
              <button type="submit" class="pa-btn pa-btn--primary pa-btn--full">Aanmaken</button>
            </.form>
          </div>
        </div>

        <div class="pa-funnel-main">
          <%= if @selected_funnel do %>
            <h3>{@selected_funnel.name}</h3>
            <%= if length(@funnel_results) > 0 do %>
              <% max_count = @funnel_results |> Enum.map(&elem(&1, 1)) |> Enum.max(fn -> 1 end) %>
              <div class="pa-funnel-chart">
                <%= for {{step, count}, idx} <- Enum.with_index(@funnel_results) do %>
                  <% pct = if max_count > 0, do: round(count / max_count * 100), else: 0 %>
                  <% drop =
                    if idx > 0 do
                      prev = @funnel_results |> Enum.at(idx - 1) |> elem(1)
                      if prev > 0, do: round((prev - count) / prev * 100), else: 0
                    else
                      nil
                    end %>
                  <div class="pa-funnel-step">
                    <div class="pa-funnel-step-label">{step}</div>
                    <div class="pa-funnel-bar-wrap">
                      <div class="pa-funnel-bar" style={"width: #{pct}%"}></div>
                    </div>
                    <div class="pa-funnel-step-stats">
                      <span class="pa-funnel-count">{count}</span>
                      <%= if drop do %>
                        <span class="pa-funnel-drop">-{drop}%</span>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% else %>
              <p class="pa-empty">Geen data voor deze funnel in de geselecteerde periode.</p>
            <% end %>
          <% else %>
            <p class="pa-empty">Selecteer een funnel of maak een nieuwe aan.</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
