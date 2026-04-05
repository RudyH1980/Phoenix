defmodule PhoenixAnalyticsWeb.AuthController do
  use PhoenixAnalyticsWeb, :controller

  require Logger

  alias PhoenixAnalytics.Accounts
  alias PhoenixAnalytics.RateLimiter

  defp ip_string(conn), do: conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

  def verify(conn, %{"token" => token}) do
    case RateLimiter.hit("verify:#{ip_string(conn)}", 15 * 60_000, 10) do
      {:deny, _} ->
        conn
        |> put_flash(:error, "Te veel pogingen. Probeer het later opnieuw.")
        |> redirect(to: ~p"/login")
        |> halt()

      {:allow, _} ->
        case Accounts.verify_token(token) do
          {:ok, user, invite_org_id} ->
            handle_verified_user(conn, user, invite_org_id)

          {:error, :invalid_or_expired} ->
            conn
            |> put_flash(:error, "Link is verlopen of al gebruikt. Vraag een nieuwe aan.")
            |> redirect(to: ~p"/login")
        end
    end
  end

  defp handle_verified_user(conn, user, invite_org_id) do
    if invite_org_id, do: Accounts.accept_invite(user.id, invite_org_id)
    {:ok, _org} = Accounts.get_or_create_default_org(user)

    Logger.info("LOGIN via magic_link",
      user_id: user.id,
      email: user.email,
      ip: ip_string(conn),
      at: DateTime.utc_now() |> DateTime.to_iso8601()
    )

    welcome = if invite_org_id, do: "Welkom - uitnodiging geaccepteerd!", else: "Welkom terug!"
    redirect_to = if user_has_sites?(user.id), do: ~p"/dashboard?neo=1", else: ~p"/onboarding"

    conn
    |> configure_session(renew: true)
    |> put_session(:user_id, user.id)
    |> put_flash(:info, welcome)
    |> redirect(to: redirect_to)
  end

  defp user_has_sites?(user_id) do
    import Ecto.Query

    org_ids = Accounts.user_org_ids(user_id)

    bins =
      Enum.flat_map(org_ids, fn id ->
        case Ecto.UUID.dump(id) do
          {:ok, bin} -> [bin]
          _ -> []
        end
      end)

    count =
      PhoenixAnalytics.Repo.one(from(s in "sites", where: s.org_id in ^bins, select: count(s.id)))

    (count || 0) > 0
  end

  def verify_password(conn, %{"user_id" => user_id, "passkey" => "true"}) do
    case RateLimiter.hit("verify_pw:#{ip_string(conn)}", 15 * 60_000, 10) do
      {:deny, _} -> deny_conn(conn)
      {:allow, _} -> handle_password_user(conn, user_id, "passkey")
    end
  end

  def verify_password(conn, %{"user_id" => user_id}) do
    case RateLimiter.hit("verify_pw:#{ip_string(conn)}", 15 * 60_000, 10) do
      {:deny, _} -> deny_conn(conn)
      {:allow, _} -> handle_password_user(conn, user_id, "password")
    end
  end

  defp deny_conn(conn) do
    conn
    |> put_flash(:error, "Te veel pogingen. Probeer het later opnieuw.")
    |> redirect(to: ~p"/login")
    |> halt()
  end

  defp handle_password_user(conn, user_id, method) do
    case Ash.get(Accounts.User, user_id) do
      {:ok, user} ->
        {:ok, _org} = Accounts.get_or_create_default_org(user)

        Logger.info("LOGIN via #{method}",
          user_id: user.id,
          email: user.email,
          ip: ip_string(conn),
          at: DateTime.utc_now() |> DateTime.to_iso8601()
        )

        redirect_to = if user_has_sites?(user.id), do: ~p"/dashboard?neo=1", else: ~p"/onboarding"

        conn
        |> configure_session(renew: true)
        |> put_session(:user_id, user.id)
        |> redirect(to: redirect_to)

      _ ->
        conn
        |> put_flash(:error, "Inloggen mislukt.")
        |> redirect(to: ~p"/login")
    end
  end

  def demo(conn, _params) do
    case RateLimiter.hit("demo:#{ip_string(conn)}", 60 * 60_000, 20) do
      {:deny, _} ->
        conn
        |> put_flash(:error, "Te veel pogingen. Probeer het later opnieuw.")
        |> redirect(to: ~p"/login")
        |> halt()

      {:allow, _} ->
        case PhoenixAnalytics.DemoSeeder.ensure_demo_account() do
          {:ok, user} ->
            Logger.info("DEMO LOGIN",
              user_id: user.id,
              ip: ip_string(conn),
              at: DateTime.utc_now() |> DateTime.to_iso8601()
            )

            conn
            |> configure_session(renew: true)
            |> put_session(:user_id, user.id)
            |> put_session(:demo, true)
            |> redirect(to: ~p"/dashboard?neo=1")

          _ ->
            conn
            |> put_flash(:error, "Demo niet beschikbaar. Probeer het later opnieuw.")
            |> redirect(to: ~p"/login")
        end
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Je bent uitgelogd.")
    |> redirect(to: ~p"/login")
  end
end
