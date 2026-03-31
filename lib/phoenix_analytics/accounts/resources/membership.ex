defmodule PhoenixAnalytics.Accounts.Membership do
  use Ash.Resource,
    domain: PhoenixAnalytics.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("memberships")
    repo(PhoenixAnalytics.Repo)

    custom_indexes do
      index([:org_id, :user_id], unique: true)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:role, :atom,
      constraints: [one_of: [:owner, :member]],
      default: :member,
      allow_nil?: false
    )

    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:role, :org_id, :user_id])
    end

    update :update do
      accept([:role])
    end
  end

  relationships do
    belongs_to :org, PhoenixAnalytics.Accounts.Organization, allow_nil?: false
    belongs_to :user, PhoenixAnalytics.Accounts.User, allow_nil?: false
  end
end
