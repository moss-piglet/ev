defmodule Metamorphic.Encrypted.Session do
  @moduledoc false

  def signing_salt, do: System.fetch_env!("SESSION_SIGNING_SALT")
  def encryption_salt, do: System.fetch_env!("SESSION_ENCRYPTION_SALT")
end
