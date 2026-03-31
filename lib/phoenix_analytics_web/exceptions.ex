defmodule PhoenixAnalyticsWeb.ForbiddenError do
  defexception message: "Geen toegang", plug_status: 403
end
