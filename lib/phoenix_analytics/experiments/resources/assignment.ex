defmodule PhoenixAnalytics.Experiments.Assignment do
  use Ash.Resource,
    domain: PhoenixAnalytics.Experiments,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "assignments"
    repo PhoenixAnalytics.Repo

    custom_indexes do
      index [:experiment_id, :session_hash], unique: true
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :session_hash, :string, allow_nil?: false
    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :assign do
      accept [:session_hash]
      upsert? true
      upsert_identity :unique_session_experiment
    end
  end

  identities do
    identity :unique_session_experiment, [:experiment_id, :session_hash]
  end

  relationships do
    belongs_to :experiment, PhoenixAnalytics.Experiments.Experiment, allow_nil?: false
    belongs_to :variant, PhoenixAnalytics.Experiments.Variant, allow_nil?: false
  end
end
