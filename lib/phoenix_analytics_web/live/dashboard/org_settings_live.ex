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
       page_title: "#{org.name} — instellingen"
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
    </div>
    """
  end
end
