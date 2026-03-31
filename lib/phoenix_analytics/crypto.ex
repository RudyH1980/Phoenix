defmodule PhoenixAnalytics.Crypto do
  @moduledoc """
  Wachtwoord hashing via PBKDF2-SHA256 (Erlang :crypto).
  Geen externe dependency nodig.
  """

  @iterations 100_000
  @key_length 32

  def hash_password(password) do
    salt = :crypto.strong_rand_bytes(16)
    hash = :crypto.pbkdf2_hmac(:sha256, password, salt, @iterations, @key_length)
    Base.encode64(salt) <> "$" <> Base.encode64(hash)
  end

  def verify_password(password, stored) do
    case String.split(stored, "$") do
      [salt_b64, hash_b64] ->
        salt = Base.decode64!(salt_b64)
        expected = Base.decode64!(hash_b64)
        actual = :crypto.pbkdf2_hmac(:sha256, password, salt, @iterations, @key_length)
        Plug.Crypto.secure_compare(actual, expected)

      _ ->
        false
    end
  end
end
