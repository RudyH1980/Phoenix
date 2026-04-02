defmodule PhoenixAnalyticsWeb.LiveAuth do
  import Phoenix.LiveView
  alias PhoenixAnalytics.Accounts

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:halt, redirect(socket, to: "/login")}

      user_id ->
        case Ash.get(Accounts.User, user_id) do
          {:ok, user} ->
            org_ids = Accounts.user_org_ids(user_id)

            {:cont,
             Phoenix.Component.assign(socket,
               current_user: user,
               current_org_ids: org_ids
             )}

          _ ->
            {:halt, redirect(socket, to: "/login")}
        end
    end
  end
end
