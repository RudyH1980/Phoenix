defmodule PhoenixAnalytics.Accounts.MagicToken do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("magic_tokens")
    repo(PhoenixAnalytics.Repo)

    custom_indexes do
      index([:token], unique: true)
      index([:inserted_at])
    end
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:token, :string, allow_nil?: false)
    # TTL: 15 minuten (Magnitude standaard)
    attribute(:expires_at, :utc_datetime, allow_nil?: false)
    attribute(:used, :boolean, default: false)
    # Optioneel: uitnodiging voor een organisatie
    attribute(:invite_org_id, :uuid)
    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:user_id, :invite_org_id])

      change(fn changeset, _ ->
        token = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
        expires_at = DateTime.add(DateTime.utc_now(), 15 * 60, :second)

        changeset
        |> Ash.Changeset.force_change_attribute(:token, token)
        |> Ash.Changeset.force_change_attribute(:expires_at, expires_at)
      end)
    end

    update :use do
      change(set_attribute(:used, true))
    end

    read :valid do
      argument(:token, :string, allow_nil?: false)

      filter(
        expr(
          token == ^arg(:token) and
            used == false and
            expires_at > ^DateTime.utc_now()
        )
      )
    end
  end

  relationships do
    belongs_to :user, PhoenixAnalytics.Accounts.User, allow_nil?: false
  end
end
