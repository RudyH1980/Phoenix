defmodule PhoenixAnalytics.Experiments.Experiment do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Experiments,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("experiments")
    repo(PhoenixAnalytics.Repo)

    custom_indexes do
      index([:site_id, :status])
    end
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false)
    attribute(:description, :string)
    attribute(:goal_event, :string, allow_nil?: false)

    attribute(:status, :atom,
      constraints: [one_of: [:draft, :running, :stopped, :archived]],
      default: :draft
    )

    # Optionele webhook URL -- notificatie bij significant resultaat
    attribute(:webhook_url, :string)
    attribute(:webhook_notified_at, :utc_datetime_usec)

    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name, :description, :goal_event, :webhook_url])
    end

    update :start do
      change(set_attribute(:status, :running))
    end

    update :stop do
      change(set_attribute(:status, :stopped))
    end

    update :update do
      accept([:name, :description, :goal_event, :webhook_url])
    end

    update :mark_webhook_notified do
      change(set_attribute(:webhook_notified_at, &DateTime.utc_now/0))
    end
  end

  relationships do
    belongs_to :site, PhoenixAnalytics.Analytics.Site, allow_nil?: false
    has_many :variants, PhoenixAnalytics.Experiments.Variant
    has_many :assignments, PhoenixAnalytics.Experiments.Assignment
  end
end
