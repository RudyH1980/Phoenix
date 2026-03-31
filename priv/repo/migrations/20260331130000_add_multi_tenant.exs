defmodule PhoenixAnalytics.Repo.Migrations.AddMultiTenant do
  use Ecto.Migration

  def up do
    create table(:organizations, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text, null: false
      add :slug, :text, null: false

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create unique_index(:organizations, [:slug], name: "organizations_unique_slug_index")

    create table(:memberships, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :role, :text, null: false, default: "member"

      add :org_id, references(:organizations, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create unique_index(:memberships, [:org_id, :user_id],
             name: "memberships_unique_org_user_index"
           )

    alter table(:sites) do
      add :org_id, references(:organizations, type: :uuid, on_delete: :nilify_all)
    end

    alter table(:magic_tokens) do
      add :invite_org_id, references(:organizations, type: :uuid, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:magic_tokens) do
      remove :invite_org_id
    end

    alter table(:sites) do
      remove :org_id
    end

    drop table(:memberships)
    drop table(:organizations)
  end
end
