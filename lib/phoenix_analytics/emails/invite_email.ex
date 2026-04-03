defmodule PhoenixAnalytics.Emails.InviteEmail do
  @moduledoc false
  import Swoosh.Email

  def build(token, org, to_email) do
    link = PhoenixAnalyticsWeb.Endpoint.url() <> "/auth/verify?token=#{token.token}"

    new()
    |> to(to_email)
    |> from({"Neo Analytics", System.get_env("MAIL_FROM") || "onboarding@resend.dev"})
    |> subject("Uitnodiging: #{org.name} op Neo Analytics")
    |> text_body("""
    Hallo,

    Je bent uitgenodigd om lid te worden van #{org.name} op Neo Analytics.

    Klik op onderstaande link om je account aan te maken en de uitnodiging te accepteren.
    Deze link is 15 minuten geldig.

    #{link}

    Als je dit niet verwacht had, kun je dit bericht negeren.

    Neo Analytics
    """)
  end
end
