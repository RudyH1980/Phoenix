defmodule PhoenixAnalytics.Analytics.Funnel do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Analytics,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("funnels")
    repo(PhoenixAnalytics.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false)
    attribute(:steps, {:array, :string}, allow_nil?: false, default: [])
    attribute(:site_id, :uuid, allow_nil?: false)
    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name, :steps, :site_id])
    end
  end

  identities do
    identity(:unique_name_per_site, [:name, :site_id])
  end
end
