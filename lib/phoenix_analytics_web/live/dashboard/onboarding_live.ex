defmodule PhoenixAnalyticsWeb.Live.Dashboard.OnboardingLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.{Accounts, Analytics}

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]

    org =
      case Accounts.user_orgs(user_id) do
        [m | _] -> Ash.get!(Accounts.Organization, m.org_id)
        [] -> nil
      end

    {:ok,
     assign(socket,
       step: 1,
       org: org,
       site: nil,
       site_form: to_form(%{"name" => "", "domain" => ""}),
       org_id: if(org, do: org.id, else: nil),
       base_url: PhoenixAnalyticsWeb.Endpoint.url(),
       snippet_verified: false,
       page_title: "Welkom bij Neo Analytics"
     )}
  end

  @impl true
  def handle_event("create_site", %{"name" => name, "domain" => domain}, socket) do
    case Analytics.Site
         |> Ash.Changeset.for_create(:create, %{
           name: name,
           domain: domain,
           org_id: socket.assigns.org_id
         })
         |> Ash.create() do
      {:ok, site} ->
        {:noreply, assign(socket, site: site, step: 2)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Kon website niet aanmaken. Controleer het domein.")}
    end
  end

  def handle_event("check_snippet", _, socket) do
    site = socket.assigns.site
    verified = PhoenixAnalytics.Analytics.Stats.recent_pageview?(site.id, minutes: 10)
    {:noreply, assign(socket, snippet_verified: verified)}
  end

  def handle_event("finish", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/dashboard/sites/#{socket.assigns.site.id}")}
  end

  def handle_event("skip", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container pa-onboarding">
      <div class="pa-onboarding-header">
        <div class="pa-onboarding-steps">
          <span class={"pa-onboarding-step#{if @step >= 1, do: " active"}"}>1. Website</span>
          <span class="pa-onboarding-step-divider">→</span>
          <span class={"pa-onboarding-step#{if @step >= 2, do: " active"}"}>2. Installeer</span>
          <span class="pa-onboarding-step-divider">→</span>
          <span class={"pa-onboarding-step#{if @step >= 3, do: " active"}"}>3. Verificeer</span>
        </div>
      </div>

      <%= if @step == 1 do %>
        <div class="pa-onboarding-card">
          <h2>Welkom bij Neo Analytics</h2>
          <p class="pa-text-muted">Voeg je eerste website toe om te beginnen met meten.</p>
          <.form for={@site_form} phx-submit="create_site" class="pa-form">
            <div class="pa-form-field">
              <label for="name">Naam</label>
              <input
                type="text"
                id="name"
                name="name"
                placeholder="Mijn Website"
                class="pa-input"
                required
              />
            </div>
            <div class="pa-form-field">
              <label for="domain">Domein</label>
              <input
                type="text"
                id="domain"
                name="domain"
                placeholder="mijnwebsite.nl"
                class="pa-input"
                required
              />
            </div>
            <div class="pa-form-actions">
              <button type="submit" class="pa-btn pa-btn--primary">Toevoegen →</button>
              <button type="button" phx-click="skip" class="pa-btn pa-btn--ghost">
                Later instellen
              </button>
            </div>
          </.form>
        </div>
      <% else %>
        <div class="pa-onboarding-card">
          <h2>Installeer de tracker</h2>
          <p class="pa-text-muted">
            Plak dit snippet in de <code>&lt;head&gt;</code> van je website.
          </p>
          <pre class="pa-code"><code>&lt;script async src="{@base_url}/js/pa.js" data-site="{@site.token}"&gt;&lt;/script&gt;</code></pre>

          <div class="pa-snippet-wp">
            <div class="pa-snippet-wp-title">WordPress installatie</div>
            <ol class="pa-snippet-wp-steps">
              <li>Installeer de <strong>WPCode</strong> plugin</li>
              <li>Ga naar <strong>Code Snippets → Header &amp; Footer</strong></li>
              <li>Plak het snippet in het <strong>Header</strong> vak en sla op</li>
            </ol>
          </div>

          <div class="pa-form-actions" style="margin-top:1.5rem">
            <button phx-click="check_snippet" class="pa-btn pa-btn--primary">
              {if @snippet_verified, do: "Verbinding bevestigd!", else: "Controleer verbinding"}
            </button>
            <%= if @snippet_verified do %>
              <button phx-click="finish" class="pa-btn pa-btn--primary">Naar dashboard →</button>
            <% end %>
            <button phx-click="skip" class="pa-btn pa-btn--ghost">Later controleren</button>
          </div>
          <%= if !@snippet_verified do %>
            <p class="pa-text-muted" style="font-size:0.8rem;margin-top:0.75rem">
              Nog geen data ontvangen. Bezoek je website na het installeren en klik op "Controleer verbinding".
            </p>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
