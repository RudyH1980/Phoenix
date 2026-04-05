defmodule PhoenixAnalyticsWeb.Live.Dashboard.NewSiteLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Accounts
  alias PhoenixAnalytics.Analytics

  @impl true
  def mount(_params, session, socket) do
    if socket.assigns[:is_demo] do
      {:ok,
       socket
       |> put_flash(:error, "Niet beschikbaar in de demo.")
       |> push_navigate(to: ~p"/dashboard")}
    else
      user_id = session["user_id"]

      org_id =
        case Accounts.user_orgs(user_id) do
          [m | _] -> m.org_id
          [] -> nil
        end

      {:ok,
       assign(socket,
         form: to_form(%{"name" => "", "domain" => ""}),
         created_site: nil,
         org_id: org_id,
         base_url: PhoenixAnalyticsWeb.Endpoint.url(),
         page_title: "Nieuwe website"
       )}
    end
  end

  @impl true
  def handle_event("submit", %{"name" => name, "domain" => domain}, socket) do
    case Analytics.Site
         |> Ash.Changeset.for_create(:create, %{
           name: name,
           domain: domain,
           org_id: socket.assigns.org_id
         })
         |> Ash.create() do
      {:ok, site} ->
        {:noreply, assign(socket, created_site: site)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link> / <strong>Nieuwe website</strong>
      </nav>

      <%= if @created_site do %>
        <div class="pa-success-card">
          <h2>Website toegevoegd!</h2>
          <p><strong>{@created_site.name}</strong> · {@created_site.domain}</p>

          <div class="pa-snippet-box">
            <div class="pa-snippet-box-header">
              <h3>Snippet 1 — Basistracker</h3>
              <span class="pa-snippet-badge pa-snippet-badge--required">Verplicht</span>
            </div>
            <p class="pa-snippet-hint">
              Registreert automatisch: paginabezoeken, unieke bezoekers, bouncepercentage, apparaat, browser, klikken op knoppen en links.
            </p>
            <p class="pa-snippet-hint">
              Plak dit snippet in de <code>&lt;head&gt;</code> van elke pagina:
            </p>
            <pre class="pa-code"><code>&lt;script async src="{@base_url}/js/pa.js" data-site="{@created_site.token}"&gt;&lt;/script&gt;</code></pre>

            <div class="pa-snippet-wp">
              <div class="pa-snippet-wp-title">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" /><path d="M11 7h2v6h-2zm0 8h2v2h-2z" />
                </svg>
                WordPress installatie
              </div>
              <ol class="pa-snippet-wp-steps">
                <li>
                  Ga naar <strong>Plugins → Nieuwe plugin</strong> en zoek op <strong>WPCode</strong>
                </li>
                <li>Installeer en activeer de plugin</li>
                <li>Ga naar <strong>Code Snippets → Header &amp; Footer</strong></li>
                <li>Plak het snippet hierboven in het vak <strong>"Header"</strong></li>
                <li>Klik op <strong>Opslaan</strong> — klaar</li>
              </ol>
            </div>
          </div>

          <div class="pa-snippet-box">
            <div class="pa-snippet-box-header">
              <h3>Snippet 2 — Conversie tracking</h3>
              <span class="pa-snippet-badge pa-snippet-badge--optional">Optioneel</span>
            </div>
            <p class="pa-snippet-hint">
              Gebruik dit als je wilt bijhouden welke specifieke knoppen of links mensen klikken — bijvoorbeeld voor A/B testen of conversiedoelen. Voeg het attribuut
              <code>data-pa-event="naam"</code>
              toe aan elk element dat je wilt meten:
            </p>
            <pre class="pa-code"><code>&lt;button data-pa-event="offerte_aangevraagd"&gt;Vraag offerte aan&lt;/button&gt;
    &lt;a href="tel:..." data-pa-event="telefoon_geklikt"&gt;Bel ons&lt;/a&gt;
    &lt;button type="submit" data-pa-event="contact_verzonden"&gt;Verstuur&lt;/button&gt;</code></pre>
          </div>

          <.link navigate={~p"/dashboard/sites/#{@created_site.id}"} class="pa-btn pa-btn--primary">
            Naar dashboard →
          </.link>
        </div>
      <% else %>
        <div class="pa-new-site-header">
          <h2>Nieuwe website toevoegen</h2>
          <p>Na het aanmaken ontvang je een tracker snippet voor jouw site.</p>
        </div>

        <.form for={@form} phx-submit="submit" class="pa-form">
          <div class="pa-field">
            <label for="name">Naam</label>
            <input
              type="text"
              id="name"
              name="name"
              value={@form[:name].value}
              placeholder="Mijn Website"
              required
              autofocus
            />
          </div>
          <div class="pa-field">
            <label for="domain">Domein</label>
            <input
              type="text"
              id="domain"
              name="domain"
              value={@form[:domain].value}
              placeholder="mijnwebsite.nl"
              required
            />
            <span class="pa-hint">Zonder https:// of www</span>
          </div>
          <div style="display:flex; gap:0.75rem; align-items:center;">
            <button type="submit" class="pa-btn pa-btn--primary">Website toevoegen</button>
            <.link navigate={~p"/dashboard"} class="pa-btn pa-btn--ghost">Annuleren</.link>
          </div>
        </.form>
      <% end %>
    </div>
    """
  end
end
