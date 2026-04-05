defmodule PhoenixAnalyticsWeb.Live.Dashboard.OrgSettingsLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Accounts
  alias PhoenixAnalytics.Accounts.Organization

  @impl true
  def mount(%{"org_id" => org_id}, session, socket) do
    user_id = session["user_id"]
    org = Ash.get!(Organization, org_id)
    members = Accounts.org_members(org_id)
    is_owner = Accounts.org_owner?(user_id, org_id)

    {:ok,
     assign(socket,
       org: org,
       members: members,
       is_owner: is_owner,
       current_user_id: user_id,
       page_title: "#{org.name} — instellingen",
       data_retention_months: org.data_retention_months || 13
     )}
  end

  @impl true
  def handle_event("remove_member", %{"id" => membership_id}, socket) do
    if socket.assigns.is_owner do
      Accounts.remove_member(membership_id)
      members = Accounts.org_members(socket.assigns.org.id)
      {:noreply, assign(socket, members: members)}
    else
      {:noreply, put_flash(socket, :error, "Alleen eigenaren kunnen leden verwijderen.")}
    end
  end

  @impl true
  def handle_event("save_retention", %{"months" => months_str}, socket) do
    if socket.assigns.is_owner do
      months = String.to_integer(months_str)

      case Ash.update(socket.assigns.org, %{data_retention_months: months},
             action: :update_settings
           ) do
        {:ok, org} ->
          {:noreply,
           socket
           |> assign(org: org, data_retention_months: org.data_retention_months)
           |> put_flash(:info, "Opgeslagen.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Opslaan mislukt.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Alleen eigenaren kunnen dit wijzigen.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link> / <strong>{@org.name}</strong>
      </nav>

      <div class="pa-page-header">
        <h2>Teaminstellingen — {@org.name}</h2>
        <%= if @is_owner do %>
          <.link navigate={~p"/dashboard/orgs/#{@org.id}/invite"} class="pa-btn pa-btn--primary">
            + Teamlid uitnodigen
          </.link>
        <% end %>
      </div>

      <%= if @is_owner do %>
        <section class="pa-card">
          <h3>Intro animatie</h3>
          <p style="font-size:0.85rem;color:var(--pa-text-muted);margin-bottom:1rem">
            De matrix intro-animatie wordt getoond aan bezoekers van de landingspagina en loginpagina.
            Bezoekers kunnen de intro altijd overslaan via de "Sla over" knop.
          </p>

          <div style="display:flex;align-items:center;gap:0.75rem;margin-bottom:1.5rem">
            <span style="font-size:0.85rem">Intro tonen aan bezoekers:</span>
            <a
              href="/dashboard/intro/reset"
              class="pa-btn pa-btn--ghost pa-btn--sm"
              title="Reset de skip-instelling voor jouw browser"
            >
              Intro opnieuw tonen (reset skip)
            </a>
          </div>

          <h4 style="font-size:0.85rem;margin-bottom:0.5rem">Seizoensgebonden intro's</h4>
          <p style="font-size:0.8rem;color:var(--pa-text-muted);margin-bottom:1rem">
            Toekomstige feature — configureer speciale intro's voor Pasen, Kerst, etc.
            Wordt gebouwd als seizoensintro-module.
          </p>
        </section>
      <% end %>

      <section class="pa-card">
        <h3>Teamleden</h3>
        <ul class="pa-data-list pa-member-list">
          <%= for m <- @members do %>
            <li>
              <div>
                <strong>{m.user.email}</strong>
                <span class={"pa-badge pa-badge--#{m.role}"}>{m.role}</span>
              </div>
              <%= if @is_owner and m.user_id != @current_user_id do %>
                <button
                  phx-click="remove_member"
                  phx-value-id={m.id}
                  class="pa-btn pa-btn--danger pa-btn--sm"
                  data-confirm="Weet je zeker dat je dit lid wil verwijderen?"
                >
                  Verwijderen
                </button>
              <% end %>
            </li>
          <% end %>
        </ul>
      </section>

      <%= if @is_owner do %>
        <section class="pa-card">
          <h3>Data bewaarperiode</h3>
          <p class="pa-text-muted" style="font-size:0.85rem;margin-bottom:1rem">
            Pageviews en events ouder dan de ingestelde periode worden automatisch verwijderd.
          </p>
          <form phx-submit="save_retention" style="display:flex;gap:0.75rem;align-items:center">
            <select name="months" class="pa-select pa-select--sm">
              <option value="3" selected={@org.data_retention_months == 3}>3 maanden</option>
              <option
                value="13"
                selected={@org.data_retention_months == 13 || is_nil(@org.data_retention_months)}
              >
                13 maanden (standaard)
              </option>
              <option value="36" selected={@org.data_retention_months == 36}>36 maanden</option>
            </select>
            <button type="submit" class="pa-btn pa-btn--primary pa-btn--sm">Opslaan</button>
          </form>
        </section>
      <% end %>
    </div>
    """
  end
end
