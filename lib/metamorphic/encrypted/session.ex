defmodule Metamorphic.Encrypted.Session do
  @moduledoc false

  def signing_salt, do: System.fetch_env!("SESSION_SIGNING_SALT")
  def encryption_salt, do: System.fetch_env!("SESSION_ENCRYPTION_SALT")
  def server_public_key, do: System.fetch_env!("SERVER_PUBLIC_KEY")
  def server_private_key, do: System.fetch_env!("SERVER_PRIVATE_KEY")
  def avatars_bucket, do: System.fetch_env!("AVATARS_BUCKET")
end
