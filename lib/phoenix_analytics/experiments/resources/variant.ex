defmodule PhoenixAnalytics.Experiments.Variant do
  use Ash.Resource,
    domain: PhoenixAnalytics.Experiments,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("variants")
    repo(PhoenixAnalytics.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false)
    # Gewicht 0-100, alle varianten per experiment moeten optellen tot 100
    attribute(:weight, :integer, default: 50)
    attribute(:description, :string)
    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name, :weight, :description])
    end

    update :update do
      accept([:name, :weight, :description])
    end
  end

  relationships do
    belongs_to :experiment, PhoenixAnalytics.Experiments.Experiment, allow_nil?: false
  end
end
