defmodule PhoenixAnalyticsWeb.Live.Auth.PasskeyLive do
  @moduledoc false
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Accounts
  alias PhoenixAnalytics.PasskeyChallengeStore

  @impl true
  def mount(_params, session, socket) do
    user_id = session["user_id"]
    passkeys = Accounts.list_passkeys(user_id)

    {:ok,
     assign(socket,
       user_id: user_id,
       passkeys: passkeys,
       page_title: "Passkeys",
       error: nil,
       status: nil
     )}
  end

  @impl true
  def handle_event("start_register", _params, socket) do
    user_id = socket.assigns.user_id
    origin = PhoenixAnalyticsWeb.Endpoint.url()
    rp_id = PhoenixAnalyticsWeb.Endpoint.host()

    {:ok, user} = Ash.get(Accounts.User, user_id)

    existing = Accounts.list_passkeys(user_id)

    exclude_credentials =
      Enum.map(existing, fn pk ->
        %{type: "public-key", id: Base.url_encode64(pk.credential_id, padding: false)}
      end)

    challenge =
      Wax.new_registration_challenge(
        origin: origin,
        rp_id: rp_id,
        attestation: "none"
      )

    PasskeyChallengeStore.put("reg:#{user_id}", challenge)

    options = %{
      challenge: Base.url_encode64(challenge.bytes, padding: false),
      rp: %{name: "Neo Analytics", id: rp_id},
      user: %{
        id: Base.url_encode64(user_id, padding: false),
        name: user.email,
        displayName: user.email
      },
      pubKeyCredParams: [
        %{type: "public-key", alg: -7},
        %{type: "public-key", alg: -257}
      ],
      excludeCredentials: exclude_credentials,
      authenticatorSelection: %{
        residentKey: "preferred",
        userVerification: "preferred"
      },
      timeout: 60_000
    }

    {:noreply, push_event(socket, "passkey_register_challenge", options)}
  end

  @impl true
  def handle_event("register_response", %{"response" => resp, "name" => name}, socket) do
    user_id = socket.assigns.user_id

    with {:ok, challenge} <- PasskeyChallengeStore.get("reg:#{user_id}"),
         {:ok, credential_id, public_key, sign_count} <-
           verify_registration(resp, challenge) do
      PasskeyChallengeStore.delete("reg:#{user_id}")

      case Accounts.create_passkey(user_id, credential_id, public_key, sign_count, name) do
        {:ok, _} ->
          passkeys = Accounts.list_passkeys(user_id)

          {:noreply,
           assign(socket, passkeys: passkeys, status: "Passkey opgeslagen!", error: nil)}

        {:error, _} ->
          {:noreply, assign(socket, error: "Kon passkey niet opslaan.", status: nil)}
      end
    else
      {:error, reason} ->
        {:noreply, assign(socket, error: "Registratie mislukt: #{inspect(reason)}", status: nil)}
    end
  end

  @impl true
  def handle_event("delete_passkey", %{"id" => id}, socket) do
    Accounts.delete_passkey(id)
    passkeys = Accounts.list_passkeys(socket.assigns.user_id)
    {:noreply, assign(socket, passkeys: passkeys)}
  end

  defp verify_registration(resp, challenge) do
    attestation_object = Base.url_decode64!(resp["attestationObject"], padding: false)
    client_data_json_raw = Base.url_decode64!(resp["clientDataJSON"], padding: false)
    credential_id = Base.url_decode64!(resp["id"], padding: false)

    case Wax.register(attestation_object, client_data_json_raw, challenge) do
      {:ok, {auth_data, _attestation_result}} ->
        public_key = auth_data.attested_credential_data.credential_public_key
        sign_count = auth_data.sign_count

        {:ok, credential_id, :erlang.term_to_binary(public_key), sign_count}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container" id="passkey-manager" phx-hook="PasskeyRegister">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link> / <strong>Passkeys</strong>
      </nav>

      <div class="pa-page-header">
        <h2>Passkeys beheren</h2>
        <button phx-click="start_register" class="pa-btn pa-btn--primary">
          + Passkey toevoegen
        </button>
      </div>

      <%= if @error do %>
        <div class="pa-alert pa-alert--error" style="margin-bottom:1rem;">
          <p>{@error}</p>
        </div>
      <% end %>
      <%= if @status do %>
        <div class="pa-alert pa-alert--success" style="margin-bottom:1rem;">
          <p>{@status}</p>
        </div>
      <% end %>

      <section class="pa-card">
        <h3>Geregistreerde passkeys</h3>
        <%= if Enum.empty?(@passkeys) do %>
          <p class="pa-empty">
            Nog geen passkeys. Voeg er een toe om in te loggen met je telefoon of biometrie.
          </p>
        <% else %>
          <ul class="pa-data-list">
            <%= for pk <- @passkeys do %>
              <li>
                <span>
                  {pk.name || "Passkey"}
                  <span style="font-size:0.75rem; color:var(--pa-text-muted); margin-left:0.5rem;">
                    Aangemaakt: {Calendar.strftime(pk.inserted_at, "%d %b %Y")}
                  </span>
                </span>
                <button
                  phx-click="delete_passkey"
                  phx-value-id={pk.id}
                  class="pa-btn pa-btn--danger pa-btn--sm"
                  data-confirm="Passkey verwijderen?"
                >
                  Verwijderen
                </button>
              </li>
            <% end %>
          </ul>
        <% end %>
      </section>

      <section class="pa-card" style="margin-top:1rem;">
        <h3>Hoe werkt het?</h3>
        <p style="color:var(--pa-text-muted); font-size:0.875rem; line-height:1.6;">
          Passkeys gebruiken de biometrie of PIN van je apparaat (Face ID, vingerafdruk, Windows Hello).
          Je hoeft geen wachtwoord te onthouden. Klik op "+ Passkey toevoegen" en volg de instructies van je browser.
        </p>
      </section>
    </div>
    """
  end
end
