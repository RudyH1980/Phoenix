defmodule PhoenixAnalytics.Repo.Migrations.AddTagsToSites do
  use Ecto.Migration

  def change do
    alter table(:sites) do
      add(:tags, {:array, :string}, default: [])
    end
  end
end
