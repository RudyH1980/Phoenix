defmodule PhoenixAnalytics.Analytics.Site do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Analytics,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("sites")
    repo(PhoenixAnalytics.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false)
    attribute(:domain, :string, allow_nil?: false)
    attribute(:token, :string, allow_nil?: false)
    attribute(:active, :boolean, default: true)
    attribute(:tags, {:array, :string}, default: [])
    # Multi-tenant: site hoort bij een organisatie (nullable voor bestaande data)
    attribute(:org_id, :uuid)
    # Soft delete: nil = actief, timestamp = verwijderd (data bewaard 6 maanden)
    attribute(:deleted_at, :utc_datetime_usec, allow_nil?: true)
    timestamps()
  end

  identities do
    identity(:unique_domain, [:domain])
    identity(:unique_token, [:token])
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name, :domain, :org_id])

      change(fn changeset, _ ->
        Ash.Changeset.force_change_attribute(
          changeset,
          :token,
          Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
        )
      end)
    end

    update :update do
      accept([:name, :domain, :active, :tags])
    end

    update :soft_delete do
      accept([])
      change(set_attribute(:deleted_at, &DateTime.utc_now/0))
      change(set_attribute(:active, false))
    end
  end

  relationships do
    has_many :pageviews, PhoenixAnalytics.Analytics.Pageview
    has_many :events, PhoenixAnalytics.Analytics.Event
    has_many :experiments, PhoenixAnalytics.Experiments.Experiment
  end
end
