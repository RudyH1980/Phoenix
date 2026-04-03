defmodule PhoenixAnalytics.Repo.Migrations.AddDeletedAtToSites do
  use Ecto.Migration

  def up do
    alter table(:sites) do
      add :deleted_at, :utc_datetime_usec, null: true
    end

    create index(:sites, [:deleted_at])
  end

  def down do
    drop index(:sites, [:deleted_at])

    alter table(:sites) do
      remove :deleted_at
    end
  end
end
