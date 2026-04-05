defmodule PhoenixAnalytics.Repo.Migrations.CreateFunnels do
  use Ecto.Migration

  def up do
    create table(:funnels, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:steps, {:array, :string}, null: false, default: [])

      add(:site_id, references(:sites, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:funnels, [:name, :site_id]))
    create(index(:funnels, [:site_id]))
  end

  def down do
    drop(table(:funnels))
  end
end
