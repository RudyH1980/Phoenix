defmodule PhoenixAnalytics.Repo.Migrations.AddDataRetentionToOrgs do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add(:data_retention_months, :integer, default: 13, null: true)
    end
  end
end
