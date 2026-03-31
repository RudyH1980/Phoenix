defmodule PhoenixAnalytics.Repo do
  use AshPostgres.Repo,
    otp_app: :phoenix_analytics,
    warn_on_missing_ash_functions?: false

  def installed_extensions do
    ["uuid-ossp", "citext"]
  end

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
end
