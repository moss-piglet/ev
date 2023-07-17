defmodule Metamorphic.Encrypted.Binary do
  @moduledoc """
  Cloak.Ecto module for implementing encryption
  functionality for binary fields.
  """
  use Cloak.Ecto.Binary, vault: Metamorphic.Vault
end
