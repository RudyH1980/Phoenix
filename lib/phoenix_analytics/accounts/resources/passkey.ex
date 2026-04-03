defmodule PhoenixAnalytics.Accounts.Passkey do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("passkeys")
    repo(PhoenixAnalytics.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:credential_id, :binary, allow_nil?: false, public?: true)
    attribute(:public_key, :binary, allow_nil?: false, public?: true)
    attribute(:sign_count, :integer, default: 0, public?: true)
    attribute(:name, :string, public?: true)
    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :user, PhoenixAnalytics.Accounts.User, allow_nil?: false, public?: true
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:credential_id, :public_key, :sign_count, :name, :user_id])
    end

    update :update_sign_count do
      accept([:sign_count])
    end
  end
end
