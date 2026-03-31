defmodule PhoenixAnalyticsWeb.Live.Auth.LoginLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"email" => ""}), sent: false, page_title: "Inloggen")}
  end

  @impl true
  def handle_event("submit", %{"email" => email}, socket) do
    case Accounts.request_magic_link(email) do
      {:ok, magic_token} ->
        send_magic_link_email(email, magic_token.token)
        {:noreply, assign(socket, sent: true)}

      {:error, _} ->
        # Toon altijd "verstuurd" om email enumeration te voorkomen
        {:noreply, assign(socket, sent: true)}
    end
  end

  defp send_magic_link_email(email, token) do
    PhoenixAnalytics.Mailer.deliver(
      PhoenixAnalytics.Emails.MagicLinkEmail.build(email, token)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-auth-container">
      <div class="pa-auth-card">
        <h1>Phoenix Analytics</h1>

        <%= if @sent do %>
          <p>Check je inbox</p>
          <div class="pa-alert pa-alert--success">
            <p><strong>Magic link verstuurd!</strong></p>
            <p>Controleer je inbox (en spammap). De link is 15 minuten geldig.</p>
          </div>
        <% else %>
          <p>Vul je e-mailadres in om in te loggen.</p>
          <.form for={@form} phx-submit="submit" class="pa-form">
            <div class="pa-field">
              <label for="email">E-mailadres</label>
              <input
                type="email"
                id="email"
                name="email"
                value={@form[:email].value}
                placeholder="jij@voorbeeld.nl"
                required
                autofocus
              />
            </div>
            <button type="submit" class="pa-btn pa-btn--primary pa-btn--full">
              Stuur magic link
            </button>
          </.form>
        <% end %>
      </div>
    </div>
    """
  end
end
