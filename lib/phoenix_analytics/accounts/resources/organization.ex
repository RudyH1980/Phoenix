defmodule PhoenixAnalytics.Accounts.Organization do
  @moduledoc false
  use Ash.Resource,
    domain: PhoenixAnalytics.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("organizations")
    repo(PhoenixAnalytics.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false)
    # URL-veilige identifier, gegenereerd uit naam
    attribute(:slug, :string, allow_nil?: false)
    timestamps()
  end

  identities do
    identity(:unique_slug, [:slug])
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name])

      change(fn changeset, _ ->
        name = Ash.Changeset.get_attribute(changeset, :name) || ""
        slug = slugify(name) <> "-" <> random_suffix()
        Ash.Changeset.force_change_attribute(changeset, :slug, slug)
      end)
    end

    update :update do
      accept([:name])
    end
  end

  relationships do
    has_many :memberships, PhoenixAnalytics.Accounts.Membership, destination_attribute: :org_id

    has_many :sites, PhoenixAnalytics.Analytics.Site, destination_attribute: :org_id
  end

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/, "")
    |> String.split(~r/\s+/, trim: true)
    |> Enum.join("-")
    |> String.slice(0, 40)
    |> case do
      "" -> "team"
      s -> s
    end
  end

  defp random_suffix do
    :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  end
end
