defmodule PhoenixAnalytics.Repo.Migrations.AddCityRegionToPageviews do
  use Ecto.Migration

  def change do
    alter table(:pageviews) do
      add(:city, :string)
      add(:region, :string)
    end
  end
end
