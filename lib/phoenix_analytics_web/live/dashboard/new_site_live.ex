defmodule PhoenixAnalyticsWeb.Live.Dashboard.NewSiteLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Accounts
  alias PhoenixAnalytics.Analytics

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    # Gebruik eerste org van de gebruiker (bij nieuwe site)
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
       page_title: "Nieuwe website"
     )}
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
            <h3>Voeg dit toe aan jouw website</h3>
            <p class="pa-snippet-hint">
              Plak dit snippet in de <code>&lt;head&gt;</code> van elke pagina:
            </p>
            <pre class="pa-code"><code>&lt;script async src="https://yourdomain.com/js/pa.js" data-site="{@created_site.token}"&gt;&lt;/script&gt;</code></pre>
          </div>

          <div class="pa-snippet-box">
            <h3>Klik-events tracken</h3>
            <p class="pa-snippet-hint">
              Voeg <code>data-pa-event="naam"</code> toe aan elk element:
            </p>
            <pre class="pa-code"><code>&lt;button data-pa-event="cta_klik"&gt;Aanmelden&lt;/button&gt; &lt;a data-pa-event="download"&gt;Download brochure&lt;/a&gt;</code></pre>
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
