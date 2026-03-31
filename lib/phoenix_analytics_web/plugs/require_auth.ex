defmodule PhoenixAnalyticsWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias PhoenixAnalytics.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "Log in om het dashboard te bekijken.")
        |> redirect(to: "/login")
        |> halt()

      user_id ->
        case Ash.get(Accounts.User, user_id) do
          {:ok, user} ->
            org_ids = Accounts.user_org_ids(user_id)

            conn
            |> assign(:current_user, user)
            |> assign(:current_org_ids, org_ids)

          _ ->
            conn |> clear_session() |> redirect(to: "/login") |> halt()
        end
    end
  end
end
