defmodule PhoenixAnalytics.Analytics.Pageview do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Analytics,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("pageviews")
    repo(PhoenixAnalytics.Repo)

    custom_indexes do
      index([:site_id, :inserted_at])
      index([:session_hash])
    end
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:session_hash, :string, allow_nil?: false)
    attribute(:url, :string, allow_nil?: false)
    attribute(:referrer, :string)
    attribute(:utm_source, :string)
    attribute(:utm_medium, :string)
    attribute(:utm_campaign, :string)
    attribute(:country, :string)
    attribute(:city, :string)
    attribute(:region, :string)
    attribute(:device_type, :string)
    attribute(:browser, :string)
    attribute(:os, :string)
    # Nooit raw IP opslaan (AVG) -- alleen dagelijks geroteerd hash
    attribute(:duration_seconds, :integer)
    attribute(:deleted_at, :utc_datetime, allow_nil?: true)
    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    update :soft_delete do
      accept([])
      change(set_attribute(:deleted_at, &DateTime.utc_now/0))
    end

    create :record do
      accept([
        :site_id,
        :session_hash,
        :url,
        :referrer,
        :utm_source,
        :utm_medium,
        :utm_campaign,
        :country,
        :city,
        :region,
        :device_type,
        :browser,
        :os
      ])
    end
  end

  relationships do
    belongs_to :site, PhoenixAnalytics.Analytics.Site, allow_nil?: false
  end
end
