defmodule PhoenixAnalytics.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    run_migrations()
    ensure_demo_account()
    set_initial_password()

    children = [
      PhoenixAnalyticsWeb.Telemetry,
      PhoenixAnalytics.Repo,
      {DNSCluster, query: Application.get_env(:phoenix_analytics, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixAnalytics.PubSub},
      PhoenixAnalytics.RateLimiter,
      {PhoenixAnalytics.PasskeyChallengeStore, []},
      {Oban, Application.fetch_env!(:phoenix_analytics, Oban)},
      PhoenixAnalyticsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixAnalytics.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  defp run_migrations do
    if Application.get_env(:phoenix_analytics, :env) == :prod do
      PhoenixAnalytics.Release.migrate()
    end
  end

  defp ensure_demo_account do
    Task.start(fn ->
      :timer.sleep(4000)
      PhoenixAnalytics.DemoSeeder.ensure_demo_account()
    end)
  end

  defp set_initial_password do
    with hash when is_binary(hash) <- System.get_env("INITIAL_PASSWORD_HASH"),
         emails when is_binary(emails) <- System.get_env("ALLOWED_EMAILS") do
      email = emails |> String.split(",") |> List.first() |> String.trim()

      Task.start(fn ->
        :timer.sleep(2000)
        apply_password_hash(email, hash)
      end)
    end
  end

  defp apply_password_hash(email, hash) do
    case PhoenixAnalytics.Accounts.set_initial_password_hash(email, hash) do
      {:ok, _} -> :ok
      _ -> :ok
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    PhoenixAnalyticsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
