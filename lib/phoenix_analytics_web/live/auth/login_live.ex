defmodule PhoenixAnalyticsWeb.Live.Auth.LoginLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Accounts

  @impl true
  def mount(_params, _session, socket) do
    peer_data = get_connect_info(socket, :peer_data)
    ip = if peer_data, do: peer_data.address |> Tuple.to_list() |> Enum.join("."), else: "unknown"

    {:ok,
     assign(socket,
       form: to_form(%{"email" => "", "password" => ""}),
       magic_form: to_form(%{"email" => ""}),
       sent: false,
       error: nil,
       page_title: "Inloggen",
       remote_ip: ip
     )}
  end

  @impl true
  def handle_event("password_login", %{"email" => email, "password" => password}, socket) do
    case PhoenixAnalytics.RateLimiter.hit("login:#{socket.assigns.remote_ip}", 10 * 60_000, 5) do
      {:deny, _} ->
        {:noreply,
         assign(socket, error: "Te veel pogingen. Probeer het over 10 minuten opnieuw.")}

      {:allow, _} ->
        case Accounts.authenticate(email, password) do
          {:ok, user} ->
            {:noreply,
             socket
             |> put_flash(:info, "Welkom terug!")
             |> redirect(to: "/auth/verify_password?user_id=#{user.id}")}

          {:error, _} ->
            {:noreply, assign(socket, error: "Ongeldig e-mailadres of wachtwoord.")}
        end
    end
  end

  def handle_event("magic_link", %{"email" => email}, socket) do
    case PhoenixAnalytics.RateLimiter.hit("login:#{socket.assigns.remote_ip}", 10 * 60_000, 5) do
      {:deny, _} ->
        {:noreply, assign(socket, sent: true)}

      {:allow, _} ->
        case Accounts.request_magic_link(email) do
          {:ok, magic_token} ->
            send_magic_link_email(email, magic_token.token)
            {:noreply, assign(socket, sent: true)}

          _ ->
            {:noreply, assign(socket, sent: true)}
        end
    end
  end

  defp send_magic_link_email(email, token) do
    PhoenixAnalytics.Mailer.deliver(PhoenixAnalytics.Emails.MagicLinkEmail.build(email, token))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-auth-container">
      <div class="pa-auth-card">
        <h1>Phoenix Analytics</h1>

        <%= if @error do %>
          <div class="pa-alert pa-alert--error" style="margin-bottom:1rem;">
            <p>{@error}</p>
          </div>
        <% end %>

        <p>Inloggen met wachtwoord</p>
        <.form for={@form} phx-submit="password_login" class="pa-form">
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
          <div class="pa-field">
            <label for="password">Wachtwoord</label>
            <input type="password" id="password" name="password" required />
          </div>
          <button type="submit" class="pa-btn pa-btn--primary pa-btn--full">
            Inloggen
          </button>
        </.form>

        <hr style="border-color:var(--pa-border-subtle);margin:1.5rem 0;" />

        <%= if @sent do %>
          <div class="pa-alert pa-alert--success">
            <p><strong>Magic link verstuurd!</strong></p>
            <p>Controleer je inbox. De link is 15 minuten geldig.</p>
          </div>
        <% else %>
          <p style="font-size:0.8rem;color:var(--pa-text-muted);margin-bottom:0.75rem;">
            Of log in via e-mail link
          </p>
          <.form for={@magic_form} phx-submit="magic_link" class="pa-form">
            <div class="pa-field">
              <input type="email" name="email" placeholder="jij@voorbeeld.nl" required />
            </div>
            <button type="submit" class="pa-btn pa-btn--ghost pa-btn--full">
              Stuur magic link
            </button>
          </.form>
        <% end %>
      </div>
    </div>
    """
  end
end
