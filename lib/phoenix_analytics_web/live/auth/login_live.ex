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

    rp_id = PhoenixAnalyticsWeb.Endpoint.host()

    challenge =
      Wax.new_authentication_challenge(
        origin: PhoenixAnalyticsWeb.Endpoint.url(),
        rp_id: rp_id,
        user_verification: "preferred"
      )

    session_key = Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
    PasskeyChallengeStore.put("auth:#{session_key}", challenge)

    {:ok,
     assign(socket,
       magic_form: to_form(%{"email" => ""}),
       sent: false,
       error: nil,
       show_magic_form: false,
       page_title: "Inloggen",
       canonical_url: "https://phoenix-analytics.fly.dev/login",
       remote_ip: ip,
       passkey_challenge: Base.url_encode64(challenge.bytes, padding: false),
       passkey_session_key: session_key,
       passkey_rp_id: rp_id
     )}
  end

  @impl true
  def handle_event("toggle_magic_form", _params, socket) do
    {:noreply, assign(socket, show_magic_form: !socket.assigns.show_magic_form)}
  end

  @impl true
  def handle_event("magic_link", %{"email" => email}, socket) do
    case RateLimiter.hit("login:#{socket.assigns.remote_ip}", 10 * 60_000, 5) do
      {:deny, _} ->
        {:noreply, assign(socket, sent: true)}

      {:allow, _} ->
        case Accounts.request_magic_link(email) do
          {:ok, magic_token} ->
            send_magic_link_email(email, magic_token.token)
            {:noreply, assign(socket, sent: true)}

          {:error, :rate_limited} ->
            {:noreply, assign(socket, error: "Te veel pogingen. Wacht 10 minuten.", sent: false)}

          _ ->
            {:noreply, assign(socket, sent: true)}
        end
    end
  end

  def handle_event(
        "passkey_login_response",
        %{"response" => resp, "session_key" => session_key},
        socket
      ) do
    case RateLimiter.hit("passkey:#{socket.assigns.remote_ip}", 15 * 60_000, 10) do
      {:deny, _} ->
        {:noreply, assign(socket, error: "Te veel pogingen. Probeer het later opnieuw.")}

      {:allow, _} ->
        passkey_login(resp, session_key, socket)
    end
  end

  defp passkey_login(resp, session_key, socket) do
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
    <div
      class="pa-auth-container"
      id="login-container"
      phx-hook="PasskeyLogin"
      data-challenge={@passkey_challenge}
      data-session-key={@passkey_session_key}
      data-rp-id={@passkey_rp_id}
    >
      <div class="pa-auth-card">
        <h1>Neo Analytics</h1>

        <%!-- Demo blok — meest prominent --%>
        <div class="pa-demo-login-block">
          <div class="pa-demo-login-header">
            <span class="pa-demo-badge">DEMO</span>
            <span class="pa-demo-login-title">Bekijk het dashboard</span>
          </div>
          <p class="pa-demo-login-desc">
            3 websites · 6 maanden data · geen account nodig
          </p>
          <a href="/auth/demo" class="pa-btn pa-btn--demo pa-btn--full">
            Probeer de demo →
          </a>
          <a
            href="https://pagespeed.web.dev/analysis?url=https%3A%2F%2Fphoenix-analytics.fly.dev%2F"
            target="_blank"
            rel="noopener noreferrer"
            class="pa-pagespeed-link"
          >
            Test paginasnelheid
          </a>
        </div>

        <div class="pa-or-divider">of log in</div>

        <%= if @error do %>
          <div class="pa-alert pa-alert--error" style="margin-bottom:1rem;">
            <p>{@error}</p>
          </div>
        <% end %>

        <button id="passkey-btn" class="pa-btn pa-btn--ghost pa-btn--full" style="margin-bottom:1rem;">
          Inloggen met passkey
        </button>

        <%= if @sent do %>
          <div class="pa-alert pa-alert--success" style="margin-top:1rem;">
            <p><strong>Magic link verstuurd!</strong></p>
            <p>Controleer je inbox. De link is 15 minuten geldig.</p>
          </div>
        <% else %>
          <button
            phx-click="toggle_magic_form"
            class="pa-btn pa-btn--link pa-btn--full"
            style="margin-top:0.5rem; font-size:0.8rem; color:var(--pa-text-muted);"
          >
            {if @show_magic_form, do: "▲ Verberg e-mail login", else: "▾ Inloggen via e-mail link"}
          </button>

          <%= if @show_magic_form do %>
            <div class="pa-magic-form-wrap">
              <.form for={@magic_form} phx-submit="magic_link" class="pa-form">
                <div class="pa-field">
                  <label for="magic_email" class="sr-only">E-mailadres voor magic link</label>
                  <input
                    type="email"
                    id="magic_email"
                    name="email"
                    placeholder="jij@voorbeeld.nl"
                    required
                    autofocus
                  />
                </div>
                <button type="submit" class="pa-btn pa-btn--ghost pa-btn--full pa-btn--sm">
                  Stuur magic link
                </button>
              </.form>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
