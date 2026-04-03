defmodule PhoenixAnalyticsWeb.LiveAuth do
  @moduledoc false
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
            is_demo = session["demo"] == true

            {:cont,
             Phoenix.Component.assign(socket,
               current_user: user,
               current_org_ids: org_ids,
               is_demo: is_demo
             )}

          _ ->
            {:halt, redirect(socket, to: "/login")}
        end
    end
  end
end
