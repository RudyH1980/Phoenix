defmodule PhoenixAnalyticsWeb.AuthController do
  use PhoenixAnalyticsWeb, :controller

  alias PhoenixAnalytics.Accounts

  def verify(conn, %{"token" => token}) do
    case Accounts.verify_token(token) do
      {:ok, user, invite_org_id} ->
        # Verwerk uitnodiging als aanwezig
        if invite_org_id, do: Accounts.accept_invite(user.id, invite_org_id)

        # Zorg voor standaard org bij eerste login
        {:ok, _org} = Accounts.get_or_create_default_org(user)

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welkom#{if invite_org_id, do: " — uitnodiging geaccepteerd!", else: " terug!"}")
        |> redirect(to: ~p"/dashboard")

      {:error, :invalid_or_expired} ->
        conn
        |> put_flash(:error, "Link is verlopen of al gebruikt. Vraag een nieuwe aan.")
        |> redirect(to: ~p"/login")
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Je bent uitgelogd.")
    |> redirect(to: ~p"/login")
  end
end
