defmodule PhoenixAnalytics.Repo.Migrations.AddWebhookToExperiments do
  use Ecto.Migration

  def up do
    alter table(:experiments) do
      add :webhook_url, :text
      add :webhook_notified_at, :utc_datetime_usec
    end
  end

  def down do
    alter table(:experiments) do
      remove :webhook_url
      remove :webhook_notified_at
    end
  end
end
