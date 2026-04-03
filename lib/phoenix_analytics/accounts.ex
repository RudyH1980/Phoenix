defmodule PhoenixAnalytics.Accounts do
  @moduledoc false
  use Ash.Domain

  require Ash.Query

  alias PhoenixAnalytics.Accounts.MagicToken
  alias PhoenixAnalytics.Accounts.Membership
  alias PhoenixAnalytics.Accounts.Organization
  alias PhoenixAnalytics.Accounts.Passkey
  alias PhoenixAnalytics.Accounts.User

  resources do
    resource(User)
    resource(MagicToken)
    resource(Organization)
    resource(Membership)
    resource(Passkey)
  end

  # --- Magic link flow ---

  def request_magic_link(email) do
    if email_allowed?(email) do
      with {:ok, user} <- find_or_create_user(email) do
        MagicToken
        |> Ash.Changeset.for_create(:create, %{user_id: user.id})
        |> Ash.create()
      end
    else
      # Geef altijd :ok terug -- geen e-mail enumeration
      {:ok, :not_allowed}
    end
  end

  def request_invite_link(email, org_id) do
    with {:ok, user} <- find_or_create_user(email) do
      MagicToken
      |> Ash.Changeset.for_create(:create, %{user_id: user.id, invite_org_id: org_id})
      |> Ash.create()
    end
  end

  defp email_allowed?(email) do
    case System.get_env("ALLOWED_EMAILS") do
      nil ->
        true

      "" ->
        true

      allowed ->
        allowed
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.downcase/1)
        |> Enum.member?(String.downcase(email))
    end
  end

  defp find_or_create_user(email) do
    case User
         |> Ash.Query.filter(email == ^email)
         |> Ash.read_one() do
      {:ok, nil} ->
        User
        |> Ash.Changeset.for_create(:create, %{email: email})
        |> Ash.create()

      {:ok, user} ->
        {:ok, user}

      error ->
        error
    end
  end

  def authenticate(email, password) do
    case User
         |> Ash.Query.filter(email == ^email)
         |> Ash.read_one() do
      {:ok, %User{hashed_password: hash} = user} when not is_nil(hash) ->
        if PhoenixAnalytics.Crypto.verify_password(password, hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end

      _ ->
        # Voer altijd een hash-operatie uit om timing attacks te voorkomen
        PhoenixAnalytics.Crypto.hash_password(password)
        {:error, :invalid_credentials}
    end
  end

  def set_password(email, password) do
    with {:ok, user} <- find_or_create_user(email) do
      user
      |> Ash.Changeset.for_update(:set_password, %{password: password})
      |> Ash.update()
    end
  end

  def set_initial_password_hash(email, hash) do
    with {:ok, user} <- find_or_create_user(email) do
      if is_nil(user.hashed_password) do
        user
        |> Ash.Changeset.for_update(:set_password_hash, %{hashed_password: hash})
        |> Ash.update()
      else
        {:ok, user}
      end
    end
  end

  def verify_token(token_string) do
    query =
      MagicToken
      |> Ash.Query.for_read(:valid, %{token: token_string})
      |> Ash.Query.load(:user)

    with {:ok, [magic_token]} <- Ash.read(query),
         {:ok, _} <-
           magic_token
           |> Ash.Changeset.for_update(:use)
           |> Ash.update() do
      {:ok, magic_token.user, magic_token.invite_org_id}
    else
      {:ok, []} -> {:error, :invalid_or_expired}
      error -> error
    end
  end

  # --- Organisatie flow ---

  def get_or_create_default_org(user) do
    case user_orgs(user.id) do
      [] ->
        org_name = user.name || user.email |> to_string() |> String.split("@") |> hd()
        create_org_with_owner(org_name, user.id)

      [membership | _] ->
        {:ok, membership.org}
    end
  end

  def user_orgs(user_id) do
    Membership
    |> Ash.Query.filter(user_id == ^user_id)
    |> Ash.Query.load(:org)
    |> Ash.read!()
  end

  def user_org_ids(user_id) do
    user_orgs(user_id) |> Enum.map(& &1.org_id)
  end

  def create_org_with_owner(name, user_id) do
    with {:ok, org} <-
           Organization
           |> Ash.Changeset.for_create(:create, %{name: name})
           |> Ash.create(),
         {:ok, _} <-
           Membership
           |> Ash.Changeset.for_create(:create, %{org_id: org.id, user_id: user_id, role: :owner})
           |> Ash.create() do
      {:ok, org}
    end
  end

  def accept_invite(user_id, org_id) do
    # Upsert: als lidmaatschap al bestaat, geen actie
    case Membership
         |> Ash.Query.filter(user_id == ^user_id and org_id == ^org_id)
         |> Ash.read_one() do
      {:ok, nil} ->
        Membership
        |> Ash.Changeset.for_create(:create, %{org_id: org_id, user_id: user_id, role: :member})
        |> Ash.create()

      {:ok, membership} ->
        {:ok, membership}

      error ->
        error
    end
  end

  def org_members(org_id) do
    Membership
    |> Ash.Query.filter(org_id == ^org_id)
    |> Ash.Query.load(:user)
    |> Ash.read!()
  end

  def remove_member(membership_id) do
    case Ash.get(Membership, membership_id) do
      {:ok, membership} -> Ash.destroy(membership)
      error -> error
    end
  end

  def org_owner?(user_id, org_id) do
    case Membership
         |> Ash.Query.filter(user_id == ^user_id and org_id == ^org_id and role == "owner")
         |> Ash.read_one() do
      {:ok, nil} -> false
      {:ok, _} -> true
      _ -> false
    end
  end

  # --- Passkey flow ---

  def list_passkeys(user_id) do
    Passkey
    |> Ash.Query.filter(user_id == ^user_id)
    |> Ash.read!()
  end

  def create_passkey(user_id, credential_id, public_key, sign_count, name) do
    Passkey
    |> Ash.Changeset.for_create(:create, %{
      user_id: user_id,
      credential_id: credential_id,
      public_key: public_key,
      sign_count: sign_count,
      name: name
    })
    |> Ash.create()
  end

  def get_passkey_by_credential_id(credential_id) do
    Passkey
    |> Ash.Query.filter(credential_id == ^credential_id)
    |> Ash.Query.load(:user)
    |> Ash.read_one()
  end

  def update_passkey_sign_count(passkey, sign_count) do
    passkey
    |> Ash.Changeset.for_update(:update_sign_count, %{sign_count: sign_count})
    |> Ash.update()
  end

  def delete_passkey(passkey_id) do
    case Ash.get(Passkey, passkey_id) do
      {:ok, passkey} -> Ash.destroy(passkey)
      error -> error
    end
  end
end
