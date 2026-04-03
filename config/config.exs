# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :phoenix_analytics,
  ecto_repos: [PhoenixAnalytics.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :phoenix_analytics, PhoenixAnalyticsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PhoenixAnalyticsWeb.ErrorHTML, json: PhoenixAnalyticsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhoenixAnalytics.PubSub,
  live_view: [signing_salt: "UYloql4p"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :phoenix_analytics, PhoenixAnalytics.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.get_env("SMTP_HOST", "localhost"),
  port: String.to_integer(System.get_env("SMTP_PORT", "1025")),
  ssl: false,
  tls: :never,
  auth: :never

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  phoenix_analytics: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  phoenix_analytics: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :email, :ip, :at]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Ash Framework
config :phoenix_analytics, :ash_domains, [
  PhoenixAnalytics.Accounts,
  PhoenixAnalytics.Analytics,
  PhoenixAnalytics.Experiments
]

# ForbiddenError voor org-access controle
config :phoenix_analytics, :forbidden_error, PhoenixAnalyticsWeb.ForbiddenError

# Oban background jobs
config :phoenix_analytics, Oban,
  repo: PhoenixAnalytics.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 3 * * *", PhoenixAnalytics.Workers.TokenCleanupWorker},
       {"0 4 * * *", PhoenixAnalytics.Workers.DataRetentionWorker},
       {"0 * * * *", PhoenixAnalytics.Workers.SignificanceNotifierWorker}
     ]}
  ],
  queues: [default: 10, analytics: 20]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
