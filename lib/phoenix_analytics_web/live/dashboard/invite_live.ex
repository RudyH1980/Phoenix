defmodule PhoenixAnalyticsWeb.Live.Dashboard.InviteLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.{Accounts}
  alias PhoenixAnalytics.Accounts.Organization
  alias PhoenixAnalytics.Emails.InviteEmail
  alias PhoenixAnalytics.Mailer

  @impl true
  def mount(%{"org_id" => org_id}, session, socket) do
    user_id = session["user_id"]
    org = Ash.get!(Organization, org_id)

    unless Accounts.is_org_owner?(user_id, org_id) do
      raise PhoenixAnalyticsWeb.ForbiddenError
    end

    {:ok,
     assign(socket,
       org: org,
       form: to_form(%{"email" => ""}),
       sent: false,
       page_title: "Uitnodiging versturen"
     )}
  end

  @impl true
  def handle_event("submit", %{"email" => email}, socket) do
    org = socket.assigns.org

    case Accounts.request_invite_link(email, org.id) do
      {:ok, token} ->
        token
        |> InviteEmail.build(org, email)
        |> Mailer.deliver()

        {:noreply, assign(socket, sent: true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Kon uitnodiging niet aanmaken.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link> /
        <.link navigate={~p"/dashboard/orgs/#{@org.id}"}>{@org.name}</.link> /
        <strong>Uitnodiging</strong>
      </nav>

      <h2>Teamlid uitnodigen</h2>

      <%= if @sent do %>
        <div class="pa-alert pa-alert--success">
          Uitnodiging verstuurd! De ontvanger krijgt een e-mail met een inloglink.
        </div>
        <.link navigate={~p"/dashboard/orgs/#{@org.id}"} class="pa-btn pa-btn--ghost" style="margin-top:1rem;">
          Terug naar teaminstellingen
        </.link>
      <% else %>
        <.form for={@form} phx-submit="submit" class="pa-form">
          <div class="pa-field">
            <label for="email">E-mailadres</label>
            <input
              type="email"
              id="email"
              name="email"
              value={@form[:email].value}
              placeholder="collega@bedrijf.nl"
              required
              autofocus
            />
          </div>
          <div style="display:flex; gap:0.75rem; align-items:center;">
            <button type="submit" class="pa-btn pa-btn--primary">Uitnodiging versturen</button>
            <.link navigate={~p"/dashboard/orgs/#{@org.id}"} class="pa-btn pa-btn--ghost">
              Annuleren
            </.link>
          </div>
        </.form>
      <% end %>
    </div>
    """
  end
end
