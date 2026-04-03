defmodule PhoenixAnalytics.Analytics.Event do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Analytics,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("events")
    repo(PhoenixAnalytics.Repo)

    custom_indexes do
      index([:site_id, :event_name, :inserted_at])
      index([:session_hash])
    end
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:session_hash, :string, allow_nil?: false)
    attribute(:event_name, :string, allow_nil?: false)
    attribute(:url, :string, allow_nil?: false)
    # Vrije metadata (klik-target, waarde, etc.) -- nooit PII opslaan
    attribute(:metadata, :map, default: %{})
    # A/B variant koppeling (optioneel)
    attribute(:experiment_id, :uuid)
    attribute(:variant_name, :string)
    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :record do
      accept([
        :site_id,
        :session_hash,
        :event_name,
        :url,
        :metadata,
        :experiment_id,
        :variant_name
      ])
    end
  end

  relationships do
    belongs_to :site, PhoenixAnalytics.Analytics.Site, allow_nil?: false
  end
end
