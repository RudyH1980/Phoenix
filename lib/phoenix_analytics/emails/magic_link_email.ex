defmodule PhoenixAnalytics.Emails.MagicLinkEmail do
  import Swoosh.Email

  def build(to_email, token) do
    link = PhoenixAnalyticsWeb.Endpoint.url() <> "/auth/verify?token=#{token}"

    new()
    |> to(to_email)
    |> from({"Phoenix Analytics", System.get_env("MAIL_FROM") || "onboarding@resend.dev"})
    |> subject("Jouw inloglink voor Phoenix Analytics")
    |> text_body("""
    Hallo,

    Klik op onderstaande link om in te loggen bij Phoenix Analytics.
    Deze link is 15 minuten geldig en kan maar eenmalig gebruikt worden.

    #{link}

    Als je dit niet aangevraagd hebt, kun je dit bericht negeren.

    Phoenix Analytics
    """)
  end
end
