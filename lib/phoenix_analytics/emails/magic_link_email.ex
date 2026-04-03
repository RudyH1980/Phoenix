defmodule PhoenixAnalytics.Emails.MagicLinkEmail do
  @moduledoc false
  import Swoosh.Email

  def build(to_email, token) do
    link = PhoenixAnalyticsWeb.Endpoint.url() <> "/auth/verify?token=#{token}"

    new()
    |> to(to_email)
    |> from({"Neo Analytics", System.get_env("MAIL_FROM") || "onboarding@resend.dev"})
    |> subject("Jouw inloglink voor Neo Analytics")
    |> text_body("""
    Hallo,

    Klik op onderstaande link om in te loggen bij Neo Analytics.
    Deze link is 15 minuten geldig en kan maar eenmalig gebruikt worden.

    #{link}

    Als je dit niet aangevraagd hebt, kun je dit bericht negeren.

    Neo Analytics
    """)
  end
end
