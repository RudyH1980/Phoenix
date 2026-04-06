defmodule PhoenixAnalytics.Repo.Migrations.AddDeletedAtToPageviews do
  use Ecto.Migration

  def change do
    alter table(:pageviews) do
      add :deleted_at, :utc_datetime, null: true
    end

    create index(:pageviews, [:deleted_at])
  end
end
