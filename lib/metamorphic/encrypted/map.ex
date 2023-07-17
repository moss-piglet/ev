defmodule Metamorphic.Encrypted.Map do
  @moduledoc """
  Cloak.Ecto module for implementing encryption
  functionality for map fields.
  """
  use Cloak.Ecto.Map, vault: Metamorphic.Vault
end
