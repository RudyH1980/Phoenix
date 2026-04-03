defmodule PhoenixAnalytics.Accounts.User do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("users")
    repo(PhoenixAnalytics.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:email, :ci_string, allow_nil?: false)
    attribute(:name, :string)
    attribute(:hashed_password, :string, allow_nil?: true, sensitive?: true)
    timestamps()
  end

  identities do
    identity(:unique_email, [:email])
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:email, :name])
    end

    update :set_password_hash do
      accept([:hashed_password])
      require_atomic?(false)
    end

    update :set_password do
      accept([])
      require_atomic?(false)
      argument(:password, :string, allow_nil?: false)

      change(fn changeset, _ ->
        password = Ash.Changeset.get_argument(changeset, :password)

        Ash.Changeset.change_attribute(
          changeset,
          :hashed_password,
          PhoenixAnalytics.Crypto.hash_password(password)
        )
      end)
    end

    read :by_email do
      argument(:email, :ci_string, allow_nil?: false)
      filter(expr(email == ^arg(:email)))
    end
  end
end
