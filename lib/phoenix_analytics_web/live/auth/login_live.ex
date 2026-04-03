defmodule PhoenixAnalyticsWeb.Live.Auth.LoginLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Accounts
  alias PhoenixAnalytics.Emails.MagicLinkEmail
  alias PhoenixAnalytics.Mailer
  alias PhoenixAnalytics.PasskeyChallengeStore
  alias PhoenixAnalytics.RateLimiter

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
       remote_ip: ip,
       passkey_session_key: nil
     )}
  end

  @impl true
  def handle_event("password_login", %{"email" => email, "password" => password}, socket) do
    case RateLimiter.hit("login:#{socket.assigns.remote_ip}", 10 * 60_000, 5) do
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
    case RateLimiter.hit("login:#{socket.assigns.remote_ip}", 10 * 60_000, 5) do
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

  def handle_event("start_passkey_login", _params, socket) do
    origin = PhoenixAnalyticsWeb.Endpoint.url()
    rp_id = PhoenixAnalyticsWeb.Endpoint.host()

    challenge =
      Wax.new_authentication_challenge(
        origin: origin,
        rp_id: rp_id,
        user_verification: "preferred"
      )

    session_key = Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
    PasskeyChallengeStore.put("auth:#{session_key}", challenge)

    {:noreply,
     socket
     |> assign(passkey_session_key: session_key)
     |> push_event("passkey_auth_challenge", %{
       challenge: Base.url_encode64(challenge.bytes, padding: false),
       rpId: rp_id,
       userVerification: "preferred",
       timeout: 60_000
     })}
  end

  def handle_event("passkey_login_response", %{"response" => resp}, socket) do
    session_key = socket.assigns[:passkey_session_key]

    with {:ok, challenge} <- PasskeyChallengeStore.get("auth:#{session_key}"),
         credential_id = Base.url_decode64!(resp["id"], padding: false),
         {:ok, passkey} <- Accounts.get_passkey_by_credential_id(credential_id),
         {:ok, new_sign_count} <- verify_authentication(resp, passkey, challenge) do
      PasskeyChallengeStore.delete("auth:#{session_key}")
      Accounts.update_passkey_sign_count(passkey, new_sign_count)

      {:noreply,
       socket
       |> put_flash(:info, "Welkom terug!")
       |> redirect(to: "/auth/verify_password?user_id=#{passkey.user.id}&passkey=true")}
    else
      _ ->
        {:noreply, assign(socket, error: "Passkey verificatie mislukt. Probeer opnieuw.")}
    end
  end

  defp verify_authentication(resp, passkey, challenge) do
    cose_key = :erlang.binary_to_term(passkey.public_key, [:safe])
    auth_data_bin = Base.url_decode64!(resp["authenticatorData"], padding: false)
    sig = Base.url_decode64!(resp["signature"], padding: false)
    client_data_json_raw = Base.url_decode64!(resp["clientDataJSON"], padding: false)

    challenge_with_creds =
      %{challenge | allow_credentials: [{passkey.credential_id, cose_key}]}

    case Wax.authenticate(
           passkey.credential_id,
           auth_data_bin,
           sig,
           client_data_json_raw,
           challenge_with_creds
         ) do
      {:ok, auth_data} -> {:ok, auth_data.sign_count}
      {:error, reason} -> {:error, reason}
    end
  end

  defp send_magic_link_email(email, token) do
    Mailer.deliver(MagicLinkEmail.build(email, token))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-auth-container" id="login-container" phx-hook="PasskeyLogin">
      <div class="pa-auth-card">
        <h1>Neo Analytics</h1>

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
        <button
          phx-click="start_passkey_login"
          class="pa-btn pa-btn--ghost pa-btn--full"
          style="margin-top:0.5rem;"
        >
          Inloggen met passkey
        </button>

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
              <label for="magic_email" class="sr-only">E-mailadres voor magic link</label>
              <input
                type="email"
                id="magic_email"
                name="email"
                placeholder="jij@voorbeeld.nl"
                required
              />
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
