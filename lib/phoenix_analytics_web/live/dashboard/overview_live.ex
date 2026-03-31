defmodule PhoenixAnalyticsWeb.Live.Dashboard.OverviewLive do
  use PhoenixAnalyticsWeb, :live_view

  import Ecto.Query
  alias PhoenixAnalytics.{Accounts, Repo}

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    org_ids = Accounts.user_org_ids(user_id)
    sites = load_sites(org_ids)
    memberships = Accounts.user_orgs(user_id)

    {:ok,
     assign(socket,
       sites: sites,
       memberships: memberships,
       page_title: "Dashboard"
     )}
  end

  defp load_sites([]), do: []

  defp load_sites(org_ids) do
    Repo.all(
      from s in "sites",
        where: s.org_id in ^org_ids and s.active == true,
        order_by: [asc: s.name],
        select: %{id: s.id, name: s.name, domain: s.domain, org_id: s.org_id}
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <header class="pa-header">
        <div>
          <h1>Phoenix Analytics</h1>
          <p>Cookieloze analytics en A/B testing</p>
        </div>
        <nav class="pa-header-nav">
          <%= for m <- @memberships do %>
            <.link navigate={~p"/dashboard/orgs/#{m.org_id}"} class="pa-btn pa-btn--ghost">
              {m.org.name}
            </.link>
          <% end %>
          <.link
            href={~p"/auth/logout"}
            method="delete"
            class="pa-btn pa-btn--ghost"
          >
            Uitloggen
          </.link>
        </nav>
      </header>

      <section>
        <div class="pa-sites-section-header">
          <h2>Websites</h2>
          <.link navigate={~p"/dashboard/sites/new"} class="pa-btn pa-btn--primary">
            + Website toevoegen
          </.link>
        </div>

        <%= if Enum.empty?(@sites) do %>
          <div style="background: var(--pa-surface); border: 1px dashed var(--pa-border); border-radius: var(--pa-radius-lg); padding: 3rem 2rem; text-align: center;">
            <p style="color: var(--pa-text-muted); margin: 0 0 1.25rem; font-size: 0.95rem;">
              Nog geen websites toegevoegd. Voeg je eerste website toe om te beginnen.
            </p>
            <.link navigate={~p"/dashboard/sites/new"} class="pa-btn pa-btn--primary">
              + Eerste website toevoegen
            </.link>
          </div>
        <% else %>
          <ul class="pa-site-list">
            <%= for site <- @sites do %>
              <li>
                <.link navigate={~p"/dashboard/sites/#{site.id}"}>
                  <div>
                    <strong>{site.name}</strong>
                    <span>{site.domain}</span>
                  </div>
                  <span class="pa-site-arrow">›</span>
                </.link>
              </li>
            <% end %>
          </ul>
        <% end %>
      </section>
    </div>
    """
  end
end
